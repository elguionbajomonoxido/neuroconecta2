import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/settings_controller.dart';

class TemaAplicacion {
  // Paletas de colores
  static const Map<String, ColorScheme> _palettes = {
    'lavanda': ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFC7A4FF),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF9575CD),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFFFFB3C6),
      onSecondary: Colors.black,
      surface: Color(0xFFF2E7FE),
      onSurface: Color(0xFF2B1E45),
      error: Color(0xFFE57373),
      onError: Colors.white,
    ),
    'azul_calma': ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF90CAF9),
      onPrimary: Colors.black,
      primaryContainer: Color(0xFF64B5F6),
      onPrimaryContainer: Colors.black,
      secondary: Color(0xFFA5D6A7),
      onSecondary: Colors.black,
      surface: Color(0xFFE3F2FD),
      onSurface: Color(0xFF1A237E),
      error: Color(0xFFEF9A9A),
      onError: Colors.black,
    ),
    'verde_esperanza': ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFA5D6A7),
      onPrimary: Colors.black,
      primaryContainer: Color(0xFF81C784),
      onPrimaryContainer: Colors.black,
      secondary: Color(0xFFFFF59D),
      onSecondary: Colors.black,
      surface: Color(0xFFE8F5E9),
      onSurface: Color(0xFF1B5E20),
      error: Color(0xFFE57373),
      onError: Colors.white,
    ),
    'rojo_pasion': ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFEF9A9A),
      onPrimary: Colors.black,
      primaryContainer: Color(0xFFE57373),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFFFFCC80),
      onSecondary: Colors.black,
      surface: Color(0xFFFFEBEE),
      onSurface: Color(0xFFB71C1C),
      error: Color(0xFFD32F2F),
      onError: Colors.white,
    ),
    'naranja_vital': ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFFFCC80),
      onPrimary: Colors.black,
      primaryContainer: Color(0xFFFFB74D),
      onPrimaryContainer: Colors.black,
      secondary: Color(0xFFFFF59D),
      onSecondary: Colors.black,
      surface: Color(0xFFFFF3E0),
      onSurface: Color(0xFFE65100),
      error: Color(0xFFE57373),
      onError: Colors.white,
    ),
    'rosa_suave': ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFF48FB1),
      onPrimary: Colors.black,
      primaryContainer: Color(0xFFF06292),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFFCE93D8),
      onSecondary: Colors.black,
      surface: Color(0xFFFCE4EC),
      onSurface: Color(0xFF880E4F),
      error: Color(0xFFE57373),
      onError: Colors.white,
    ),
  };

  static List<String> get validPalettes => _palettes.keys.toList();

  // Modos para daltónicos (ajustes sobre la paleta base)
  static ColorScheme _applyColorBlindMode(ColorScheme scheme, String mode) {
    switch (mode) {
      case 'deuteranopia': // Rojo/Verde -> Azul/Naranja
        return scheme.copyWith(
          primary: const Color(0xFF0072B2),
          secondary: const Color(0xFFE69F00),
          error: const Color(0xFFD55E00),
        );
      case 'protanopia': // Similar a deuteranopia pero menos rojo
        return scheme.copyWith(
          primary: const Color(0xFF0072B2),
          secondary: const Color(0xFFF0E442),
          error: const Color(0xFFD55E00),
        );
      case 'tritanopia': // Azul/Amarillo -> Rosa/Turquesa
        return scheme.copyWith(
          primary: const Color(0xFFCC79A7),
          secondary: const Color(0xFF009E73),
          error: const Color(0xFFD55E00),
        );
      default:
        return scheme;
    }
  }

  static ThemeData obtenerTema(ControladorConfiguracion settings) {
    // 1. Seleccionar paleta base
    ColorScheme baseScheme = _palettes[settings.themePalette] ?? _palettes['lavanda']!;

    // 2. Aplicar modo daltónico
    ColorScheme finalScheme = _applyColorBlindMode(baseScheme, settings.colorBlindMode);

    // 3. Factor de escala de texto
    final double textScale = settings.textScaleFactor;

    return ThemeData(
      useMaterial3: true,
      colorScheme: finalScheme,
      scaffoldBackgroundColor: finalScheme.surface, // Usar surface como fondo general o definir uno específico
      
      // Typography - Escalado dinámico
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 32 * textScale, fontWeight: FontWeight.bold, color: finalScheme.onSurface),
        displayMedium: GoogleFonts.poppins(fontSize: 28 * textScale, fontWeight: FontWeight.bold, color: finalScheme.onSurface),
        titleLarge: GoogleFonts.poppins(fontSize: 22 * textScale, fontWeight: FontWeight.w600, color: finalScheme.onSurface),
        titleMedium: GoogleFonts.poppins(fontSize: 18 * textScale, fontWeight: FontWeight.w600, color: finalScheme.onSurface),
        bodyLarge: GoogleFonts.openSans(fontSize: 18 * textScale, color: finalScheme.onSurface),
        bodyMedium: GoogleFonts.openSans(fontSize: 16 * textScale, color: finalScheme.onSurface),
        labelLarge: GoogleFonts.openSans(fontSize: 16 * textScale, fontWeight: FontWeight.bold),
      ),

      // Button Styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: finalScheme.primary,
          foregroundColor: finalScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.poppins(fontSize: 18 * textScale, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Card Styles
      cardTheme: CardThemeData(
        color: Colors.white, // Mantener tarjetas blancas para contraste
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: finalScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: GoogleFonts.openSans(fontSize: 16 * textScale),
      ),
    );
  }
}
