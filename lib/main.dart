import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Orientation is declared in AndroidManifest. Keep optional Ads/Billing SDK
  // initialization out of app launch; each service starts only when needed.
  runApp(const BrainSpeedApp());
}
