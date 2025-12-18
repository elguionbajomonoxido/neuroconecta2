// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neuroconecta2/models/guia.dart';
import 'package:neuroconecta2/services/guias_storage_service.dart';

class GaleriaImagenesConDragDrop extends StatefulWidget {
  final List<ImagenGuia> imagenes;
  final ValueChanged<List<ImagenGuia>> onImagenesChanged;
  final GuiasStorageService storageService;
  final String guiaId;

  const GaleriaImagenesConDragDrop({
    super.key,
    required this.imagenes,
    required this.onImagenesChanged,
    required this.storageService,
    required this.guiaId,
  });

  @override
  State<GaleriaImagenesConDragDrop> createState() =>
      _GaleriaImagenesConDragDropState();
}

class _GaleriaImagenesConDragDropState
    extends State<GaleriaImagenesConDragDrop> {
  late List<ImagenGuia> _imagenes;
  bool _cargando = false;
  int _progreso = 0;

  @override
  void initState() {
    super.initState();
    _imagenes = List.from(widget.imagenes);
  }

  void _agregarImagen() async {
    setState(() => _cargando = true);

    try {
      final nuevoOrden = _imagenes.isEmpty
          ? 1
          : _imagenes.map((img) => img.orden).reduce((a, b) => a > b ? a : b) +
              1;

      final url = await widget.storageService.subirImagenConCompresion(
        guiaId: widget.guiaId,
        onProgress: (percent) {
          setState(() => _progreso = percent);
        },
      );

      final nuevaImagen = ImagenGuia(
        url: url,
        nombre: 'Imagen $nuevoOrden',
        orden: nuevoOrden,
      );

      setState(() {
        _imagenes.add(nuevaImagen);
        _cargando = false;
        _progreso = 0;
      });

      widget.onImagenesChanged(_imagenes);
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _eliminarImagen(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text('¿Estás seguro de que deseas eliminar esta imagen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.storageService
                    .eliminarImagen(urlImagen: _imagenes[index].url);
                if (!mounted) return;
                setState(() => _imagenes.removeAt(index));
                widget.onImagenesChanged(_imagenes);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _reordenarImagenes(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final imagen = _imagenes.removeAt(oldIndex);
      _imagenes.insert(newIndex, imagen);

      // Actualizar órdenes
      for (int i = 0; i < _imagenes.length; i++) {
        _imagenes[i] = ImagenGuia(
          url: _imagenes[i].url,
          nombre: _imagenes[i].nombre,
          orden: i + 1,
        );
      }
    });

    widget.onImagenesChanged(_imagenes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galería de Imágenes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        // Mostrar progreso si está cargando
        if (_cargando) ...[
          LinearProgressIndicator(value: _progreso / 100),
          const SizedBox(height: 8),
          Text('Cargando... $_progreso%',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
        ],
        // Botón para agregar imagen
        ElevatedButton.icon(
          onPressed: _cargando ? null : _agregarImagen,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Agregar Imagen'),
        ),
        const SizedBox(height: 16),
        // Lista de imágenes con drag-drop
        if (_imagenes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No hay imágenes. Agrega una para comenzar.',
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _imagenes.length,
            onReorder: _reordenarImagenes,
            itemBuilder: (context, index) {
              final imagen = _imagenes[index];
              return Container(
                key: ValueKey(imagen.url),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Drag handle
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.drag_handle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: imagen.url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Información
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextField(
                            controller: TextEditingController(
                              text: imagen.nombre,
                            ),
                            onChanged: (valor) {
                              _imagenes[index] = ImagenGuia(
                                url: imagen.url,
                                nombre: valor,
                                orden: imagen.orden,
                              );
                              widget.onImagenesChanged(_imagenes);
                            },
                            decoration: const InputDecoration(
                              hintText: 'Nombre de la imagen',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Orden: ${imagen.orden}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    // Botón eliminar
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _eliminarImagen(index),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
