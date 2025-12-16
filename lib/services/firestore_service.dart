import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/capsula.dart';
import 'feedback_service.dart';

// Servicio para interactuar con Firestore
class ServicioFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- USUARIOS ---

  // Obtener rol del usuario actual
  Future<String> obtenerRolUsuario() async {
    final user = _auth.currentUser;
    if (user == null) return 'usuario';

    try {
      final doc = await _db.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['rol'] ?? 'usuario';
      }
    } catch (e) {
      // Error silencioso o log
    }
    return 'usuario';
  }

  Future<bool> esAdmin() async {
    final role = await obtenerRolUsuario();
    return role == 'admin';
  }

  Future<bool> esAutor() async {
    final role = await obtenerRolUsuario();
    return role == 'autor';
  }

  // --- CÁPSULAS ---
  Stream<List<Capsula>> obtenerCapsulas() {
    
    return _db.collection('capsulas')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Capsula.desdeFirestore(doc)).toList();
        });
  }

  // Obtener una cápsula por ID
  Stream<Capsula> obtenerCapsula(String id) {
    return _db.collection('capsulas').doc(id).snapshots().map((doc) {
      return Capsula.desdeFirestore(doc);
    });
  }

  // Crear cápsula
  Future<void> agregarCapsula(Capsula capsula) async {
    // Validar que no contenga groserías (ningún usuario, ni admin)
    try {
      final servicioRetro = ServicioRetroalimentacion();
      var malas = await servicioRetro.obtenerListaGroseriasFirestore();
      if (malas.isEmpty) {
        malas = ['puta', 'mierda', 'gilipollas', 'idiota', 'imbecil', 'cabron', 'pendejo'];
      }
      final texto = '${capsula.titulo} ${capsula.resumen} ${capsula.contenidoLargo}';
      for (final m in malas) {
        final p = m.toLowerCase().trim();
        if (p.isEmpty) continue;
        final regex = RegExp(r'(^|\W)'+RegExp.escape(p)+r'($|\W)', caseSensitive: false);
        if (regex.hasMatch(texto.toLowerCase())) {
          throw Exception('El contenido contiene palabras censuradas');
        }
      }
    } catch (_) {
      // Si falla la validación remota, usamos lista por defecto y seguimos validando
      final malas = ['puta', 'mierda', 'gilipollas', 'idiota', 'imbecil', 'cabron', 'pendejo'];
      final texto = '${capsula.titulo} ${capsula.resumen} ${capsula.contenidoLargo}';
      for (final m in malas) {
        final p = m.toLowerCase().trim();
        if (p.isEmpty) continue;
        final regex = RegExp(r'(^|\W)'+RegExp.escape(p)+r'($|\W)', caseSensitive: false);
        if (regex.hasMatch(texto.toLowerCase())) {
          throw Exception('El contenido contiene palabras censuradas');
        }
      }
    }

    // Al crear, usar serverTimestamp para createdAt y evitar confiar en el reloj del cliente
    final mapa = Map<String, dynamic>.from(capsula.aMapa());
    mapa['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('capsulas').add(mapa);
  }

  // Actualizar cápsula
  Future<void> actualizarCapsula(String id, Map<String, dynamic> data) async {
    // Validar que no contenga groserías en los campos principales
    try {
      final servicioRetro = ServicioRetroalimentacion();
      final malas = await servicioRetro.obtenerListaGroseriasFirestore();
      final texto = '${data['titulo'] ?? ''} ${data['resumen'] ?? ''} ${data['contenidoLargo'] ?? ''}';
      for (final m in malas) {
        final p = m.toLowerCase().trim();
        if (p.isEmpty) continue;
        final regex = RegExp(r'(^|\W)'+RegExp.escape(p)+r'($|\W)', caseSensitive: false);
        if (regex.hasMatch(texto.toLowerCase())) {
          throw Exception('El contenido contiene palabras censuradas');
        }
      }
    } catch (_) {
      // Si falla la validación remota, permitimos continuar
    }

    await _db.collection('capsulas').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar cápsula
  Future<void> eliminarCapsula(String id) async {
    await _db.collection('capsulas').doc(id).delete();
  }
}
