import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// -----------------------------------------------------------------------------
// Gestor de Temas (ThemeProvider)
// -----------------------------------------------------------------------------
/// Controla o tema da aplicação (Claro, Escuro, Sistema) e guarda a
/// preferência do utilizador no dispositivo.
// -----------------------------------------------------------------------------
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      default:
        return 'Sistema';
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  /// Carrega a preferência de tema guardada.
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode') ?? 'Sistema';
    _themeMode = _stringToThemeMode(themeString);
    notifyListeners();
  }

  /// Guarda a preferência de tema.
  Future<void> _saveTheme(String themeString) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('theme_mode', themeString);
  }

  /// Atualiza o tema da aplicação.
  void setTheme(String themeString) {
    _themeMode = _stringToThemeMode(themeString);
    _saveTheme(themeString);
    notifyListeners();
  }

  ThemeMode _stringToThemeMode(String themeString) {
    switch (themeString) {
      case 'Claro':
        return ThemeMode.light;
      case 'Escuro':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // --- DEFINIÇÕES DE TEMA CENTRALIZADAS ---

  // Tema Claro
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1ABC9C),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1ABC9C),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
    ),
    cardColor: Colors.white,
    // Define um colorScheme para consistência
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1ABC9C),
      secondary: Color(0xFF16A085),
      background: Color(0xFFF5F5F5),
      surface: Colors.white,
    ),
  );

  // Tema Escuro
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF222222),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF222222),
      selectedItemColor: Color(0xFF1ABC9C),
      unselectedItemColor: Colors.grey,
    ),
    cardColor: const Color(0xFF1E1E1E),
    // Define um colorScheme escuro
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1ABC9C),
      secondary: Color(0xFF16A085),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
    ),
  );
}
