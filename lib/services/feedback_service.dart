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

  // Eliminar retroalimentación (solo dueño o admin)
  Future<void> eliminarRetroalimentacion(String id) async {
    await _db.collection('retroalimentaciones').doc(id).delete();
  }
}
