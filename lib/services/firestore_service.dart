import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/capsula.dart';
import 'groserias_repository.dart';

// Servicio para interactuar con Firestore
class ServicioFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GroseriasRepository _groseriasRepository = GroseriasRepository();

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

  Future<bool> esAdminOAutor() async {
    final role = await obtenerRolUsuario();
    return role == 'admin' || role == 'autor';
  }

  // --- CÁPSULAS ---
  Stream<List<Capsula>> obtenerCapsulas() {
    return _db
        .collection('capsulas')
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
    final malas = await _groseriasRepository.obtenerLista();
    final texto = '${capsula.titulo} ${capsula.resumen} ${capsula.contenidoLargo}';
    if (_groseriasRepository.contieneGroseriaEnTexto(texto, malas)) {
      throw Exception('El contenido contiene palabras censuradas');
    }

    final mapa = Map<String, dynamic>.from(capsula.aMapa());
    mapa['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('capsulas').add(mapa);
  }

  // Actualizar cápsula
  Future<void> actualizarCapsula(String id, Map<String, dynamic> data) async {
    try {
      final malas = await _groseriasRepository.obtenerLista();
      final texto = '${data['titulo'] ?? ''} ${data['resumen'] ?? ''} ${data['contenidoLargo'] ?? ''}';
      if (_groseriasRepository.contieneGroseriaEnTexto(texto, malas)) {
        throw Exception('El contenido contiene palabras censuradas');
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
