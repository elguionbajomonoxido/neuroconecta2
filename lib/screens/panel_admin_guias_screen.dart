import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroconecta2/models/guia.dart';
import 'package:neuroconecta2/services/guias_firestore_service.dart';
import 'package:neuroconecta2/screens/editar_guia_screen.dart';

class PanelAdminGuiasScreen extends StatelessWidget {
  const PanelAdminGuiasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guiasService = GuiasFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Guías'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditarGuiaScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Guía'),
      ),
      body: StreamBuilder<List<Guia>>(
        stream: guiasService.obtenerTodasLasGuias(),
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
                  ),
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
                  const Icon(Icons.description_outlined, size: 64),
                  const SizedBox(height: 16),
                  const Text('No hay guías creadas'),
                  const SizedBox(height: 16),
                  const Text('Crea una nueva guía usando el botón +'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: guias.length,
            itemBuilder: (context, index) {
              final guia = guias[index];
              return _construirTarjetaGuia(context, guia, guiasService);
            },
          );
        },
      ),
    );
  }

  Widget _construirTarjetaGuia(
    BuildContext context,
    Guia guia,
    GuiasFirestoreService guiasService,
  ) {
    final tipoTexto = guia.tipoGuia == 'funcionalidades'
        ? 'Funcionalidades'
        : 'Autores';
    final tipoColor = guia.tipoGuia == 'funcionalidades'
        ? Colors.blue
        : Colors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(guia.titulo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(tipoTexto),
                  backgroundColor: tipoColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: tipoColor),
                  side: BorderSide(color: tipoColor),
                ),
                Chip(
                  label: Text('${guia.imagenes.length} imágenes'),
                  avatar: const Icon(Icons.image, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Actualizado: ${guia.updatedAt?.toString().split('.')[0] ?? guia.createdAt.toString().split('.')[0]}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditarGuiaScreen(guia: guia),
              ),
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditarGuiaScreen(guia: guia),
            ),
          );
        },
      ),
    );
  }
}
