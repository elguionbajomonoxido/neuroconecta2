import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'controllers/settings_controller.dart';

class AplicacionNeuroConecta extends StatelessWidget {
  const AplicacionNeuroConecta({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ControladorConfiguracion>(
      builder: (context, settings, child) {
        return MaterialApp.router(
          title: 'NeuroConecta',
          debugShowCheckedModeBanner: false,
          theme: TemaAplicacion.obtenerTema(settings),
          routerConfig: RutasAplicacion.router,
        );
      },
    );
  }
}
