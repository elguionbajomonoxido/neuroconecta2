import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/retroalimentacion.dart';

class FeedbackService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener retroalimentaciones de una cápsula
  Stream<List<Retroalimentacion>> getFeedbackForCapsule(String capsulaId) {
    return _db
        .collection('retroalimentaciones')
        .where('capsulaId', isEqualTo: capsulaId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Retroalimentacion.fromFirestore(doc)).toList();
    });
  }

  // Agregar retroalimentación
  Future<void> addFeedback(Retroalimentacion feedback) async {
    await _db.collection('retroalimentaciones').add(feedback.toMap());
  }

  // Eliminar retroalimentación (solo dueño o admin)
  Future<void> deleteFeedback(String id) async {
    await _db.collection('retroalimentaciones').doc(id).delete();
  }
}
