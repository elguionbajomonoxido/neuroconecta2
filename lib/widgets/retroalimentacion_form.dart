import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/retroalimentacion.dart';
import '../services/feedback_service.dart';
import 'estrella_rating.dart';

class FormularioRetroalimentacion extends StatefulWidget {
  final String capsulaId;

  const FormularioRetroalimentacion({super.key, required this.capsulaId});

  @override
  State<FormularioRetroalimentacion> createState() => _FormularioRetroalimentacionState();
}

class _FormularioRetroalimentacionState extends State<FormularioRetroalimentacion> {
  final _controladorComentario = TextEditingController();
  final ServicioRetroalimentacion _servicioRetroalimentacion = ServicioRetroalimentacion();
  int _calificacion = 0;
  bool _estaEnviando = false;
  String? _feedbackId;
  List<String> _listaGroserias = [];

  @override
  void dispose() {
    _controladorComentario.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _cargarListaGroserias();
    if (!mounted) return;
    await _cargarSiExiste();
  }

  Future<void> _cargarSiExiste() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final existente = await _servicioRetroalimentacion.obtenerRetroalimentacionUsuario(widget.capsulaId, user.uid);
    if (existente != null) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _feedbackId = existente.id;
          _calificacion = existente.estrellas;
          _controladorComentario.text = existente.comentario;
        });
      });
    }
  }

  Future<void> _cargarListaGroserias() async {
    // Intentar cargar desde Firestore primero
    try {
      final desdeFirestore = await _servicioRetroalimentacion.obtenerListaGroseriasFirestore();
      if (desdeFirestore.isNotEmpty) {
        _listaGroserias = desdeFirestore;
        return;
      }
    } catch (_) {
      // continuar a asset
    }

    // Luego intentar cargar desde asset JSON
    try {
      final raw = await rootBundle.loadString('assets/groserias.json');
      final data = json.decode(raw);
      if (data is List) {
        _listaGroserias = data.map((e) => e.toString()).toList();
        return;
      }
    } catch (_) {
      // continuar a fallback
    }

    // Fallback por defecto si todo falla
    _listaGroserias = ['puta', 'mierda', 'gilipollas', 'idiota', 'imbecil', 'cabron', 'pendejo'];
  }

  String _sanitizarComentario(String texto) {
    final malas = _listaGroserias.isNotEmpty
        ? _listaGroserias
        : ['puta', 'mierda', 'gilipollas', 'idiota', 'imbecil', 'cabron', 'pendejo'];
    var limpio = texto;
    for (final m in malas) {
      final regex = RegExp('\\b' + RegExp.escape(m) + '\\b', caseSensitive: false);
      limpio = limpio.replaceAll(regex, '*' * m.length);
    }
    return limpio;
  }

  Future<void> _enviarRetroalimentacion() async {
    if (_calificacion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una calificación (estrellas).')),
      );
      return;
    }
    if (_controladorComentario.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un comentario.')),
      );
      return;
    }

    setState(() => _estaEnviando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final comentarioLimpio = _sanitizarComentario(_controladorComentario.text.trim());

      if (_feedbackId != null) {
        // Actualizar existente
        await _servicioRetroalimentacion.actualizarRetroalimentacion(_feedbackId!, {
          'comentario': comentarioLimpio,
          'estrellas': _calificacion,
        });
      } else {
        final feedback = Retroalimentacion(
          id: '',
          capsulaId: widget.capsulaId,
          usuarioUid: user.uid,
          nombreUsuario: user.displayName ?? 'Usuario',
          comentario: comentarioLimpio,
          estrellas: _calificacion,
          createdAt: DateTime.now(),
        );

        await _servicioRetroalimentacion.agregarRetroalimentacion(feedback);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por tu opinión!'), backgroundColor: Colors.green),
        );
        // Mantener el comentario y calificación para permitir edición; si se desea limpiar descomentar
        //_controladorComentario.clear();
        //setState(() { _calificacion = 0; _feedbackId = null; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _estaEnviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deja tu opinión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Center(
              child: ClasificacionEstrellas(
                calificacion: _calificacion,
                tamano: 40,
                alCambiarCalificacion: (rating) => setState(() => _calificacion = rating),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorComentario,
              decoration: const InputDecoration(
                hintText: 'Escribe tu comentario aquí...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _estaEnviando ? null : _enviarRetroalimentacion,
                child: _estaEnviando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Enviar Comentario'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
