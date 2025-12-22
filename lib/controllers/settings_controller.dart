import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControladorConfiguracion extends ChangeNotifier {
  static const String _themePaletteKey = 'paletaTema';
  static const String _colorBlindModeKey = 'modoDaltonismo';
  static const String _textScaleFactorKey = 'factorEscalaTexto';
  static const String _kidsModeEnabledKey = 'modoNinosActivado';
  static const Set<String> _paletasValidas = {
    'lavanda',
    'azul_calma',
    'verde_esperanza',
    'rojo_pasion',
    'naranja_vital',
    'rosa_suave',
  };
  static const Set<String> _modosDaltonismoValidos = {
    'none',
    'protanopia',
    'deuteranopia',
    'tritanopia',
  };

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

    if (!_paletasValidas.contains(loadedPalette)) {
      loadedPalette = 'lavanda';
      await _prefs.setString(_themePaletteKey, loadedPalette);
    }

    final storedColorBlind = _prefs.getString(_colorBlindModeKey) ?? 'none';
    if (_modosDaltonismoValidos.contains(storedColorBlind)) {
      _colorBlindMode = storedColorBlind;
    } else {
      _colorBlindMode = 'none';
      await _prefs.setString(_colorBlindModeKey, _colorBlindMode);
    }

    final storedScale = _prefs.getDouble(_textScaleFactorKey) ?? 1.0;
    _textScaleFactor = storedScale.clamp(0.8, 1.25);
    if (_textScaleFactor != storedScale) {
      await _prefs.setDouble(_textScaleFactorKey, _textScaleFactor);
    }

    _kidsModeEnabled = _prefs.getBool(_kidsModeEnabledKey) ?? false;
    notifyListeners();
  }

  // Setters con persistencia
  Future<void> establecerPaletaTema(String palette) async {
    if (!_paletasValidas.contains(palette)) {
      debugPrint('Paleta inválida: $palette');
      return;
    }
    _themePalette = palette;
    await _prefs.setString(_themePaletteKey, palette);
    notifyListeners();
  }
  // Establece el modo daltonismo
  Future<void> establecerModoDaltonismo(String mode) async {
    if (!_modosDaltonismoValidos.contains(mode)) {
      debugPrint('Modo daltonismo inválido: $mode');
      return;
    }
    _colorBlindMode = mode;
    await _prefs.setString(_colorBlindModeKey, mode);
    notifyListeners();
  }
  // Establece la escala de texto
  Future<void> establecerFactorEscalaTexto(double scale) async {
    _textScaleFactor = scale.clamp(0.8, 1.25);
    await _prefs.setDouble(_textScaleFactorKey, _textScaleFactor);
    notifyListeners();
  }
  // Establece el modo niños
  Future<void> establecerModoNinos(bool enabled) async {
    _kidsModeEnabled = enabled;
    await _prefs.setBool(_kidsModeEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> restablecerPreferencias() async {
    _themePalette = 'lavanda';
    _colorBlindMode = 'none';
    _textScaleFactor = 1.0;
    _kidsModeEnabled = false;

    await _prefs.setString(_themePaletteKey, _themePalette);
    await _prefs.setString(_colorBlindModeKey, _colorBlindMode);
    await _prefs.setDouble(_textScaleFactorKey, _textScaleFactor);
    await _prefs.setBool(_kidsModeEnabledKey, _kidsModeEnabled);
    notifyListeners();
  }
}
