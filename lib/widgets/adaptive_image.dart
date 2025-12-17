import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

/// Widget adaptativo que muestra una imagen desde URL o base64
/// Si la URL comienza con 'data:image', usa Image.memory
/// Si no, usa CachedNetworkImage
class AdaptiveImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AdaptiveImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super();

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImage();
    
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildImage() {
    if (imageUrl.startsWith('data:image')) {
      // Es una imagen en base64, extraer los datos
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
        );
      } catch (e) {
        debugPrint('Error al decodificar base64: $e');
        return Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image)),
        );
      }
    } else {
      // Es una URL normal, usar CachedNetworkImage
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) => Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      );
    }
  }
}
