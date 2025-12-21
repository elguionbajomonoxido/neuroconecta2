import 'package:flutter/foundation.dart';
import '../services/favoritos_service.dart';

class FavoritosController extends ChangeNotifier {
  final FavoritosService _servicioFavoritos = FavoritosService();

  Set<String> _favoritosIds = {};

  Set<String> get favoritosIds => _favoritosIds;

  /// Cambia localmente el estado de un favorito (optimistic UI)
  void toggleLocal(String capsulaId) {
    if (_favoritosIds.contains(capsulaId)) {
      _favoritosIds.remove(capsulaId);
    } else {
      _favoritosIds.add(capsulaId);
    }
    notifyListeners();
  }

  /// Sincroniza los favoritos desde Firestore y actualiza el cache
  Future<void> syncFromFirestore() async {
    try {
      _favoritosIds = await _servicioFavoritos.obtenerFavoritosUnaVez();
      notifyListeners();
    } catch (e) {
      debugPrint('Error sincronizando favoritos: $e');
      rethrow;
    }
  }

  /// Persiste el cambio a Firestore (puede llamarse después del toggleLocal)
  Future<void> persistirToggle(String capsulaId, {required bool esFavorita}) async {
    try {
      await _servicioFavoritos.alternarFavorito(capsulaId, esFavorita: esFavorita);
    } catch (e) {
      debugPrint('Error persistiendo favorito: $e');
      rethrow;
    }
  }

  /// Verifica si un id está en favoritos
  bool isFavorite(String capsulaId) => _favoritosIds.contains(capsulaId);
}
