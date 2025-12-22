import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/retroalimentacion.dart';
import 'groserias_repository.dart';

class ServicioRetroalimentacion {
  ServicioRetroalimentacion({GroseriasRepository? groseriasRepository})
      : _groseriasRepository = groseriasRepository ?? GroseriasRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GroseriasRepository _groseriasRepository;
  Map<String, double>? _promediosCache;
  DateTime? _ultimaActualizacionPromedios;

  // Obtener retroalimentaciones de una cápsula
  Stream<List<Retroalimentacion>> obtenerRetroalimentacionPorCapsula(String capsulaId) {
    return _db
        .collection('retroalimentaciones')
        .where('capsulaId', isEqualTo: capsulaId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Retroalimentacion.desdeFirestore(doc)).toList();
    });
  }

  // Agregar retroalimentación
  Future<void> agregarRetroalimentacion(Retroalimentacion feedback) async {
    final mapa = Map<String, dynamic>.from(feedback.aMapa());
    final comentario = (mapa['comentario'] as String?) ?? '';
    final malas = await _groseriasRepository.obtenerLista();
    if (_groseriasRepository.contieneGroseriaEnTexto(comentario, malas)) {
      throw Exception('El comentario contiene palabras censuradas');
    }

    final fbId = '${feedback.capsulaId}_${feedback.usuarioUid}';
    mapa['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('retroalimentaciones').doc(fbId).set(mapa);
  }

  // Obtener retroalimentación de un usuario para una capsula (si existe)
  Future<Retroalimentacion?> obtenerRetroalimentacionUsuario(String capsulaId, String usuarioUid) async {
    final snapshot = await _db
        .collection('retroalimentaciones')
        .where('capsulaId', isEqualTo: capsulaId)
        .where('usuarioUid', isEqualTo: usuarioUid)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Retroalimentacion.desdeFirestore(snapshot.docs.first);
  }

  // Actualizar retroalimentación
  Future<void> actualizarRetroalimentacion(String id, Map<String, dynamic> data) async {
    final comentario = (data['comentario'] as String?) ?? '';
    final malas = await _groseriasRepository.obtenerLista();
    if (_groseriasRepository.contieneGroseriaEnTexto(comentario, malas)) {
      throw Exception('El comentario contiene palabras censuradas');
    }

    await _db.collection('retroalimentaciones').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar retroalimentación (solo dueño o admin)
  Future<void> eliminarRetroalimentacion(String id) async {
    await _db.collection('retroalimentaciones').doc(id).delete();
  }

  // Obtener promedios de estrellas por capsulaId (map capsulaId -> promedio)
  Future<Map<String, double>> obtenerPromediosPorCapsulas({
    Duration cacheValidez = const Duration(minutes: 5),
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _promediosCache != null &&
        _ultimaActualizacionPromedios != null &&
        DateTime.now().difference(_ultimaActualizacionPromedios!) < cacheValidez) {
      return _promediosCache!;
    }

    final snapshot = await _db.collection('retroalimentaciones').get();
    final Map<String, List<int>> agrupado = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final capsulaId = data['capsulaId'] as String? ?? '';
      final estrellas = (data['estrellas'] as num?)?.toInt() ?? 0;
      if (capsulaId.isEmpty) continue;
      agrupado.putIfAbsent(capsulaId, () => []).add(estrellas);
    }

    final Map<String, double> promedios = {};
    agrupado.forEach((capsulaId, lista) {
      final suma = lista.fold<int>(0, (a, b) => a + b);
      promedios[capsulaId] = lista.isNotEmpty ? (suma / lista.length) : 0.0;
    });

    _promediosCache = promedios;
    _ultimaActualizacionPromedios = DateTime.now();
    return promedios;
  }

  // Obtener estadísticas (promedio y conteo) para una capsula
  Future<Map<String, dynamic>> obtenerEstadisticasCapsula(String capsulaId) async {
    final snapshot = await _db
        .collection('retroalimentaciones')
        .where('capsulaId', isEqualTo: capsulaId)
        .get();
    final docs = snapshot.docs;
    if (docs.isEmpty) return {'avg': 0.0, 'count': 0};
    final List<int> estrellas = docs.map((d) => (d.data()['estrellas'] as num?)?.toInt() ?? 0).toList();
    final suma = estrellas.fold<int>(0, (a, b) => a + b);
    final avg = suma / estrellas.length;
    return {'avg': avg, 'count': estrellas.length};
  }

  @visibleForTesting
  GroseriasRepository get groseriasRepository => _groseriasRepository;

  Future<List<String>> obtenerListaGroserias() => _groseriasRepository.obtenerLista();

  Future<void> actualizarListaGroserias(List<String> palabras) =>
      _groseriasRepository.actualizarLista(palabras);
}
