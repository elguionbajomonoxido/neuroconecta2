import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/retroalimentacion.dart';
import '../services/feedback_service.dart';
import 'estrella_rating.dart';

class ListaRetroalimentacion extends StatefulWidget {
  final String capsulaId;
  final bool esAdmin;

  const ListaRetroalimentacion({
    super.key,
    required this.capsulaId,
    required this.esAdmin,
  });

  @override
  State<ListaRetroalimentacion> createState() => _ListaRetroalimentacionState();
}

class _ListaRetroalimentacionState extends State<ListaRetroalimentacion> {
  final ServicioRetroalimentacion _servicio = ServicioRetroalimentacion();
  List<String> _listaGroserias = [];

  @override
  void initState() {
    super.initState();
    _cargarGroserias();
  }

  Future<void> _cargarGroserias() async {
    try {
      final desdeFirestore = await _servicio.obtenerListaGroseriasFirestore();
      if (desdeFirestore.isNotEmpty) {
        if (!mounted) return;
        setState(() => _listaGroserias = desdeFirestore);
        return;
      }
    } catch (_) {
      // ignore and fallback
    }

    // fallback to asset
    try {
      final raw = await rootBundle.loadString('assets/groserias.json');
      final data = json.decode(raw);
      if (data is List) {
        if (!mounted) return;
        setState(() => _listaGroserias = data.map((e) => e.toString()).toList());
        return;
      }
    } catch (_) {
      // final fallback below
    }

    if (!mounted) return;
    setState(() => _listaGroserias = ['puta', 'mierda', 'gilipollas']);
  }

  String _sanitizarComentario(String texto) {
    final malas = _listaGroserias.isNotEmpty
        ? _listaGroserias
        : ['puta', 'mierda', 'gilipollas'];
    var limpio = texto;
    for (final m in malas) {
      final regex = RegExp('\\b' + RegExp.escape(m) + '\\b', caseSensitive: false);
      limpio = limpio.replaceAll(regex, '*' * m.length);
    }
    return limpio;
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = FirebaseAuth.instance.currentUser;

    return StreamBuilder<List<Retroalimentacion>>(
      stream: _servicio.obtenerRetroalimentacionPorCapsula(widget.capsulaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error cargando comentarios: ${snapshot.error}');
        }

        final feedbacks = snapshot.data ?? [];

        if (feedbacks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Aún no hay comentarios. ¡Sé el primero!', style: TextStyle(fontStyle: FontStyle.italic)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: feedbacks.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final item = feedbacks[index];
            final esPropietario = usuarioActual?.uid == item.usuarioUid;
            final puedeEliminar = widget.esAdmin || esPropietario;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Text(
                  item.nombreUsuario.isNotEmpty ? item.nombreUsuario[0].toUpperCase() : '?',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.nombreUsuario,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ClasificacionEstrellas(calificacion: item.estrellas, tamano: 16),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(_sanitizarComentario(item.comentario)),
                  const SizedBox(height: 4),
                  Text(
                    _formatearFecha(item.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              trailing: puedeEliminar
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: () => _confirmarEliminacion(context, _servicio, item.id),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  String _formatearFecha(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmarEliminacion(BuildContext context, ServicioRetroalimentacion servicio, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Estás seguro de que quieres eliminar este comentario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              servicio.eliminarRetroalimentacion(id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
