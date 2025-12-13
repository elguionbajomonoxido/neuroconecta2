import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  
  String _segmento = 'adultos';
  bool _esBorrador = false;
  bool _estaCargando = false;
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _controladorTitulo = TextEditingController();
    _controladorResumen = TextEditingController();
    _controladorContenido = TextEditingController();
    _controladorCategoria = TextEditingController();
    _controladorMediaUrl = TextEditingController();
    _cargarCapsula();
  }

  Future<void> _cargarCapsula() async {
    try {
      // Usamos first para obtener el valor actual del stream una sola vez
      final capsula = await _servicioFirestore.obtenerCapsula(widget.capsuleId).first;
      
      _controladorTitulo.text = capsula.titulo;
      _controladorResumen.text = capsula.resumen;
      _controladorContenido.text = capsula.contenidoLargo;
      _controladorCategoria.text = capsula.categoria;
      _controladorMediaUrl.text = capsula.mediaUrl ?? '';
      
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
    super.dispose();
  }

  Future<void> _actualizarCapsula() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _estaCargando = true);

    try {
      final updatedData = {
        'titulo': _controladorTitulo.text.trim(),
        'resumen': _controladorResumen.text.trim(),
        'contenidoLargo': _controladorContenido.text.trim(),
        'categoria': _controladorCategoria.text.trim(),
        'segmento': _segmento,
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

