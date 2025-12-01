import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';

class NeuroConectaApp extends StatelessWidget {
  const NeuroConectaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NeuroConecta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: AppRoutes.router,
    );
  }
}
