import 'package:flutter/material.dart';

class ClasificacionEstrellas extends StatelessWidget {
  final int calificacion;
  final double tamano;
  final Color color;
  final Function(int)? alCambiarCalificacion;

  const ClasificacionEstrellas({
    super.key,
    required this.calificacion,
    this.tamano = 24,
    this.color = Colors.amber,
    this.alCambiarCalificacion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: alCambiarCalificacion != null ? () => alCambiarCalificacion!(starIndex) : null,
          child: Icon(
            starIndex <= calificacion ? Icons.star : Icons.star_border,
            size: tamano,
            color: color,
          ),
        );
      }),
    );
  }
}
