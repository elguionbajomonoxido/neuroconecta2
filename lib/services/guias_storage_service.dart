import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class GuiasStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Límite máximo de tamaño de archivo en bytes (5 MB)
  static const int maxFileSize = 5 * 1024 * 1024;

  /// Sube una imagen con compresión automática via image_picker
  /// Retorna URL de la imagen descargable
  /// [guiaId] - ID de la guía para organizar en storage
  /// [onProgress] - callback para actualizar progreso (0-100)
  /// [source] - fuente de la imagen: cámara o galería (por defecto: galería)
  /// Lanza excepción si la imagen supera 5MB
  Future<String> subirImagenConCompresion({
    required String guiaId,
    required Function(int) onProgress,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Verificar autenticación
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('[GuiasStorageService] ❌ Usuario NO autenticado');
        throw Exception('Usuario no autenticado. Inicia sesión para subir imágenes.');
      }
      debugPrint('[GuiasStorageService] ✓ Usuario autenticado: ${currentUser.email}');

      final XFile? imagen = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compresión automática al 80%
      );

      if (imagen == null) {
        throw Exception('No se seleccionó imagen');
      }

      final File file = File(imagen.path);
      final int fileSize = file.lengthSync();

      // Validar tamaño máximo
      if (fileSize > maxFileSize) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
        throw Exception(
          'Imagen demasiado grande ($sizeMB MB). Máximo permitido: 5 MB',
        );
      }

      debugPrint('[GuiasStorageService] 📸 Imagen seleccionada: ${imagen.name}, tamaño: ${fileSize ~/ 1024} KB');

      final String nombreArchivo =
          '${DateTime.now().millisecondsSinceEpoch}_${imagen.name}';
      
      // Usar una ruta más segura y consistente
      final String rutaStorage = 'guias/$guiaId/$nombreArchivo';
      debugPrint('[GuiasStorageService] 📁 Subiendo a: $rutaStorage');
      
      final Reference ref = _storage.ref(rutaStorage);

      // Determinar tipo de contenido dinámicamente
      String contentType = 'image/jpeg';
      if (imagen.name.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (imagen.name.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (imagen.name.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }

      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadedBy': currentUser.uid,
            'guiaId': guiaId,
          },
        ),
      );

      // Escuchar progreso de carga
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final int percent = ((snapshot.bytesTransferred / snapshot.totalBytes) *
                100)
            .toInt();
        debugPrint('[GuiasStorageService] ⏳ Progreso: $percent% (${snapshot.bytesTransferred ~/ 1024} KB / ${snapshot.totalBytes ~/ 1024} KB)');
        onProgress(percent);
      });

      await uploadTask;
      debugPrint('[GuiasStorageService] ✓ Upload completado');

      // Obtener URL descargable
      final String urlDescargable = await ref.getDownloadURL();
      debugPrint('[GuiasStorageService] 🔗 URL obtenida: $urlDescargable');
      return urlDescargable;
    } on FirebaseException catch (e) {
      debugPrint('[GuiasStorageService] ❌ FirebaseException: ${e.code} - ${e.message}');
      debugPrint('[GuiasStorageService] ❌ Plugin code: ${e.plugin}');
      throw Exception('Error Firebase al subir imagen: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('[GuiasStorageService] ❌ Error general: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Elimina una imagen de Firebase Storage
  Future<void> eliminarImagen({required String urlImagen}) async {
    try {
      final Reference ref = _storage.refFromURL(urlImagen);
      await ref.delete();
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Obtiene URL descargable de una imagen
  Future<String> obtenerUrlDescargable({required String urlImagen}) async {
    try {
      final Reference ref = _storage.refFromURL(urlImagen);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error al obtener URL: $e');
    }
  }
}
