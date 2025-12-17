import 'package:cloud_firestore/cloud_firestore.dart';

class ImagenGuia {
  final String url;
  final String nombre;
  final int orden;

  ImagenGuia({
    required this.url,
    required this.nombre,
    required this.orden,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'nombre': nombre,
      'orden': orden,
    };
  }

  factory ImagenGuia.fromMap(Map<String, dynamic> map) {
    return ImagenGuia(
      url: map['url'] ?? '',
      nombre: map['nombre'] ?? '',
      orden: map['orden'] ?? 0,
    );
  }
}

class BloqueGuia {
  final String tipo; // 'texto' | 'texto_plano' | 'imagen'
  final String? texto;
  final String? url;
  final String? nombre;
  final int orden;

  BloqueGuia({
    required this.tipo,
    required this.orden,
    this.texto,
    this.url,
    this.nombre,
  });

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'texto': texto,
      'url': url,
      'nombre': nombre,
      'orden': orden,
    };
  }

  factory BloqueGuia.fromMap(Map<String, dynamic> map) {
    return BloqueGuia(
      tipo: (map['tipo'] ?? 'texto').toString(),
      texto: map['texto']?.toString(),
      url: map['url']?.toString(),
      nombre: map['nombre']?.toString(),
      orden: (map['orden'] is int)
          ? map['orden'] as int
          : int.tryParse(map['orden']?.toString() ?? '0') ?? 0,
    );
  }
}

class Guia {
  final String id;
  final String titulo;
  final String tipoGuia; // 'funcionalidades' o 'autores'
  final String contenidoMarkdown; // legacy fallback
  final List<ImagenGuia> imagenes; // legacy fallback
  final List<BloqueGuia> bloques;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String creadoPorUid;

  Guia({
    required this.id,
    required this.titulo,
    required this.tipoGuia,
    required this.contenidoMarkdown,
    required this.imagenes,
    required this.bloques,
    required this.createdAt,
    this.updatedAt,
    required this.creadoPorUid,
  });

  Map<String, dynamic> toMap() {
    final textoBlocks = bloques
        .where((b) => b.tipo == 'texto' && (b.texto?.isNotEmpty ?? false))
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
    final imageBlocks = bloques
        .where((b) => b.tipo == 'imagen' && (b.url?.isNotEmpty ?? false))
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));

    final legacyMarkdown = textoBlocks.map((b) => b.texto!).join('\n\n');
    final legacyImagenes = imageBlocks
        .map(
          (b) => ImagenGuia(
            url: b.url ?? '',
            nombre: b.nombre ?? 'Imagen',
            orden: b.orden,
          ),
        )
        .toList();

    return {
      'id': id,
      'titulo': titulo,
      'tipoGuia': tipoGuia,
      'bloques': bloques.map((b) => b.toMap()).toList(),
      // campos legacy para compatibilidad con lectores viejos
      'contenidoMarkdown': legacyMarkdown,
      'imagenes': legacyImagenes.map((img) => img.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'creadoPorUid': creadoPorUid,
    };
  }

  factory Guia.fromMap(Map<String, dynamic> map, String docId) {
    final dynamic bloquesRaw = map['bloques'];
    List<BloqueGuia> bloques = [];

    if (bloquesRaw is List) {
      bloques = bloquesRaw
          .whereType<Map>()
          .map((b) => BloqueGuia.fromMap(Map<String, dynamic>.from(b)))
          .toList();
    }

    final dynamic imagenesRaw = map['imagenes'];
    final List<ImagenGuia> imagenes = imagenesRaw is List
        ? imagenesRaw
            .map((img) => img is Map<String, dynamic>
                ? ImagenGuia.fromMap(img)
                : ImagenGuia.fromMap(Map<String, dynamic>.from(img as Map)))
            .toList()
        : <ImagenGuia>[];

    final String contenido = (map['contenidoMarkdown'] ??
            map['contenidoLargo'] ??
            map['contenido'] ??
            '')
        .toString();

    // fallback: si no hay bloques, construirlos desde legacy
    if (bloques.isEmpty) {
      int orden = 0;
      if (contenido.isNotEmpty) {
        bloques.add(
          BloqueGuia(tipo: 'texto', texto: contenido, orden: orden++),
        );
      }
      for (final img in imagenes) {
        bloques.add(
          BloqueGuia(
            tipo: 'imagen',
            url: img.url,
            nombre: img.nombre,
            orden: orden++,
          ),
        );
      }
    }

    // ordenar bloques por orden
    bloques.sort((a, b) => a.orden.compareTo(b.orden));

    return Guia(
      id: docId,
      titulo: map['titulo'] ?? '',
      tipoGuia: map['tipoGuia'] ?? 'funcionalidades',
      contenidoMarkdown: contenido,
      imagenes: imagenes,
      bloques: bloques,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      creadoPorUid: map['creadoPorUid'] ?? '',
    );
  }

  Guia copyWith({
    String? id,
    String? titulo,
    String? tipoGuia,
    String? contenidoMarkdown,
    List<ImagenGuia>? imagenes,
    List<BloqueGuia>? bloques,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creadoPorUid,
  }) {
    return Guia(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      tipoGuia: tipoGuia ?? this.tipoGuia,
      contenidoMarkdown: contenidoMarkdown ?? this.contenidoMarkdown,
      imagenes: imagenes ?? this.imagenes,
      bloques: bloques ?? this.bloques,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creadoPorUid: creadoPorUid ?? this.creadoPorUid,
    );
  }
}
