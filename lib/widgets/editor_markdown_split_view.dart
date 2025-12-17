import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class EditorMarkdownSplitView extends StatefulWidget {
  final String initialContent;
  final ValueChanged<String>? onChanged;
  final String label;

  const EditorMarkdownSplitView({
    super.key,
    required this.initialContent,
    this.onChanged,
    this.label = 'Contenido (Markdown)',
  });

  @override
  State<EditorMarkdownSplitView> createState() =>
      _EditorMarkdownSplitViewState();
}

class _EditorMarkdownSplitViewState extends State<EditorMarkdownSplitView> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool esEscritorio = MediaQuery.of(context).size.width >= 600;

    if (esEscritorio) {
      // Layout lado a lado para escritorio
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Editor izquierdo
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Escritura',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _controller,
                            onChanged: (value) {
                              setState(() {});
                              widget.onChanged?.call(value);
                            },
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                              hintText: 'Escribe aquí usando markdown...',
                            ),
                            textAlignVertical: TextAlignVertical.top,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Preview derecho
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Vista Previa',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: MarkdownBody(
                              data: _controller.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Layout apilado para móvil
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                // Editor arriba
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Escritura',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _controller,
                            onChanged: (value) {
                              setState(() {});
                              widget.onChanged?.call(value);
                            },
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                              hintText: 'Escribe aquí usando markdown...',
                            ),
                            textAlignVertical: TextAlignVertical.top,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(),
                ),
                // Preview abajo
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Vista Previa',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: MarkdownBody(
                              data: _controller.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
