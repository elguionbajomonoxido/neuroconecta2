import 'package:cloud_firestore/cloud_firestore.dart';

class Capsula {
  final String id;
  final String titulo;
  final String resumen;
  final String contenidoLargo;
  final String categoria;
  final String segmento; // 'niños', 'adolescentes', 'adultos'
  final bool esBorrador;
  final String creadoPorUid;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Capsula({
    required this.id,
    required this.titulo,
    required this.resumen,
    required this.contenidoLargo,
    required this.categoria,
    required this.segmento,
    required this.esBorrador,
    required this.creadoPorUid,
    required this.createdAt,
    this.updatedAt,
  });

  factory Capsula.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Capsula(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      resumen: data['resumen'] ?? '',
      contenidoLargo: data['contenidoLargo'] ?? '',
      categoria: data['categoria'] ?? '',
      segmento: data['segmento'] ?? 'adultos',
      esBorrador: data['esBorrador'] ?? false,
      creadoPorUid: data['creadoPorUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'resumen': resumen,
      'contenidoLargo': contenidoLargo,
      'categoria': categoria,
      'segmento': segmento,
      'esBorrador': esBorrador,
      'creadoPorUid': creadoPorUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
