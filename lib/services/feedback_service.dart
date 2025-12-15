import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/retroalimentacion.dart';

class ServicioRetroalimentacion {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    await _db.collection('retroalimentaciones').add(feedback.aMapa());
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
  Future<Map<String, double>> obtenerPromediosPorCapsulas() async {
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

    return promedios;
  }

  // Obtener lista de groserías desde Firestore (doc: 'config/groserias', campo 'palabras' como array)
  Future<List<String>> obtenerListaGroseriasFirestore() async {
    try {
      final doc = await _db.collection('config').doc('groserias').get();
      if (doc.exists) {
        final data = doc.data();
        final palabras = data?['palabras'];
        if (palabras is List) {
          return palabras.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {
      // ignore
    }
    return [];
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
}
