import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/feedback_service.dart';

class EditarGroseriasScreen extends StatefulWidget {
  const EditarGroseriasScreen({super.key});

  @override
  State<EditarGroseriasScreen> createState() => _EditarGroseriasScreenState();
}

class _EditarGroseriasScreenState extends State<EditarGroseriasScreen> {
  final ServicioRetroalimentacion _servicio = ServicioRetroalimentacion();
  final List<TextEditingController> _controllers = [];
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lista = await _servicio.obtenerListaGroseriasFirestore();
      if (lista.isNotEmpty) {
        if (!mounted) return;
        _setControllersFromList(lista);
        setState(() => _cargando = false);
        return;
      }
    } catch (_) {
      // ignore and fallback to asset
    }

    // Intentar cargar desde asset
    try {
      final raw = await rootBundle.loadString('assets/groserias.json');
      final data = json.decode(raw);
      if (data is List) {
        if (!mounted) return;
        final list = data.map((e) => e.toString()).toList();
        _setControllersFromList(list);
        setState(() => _cargando = false);
        return;
      }
    } catch (_) {
      // final fallback
    }

    if (!mounted) return;
    _setControllersFromList(['puta', 'mierda', 'gilipollas']);
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _guardar() async {
    final lista = _controllers.map((c) => c.text.trim()).where((e) => e.isNotEmpty).toList();
    setState(() => _guardando = true);
    try {
      await _servicio.actualizarListaGroseriasFirestore(lista);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lista guardada correctamente')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setControllersFromList(List<String> lista) {
    // limpiar
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    for (final p in lista) {
      _controllers.add(TextEditingController(text: p));
    }
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
    }
  }

  void _addEmpty() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeAt(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      if (_controllers.isEmpty) _controllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editar groserías'),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Gestiona la lista de groserías. Añade, edita o elimina palabras.'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _controllers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final controller = _controllers[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: 'Palabra #${index + 1}',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.save, color: Colors.green),
                                  onPressed: _guardando ? null : () => _guardarIndividual(index),
                                  tooltip: 'Guardar palabra',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: _guardando ? null : () => _removeAt(index),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addEmpty,
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir palabra'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _guardarIndividual(int index) async {
    final palabra = _controllers[index].text.trim();
    if (palabra.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La palabra está vacía')));
      return;
    }
    setState(() => _guardando = true);
    try {
      final lista = _controllers.map((c) => c.text.trim()).where((e) => e.isNotEmpty).toList();
      await _servicio.actualizarListaGroseriasFirestore(lista);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
