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
    // --- CORREÇÃO FINAL APLICADA AQUI ---
    // Usamos o nome de classe correto: 'BottomAppBarThemeData'.
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: Color(0xFF1ABC9C),
    ),
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1ABC9C),
      secondary: Color(0xFF16A085),
      background: Color(0xFFF5F5F5),
      surface: Colors.white,
      onPrimary: Colors.white, // Cor do texto/ícones em cima da cor primária
    ),

    // Define um estilo global para todos os ElevatedButtons.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFF1ABC9C)),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
    // --- CORREÇÃO FINAL APLICADA AQUI ---
    // Usamos o nome de classe correto: 'BottomAppBarThemeData'.
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: Color(0xFF222222),
    ),
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1ABC9C),
      secondary: Color(0xFF16A085),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.black, // Cor do texto/ícones em cima da cor primária
    ),

    // Define um estilo global para os ElevatedButtons no modo escuro.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFF222222)),
        foregroundColor: MaterialStateProperty.all(const Color(0xFF1ABC9C)),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

