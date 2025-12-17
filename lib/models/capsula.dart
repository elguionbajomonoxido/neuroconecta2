import 'package:cloud_firestore/cloud_firestore.dart';

class Capsula {
  final String id;
  final String titulo;
  final String resumen;
  final String contenidoLargo;
  final String categoria;
  final String segmento; // 'niños', 'adolescentes', 'adultos'
  final bool esBorrador;
  final String? mediaUrl;
  final String creadoPorUid;
  final String autor;
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
    this.mediaUrl,
    required this.creadoPorUid,
    required this.autor,
    required this.createdAt,
    this.updatedAt,
  });

  factory Capsula.desdeFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      // Retorna cápsula vacía si el documento no existe
      return Capsula(
        id: doc.id,
        titulo: 'No disponible',
        resumen: '',
        contenidoLargo: '',
        categoria: '',
        segmento: 'adultos',
        esBorrador: false,
        mediaUrl: null,
        creadoPorUid: '',
        autor: '',
        createdAt: DateTime.now(),
        updatedAt: null,
      );
    }
    return Capsula(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      resumen: data['resumen'] ?? '',
      contenidoLargo: data['contenidoLargo'] ?? '',
      categoria: data['categoria'] ?? '',
      segmento: data['segmento'] ?? 'adultos',
      esBorrador: data['esBorrador'] ?? false,
      mediaUrl: data['mediaUrl'],
      creadoPorUid: data['creadoPorUid'] ?? '',
      autor: data['autor'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'titulo': titulo,
      'resumen': resumen,
      'contenidoLargo': contenidoLargo,
      'categoria': categoria,
      'segmento': segmento,
      'esBorrador': esBorrador,
      'mediaUrl': mediaUrl,
      'creadoPorUid': creadoPorUid,
      'autor': autor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
