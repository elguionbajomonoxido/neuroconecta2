import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void dispose() {
    _controladorComentario.dispose();
    super.dispose();
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

      final feedback = Retroalimentacion(
        id: '',
        capsulaId: widget.capsulaId,
        usuarioUid: user.uid,
        nombreUsuario: user.displayName ?? 'Usuario',
        comentario: _controladorComentario.text.trim(),
        estrellas: _calificacion,
        createdAt: DateTime.now(),
      );

      await _servicioRetroalimentacion.agregarRetroalimentacion(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por tu opinión!'), backgroundColor: Colors.green),
        );
        _controladorComentario.clear();
        setState(() {
          _calificacion = 0;
        });
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
