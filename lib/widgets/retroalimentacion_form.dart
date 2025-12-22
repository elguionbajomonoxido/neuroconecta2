import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/retroalimentacion.dart';
import '../services/feedback_service.dart';
import 'estrella_rating.dart';

class FormularioRetroalimentacion extends StatefulWidget {
  final String capsulaId;
  final bool forceCompactIfExists;

  const FormularioRetroalimentacion({super.key, required this.capsulaId, this.forceCompactIfExists = false});

  @override
  State<FormularioRetroalimentacion> createState() => _FormularioRetroalimentacionState();
}

class _FormularioRetroalimentacionState extends State<FormularioRetroalimentacion> {
  final _controladorComentario = TextEditingController();
  final ServicioRetroalimentacion _servicioRetroalimentacion = ServicioRetroalimentacion();
  int _calificacion = 0;
  bool _estaEnviando = false;
  String? _feedbackId;
  bool _editando = false;
  List<String> _listaGroserias = [];
  bool _cargaCompletada = false;

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
          // por defecto no abrir el editor: mostramos vista compacta
          _editando = false;
        });
      });
    }
    // Marca que la comprobación inicial ya se completó
    if (mounted) setState(() => _cargaCompletada = true);
  }

  Future<void> _cargarListaGroserias() async {
    // Intentar cargar desde Firestore primero
    try {
      final desdeFirestore = await _servicioRetroalimentacion.obtenerListaGroserias();
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
      final regex = RegExp('\\b${RegExp.escape(m)}\\b', caseSensitive: false);
      limpio = limpio.replaceAll(regex, '*' * m.length);
    }
    return limpio;
  }

  bool _contieneGroseria(String texto) {
    final malas = _listaGroserias.isNotEmpty
        ? _listaGroserias
        : ['puta', 'mierda', 'gilipollas', 'idiota', 'imbecil', 'cabron', 'pendejo'];
    final s = texto.toLowerCase();
    for (final m in malas) {
      final p = m.toLowerCase().trim();
      if (p.isEmpty) continue;
      final regex = RegExp(r'(^|\W)'+RegExp.escape(p)+r'($|\W)', caseSensitive: false);
      if (regex.hasMatch(s)) return true;
    }
    return false;
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

      final rawComentario = _controladorComentario.text.trim();
      // Denegar si contiene groserías (no se permite ni a admins)
      if (_contieneGroseria(rawComentario)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El comentario contiene palabras censuradas'), backgroundColor: Colors.red));
        return;
      }

      final comentarioLimpio = _sanitizarComentario(rawComentario);

      if (_feedbackId != null) {
        // Actualizar existente
        await _servicioRetroalimentacion.actualizarRetroalimentacion(_feedbackId!, {
          'comentario': comentarioLimpio,
          'estrellas': _calificacion,
        });
        if (mounted) setState(() => _editando = false);
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
        // asignar id determinístico localmente para reflejar existencia
        final nuevoId = '${widget.capsulaId}_${user.uid}';
        if (mounted) {
          setState(() {
          _feedbackId = nuevoId;
          _editando = false;
        });
        }
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
    // Si se solicitó forzar compact view y aún no hemos comprobado, mostrar indicador
    if (widget.forceCompactIfExists && !_cargaCompletada) {
      return const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator()));
    }

    // Si ya existe feedback y no estamos en modo edición, mostrar vista compacta con botón Editar
    if (_feedbackId != null && !_editando) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu opinión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  ClasificacionEstrellas(calificacion: _calificacion, tamano: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$_calificacion estrella(s)', style: const TextStyle(fontWeight: FontWeight.w600))),
                  TextButton(onPressed: () => setState(() => _editando = true), child: const Text('Editar')),
                ],
              ),
              const SizedBox(height: 12),
              Text(_controladorComentario.text.trim(), style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // Modo edición / nuevo comentario
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_feedbackId == null ? 'Deja tu opinión' : 'Editar tu opinión', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _estaEnviando ? null : _enviarRetroalimentacion,
                    child: _estaEnviando
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                        : Text(_feedbackId == null ? 'Enviar Comentario' : 'Guardar Cambios'),
                  ),
                ),
                const SizedBox(width: 8),
                if (_feedbackId != null)
                  OutlinedButton(onPressed: () => setState(() => _editando = false), child: const Text('Cancelar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
