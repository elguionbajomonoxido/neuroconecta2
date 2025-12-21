import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class FavoritosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final Stream<Set<String>> _favoritosStream = _createFavoritosStream();

  /// Stream con el Set de IDs de cápsulas favoritas del usuario actual
  Stream<Set<String>> streamFavoritosIds() => _favoritosStream;

  Stream<Set<String>> _createFavoritosStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<String>{});

      final uid = user.uid;
      return _db
          .collection('usuarios')
          .doc(uid)
          .collection('favoritos')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet())
          .handleError((_) {});
    });
  }

  /// Obtiene los favoritos una sola vez
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

  /// Agrega favorito SIN provocar update/overwrite (idempotente)
  Future<void> agregarFavorito(String capsulaId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final ref = _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .doc(capsulaId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return; // ya existe, no tocar createdAt

      tx.set(ref, {
        'capsulaId': capsulaId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Quita favorito
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

  /// Alterna favorito de forma segura (NO depende del bool externo)
  Future<void> alternarFavorito(String capsulaId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final ref = _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .doc(capsulaId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (snap.exists) {
        tx.delete(ref);
      } else {
        tx.set(ref, {
          'capsulaId': capsulaId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
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
