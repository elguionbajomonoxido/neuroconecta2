import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/favoritos_service.dart';

class FavoritosController extends ChangeNotifier {
  final FavoritosService _servicioFavoritos = FavoritosService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<ConnectivityResult>>? _connectSub;
  String? _uid;
  bool _isOffline = false;
  bool _sincronizando = false;

  Set<String> _favoritosIds = {};

  Set<String> get favoritosIds => _favoritosIds;
  bool get isOffline => _isOffline;

  FavoritosController() {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
    _connectSub = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOffline = result == ConnectivityResult.none;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final wasOffline = _isOffline;
    final offlineNow = results.isEmpty || results.contains(ConnectivityResult.none);
    _isOffline = offlineNow;
    notifyListeners();

    if (wasOffline && !_isOffline && _uid != null) {
      // Re-sincronizar automáticamente al recuperar conexión
      await syncFromFirestore();
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    _uid = user?.uid;
    if (user == null) {
      _favoritosIds = {};
      notifyListeners();
      return;
    }

    await _cargarDesdeCache(user.uid);
    await syncFromFirestore();
  }

  String _prefsKey(String uid) => 'favoritos_$uid';

  Future<void> _cargarDesdeCache(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = prefs.getStringList(_prefsKey(uid));
      _favoritosIds = lista?.toSet() ?? {};
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _guardarEnCache() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey(uid), _favoritosIds.toList());
    } catch (_) {}
  }

  /// Cambia localmente el estado de un favorito (optimistic UI)
  void toggleLocal(String capsulaId) {
    if (_favoritosIds.contains(capsulaId)) {
      _favoritosIds.remove(capsulaId);
    } else {
      _favoritosIds.add(capsulaId);
    }
    notifyListeners();
    _guardarEnCache();
  }

  /// Sincroniza los favoritos desde Firestore y actualiza el cache
  Future<void> syncFromFirestore() async {
    if (_sincronizando) return;
    final user = _auth.currentUser;
    if (user == null) {
      _favoritosIds = {};
      notifyListeners();
      return;
    }
    _sincronizando = true;
    try {
      _favoritosIds = await _servicioFavoritos.obtenerFavoritosUnaVez();
      notifyListeners();
      await _guardarEnCache();
    } catch (e) {
      debugPrint('Error sincronizando favoritos: $e');
      rethrow;
    } finally {
      _sincronizando = false;
    }
  }

  /// Persiste el cambio a Firestore (puede llamarse después del toggleLocal)
  Future<void> persistirToggle(String capsulaId) async {
    if (_isOffline) {
      throw Exception('Sin conexión. Conéctate a internet para continuar.');
    }
    try {
      await _servicioFavoritos.alternarFavorito(capsulaId);
      await _guardarEnCache();
    } catch (e) {
      debugPrint('Error persistiendo favorito: $e');
      rethrow;
    }
  }

  /// Verifica si un id está en favoritos
  bool isFavorite(String capsulaId) => _favoritosIds.contains(capsulaId);

  @override
  void dispose() {
    _authSub?.cancel();
    _connectSub?.cancel();
    super.dispose();
  }
}
