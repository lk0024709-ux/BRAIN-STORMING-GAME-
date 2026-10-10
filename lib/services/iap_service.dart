import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_config.dart';

/// Validates a Play / App Store purchase before Pro is granted.
///
/// This is the complete on-device check: product id must match and the store
/// must report purchased or restored. A backend receipt check is the right
/// extra fraud control before a high-revenue launch; it is not required for the
/// billing flow itself to run.
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
  Future<bool>? _availabilityFlight;
  Future<void>? _prepareFlight;

  ProductDetails? product;
  bool available = false;
  bool storeQueryDone = false;
  bool purchasePending = false;
  bool started = false;
  String? error;
  String? statusMessage;

  bool _availabilityChecked = false;

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

  /// Starts only the purchase-update listener. Availability and product-detail
  /// queries are deferred until the player opens the Pro screen, keeping store
  /// IPC out of the critical first-frame startup path.
  Future<void> start({required Future<void> Function() grantPro}) {
    _grantPro = grantPro;
    if (started) return Future<void>.value();

    try {
      _subscription = _iap.purchaseStream.listen(
        (purchases) => unawaited(_onPurchasesSafely(purchases)),
        onError: (Object caught, StackTrace stackTrace) {
          error = caught.toString();
          purchasePending = false;
          debugPrint('Purchase stream failed: $caught\n$stackTrace');
          notifyListeners();
        },
      );
      started = true;
    } catch (caught, stackTrace) {
      started = false;
      error = 'Purchase updates could not start: $caught';
      debugPrint('Purchase listener setup failed: $caught\n$stackTrace');
    }
    notifyListeners();
    return Future<void>.value();
  }

  /// Checks the store and loads the Pro product once. Pass [force] to retry a
  /// prior unavailable/error result (e.g. after reconnecting to Play Store).
  Future<void> prepareStore({bool force = false}) {
    final inFlight = _prepareFlight;
    if (inFlight != null) return inFlight;
    if (storeQueryDone && !force) return Future<void>.value();

    late final Future<void> flight;
    flight = _loadStore(force: force).whenComplete(() {
      if (identical(_prepareFlight, flight)) _prepareFlight = null;
    });
    _prepareFlight = flight;
    return flight;
  }

  Future<void> _loadStore({required bool force}) async {
    error = null;
    statusMessage = null;
    storeQueryDone = false;
    notifyListeners();

    final storeAvailable = await _checkAvailability(force: force);
    if (!storeAvailable) {
      product = null;
      storeQueryDone = true;
      error ??= 'Google Play Billing is unavailable on this device.';
      notifyListeners();
      return;
    }

    await _queryProducts();
  }

  Future<bool> _checkAvailability({bool force = false}) {
    final inFlight = _availabilityFlight;
    if (inFlight != null) return inFlight;
    if (_availabilityChecked && !force) return Future<bool>.value(available);

    late final Future<bool> flight;
    flight = _queryAvailability().whenComplete(() {
      if (identical(_availabilityFlight, flight)) _availabilityFlight = null;
    });
    _availabilityFlight = flight;
    return flight;
  }

  Future<bool> _queryAvailability() async {
    try {
      available = await _iap.isAvailable();
      if (!available) {
        error = 'Google Play Billing is unavailable on this device.';
      } else {
        error = null;
      }
    } catch (caught, stackTrace) {
      available = false;
      error = 'Could not connect to Google Play Billing: $caught';
      debugPrint('Store availability check failed: $caught\n$stackTrace');
    }
    _availabilityChecked = true;
    notifyListeners();
    return available;
  }

  Future<void> _queryProducts() async {
    try {
      final response = await _iap.queryProductDetails({AppConfig.proProductId});
      if (response.error != null) error = response.error!.message;
      final matches = response.productDetails
          .where((details) => details.id == AppConfig.proProductId)
          .toList(growable: false);
      product = matches.isEmpty ? null : matches.first;
      if (product == null &&
          response.notFoundIDs.contains(AppConfig.proProductId)) {
        error =
            '${AppConfig.proProductId} is not live in the store yet. Create a non-consumable with that exact id.';
      } else if (product == null && error == null) {
        error = 'The Pro product was not returned by the store.';
      }
    } catch (caught, stackTrace) {
      error = 'Could not load Pro pricing: $caught';
      product = null;
      debugPrint('Product query failed: $caught\n$stackTrace');
    }
    storeQueryDone = true;
    notifyListeners();
  }

  Future<bool> buy() async {
    if (purchasePending) return false;
    if (!started) {
      error = 'Purchase updates are not ready. Reopen the app and try again.';
      notifyListeners();
      return false;
    }
    error = null;
    statusMessage = null;
    await prepareStore();
    if (!available) {
      error ??= 'Billing is not available on this device.';
      notifyListeners();
      return false;
    }

    final details = product;
    if (details == null) {
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
    } catch (caught, stackTrace) {
      purchasePending = false;
      error = caught.toString();
      debugPrint('Purchase request failed: $caught\n$stackTrace');
      notifyListeners();
      return false;
    }
  }

  Future<void> restore() async {
    if (purchasePending) return;
    if (!started) {
      error = 'Purchase updates are not ready. Reopen the app and try again.';
      statusMessage = null;
      notifyListeners();
      return;
    }
    error = null;
    statusMessage = 'Asking the store for previous purchases...';
    purchasePending = true;
    notifyListeners();
    try {
      final storeAvailable = await _checkAvailability(force: true);
      if (!storeAvailable) {
        error ??= 'Google Play Billing is unavailable on this device.';
        statusMessage = null;
        return;
      }
      await _iap.restorePurchases();
      statusMessage = 'Restore request sent. If you own Pro, it will unlock.';
    } catch (caught, stackTrace) {
      error = caught.toString();
      statusMessage = null;
      debugPrint('Purchase restore failed: $caught\n$stackTrace');
    } finally {
      purchasePending = false;
      notifyListeners();
    }
  }

  Future<void> _onPurchasesSafely(List<PurchaseDetails> purchases) async {
    try {
      for (final purchase in purchases) {
        await _handle(purchase);
      }
    } catch (caught, stackTrace) {
      error = 'Could not finish processing the purchase: $caught';
      purchasePending = false;
      debugPrint('Purchase update handler failed: $caught\n$stackTrace');
      notifyListeners();
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
          final grantPro = _grantPro;
          if (grantPro == null) {
            error = 'The profile is not ready to receive this purchase yet.';
          } else {
            await grantPro();
            statusMessage = purchase.status == PurchaseStatus.restored
                ? 'Pro restored.'
                : 'Pro unlocked.';
            error = null;
          }
        } else {
          error = 'Purchase could not be verified for ${purchase.productID}.';
        }
        break;
    }

    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
      } catch (caught, stackTrace) {
        debugPrint('completePurchase failed: $caught\n$stackTrace');
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
