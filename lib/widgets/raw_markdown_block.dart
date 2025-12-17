import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget que renderiza markdown de manera literal (sin interpretar)
/// Útil para mostrar ejemplos de cómo escribir markdown
class RawMarkdownBlock extends StatelessWidget {
  /// Contenido markdown a mostrar literal
  final String content;

  /// Permitir selección y copia del texto
  final bool selectable;

  /// Mostrar borde lateral izquierdo distintivo
  final bool showBorder;

  const RawMarkdownBlock({
    required this.content,
    this.selectable = true,
    this.showBorder = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5);
    final borderColor = isDarkMode ? Color(0xFF404040) : Color(0xFFD0D0D0);
    final textColor = isDarkMode ? Color(0xFFE0E0E0) : Color(0xFF333333);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: showBorder
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                )
              : BorderSide.none,
          top: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: selectable
            ? SelectableText(
                content,
                style: GoogleFonts.inconsolata(
                  fontSize: 11,
                  height: 1.6,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              )
            : Text(
                content,
                style: GoogleFonts.inconsolata(
                  fontSize: 11,
                  height: 1.6,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}
