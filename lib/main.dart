import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/file_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Limpia temporales de sesiones previas (best-effort, sin bloquear el arranque).
  unawaited(FileUtils.cleanTempFiles());
  runApp(const ProviderScope(child: RoLuckApp()));
}
