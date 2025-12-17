import 'dart:io';
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
  /// Lanza excepción si la imagen supera 5MB
  Future<String> subirImagenConCompresion({
    required String guiaId,
    required Function(int) onProgress,
  }) async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
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

      final String nombreArchivo =
          '${DateTime.now().millisecondsSinceEpoch}_${imagen.name}';
      final Reference ref = _storage.ref('guias/$guiaId/$nombreArchivo');

      final UploadTask uploadTask = ref.putFile(file);

      // Escuchar progreso de carga
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final int percent = ((snapshot.bytesTransferred / snapshot.totalBytes) *
                100)
            .toInt();
        onProgress(percent);
      });

      await uploadTask;

      // Obtener URL descargable
      final String urlDescargable = await ref.getDownloadURL();
      return urlDescargable;
    } catch (e) {
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
