import 'package:cloud_firestore/cloud_firestore.dart';

class GroseriasRepository {
  GroseriasRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<String> _listaPorDefecto = [
    'puta',
    'mierda',
    'gilipollas',
    'idiota',
    'imbecil',
    'cabron',
    'pendejo',
  ];

  static List<String>? _cache;

  Future<List<String>> obtenerLista({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null && _cache!.isNotEmpty) {
      return _cache!;
    }

    final desdeRemoto = await _obtenerListaDesdeFirestore();
    _cache = desdeRemoto.isNotEmpty ? desdeRemoto : _listaPorDefecto;
    return _cache!;
  }

  Future<void> actualizarLista(List<String> palabras) async {
    await _firestore.collection('config').doc('groserias').set({
      'palabras': palabras,
    });
    _cache = palabras;
  }

  Future<List<String>> _obtenerListaDesdeFirestore() async {
    try {
      final doc = await _firestore.collection('config').doc('groserias').get();
      if (doc.exists) {
        final data = doc.data();
        final palabras = data?['palabras'];
        if (palabras is List) {
          return palabras.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {
      // No hacemos throw para permitir fallback a la lista local
    }
    return [];
  }

  bool contieneGroseriaEnTexto(String texto, List<String> malas) {
    if (malas.isEmpty || texto.trim().isEmpty) return false;
    final lower = texto.toLowerCase();
    for (final m in malas) {
      final p = m.toLowerCase().trim();
      if (p.isEmpty) continue;
      final regex = RegExp(r'(^|\W)' + RegExp.escape(p) + r'($|\W)', caseSensitive: false);
      if (regex.hasMatch(lower)) return true;
    }
    return false;
  }

  List<String> get listaPorDefecto => List.unmodifiable(_listaPorDefecto);
}
