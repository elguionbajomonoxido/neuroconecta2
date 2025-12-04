import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/login_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/home_screen.dart';
import '../screens/detalles_capsula_screen.dart';
import '../screens/crea_capsula_screen.dart';
import '../screens/edita_capsula_screen.dart';
import '../screens/settings_screen.dart';

class RutasAplicacion {
  static const String inicioSesion = '/inicio-sesion';
  static const String bienvenida = '/bienvenida';
  static const String inicio = '/';
  static const String crearCapsula = '/crear-capsula';
  static const String editarCapsula = '/editar-capsula';
  static const String detalleCapsula = '/detalle-capsula';
  static const String configuracion = '/configuracion';

  static final GoRouter router = GoRouter(
    initialLocation: inicioSesion,
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    routes: [
      GoRoute(
        path: inicioSesion,
        builder: (context, state) => const PantallaLogin(),
      ),
      GoRoute(
        path: bienvenida,
        builder: (context, state) => const PantallaBienvenida(),
      ),
      GoRoute(
        path: inicio,
        builder: (context, state) => const PaginaInicio(),
      ),
      GoRoute(
        path: configuracion,
        builder: (context, state) => const PaginaConfiguracion(),
      ),
      GoRoute(
        path: crearCapsula,
        builder: (context, state) => const PantallaCrearCapsula(),
      ),
      GoRoute(
        path: '$editarCapsula/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PantallaEditarCapsula(capsuleId: id);
        },
      ),
      GoRoute(
        path: '$detalleCapsula/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PantallaDetalleCapsula(capsuleId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isLoggingIn = state.uri.toString() == inicioSesion;

      // Si no está logueado y no está en inicioSesion, mandar a inicioSesion
      if (!isLoggedIn && !isLoggingIn) {
        return inicioSesion;
      }

      // Si ya está logueado
      if (isLoggedIn) {
        // Verificar si el email está verificado (si usó email/password)
        // Nota: Google Auth siempre tiene emailVerified = true
        if (!user.emailVerified) {
           // Si estamos en inicioSesion, permitimos estar ahí para que vea el mensaje de "Verifica tu correo"
           return null; 
        }

        // Si está verificado y trata de ir a inicioSesion, mandar a bienvenida
        if (isLoggingIn) {
          return bienvenida; 
        }
      }

      return null;
    },
  );
}

// Clase auxiliar para convertir Stream a Listenable para GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
