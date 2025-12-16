import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class PantallaEditarCapsula extends StatefulWidget {
  final String capsuleId;

  const PantallaEditarCapsula({super.key, required this.capsuleId});

  @override
  State<PantallaEditarCapsula> createState() => _PantallaEditarCapsulaState();
}

class _PantallaEditarCapsulaState extends State<PantallaEditarCapsula> {
  final _formKey = GlobalKey<FormState>();
  final ServicioFirestore _servicioFirestore = ServicioFirestore();

  // Controladores
  late TextEditingController _controladorTitulo;
  late TextEditingController _controladorResumen;
  late TextEditingController _controladorContenido;
  late TextEditingController _controladorCategoria;
  late TextEditingController _controladorMediaUrl;
  late TextEditingController _controladorAutor;
  
  String _segmento = 'adultos';
  bool _esBorrador = false;
  bool _estaCargando = false;
  bool _cargandoDatos = true;
  // Lista de groserías cargada desde Firestore
  List<String> _listaGroserias = [];

  @override
  void initState() {
    super.initState();
    _controladorTitulo = TextEditingController();
    _controladorResumen = TextEditingController();
    _controladorContenido = TextEditingController();
    _controladorCategoria = TextEditingController();
    _controladorMediaUrl = TextEditingController();
    _controladorAutor = TextEditingController();
    _cargarGroserias();
    _cargarCapsula();
  }

  Future<void> _cargarGroserias() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('groserias').get();
      final data = doc.data();
      if (data != null && data['palabras'] is List) {
        _listaGroserias = List<String>.from(data['palabras'].map((e) => e.toString()));
      } else {
        _listaGroserias = [];
      }
    } catch (_) {
      _listaGroserias = [];
    }
  }

  bool _contieneGroseria(String texto) {
    if (_listaGroserias.isEmpty) return false;
    final s = texto.toLowerCase();
    for (final palabra in _listaGroserias) {
      final p = palabra.toLowerCase().trim();
      if (p.isEmpty) continue;
      final regex = RegExp(r'(^|\\W)'+RegExp.escape(p)+r'($|\\W)', caseSensitive: false);
      if (regex.hasMatch(s)) return true;
    }
    return false;
  }

  Future<void> _cargarCapsula() async {
    try {
      // Usamos first para obtener el valor actual del stream una sola vez
      final capsula = await _servicioFirestore.obtenerCapsula(widget.capsuleId).first;
      // Verificar permisos: admin o autor propietario
      final role = await _servicioFirestore.obtenerRolUsuario();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final puedeEditar = role == 'admin' || (role == 'autor' && capsula.creadoPorUid == uid);
      if (!puedeEditar) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tienes permiso para editar esta cápsula'), backgroundColor: Colors.red),
          );
          context.pop();
        }
        return;
      }
      
      _controladorTitulo.text = capsula.titulo;
      _controladorResumen.text = capsula.resumen;
      _controladorContenido.text = capsula.contenidoLargo;
      _controladorCategoria.text = capsula.categoria;
      _controladorMediaUrl.text = capsula.mediaUrl ?? '';
      _controladorAutor.text = capsula.autor;
      
      setState(() {
        _segmento = capsula.segmento;
        _esBorrador = capsula.esBorrador;
        _cargandoDatos = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando cápsula: $e')),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorResumen.dispose();
    _controladorContenido.dispose();
    _controladorMediaUrl.dispose();
    _controladorCategoria.dispose();
    _controladorAutor.dispose();
    super.dispose();
  }

  Future<void> _actualizarCapsula() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar contenido frente a lista de groserías antes de enviar
    final titulo = _controladorTitulo.text.trim();
    final resumen = _controladorResumen.text.trim();
    final contenido = _controladorContenido.text.trim();

    if (_contieneGroseria(titulo) || _contieneGroseria(resumen) || _contieneGroseria(contenido)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El contenido contiene palabras censuradas'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _estaCargando = true);

    try {
      final updatedData = {
        'titulo': _controladorTitulo.text.trim(),
        'resumen': _controladorResumen.text.trim(),
        'contenidoLargo': _controladorContenido.text.trim(),
        'categoria': _controladorCategoria.text.trim(),
        'segmento': _segmento,
        'autor': _controladorAutor.text.trim(),
        'mediaUrl': _controladorMediaUrl.text.trim().isEmpty ? null : _controladorMediaUrl.text.trim(),
        'esBorrador': _esBorrador,
      };

      await _servicioFirestore.actualizarCapsula(widget.capsuleId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cápsula actualizada'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cápsula'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              TextFormField(
                controller: _controladorTitulo,
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Obligatorio';
                  if (value.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Resumen
              TextFormField(
                controller: _controladorResumen,
                decoration: const InputDecoration(labelText: 'Resumen corto *'),
                maxLines: 2,
                validator: (value) => (value == null || value.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Categoría
              TextFormField(
                controller: _controladorCategoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 16),

              // Autor
              TextFormField(
                controller: _controladorAutor,
                decoration: const InputDecoration(labelText: 'Autor'),
              ),
              const SizedBox(height: 16),

              // Media URL
              TextFormField(
                controller: _controladorMediaUrl,
                decoration: const InputDecoration(labelText: 'URL de Video o Imagen (Opcional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Segmento
              DropdownButtonFormField<String>(
                initialValue: _segmento,
                decoration: const InputDecoration(labelText: 'Segmento'),
                items: const [
                  DropdownMenuItem(value: 'niños', child: Text('Niños')),
                  DropdownMenuItem(value: 'adolescentes', child: Text('Adolescentes')),
                  DropdownMenuItem(value: 'adultos', child: Text('Adultos')),
                ],
                onChanged: (val) => setState(() => _segmento = val!),
              ),
              const SizedBox(height: 16),

              // Contenido
              TextFormField(
                controller: _controladorContenido,
                decoration: const InputDecoration(
                  labelText: 'Contenido (Markdown) *',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) => (value == null || value.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Borrador
              SwitchListTile(
                title: const Text('Guardar como borrador'),
                value: _esBorrador,
                onChanged: (val) => setState(() => _esBorrador = val),
              ),
              const SizedBox(height: 24),

              // Botón Actualizar
              ElevatedButton(
                onPressed: _estaCargando ? null : _actualizarCapsula,
                child: _estaCargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

