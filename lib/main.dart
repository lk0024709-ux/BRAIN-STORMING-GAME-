import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Orientation is declared in AndroidManifest. Billing starts only after an
  // explicit purchase or restore action.
  runApp(const BrainSpeedApp());
}
