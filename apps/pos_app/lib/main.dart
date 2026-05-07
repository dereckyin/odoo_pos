import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.initialize();
  runApp(const ProviderScope(child: PosApp()));
}
