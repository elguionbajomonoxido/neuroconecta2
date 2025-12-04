import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const String _themePaletteKey = 'themePalette';
  static const String _colorBlindModeKey = 'colorBlindMode';
  static const String _textScaleFactorKey = 'textScaleFactor';
  static const String _kidsModeEnabledKey = 'kidsModeEnabled';

  late SharedPreferences _prefs;

  // Valores por defecto
  String _themePalette = 'lavanda';
  String _colorBlindMode = 'none';
  double _textScaleFactor = 1.0;
  bool _kidsModeEnabled = false;

  // Getters
  String get themePalette => _themePalette;
  String get colorBlindMode => _colorBlindMode;
  double get textScaleFactor => _textScaleFactor;
  bool get kidsModeEnabled => _kidsModeEnabled;

  // Inicialización
  Future<void> loadSettings() async {
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
  Future<void> setThemePalette(String palette) async {
    _themePalette = palette;
    await _prefs.setString(_themePaletteKey, palette);
    notifyListeners();
  }

  Future<void> setColorBlindMode(String mode) async {
    _colorBlindMode = mode;
    await _prefs.setString(_colorBlindModeKey, mode);
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double scale) async {
    _textScaleFactor = scale.clamp(0.8, 1.5);
    await _prefs.setDouble(_textScaleFactorKey, _textScaleFactor);
    notifyListeners();
  }

  Future<void> setKidsModeEnabled(bool enabled) async {
    _kidsModeEnabled = enabled;
    await _prefs.setBool(_kidsModeEnabledKey, enabled);
    notifyListeners();
  }
}
