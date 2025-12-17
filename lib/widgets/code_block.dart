import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget que renderiza bloques de código con syntax highlighting
/// Soporta múltiples lenguajes: dart, python, javascript, java, cpp, sql, bash, etc.
class CodeBlock extends StatelessWidget {
  /// Contenido del código
  final String code;

  /// Lenguaje de programación (dart, python, javascript, etc.)
  /// Si no se especifica o no es reconocido, se renderiza sin colores
  final String? language;

  /// Mostrar número de líneas
  final bool showLineNumbers;

  const CodeBlock({
    required this.code,
    this.language,
    this.showLineNumbers = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final displayLanguage = (language?.isNotEmpty ?? false) ? language : 'code';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282C34),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF61AFEF),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con lenguaje
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Chip(
                  label: Text(
                    displayLanguage ?? 'code',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF61AFEF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: const Color(0xFF3E4451),
                  side: const BorderSide(
                    color: Color(0xFF61AFEF),
                    width: 0.5,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ],
            ),
          ),
          // Bloque de código con highlighting
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              code.trimRight(),
              language: language ?? 'plaintext',
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.all(8),
              textStyle: GoogleFonts.inconsolata(
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
