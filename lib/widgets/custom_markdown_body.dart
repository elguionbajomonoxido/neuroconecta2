import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:neuroconecta2/widgets/code_block.dart';

/// Widget personalizado para renderizar markdown con soporte para:
/// - Syntax highlighting en bloques de código (CodeBlock)
/// - Markdown literal sin interpretar (RawMarkdownBlock)
/// - Estilos personalizados según el tema
class CustomMarkdownBody extends StatelessWidget {
  /// Contenido markdown a renderizar
  final String data;

  /// Si es selectable
  final bool selectable;

  /// Builders personalizados para elementos específicos
  final Map<String, MarkdownElementBuilder>? builders;

  /// Stylesheet personalizado
  final MarkdownStyleSheet? styleSheet;

  const CustomMarkdownBody({
    required this.data,
    this.selectable = true,
    this.builders,
    this.styleSheet,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final customBuilders = <String, MarkdownElementBuilder>{
      'code': _CodeBuilder(),
      if (builders != null) ...?builders,
    };

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: styleSheet ??
          MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            codeblockPadding: EdgeInsets.zero,
            codeblockDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
          ),
      builders: customBuilders,
      onTapLink: (text, href, title) {
        // Manejar links si es necesario
        debugPrint('[CustomMarkdownBody] Link: $href');
      },
    );
  }
}

/// Builder personalizado para bloques de código
class _CodeBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(element, TextStyle? preferredStyle) {
    final contenido = element.textContent;

    // Extraer lenguaje del contenido
    String? lenguaje;
    String codigoLimpio = contenido;

    if (contenido.isNotEmpty) {
      final primeraSalto = contenido.indexOf('\n');
      if (primeraSalto != -1) {
        lenguaje = contenido.substring(0, primeraSalto).trim();
        codigoLimpio = contenido.substring(primeraSalto + 1);

        // Si la primera línea no se ve como un lenguaje, usarla como código
        if (lenguaje.contains(' ') || lenguaje.isEmpty) {
          lenguaje = null;
          codigoLimpio = contenido;
        }
      }
    }

    return CodeBlock(
      code: codigoLimpio,
      language: lenguaje,
    );
  }
}
