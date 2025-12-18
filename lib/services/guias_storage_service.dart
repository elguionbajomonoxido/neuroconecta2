import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class GuiasStorageService {
  final ImagePicker _picker = ImagePicker();

  /// Límite máximo de tamaño de archivo en bytes (5 MB)
  static const int maxFileSize = 5 * 1024 * 1024;

  /// Selecciona una imagen y la convierte a base64
  /// Retorna la cadena base64 de la imagen comprimida
  /// [onProgress] - callback para actualizar progreso (0-100)
  /// [source] - fuente de la imagen: cámara o galería (por defecto: galería)
  /// Lanza excepción si la imagen supera 5MB
  Future<String> subirImagenConCompresion({
    required String guiaId,
    required Function(int) onProgress,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
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

      // Leer bytes de la imagen
      final bytes = await file.readAsBytes();
      debugPrint('[GuiasStorageService] 📁 Leyendo bytes: ${bytes.length ~/ 1024} KB');

      // Simular progreso (lectura instantánea)
      onProgress(50);
      
      // Convertir a base64
      final base64String = base64Encode(bytes);
      debugPrint('[GuiasStorageService] ✓ Conversión a base64 completada: ${base64String.length ~/ 1024} KB');
      
      onProgress(100);

      // Retornar el data URI
      final dataUri = 'data:image/jpeg;base64,$base64String';
      debugPrint('[GuiasStorageService] 🔗 Data URI generado (primeros 50 caracteres): ${dataUri.substring(0, 50)}...');
      
      return dataUri;
    } catch (e) {
      debugPrint('[GuiasStorageService] ❌ Error: $e');
      throw Exception('Error al procesar imagen: $e');
    }
  }

  /// Elimina una imagen (no hace nada ya que no hay storage remoto)
  Future<void> eliminarImagen({required String urlImagen}) async {
    debugPrint('[GuiasStorageService] 🗑️ Marca de eliminación recibida (sin acción real)');
    // No hacemos nada porque la imagen está almacenada en Firestore
  }

  /// Obtiene URL descargable de una imagen
  Future<String> obtenerUrlDescargable({required String urlImagen}) async {
    // La imagen ya es un data URI, la retornamos tal cual
    return urlImagen;
  }
}
