import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroconecta2/models/guia.dart';
import 'package:neuroconecta2/services/groserias_repository.dart';

class GuiasFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GroseriasRepository _groseriasRepository = GroseriasRepository();
  Timer? _debounceTimer;

  /// Obtiene una guía por ID
  Stream<Guia?> obtenerGuia(String guiaId) {
    return _db.collection('guias').doc(guiaId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Guia.fromMap(doc.data() ?? {}, doc.id);
    });
  }

  /// Obtiene todas las guías de un tipo específico
  Stream<List<Guia>> obtenerGuiasPorTipo(String tipoGuia) {
    return _db
        .collection('guias')
        .where('tipoGuia', isEqualTo: tipoGuia)
        .snapshots()
        .map((snapshot) {
      final guias = snapshot.docs.map((doc) => Guia.fromMap(doc.data(), doc.id)).toList();
      guias.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return guias;
    });
  }

  /// Obtiene todas las guías (para admin panel)
  Stream<List<Guia>> obtenerTodasLasGuias() {
    return _db.collection('guias').snapshots().map((snapshot) {
      final guias = snapshot.docs.map((doc) => Guia.fromMap(doc.data(), doc.id)).toList();
      guias.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return guias;
    });
  }

  /// Crea una nueva guía
  Future<String> crearGuia({
    required String titulo,
    required String tipoGuia,
    required List<BloqueGuia> bloques,
    required String creadoPorUid,
  }) async {
    try {
      await _validarGroserias(bloques);

      final legacy = _legacyFromBloques(bloques);
      final docRef = await _db.collection('guias').add({
        'titulo': titulo,
        'tipoGuia': tipoGuia,
        'bloques': bloques.map((b) => b.toMap()).toList(),
        'contenidoMarkdown': legacy['contenidoMarkdown'],
        'imagenes': legacy['imagenes'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'creadoPorUid': creadoPorUid,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear guía: $e');
    }
  }

  /// Actualiza una guía existente
  Future<void> actualizarGuia({
    required String guiaId,
    String? titulo,
    String? tipoGuia,
    List<BloqueGuia>? bloques,
  }) async {
    try {
      final Map<String, dynamic> datosActualizar = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (titulo != null) datosActualizar['titulo'] = titulo;
      if (tipoGuia != null) datosActualizar['tipoGuia'] = tipoGuia;
      if (bloques != null) {
        await _validarGroserias(bloques);
        datosActualizar['bloques'] = bloques.map((b) => b.toMap()).toList();
        final legacy = _legacyFromBloques(bloques);
        datosActualizar['contenidoMarkdown'] = legacy['contenidoMarkdown'];
        datosActualizar['imagenes'] = legacy['imagenes'];
      }

      await _db.collection('guias').doc(guiaId).update(datosActualizar);
    } catch (e) {
      throw Exception('Error al actualizar guía: $e');
    }
  }

  /// Reordena las imágenes de una guía con debounce
  void reordenarImagenes({
    required String guiaId,
    required List<ImagenGuia> imagenesReordenadas,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () async {
      try {
        await _db.collection('guias').doc(guiaId).update({
          'imagenes': imagenesReordenadas.map((img) => img.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        throw Exception('Error al reordenar imágenes: $e');
      }
    });
  }

  /// Elimina una guía
  Future<void> eliminarGuia(String guiaId) async {
    try {
      await _db.collection('guias').doc(guiaId).delete();
    } catch (e) {
      throw Exception('Error al eliminar guía: $e');
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }

  Future<void> _validarGroserias(List<BloqueGuia> bloques) async {
    try {
      final malas = await _groseriasRepository.obtenerLista();
      final textos =
          bloques.where((b) => b.tipo == 'texto').map((b) => b.texto ?? '').join(' ');
      for (final m in malas) {
        final p = m.toLowerCase().trim();
        if (p.isEmpty) continue;
        final regex = RegExp(r'(^|\W)' + RegExp.escape(p) + r'($|\W)', caseSensitive: false);
        if (regex.hasMatch(textos.toLowerCase())) {
          throw Exception('El contenido contiene palabras censuradas');
        }
      }
    } catch (_) {
      final malas = _groseriasRepository.listaPorDefecto;
      final textos =
          bloques.where((b) => b.tipo == 'texto').map((b) => b.texto ?? '').join(' ');
      for (final m in malas) {
        final p = m.toLowerCase().trim();
        if (p.isEmpty) continue;
        final regex = RegExp(r'(^|\W)' + RegExp.escape(p) + r'($|\W)', caseSensitive: false);
        if (regex.hasMatch(textos.toLowerCase())) {
          throw Exception('El contenido contiene palabras censuradas');
        }
      }
    }
  }

  Map<String, dynamic> _legacyFromBloques(List<BloqueGuia> bloques) {
    final textoBlocks =
        bloques.where((b) => b.tipo == 'texto' && (b.texto?.isNotEmpty ?? false)).toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));
    final imageBlocks =
        bloques.where((b) => b.tipo == 'imagen' && (b.url?.isNotEmpty ?? false)).toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));

    final legacyMarkdown = textoBlocks.map((b) => b.texto!).join('\n\n');
    final legacyImagenes = imageBlocks
        .map(
          (b) => ImagenGuia(
            url: b.url ?? '',
            nombre: b.nombre ?? 'Imagen',
            orden: b.orden,
          ).toMap(),
        )
        .toList();

    return {
      'contenidoMarkdown': legacyMarkdown,
      'imagenes': legacyImagenes,
    };
  }
}
