import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neuroconecta2/models/guia.dart';
import 'package:neuroconecta2/services/guias_firestore_service.dart';
import 'package:neuroconecta2/widgets/custom_markdown_body.dart';

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
      child: ExpansionTile(
        title: Text(guia.titulo),
        subtitle: Text(
          'Actualizado: ${guia.updatedAt?.toString().split('.')[0] ?? guia.createdAt.toString().split('.')[0]}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._renderBloques(context, guia),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _renderBloques(BuildContext context, Guia guia) {
    if (guia.bloques.isEmpty) {
      return [
        CustomMarkdownBody(
          data: guia.contenidoMarkdown,
          selectable: true,
        ),
      ];
    }

    return guia.bloques
        .map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: b.tipo == 'texto'
                ? CustomMarkdownBody(data: b.texto ?? '', selectable: true)
                : _imagenWidget(b),
          ),
        )
        .toList();
  }

  Widget _imagenWidget(BloqueGuia b) {
    if (b.url == null || b.url!.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('Imagen no disponible')),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: b.url!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }
}
