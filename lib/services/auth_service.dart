import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      // 1. Seleccionar cuenta
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado por el usuario');
      }

      // 2. Obtener tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Crear credencial de Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Loguear en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Guardar usuario en Firestore si es nuevo
      await _guardarUsuarioEnFirestore(userCredential.user);

      return userCredential;
    } catch (e) {
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

  // Cerrar Sesión
  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
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

  // Manejo de errores de Firebase Auth
  Exception _manejarExcepcionAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('El correo ya está registrado.');
      case 'invalid-email':
        return Exception('El correo no es válido.');
      case 'weak-password':
        return Exception('La contraseña es muy débil.');
      case 'user-disabled':
        return Exception('Este usuario ha sido deshabilitado.');
      case 'user-not-found':
        return Exception('No se encontró usuario con este correo.');
      case 'wrong-password':
        return Exception('Contraseña incorrecta.');
      case 'credential-already-in-use':
        return Exception('Esta credencial ya está asociada a otra cuenta.');
      default:
        return Exception('Error de autenticación: ${e.message}');
    }
  }
}
