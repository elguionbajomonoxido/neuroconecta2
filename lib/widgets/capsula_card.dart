import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../models/capsula.dart';

class TarjetaCapsula extends StatelessWidget {
  final Capsula capsula;

  const TarjetaCapsula({super.key, required this.capsula});

  @override
  Widget build(BuildContext context) {
    // Icono según segmento
    IconData iconData;
    Color iconColor;
    
    switch (capsula.segmento.toLowerCase()) {
      case 'niños':
        iconData = Icons.child_care;
        iconColor = Colors.orangeAccent;
        break;
      case 'adolescentes':
        iconData = Icons.school;
        iconColor = Colors.blueAccent;
        break;
      case 'adultos':
      default:
        iconData = Icons.person;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          context.push('${RutasAplicacion.detalleCapsula}/${capsula.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          capsula.titulo,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTagTheme(context, capsula.categoria, primary: true),
                            const SizedBox(width: 8),
                            if (capsula.esBorrador)
                              _buildTagTheme(context, 'Borrador', primary: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                capsula.resumen,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagTheme(BuildContext context, String text, {bool primary = true}) {
    final cs = Theme.of(context).colorScheme;
    final bg = primary ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = primary ? cs.onPrimaryContainer : cs.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
