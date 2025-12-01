import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../services/firestore_service.dart';

class EditCapsuleScreen extends StatefulWidget {
  final String capsuleId;

  const EditCapsuleScreen({super.key, required this.capsuleId});

  @override
  State<EditCapsuleScreen> createState() => _EditCapsuleScreenState();
}

class _EditCapsuleScreenState extends State<EditCapsuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controladores
  late TextEditingController _tituloController;
  late TextEditingController _resumenController;
  late TextEditingController _contenidoController;
  late TextEditingController _categoriaController;
  
  String _segmento = 'adultos';
  bool _esBorrador = false;
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController();
    _resumenController = TextEditingController();
    _contenidoController = TextEditingController();
    _categoriaController = TextEditingController();
    _loadCapsule();
  }

  Future<void> _loadCapsule() async {
    try {
      // Usamos first para obtener el valor actual del stream una sola vez
      final capsula = await _firestoreService.getCapsula(widget.capsuleId).first;
      
      _tituloController.text = capsula.titulo;
      _resumenController.text = capsula.resumen;
      _contenidoController.text = capsula.contenidoLargo;
      _categoriaController.text = capsula.categoria;
      
      setState(() {
        _segmento = capsula.segmento;
        _esBorrador = capsula.esBorrador;
        _isFetching = false;
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
    _tituloController.dispose();
    _resumenController.dispose();
    _contenidoController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Future<void> _updateCapsule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedData = {
        'titulo': _tituloController.text.trim(),
        'resumen': _resumenController.text.trim(),
        'contenidoLargo': _contenidoController.text.trim(),
        'categoria': _categoriaController.text.trim(),
        'segmento': _segmento,
        'esBorrador': _esBorrador,
      };

      await _firestoreService.updateCapsula(widget.capsuleId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cápsula actualizada'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cápsula'),
        backgroundColor: AppTheme.backgroundColor,
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
                controller: _tituloController,
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
                controller: _resumenController,
                decoration: const InputDecoration(labelText: 'Resumen corto *'),
                maxLines: 2,
                validator: (value) => (value == null || value.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Categoría
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 16),

              // Segmento
              DropdownButtonFormField<String>(
                value: _segmento,
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
                controller: _contenidoController,
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
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),

              // Botón Actualizar
              ElevatedButton(
                onPressed: _isLoading ? null : _updateCapsule,
                child: _isLoading
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

