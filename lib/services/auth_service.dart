import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class ServicioAutenticacion {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get cambiosEstadoAutenticacion => _auth.authStateChanges();

  // Obtener usuario actual
  User? get usuarioActual => _auth.currentUser;

  // Login con Google
  Future<UserCredential> iniciarSesionConGoogle() async {
    try {
      debugPrint('Iniciando Google Sign In...');
      // 1. Seleccionar cuenta
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign In cancelado por el usuario.');
        throw Exception('Inicio de sesión cancelado por el usuario');
      }
      debugPrint('Usuario de Google obtenido: ${googleUser.email}');

      // 2. Obtener tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('Tokens de Google obtenidos.');

      // 3. Crear credencial de Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Loguear en Firebase
      debugPrint('Iniciando sesión en Firebase con credenciales de Google...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Sesión en Firebase exitosa: ${userCredential.user?.uid}');
      
      // Guardar usuario en Firestore si es nuevo
      await _guardarUsuarioEnFirestore(userCredential.user);

      return userCredential;
    } catch (e) {
      debugPrint('Error detallado en Google Sign In: $e');
      // Si es una excepción nuestra, la relanzamos tal cual
      if (e.toString().contains('Inicio de sesión cancelado')) {
        rethrow;
      }
      // Si es otro error, lo envolvemos
      throw Exception('Error en Google Sign In: $e');
    }
  }

  // Registro con Email y Password
  Future<UserCredential> registrarseConEmailYContrasena(String email, String password, String name) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enviar correo de verificación
      await userCredential.user?.sendEmailVerification();

      // Actualizar nombre de usuario (Display Name)
      await userCredential.user?.updateDisplayName(name);

      // Guardar en Firestore
      await _guardarUsuarioEnFirestore(userCredential.user, name: name);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _manejarExcepcionAuth(e);
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  // Login con Email y Password
  Future<UserCredential> iniciarSesionConEmailYContrasena(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _manejarExcepcionAuth(e);
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  // Enviar correo de recuperación de contraseña
  Future<void> enviarCorreoRecuperacionContrasena(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _manejarExcepcionAuth(e);
    }
  }

  // Cambiar contraseña (requiere re-autenticación si ha pasado mucho tiempo)
  Future<void> cambiarContrasena(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw 'No hay usuario autenticado';

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      // Re-autenticar al usuario antes de operaciones sensibles
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } catch (e) {
      throw _manejarExcepcionAuth(e);
    }
  }

  // Cambiar correo electrónico
  Future<void> cambiarEmail(String currentPassword, String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw 'No hay usuario autenticado';

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(newEmail); 
      // Nota: verifyBeforeUpdateEmail envía un correo de verificación al nuevo email.
      // El cambio no se completa hasta que se verifica.
    } catch (e) {
      throw _manejarExcepcionAuth(e);
    }
  }

  Exception _manejarExcepcionAuth(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No existe usuario con ese correo.');
        case 'wrong-password':
          return Exception('Contraseña incorrecta.');
        case 'email-already-in-use':
          return Exception('El correo ya está en uso por otra cuenta.');
        case 'invalid-email':
          return Exception('El formato del correo no es válido.');
        case 'weak-password':
          return Exception('La contraseña es muy débil.');
        case 'requires-recent-login':
          return Exception('Por seguridad, inicia sesión nuevamente antes de realizar este cambio.');
        case 'user-disabled':
          return Exception('Este usuario ha sido deshabilitado.');
        case 'credential-already-in-use':
          return Exception('Esta credencial ya está asociada a otra cuenta.');
        default:
          return Exception('Error de autenticación: ${e.message}');
      }
    }
    return Exception('Ocurrió un error inesperado: $e');
  }

  // Cerrar Sesión
  Future<void> cerrarSesion() async {
    // Intentar desconectar de Firebase primero (orden invertido para evitar conflictos)
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión de Firebase: $e');
    }

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión de Google: $e');
    }
  }

  // Guardar usuario en Firestore
  Future<void> _guardarUsuarioEnFirestore(User? user, {String? name}) async {
    if (user == null) return;

    final userRef = _firestore.collection('usuarios').doc(user.uid);
    final docSnapshot = await userRef.get();

    if (!docSnapshot.exists) {
      await userRef.set({
        'uid': user.uid,
        'nombre': name ?? user.displayName ?? 'Usuario',
        'email': user.email,
        'fotoUrl': user.photoURL ?? '',
        'rol': 'usuario', // Por defecto rol usuario
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }


}
