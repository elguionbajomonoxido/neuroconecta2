import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';
import '../models/capsula.dart';
import '../services/firestore_service.dart';

class CreateCapsuleScreen extends StatefulWidget {
  const CreateCapsuleScreen({super.key});

  @override
  State<CreateCapsuleScreen> createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends State<CreateCapsuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controladores
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _resumenController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  
  String _segmento = 'adultos'; // Valor por defecto
  bool _esBorrador = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _resumenController.dispose();
    _contenidoController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Future<void> _saveCapsule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final newCapsule = Capsula(
        id: '', // Firestore generará el ID
        titulo: _tituloController.text.trim(),
        resumen: _resumenController.text.trim(),
        contenidoLargo: _contenidoController.text.trim(),
        categoria: _categoriaController.text.trim(),
        segmento: _segmento,
        esBorrador: _esBorrador,
        creadoPorUid: user.uid,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addCapsula(newCapsule);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cápsula creada exitosamente'), backgroundColor: Colors.green),
        );
        context.pop(); // Volver al Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cápsula'),
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
                decoration: const InputDecoration(labelText: 'Categoría (ej. Ansiedad, Estudio)'),
              ),
              const SizedBox(height: 16),

              // Segmento (Dropdown)
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

              // Contenido Largo (Markdown)
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

              // Es Borrador (Switch)
              SwitchListTile(
                title: const Text('Guardar como borrador'),
                value: _esBorrador,
                onChanged: (val) => setState(() => _esBorrador = val),
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCapsule,
                child: _isLoading
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

