import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neuroconecta2/models/guia.dart';
import 'package:neuroconecta2/services/guias_firestore_service.dart';
import 'package:neuroconecta2/services/guias_storage_service.dart';
import 'package:neuroconecta2/widgets/custom_markdown_body.dart';
import 'package:neuroconecta2/widgets/adaptive_image.dart';

class EditarGuiaScreen extends StatefulWidget {
  final Guia? guia;

  const EditarGuiaScreen({super.key, this.guia});

  @override
  State<EditarGuiaScreen> createState() => _EditarGuiaScreenState();
}

class _EditarGuiaScreenState extends State<EditarGuiaScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  String _tipoGuia = 'autores';
  bool _guardando = false;
  late List<BloqueGuia> _bloques;

  final _guiasService = GuiasFirestoreService();
  final _storageService = GuiasStorageService();

  @override
  void initState() {
    super.initState();
    final guia = widget.guia;
    if (guia != null) {
      _tituloController.text = guia.titulo;
      _tipoGuia = guia.tipoGuia;
      _bloques = List.from(guia.bloques);
    } else {
      _bloques = [BloqueGuia(tipo: 'texto', texto: '', orden: 0)];
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validarBloques()) return;
    setState(() => _guardando = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final bloquesOrdenados = _recalcularOrden();

      if (widget.guia == null) {
        await _guiasService.crearGuia(
          titulo: _tituloController.text.trim(),
          tipoGuia: _tipoGuia,
          bloques: bloquesOrdenados,
          creadoPorUid: userId,
        );
      } else {
        await _guiasService.actualizarGuia(
          guiaId: widget.guia!.id,
          titulo: _tituloController.text.trim(),
          tipoGuia: _tipoGuia,
          bloques: bloquesOrdenados,
        );
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.guia != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: DefaultTabController(
        length: 2,
        initialIndex: 0,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: Text(esEdicion ? 'Editar guía' : 'Nueva guía'),
              floating: true,
              snap: true,
              elevation: innerBoxIsScrolled ? 4 : 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _guardando ? 'Guardando...' : 'Guardar',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(
                    icon: const Icon(Icons.view_stream),
                    text: isMobile ? 'Bloques' : 'Editar bloques',
                  ),
                  Tab(
                    icon: const Icon(Icons.preview),
                    text: isMobile ? 'Vista' : 'Vista previa',
                  ),
                ],
              ),
            ),
          ],
          body: Form(
            key: _formKey,
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Tab 1: Editor de bloques
                Column(
                  children: [
                    // Encabezado con título y tipo
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _tituloController,
                              decoration: const InputDecoration(
                                labelText: 'Título',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _tipoGuia,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de guía',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'autores',
                                  child: Text('Autores'),
                                ),
                                DropdownMenuItem(
                                  value: 'funcionalidades',
                                  child: Text('Funcionalidades'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _tipoGuia = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Contenido: Editor de bloques
                    Expanded(
                      child: _buildBloquesEditor(),
                    ),
                  ],
                ),

                // Tab 2: Vista Previa
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y tipo
                      Text(
                        _tituloController.text.isEmpty
                            ? 'Título aquí'
                            : _tituloController.text,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(_tipoGuia),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                      ),
                      const SizedBox(height: 16),

                      // Render de bloques intercalados
                      if (_bloques.isEmpty)
                        Center(
                          child: Text(
                            'Agrega bloques de texto o imagen para ver la vista previa',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _bloques
                              .map(
                                (b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _renderBloque(b),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingMenu(),
    );
  }

  /// Menú flotante con opciones de guardar, cancelar y agregar bloques
  Widget _buildFloatingMenu() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Opción: Guardar
        Positioned(
          bottom: 110,
          right: 10,
          child: _FloatingMenuAction(
            icon: Icons.save,
            label: 'Guardar',
            onPressed: _guardando ? null : _guardar,
            loading: _guardando,
            heroTag: 'fab-guardar',
          ),
        ),
        // Opción: Cancelar
        Positioned(
          bottom: 65,
          right: 10,
          child: _FloatingMenuAction(
            icon: Icons.close,
            label: 'Cancelar',
            onPressed: () => context.pop(),
            heroTag: 'fab-cancelar',
          ),
        ),
        // Botón principal del menú -> mostrar Modal Bottom Sheet
        FloatingActionButton(
          heroTag: 'fab-agregar-menu',
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (sheetContext) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.text_fields),
                          title: const Text('Agregar texto (Markdown)'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            // Ejecutar la acción después de cerrar el sheet
                            Future.microtask(() => _agregarTexto());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.description),
                          title: const Text('Agregar texto plano'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            Future.microtask(() => _agregarTextoPlano());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Elegir de galería'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            Future.microtask(
                              () => _agregarImagenDesde(ImageSource.gallery),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Tomar foto'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            Future.microtask(
                              () => _agregarImagenDesde(ImageSource.camera),
                            );
                          },
                        ),
                        const Divider(height: 8),
                        ListTile(
                          leading: const Icon(Icons.close),
                          title: const Text('Cancelar'),
                          onTap: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          tooltip: 'Agregar bloque',
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildBloquesEditor() {
    if (_bloques.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Agrega tu primer bloque para comenzar',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el botón flotante (+) para agregar contenido',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _bloques.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _bloques.removeAt(oldIndex);
                _bloques.insert(newIndex, item);
                _recalcularOrden();
              });
            },
            itemBuilder: (context, index) {
              final bloque = _bloques[index];
              return Card(
                key: ValueKey('bloque_${bloque.tipo}_$index'),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bloque.tipo == 'texto'
                                ? 'Bloque de texto (Markdown)'
                                : bloque.tipo == 'texto_plano'
                                    ? 'Bloque de texto plano'
                                    : 'Bloque de imagen',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          PopupMenuButton<String>(
                            onSelected: (String tipo) {
                              if (bloque.tipo != 'imagen') {
                                setState(() {
                                  final b = _bloques[index];
                                  _bloques[index] = BloqueGuia(
                                    tipo: tipo,
                                    texto: b.texto,
                                    orden: b.orden,
                                  );
                                });
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'texto',
                                child: Text('Texto con Markdown'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'texto_plano',
                                child: Text('Texto plano (sin Markdown)'),
                              ),
                            ],
                            child: IconButton(
                              onPressed: null,
                              icon: const Icon(Icons.swap_horiz),
                              tooltip: 'Cambiar tipo de texto',
                            ),
                          ),
                          IconButton(
                            onPressed: () => _eliminarBloque(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (bloque.tipo == 'texto' || bloque.tipo == 'texto_plano')
                        TextFormField(
                          key: ValueKey('texto_${index}_${bloque.orden}'),
                          initialValue: bloque.texto ?? '',
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: bloque.tipo == 'texto'
                                ? 'Contenido (Markdown - soporta **negrita**, *cursiva*, # títulos, etc.)'
                                : 'Contenido (Texto plano - no interpreta Markdown)',
                            border: const OutlineInputBorder(),
                            helperText: bloque.tipo == 'texto'
                                ? 'Ej: # Título\n**Negrita** y *cursiva*'
                                : 'Ej: Este es texto plano sin interpretación',
                          ),
                          onChanged: (v) => _actualizarTexto(index, v),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bloque.url != null && bloque.url!.isNotEmpty)
                              AdaptiveImage(
                                imageUrl: bloque.url!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(8),
                              )
                            else
                              Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text('Sin imagen'),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _cambiarImagen(index),
                                  icon: const Icon(Icons.image),
                                  label: const Text('Reemplazar imagen'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _eliminarBloque(index),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Eliminar bloque'),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _renderBloque(BloqueGuia bloque) {
    if (bloque.tipo == 'imagen') {
      if (bloque.url == null || bloque.url!.isEmpty) {
        return Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Text('Imagen faltante')),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AdaptiveImage(
          imageUrl: bloque.url!,
          fit: BoxFit.cover,
        ),
      );
    }

    return CustomMarkdownBody(
      data: bloque.texto ?? '',
      selectable: true,
    );
  }

  List<BloqueGuia> _recalcularOrden() {
    for (var i = 0; i < _bloques.length; i++) {
      final b = _bloques[i];
      _bloques[i] = BloqueGuia(
        tipo: b.tipo,
        texto: b.texto,
        url: b.url,
        nombre: b.nombre,
        orden: i,
      );
    }
    return List<BloqueGuia>.from(_bloques);
  }

  void _actualizarTexto(int index, String value) {
    setState(() {
      final b = _bloques[index];
      _bloques[index] = BloqueGuia(
        tipo: 'texto',
        texto: value,
        orden: b.orden,
      );
    });
  }

  void _agregarTexto() {
    setState(() {
      _bloques.add(
        BloqueGuia(
          tipo: 'texto',
          texto: '',
          orden: _bloques.length,
        ),
      );
    });
  }

  void _agregarTextoPlano() {
    setState(() {
      _bloques.add(
        BloqueGuia(
          tipo: 'texto_plano',
          texto: '',
          orden: _bloques.length,
        ),
      );
    });
  }

  Future<void> _agregarImagenDesde(ImageSource source) async {
    try {
      final url = await _storageService.subirImagenConCompresion(
        guiaId: widget.guia?.id ?? 'nueva',
        onProgress: (progress) => debugPrint('Progreso de carga: $progress%'),
        source: source,
      );
      setState(() {
        _bloques.add(
          BloqueGuia(
            tipo: 'imagen',
            url: url,
            nombre: 'Imagen ${_bloques.length + 1}',
            orden: _bloques.length,
          ),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen agregada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    }
  }

  Future<void> _cambiarImagen(int index) async {
    try {
      final url = await _storageService.subirImagenConCompresion(
        guiaId: widget.guia?.id ?? 'nueva',
        onProgress: (progress) => debugPrint('Progreso de carga: $progress%'),
      );
      setState(() {
        final b = _bloques[index];
        _bloques[index] = BloqueGuia(
          tipo: 'imagen',
          url: url,
          nombre: b.nombre ?? 'Imagen ${index + 1}',
          orden: b.orden,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen reemplazada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reemplazar: $e')),
        );
      }
    }
  }

  void _eliminarBloque(int index) {
    setState(() {
      _bloques.removeAt(index);
      _recalcularOrden();
    });
  }

  bool _validarBloques() {
    final tieneTexto = _bloques.any(
      (b) => b.tipo == 'texto' && (b.texto?.trim().isNotEmpty ?? false),
    );

    if (!tieneTexto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un bloque de texto')),
      );
      return false;
    }
    return true;
  }
}

/// Widget para representar una acción en el menú flotante
class _FloatingMenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String heroTag;

  const _FloatingMenuAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: FloatingActionButton.small(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(icon),
      ),
    );
  }
}
