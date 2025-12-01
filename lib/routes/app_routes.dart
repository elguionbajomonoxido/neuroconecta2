import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/capsulas/screens/home_screen.dart';
import '../features/capsulas/screens/capsule_detail_screen.dart';
import '../features/capsulas/screens/create_capsule_screen.dart';
import '../features/capsulas/screens/edit_capsule_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String welcome = '/welcome';
  static const String home = '/';
  static const String createCapsule = '/create-capsule';
  static const String editCapsule = '/edit-capsule';
  static const String capsuleDetail = '/capsule-detail';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: createCapsule,
        builder: (context, state) => const CreateCapsuleScreen(),
      ),
      GoRoute(
        path: '$editCapsule/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditCapsuleScreen(capsuleId: id);
        },
      ),
      GoRoute(
        path: '$capsuleDetail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CapsuleDetailScreen(capsuleId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isLoggingIn = state.uri.toString() == login;

      // Si no está logueado y no está en login, mandar a login
      if (!isLoggedIn && !isLoggingIn) {
        return login;
      }

      // Si ya está logueado
      if (isLoggedIn) {
        // Verificar si el email está verificado (si usó email/password)
        // Nota: Google Auth siempre tiene emailVerified = true
        if (!user.emailVerified) {
           // Si estamos en login, permitimos estar ahí para que vea el mensaje de "Verifica tu correo"
           return null; 
        }

        // Si está verificado y trata de ir a login, mandar a home
        if (isLoggingIn) {
          return home; 
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
