import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/capsula.dart';
import '../services/firestore_service.dart';
import '../services/feedback_service.dart';

class PantallaCrearCapsula extends StatefulWidget {
  const PantallaCrearCapsula({super.key});

  @override
  State<PantallaCrearCapsula> createState() => _PantallaCrearCapsulaState();
}

class _PantallaCrearCapsulaState extends State<PantallaCrearCapsula> {
  final _formKey = GlobalKey<FormState>();
  final ServicioFirestore _servicioFirestore = ServicioFirestore();

  // Controladores
  final TextEditingController _tituloControlador = TextEditingController();
  final TextEditingController _resumenControlador = TextEditingController();
  final TextEditingController _contenidoControlador = TextEditingController();
  final TextEditingController _categoriaControlador = TextEditingController();
  final TextEditingController _mediaUrlControlador = TextEditingController();
  final TextEditingController _autorControlador = TextEditingController();
  
  String _segmento = 'adultos'; // Valor por defecto
  bool _esBorrador = false;
  bool _estaCargando = false;
  // Lista de groserías
  List<String> _listaGroserias = [];

  @override
  void dispose() {
    _tituloControlador.dispose();
    _resumenControlador.dispose();
    _contenidoControlador.dispose();
    _categoriaControlador.dispose();
    _mediaUrlControlador.dispose();
    _autorControlador.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      _autorControlador.text = user.displayName!;
    }
    _cargarGroserias();
  }

  Future<void> _cargarGroserias() async {
    try {
      final servicio = ServicioRetroalimentacion();
      final desdeFs = await servicio.obtenerListaGroserias();
      if (desdeFs.isNotEmpty) {
        _listaGroserias = desdeFs;
        return;
      }
    } catch (_) {}
    // fallback básico
    _listaGroserias = ['puta', 'mierda', 'gilipollas', 'idiota', 'imbecil', 'cabron', 'pendejo'];
  }

  bool _contieneGroseria(String texto) {
    if (_listaGroserias.isEmpty) return false;
    final s = texto.toLowerCase();
    for (final m in _listaGroserias) {
      final p = m.toLowerCase().trim();
      if (p.isEmpty) continue;
      final regex = RegExp(r'(^|\W)'+RegExp.escape(p)+r'($|\W)', caseSensitive: false);
      if (regex.hasMatch(s)) return true;
    }
    return false;
  }

  Future<void> _guardarCapsula() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar groserías
    final titulo = _tituloControlador.text.trim();
    final resumen = _resumenControlador.text.trim();
    final contenido = _contenidoControlador.text.trim();
    if (_contieneGroseria(titulo) || _contieneGroseria(resumen) || _contieneGroseria(contenido)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El contenido contiene palabras censuradas'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _estaCargando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final nuevaCapsula = Capsula(
        id: '', // Firestore generará el ID
        titulo: _tituloControlador.text.trim(),
        resumen: _resumenControlador.text.trim(),
        contenidoLargo: _contenidoControlador.text.trim(),
        categoria: _categoriaControlador.text.trim(),
        segmento: _segmento,
        esBorrador: _esBorrador,
        mediaUrl: _mediaUrlControlador.text.trim().isEmpty ? null : _mediaUrlControlador.text.trim(),
        autor: _autorControlador.text.trim(),
        creadoPorUid: user.uid,
        createdAt: DateTime.now(),
      );

      await _servicioFirestore.agregarCapsula(nuevaCapsula);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cápsula creada exitosamente'), backgroundColor: Colors.green),
        );
        context.pop(); // Volver al Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cápsula'),
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
                controller: _tituloControlador,
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Obligatorio';
                  if (value.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Autor
              TextFormField(
                controller: _autorControlador,
                decoration: const InputDecoration(labelText: 'Autor'),
              ),
              const SizedBox(height: 16),

              // Resumen
              TextFormField(
                controller: _resumenControlador,
                decoration: const InputDecoration(labelText: 'Resumen corto *'),
                maxLines: 2,
                validator: (value) => (value == null || value.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Categoría
              TextFormField(
                controller: _categoriaControlador,
                decoration: const InputDecoration(labelText: 'Categoría (ej. Ansiedad, Estudio)'),
              ),
              const SizedBox(height: 16),

              // Media URL
              TextFormField(
                controller: _mediaUrlControlador,
                decoration: const InputDecoration(labelText: 'URL de Video o Imagen (Opcional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // 
              // Segmento (Dropdown)
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

              // Contenido Largo (Markdown)
              TextFormField(
                controller: _contenidoControlador,
                decoration: const InputDecoration(
                  labelText: 'Contenido (Markdown) *',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) => (value == null || value.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Es Borrador (Switch)
              SwitchListTile(
                title: const Text('Guardar como borrador'),
                value: _esBorrador,
                onChanged: (val) => setState(() => _esBorrador = val),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton(
                onPressed: _estaCargando ? null : _guardarCapsula,
                child: _estaCargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Crear Cápsula'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
