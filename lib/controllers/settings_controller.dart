import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControladorConfiguracion extends ChangeNotifier {
  static const String _themePaletteKey = 'paletaTema';
  static const String _colorBlindModeKey = 'modoDaltonismo';
  static const String _textScaleFactorKey = 'factorEscalaTexto';
  static const String _kidsModeEnabledKey = 'modoNinosActivado';

  late SharedPreferences _prefs;

  // Valores por defecto
  String _themePalette = 'lavanda';
  String _colorBlindMode = 'none';
  double _textScaleFactor = 1.0;
  bool _kidsModeEnabled = false;

  // Getters
  String get paletaTema => _themePalette;
  String get modoDaltonismo => _colorBlindMode;
  double get factorEscalaTexto => _textScaleFactor;
  bool get modoNinosActivado => _kidsModeEnabled;

  // English Getters (Aliases)
  String get themePalette => _themePalette;
  String get colorBlindMode => _colorBlindMode;
  double get textScaleFactor => _textScaleFactor;

  // Inicialización
  Future<void> cargarConfiguracion() async {
    _prefs = await SharedPreferences.getInstance();
    String loadedPalette = _prefs.getString(_themePaletteKey) ?? 'lavanda';
    
    // Validar que la paleta cargada exista (por si se eliminó alguna)
    const validPalettes = [
      'lavanda', 'azul_calma', 'verde_esperanza', 'rojo_pasion', 
      'naranja_vital', 'rosa_suave'
    ];
    
    if (!validPalettes.contains(loadedPalette)) {
      loadedPalette = 'lavanda';
      await _prefs.setString(_themePaletteKey, loadedPalette);
    }

    _themePalette = loadedPalette;
    _colorBlindMode = _prefs.getString(_colorBlindModeKey) ?? 'none';
    _textScaleFactor = _prefs.getDouble(_textScaleFactorKey) ?? 1.0;
    _kidsModeEnabled = _prefs.getBool(_kidsModeEnabledKey) ?? false;
    notifyListeners();
  }

  // Setters con persistencia
  Future<void> establecerPaletaTema(String palette) async {
    _themePalette = palette;
    await _prefs.setString(_themePaletteKey, palette);
    notifyListeners();
  }
  // Establece el modo daltonismo
  Future<void> establecerModoDaltonismo(String mode) async {
    _colorBlindMode = mode;
    await _prefs.setString(_colorBlindModeKey, mode);
    notifyListeners();
  }
  // Establece la escala de texto
  Future<void> establecerFactorEscalaTexto(double scale) async {
    _textScaleFactor = scale.clamp(0.8, 1.5);
    await _prefs.setDouble(_textScaleFactorKey, _textScaleFactor);
    notifyListeners();
  }
  // Establece el modo niños
  Future<void> establecerModoNinos(bool enabled) async {
    _kidsModeEnabled = enabled;
    await _prefs.setBool(_kidsModeEnabledKey, enabled);
    notifyListeners();
  }
}
