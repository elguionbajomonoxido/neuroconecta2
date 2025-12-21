import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class FavoritosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final Stream<Set<String>> _favoritosStream = _createFavoritosStream();

  /// Retorna un Stream que emite el Set de IDs de cápsulas favoritas del usuario actual
  Stream<Set<String>> streamFavoritosIds() => _favoritosStream;

  /// Crea el stream de favoritos con manejo de errores
  Stream<Set<String>> _createFavoritosStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(<String>{});
      }

      final uid = user.uid;
      return _db
          .collection('usuarios')
          .doc(uid)
          .collection('favoritos')
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs.map((doc) => doc.id).toSet();
            } catch (_) {
              return <String>{};
            }
          })
          .handleError((_) => <String>{});
    });
  }

  /// Obtiene los favoritos una sola vez (útil para debug o inicialización)
  Future<Set<String>> obtenerFavoritosUnaVez() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final snapshot = await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  /// Agrega una cápsula a favoritos
  Future<void> agregarFavorito(String capsulaId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .doc(capsulaId)
        .set({
      'capsulaId': capsulaId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Quita una cápsula de favoritos
  Future<void> quitarFavorito(String capsulaId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .doc(capsulaId)
        .delete();
  }

  /// Alterna el estado de favorito (agrega si no está, quita si está)
  Future<void> alternarFavorito(String capsulaId, {required bool esFavorita}) async {
    if (esFavorita) {
      await quitarFavorito(capsulaId);
    } else {
      await agregarFavorito(capsulaId);
    }
  }

  /// Verifica si una cápsula es favorita
  Future<bool> esFavorita(String capsulaId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .doc(capsulaId)
        .get();

    return doc.exists;
  }
}
