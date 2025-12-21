import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'controllers/settings_controller.dart';
import 'controllers/favoritos_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar ControladorConfiguracion
  final settingsController = ControladorConfiguracion();
  await settingsController.cargarConfiguracion();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsController),
        ChangeNotifierProvider(create: (_) => FavoritosController()),
      ],
      child: const AplicacionNeuroConecta(),
    ),
  );
}
