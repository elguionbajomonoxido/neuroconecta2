import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroconecta2/models/guia.dart';
import 'package:neuroconecta2/services/guias_firestore_service.dart';
import 'package:neuroconecta2/widgets/custom_markdown_body.dart';
import 'package:neuroconecta2/widgets/adaptive_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetallesGuiaScreen extends StatefulWidget {
  final String guiaId;

  const DetallesGuiaScreen({super.key, required this.guiaId});

  @override
  State<DetallesGuiaScreen> createState() => _DetallesGuiaScreenState();
}

class _DetallesGuiaScreenState extends State<DetallesGuiaScreen> {
  final GuiasFirestoreService _guiasService = GuiasFirestoreService();
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificarAutenticacion();
  }

  Future<void> _verificarAutenticacion() async {
    final user = FirebaseAuth.instance.currentUser;
    // Por ahora simplemente verificar que esté autenticado
    setState(() {
      _esAdmin = user != null;
    });
  }

  Future<void> _eliminarGuia() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar guía'),
        content:
            const Text('¿Estás seguro de que deseas eliminar esta guía?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirm == true) {
      try {
        await _guiasService.eliminarGuia(widget.guiaId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guía eliminada')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Guia?>(
      stream: _guiasService.obtenerGuia(widget.guiaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('No se pudo cargar la guía'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        final guia = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(guia.titulo),
            elevation: 0,
            actions: [
              if (_esAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/editar-guia/${guia.id}'),
                  tooltip: 'Editar',
                ),
              if (_esAdmin)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _eliminarGuia,
                  tooltip: 'Eliminar',
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guia.titulo,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tipo: ${guia.tipoGuia}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Actualizado: ${guia.updatedAt?.toString().split('.')[0] ?? guia.createdAt.toString().split('.')[0]}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _renderBloques(context, guia),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _renderBloques(BuildContext context, Guia guia) {
    if (guia.bloques.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: CustomMarkdownBody(
            data: guia.contenidoMarkdown,
            selectable: true,
          ),
        ),
      ];
    }

    return guia.bloques
        .map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: b.tipo == 'imagen'
                ? _renderImagen(b)
                : _renderTexto(b),
          ),
        )
        .toList();
  }

  Widget _renderTexto(BloqueGuia bloque) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: bloque.tipo == 'texto'
          ? CustomMarkdownBody(data: bloque.texto ?? '', selectable: true)
          : Text(
              bloque.texto ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
    );
  }

  Widget _renderImagen(BloqueGuia bloque) {
    if (bloque.url == null || bloque.url!.isEmpty) {
      return Container(
        height: 200,
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
      child: AdaptiveImage(
        imageUrl: bloque.url!,
        fit: BoxFit.contain,
        width: double.infinity,
      ),
    );
  }
}
