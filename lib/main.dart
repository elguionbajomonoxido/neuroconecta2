import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'controllers/settings_controller.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'main',
          context: ErrorDescription('Error inicializando Firebase'),
        ),
      );
      runApp(AppInitErrorScreen(error: e.toString()));
      return;
    }

    final settingsController = ControladorConfiguracion();
    try {
      await settingsController.cargarConfiguracion();
    } catch (e, st) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'main',
          context: ErrorDescription('Error cargando configuración local'),
        ),
      );
    }

    runApp(
      ChangeNotifierProvider.value(
        value: settingsController,
        child: const AplicacionNeuroConecta(),
      ),
    );
  }, (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'main',
        context: ErrorDescription('Excepción no capturada en zona inicial'),
      ),
    );
    runApp(AppInitErrorScreen(error: error.toString()));
  });
}

class AppInitErrorScreen extends StatelessWidget {
  const AppInitErrorScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'No pudimos iniciar la aplicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
