import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_config.dart';

/// Validates a Play / App Store purchase before Pro is granted.
///
/// This is the complete on-device check: product id must match and the store
/// must report purchased or restored. A backend receipt check is the right
/// extra fraud control before a high-revenue launch; it is not required for
/// the billing flow itself to run.
class PurchaseVerifier {
  const PurchaseVerifier();

  bool isValidProPurchase(PurchaseDetails purchase) {
    if (purchase.productID != AppConfig.proProductId) return false;
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }
}

class IAPService extends ChangeNotifier {
  IAPService({
    InAppPurchase? iap,
    PurchaseVerifier verifier = const PurchaseVerifier(),
  })  : _iap = iap ?? InAppPurchase.instance,
        _verifier = verifier;

  final InAppPurchase _iap;
  final PurchaseVerifier _verifier;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void> Function()? _grantPro;

  ProductDetails? product;
  bool available = false;
  bool storeQueryDone = false;
  bool purchasePending = false;
  bool started = false;
  String? error;
  String? statusMessage;

  String get priceLabel {
    if (!storeQueryDone) return 'Checking Play Billing...';
    if (!available) return 'Store unavailable on this device';
    final details = product;
    if (details == null) {
      return 'Add ${AppConfig.proProductId} in Play Console';
    }
    return details.price;
  }

  String get productTitle => product?.title ?? 'BrainSpeed IQ Pro';

  Future<void> start({required Future<void> Function() grantPro}) async {
    _grantPro = grantPro;
    if (started) return;
    started = true;
    _subscription = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) {
        this.error = error.toString();
        purchasePending = false;
        notifyListeners();
      },
    );
    try {
      available = await _iap.isAvailable();
    } catch (caught) {
      available = false;
      error = caught.toString();
    }
    if (available) {
      await reloadProducts();
    } else {
      storeQueryDone = true;
    }
    notifyListeners();
  }

  Future<void> reloadProducts() async {
    try {
      final response = await _iap.queryProductDetails({AppConfig.proProductId});
      if (response.error != null) {
        error = response.error!.message;
      }
      if (response.productDetails.isEmpty) {
        product = null;
        if (response.notFoundIDs.contains(AppConfig.proProductId)) {
          error =
              '${AppConfig.proProductId} is not live in the store yet. Create a non-consumable with that exact id.';
        }
      } else {
        product = response.productDetails.first;
        error = response.error?.message;
      }
    } catch (caught) {
      error = caught.toString();
      product = null;
    }
    storeQueryDone = true;
    notifyListeners();
  }

  Future<bool> buy() async {
    error = null;
    statusMessage = null;
    if (!available) {
      error = 'Billing is not available on this device.';
      notifyListeners();
      return false;
    }
    final details = product;
    if (details == null) {
      await reloadProducts();
      error ??=
          'Pro product is missing. Create ${AppConfig.proProductId} as a non-consumable in Play Console.';
      notifyListeners();
      return false;
    }
    purchasePending = true;
    notifyListeners();
    try {
      final startedPurchase = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!startedPurchase) {
        purchasePending = false;
        error = 'The store did not open the purchase sheet.';
        notifyListeners();
      }
      return startedPurchase;
    } catch (caught) {
      purchasePending = false;
      error = caught.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> restore() async {
    error = null;
    statusMessage = 'Asking the store for previous purchases...';
    purchasePending = true;
    notifyListeners();
    try {
      await _iap.restorePurchases();
      statusMessage = 'Restore request sent. If you own Pro, it will unlock.';
    } catch (caught) {
      error = caught.toString();
      statusMessage = null;
    }
    purchasePending = false;
    notifyListeners();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handle(purchase);
    }
  }

  Future<void> _handle(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        purchasePending = true;
        statusMessage = 'Purchase pending approval.';
        notifyListeners();
        return;
      case PurchaseStatus.canceled:
        purchasePending = false;
        statusMessage = 'Purchase canceled.';
        break;
      case PurchaseStatus.error:
        purchasePending = false;
        error = purchase.error?.message ?? 'Purchase failed.';
        statusMessage = null;
        if (_alreadyOwned(purchase.error)) {
          statusMessage = 'Pro is already owned. Restoring...';
          notifyListeners();
          await restore();
        }
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        purchasePending = false;
        if (_verifier.isValidProPurchase(purchase)) {
          await _grantPro?.call();
          statusMessage = purchase.status == PurchaseStatus.restored
              ? 'Pro restored.'
              : 'Pro unlocked.';
          error = null;
        } else {
          error = 'Purchase could not be verified for ${purchase.productID}.';
        }
        break;
    }
    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
      } catch (caught) {
        debugPrint('completePurchase failed: $caught');
      }
    }
    notifyListeners();
  }

  bool _alreadyOwned(IAPError? purchaseError) {
    if (purchaseError == null) return false;
    final blob = '${purchaseError.code} ${purchaseError.message}'.toLowerCase();
    return blob.contains('already') || blob.contains('itemalreadyowned');
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
