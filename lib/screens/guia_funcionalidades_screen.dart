import 'package:flutter/material.dart';
import 'package:neuroconecta2/models/guia.dart';
import 'package:neuroconecta2/services/guias_firestore_service.dart';
import 'package:neuroconecta2/widgets/adaptive_image.dart';
import 'package:go_router/go_router.dart';

class GuiaFuncionalidadesScreen extends StatelessWidget {
  const GuiaFuncionalidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guiasService = GuiasFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía de Funcionalidades'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Guia>>(
        stream: guiasService.obtenerGuiasPorTipo('funcionalidades'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final guias = snapshot.data ?? [];

          if (guias.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 64),
                  const SizedBox(height: 16),
                  const Text('No hay guías disponibles'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: guias.length,
            itemBuilder: (context, index) {
              final guia = guias[index];
              return _construirTarjetaGuia(context, guia);
            },
          );
        },
      ),
    );
  }

  Widget _construirTarjetaGuia(BuildContext context, Guia guia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/detalles-guia/${guia.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guia.titulo, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Actualizado: ${guia.updatedAt?.toString().split('.')[0] ?? guia.createdAt.toString().split('.')[0]}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                if (guia.bloques.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: guia.bloques.take(3).map((bloque) {
                        if (bloque.tipo == 'imagen' && bloque.url != null && bloque.url!.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AdaptiveImage(
                                imageUrl: bloque.url!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/detalles-guia/${guia.id}'),
                    child: const Text('Ver detalles'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => context.push('/editar-guia/${guia.id}'),
                  tooltip: 'Editar',
                  iconSize: 20,
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _mostrarConfirmacionEliminar(context, guia),
                  tooltip: 'Eliminar',
                  color: Colors.red,
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarConfirmacionEliminar(BuildContext context, Guia guia) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar guía'),
        content: Text('¿Eliminar "${guia.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final guiasService = GuiasFirestoreService();
        await guiasService.eliminarGuia(guia.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guía eliminada')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
