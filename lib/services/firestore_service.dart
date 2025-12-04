import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/capsula.dart';

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

  // --- CÁPSULAS ---

  // Obtener todas las cápsulas (Stream)
  // Los admins ven todo, los usuarios solo las que NO son borrador
  Stream<List<Capsula>> obtenerCapsulas() {
    // Nota: Firestore no permite filtros condicionales complejos en el cliente sin índices específicos
    // Para simplificar, traemos la colección y filtramos en memoria o usamos dos queries distintas.
    // Aquí haremos un stream general y filtraremos en la UI o en el map si es necesario,
    // pero lo ideal es filtrar en la query.
    
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
    await _db.collection('capsulas').add(capsula.aMapa());
  }

  // Actualizar cápsula
  Future<void> actualizarCapsula(String id, Map<String, dynamic> data) async {
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
