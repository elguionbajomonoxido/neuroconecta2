import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../models/capsula.dart';
import '../services/firestore_service.dart';
import '../widgets/retroalimentacion_list.dart';
import '../widgets/retroalimentacion_form.dart';
import '../widgets/media_viewer.dart';

class PantallaDetalleCapsula extends StatefulWidget {
  final String capsuleId;

  const PantallaDetalleCapsula({super.key, required this.capsuleId});

  @override
  State<PantallaDetalleCapsula> createState() => _PantallaDetalleCapsulaState();
}

class _PantallaDetalleCapsulaState extends State<PantallaDetalleCapsula> {
  final ServicioFirestore _servicioFirestore = ServicioFirestore();
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificarRol();
  }

  Future<void> _verificarRol() async {
    final esAdmin = await _servicioFirestore.esAdmin();
    if (mounted) {
      setState(() {
        _esAdmin = esAdmin;
      });
    }
  }

  Future<void> _eliminarCapsula(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cápsula'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _servicioFirestore.eliminarCapsula(widget.capsuleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cápsula eliminada')),
        );
        context.pop(); // Volver al Home
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Capsula>(
      stream: _servicioFirestore.obtenerCapsula(widget.capsuleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('No se pudo cargar la cápsula')),
          );
        }

        final capsula = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(capsula.titulo),
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: _esAdmin
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        context.push('${RutasAplicacion.editarCapsula}/${capsula.id}');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminarCapsula(context),
                    ),
                  ]
                : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Viewer
                if (capsula.mediaUrl != null && capsula.mediaUrl!.isNotEmpty) ...[
                  MediaViewer(url: capsula.mediaUrl),
                  const SizedBox(height: 16),
                ],

                // Header Info
                Row(
                  children: [
                    Chip(
                      label: Text(capsula.categoria),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(capsula.segmento.toUpperCase()),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contenido Markdown
                MarkdownBody(
                  data: capsula.contenidoLargo,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: Theme.of(context).textTheme.bodyLarge,
                    h1: Theme.of(context).textTheme.displaySmall,
                    h2: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),

                // Sección de Retroalimentación
                Text(
                  'Comentarios y Valoraciones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                FormularioRetroalimentacion(capsulaId: capsula.id),
                
                const SizedBox(height: 16),
                
                ListaRetroalimentacion(capsulaId: capsula.id, esAdmin: _esAdmin),
              ],
            ),
          ),
        );
      },
    );
  }
}

