import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  // Padrão: Tema Escuro (Seu azul) e Som Ligado
  bool _isDark = true; 
  bool _isMuted = false;

  bool get isDark => _isDark;
  bool get isMuted => _isMuted;

  AppSettings() {
    _carregarPreferencias();
  }

  // Alternar Tema
  void toggleTheme() {
    _isDark = !_isDark;
    _salvarPreferencias();
    notifyListeners(); // Avisa o app todo para mudar a cor
  }

  // Alternar Som
  void toggleMute() {
    _isMuted = !_isMuted;
    _salvarPreferencias();
    notifyListeners();
  }

  // Salvar na memória do celular
  Future<void> _salvarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', _isDark);
    prefs.setBool('isMuted', _isMuted);
  }

  // Ler da memória ao abrir o app
  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? true; // Padrão true (Escuro)
    _isMuted = prefs.getBool('isMuted') ?? false; // Padrão false (Com som)
    notifyListeners();
  }
}