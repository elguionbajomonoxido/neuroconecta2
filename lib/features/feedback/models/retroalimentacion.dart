import 'package:cloud_firestore/cloud_firestore.dart';

class Retroalimentacion {
  final String id;
  final String capsulaId;
  final String usuarioUid;
  final String nombreUsuario;
  final String comentario;
  final int estrellas; // 1-5
  final DateTime createdAt;

  Retroalimentacion({
    required this.id,
    required this.capsulaId,
    required this.usuarioUid,
    required this.nombreUsuario,
    required this.comentario,
    required this.estrellas,
    required this.createdAt,
  });

  factory Retroalimentacion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Retroalimentacion(
      id: doc.id,
      capsulaId: data['capsulaId'] ?? '',
      usuarioUid: data['usuarioUid'] ?? '',
      nombreUsuario: data['nombreUsuario'] ?? 'Anónimo',
      comentario: data['comentario'] ?? '',
      estrellas: (data['estrellas'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'capsulaId': capsulaId,
      'usuarioUid': usuarioUid,
      'nombreUsuario': nombreUsuario,
      'comentario': comentario,
      'estrellas': estrellas,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
