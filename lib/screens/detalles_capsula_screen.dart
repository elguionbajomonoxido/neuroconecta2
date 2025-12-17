import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../models/capsula.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/retroalimentacion_list.dart';
import '../widgets/retroalimentacion_form.dart';
import '../widgets/media_viewer.dart';
import '../services/feedback_service.dart';
import '../widgets/estrella_rating.dart';

class PantallaDetalleCapsula extends StatefulWidget {
  final String capsuleId;

  const PantallaDetalleCapsula({super.key, required this.capsuleId});

  @override
  State<PantallaDetalleCapsula> createState() => _PantallaDetalleCapsulaState();
}

class _PantallaDetalleCapsulaState extends State<PantallaDetalleCapsula> {
  final ServicioFirestore _servicioFirestore = ServicioFirestore();
  final ServicioRetroalimentacion _servicioRetro = ServicioRetroalimentacion();
  bool _esAdmin = false;
  bool _esAutor = false;
  String? _usuarioUid;

  @override
  void initState() {
    super.initState();
    _verificarAdmin();
  }

  Future<void> _verificarAdmin() async {
    try {
      final role = await _servicioFirestore.obtenerRolUsuario();
      if (!mounted) return;
      setState(() {
        _esAdmin = role == 'admin';
        _esAutor = role == 'autor';
        _usuarioUid = FirebaseAuth.instance.currentUser?.uid;
      });
    } catch (_) {}
  }

  Future<void> _eliminarCapsula(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cápsula'),
        content: const Text('¿Estás seguro de que deseas eliminar esta cápsula? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
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
            actions: () {
              final List<Widget> acciones = [];
              // Edit solo para admin
              // Editar: admin o autor que sea propietario de la cápsula
              if (_esAdmin || (_esAutor && capsula.creadoPorUid == _usuarioUid)) {
                acciones.add(IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('${RutasAplicacion.editarCapsula}/${capsula.id}'),
                ));
              }

              // Eliminar para admin o para autor que sea propietario de la cápsula
              final puedeEliminar = _esAdmin || (_esAutor && capsula.creadoPorUid == _usuarioUid);
              if (puedeEliminar) {
                acciones.add(IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _eliminarCapsula(context),
                ));
              }

              return acciones.isEmpty ? null : acciones;
            }(),
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
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Builder(
                              builder: (ctx) {
                                final cs = Theme.of(ctx).colorScheme;
                                return Chip(
                                  label: Text(capsula.categoria, style: TextStyle(color: cs.onPrimaryContainer)),
                                  backgroundColor: cs.primaryContainer,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                              child: Builder(
                                builder: (ctx) {
                                  final cs = Theme.of(ctx).colorScheme;
                                  return Chip(
                                    label: Text(capsula.segmento.toUpperCase(), style: TextStyle(color: cs.onSurface)),
                                    backgroundColor: cs.surfaceContainerHighest,
                                  );
                                },
                              ),
                          ),
                        ],
                      ),
                    ),

                    // Mostrar valoración promedio (derecha, ancho fijo)
                    FutureBuilder<Map<String, dynamic>>(
                      future: _servicioRetro.obtenerEstadisticasCapsula(capsula.id),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox(width: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                        }
                        final data = snap.data ?? {'avg': 0.0, 'count': 0};
                        final avg = (data['avg'] as num?)?.toDouble() ?? 0.0;
                        final count = (data['count'] as int?) ?? 0;
                        return SizedBox(
                          width: 140,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClasificacionEstrellas(calificacion: avg.round(), tamano: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    count > 0 ? '${avg.toStringAsFixed(1)} ($count)' : 'Sin valoraciones',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                
                FormularioRetroalimentacion(capsulaId: capsula.id, forceCompactIfExists: true),
                
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

