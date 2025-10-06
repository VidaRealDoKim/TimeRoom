import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// -----------------------------------------------------------------------------
// Gestor de Temas (ThemeProvider)
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

  // ---------------------------------------------------------------------------
  // TEMA CLARO
  // ---------------------------------------------------------------------------
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1ABC9C),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: Color(0xFF1ABC9C),
    ),
    cardColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF1ABC9C), // Verde principal
      background: const Color(0xFFF5F5F5), // Fundo claro
      surface: Colors.white, // Cards e superfícies
      onPrimary: Colors.white, // Texto sobre verde
      onSurface: Colors.black87, // Texto normal
      onBackground: Colors.black87,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(Color(0xFF1ABC9C)),
        foregroundColor: MaterialStatePropertyAll(Colors.white),
        padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        textStyle: MaterialStatePropertyAll(
          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // TEMA ESCURO
  // ---------------------------------------------------------------------------
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: Color(0xFF1E1E1E),
    ),
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF1ABC9C), // Verde principal
      background: const Color(0xFF121212), // Fundo escuro
      surface: const Color(0xFF1E1E1E), // Cards
      onPrimary: Colors.black, // Texto sobre verde
      onSurface: Colors.white70, // Texto normal
      onBackground: Colors.white70,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(Color(0xFF1ABC9C)),
        foregroundColor: MaterialStatePropertyAll(Colors.black),
        padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        textStyle: MaterialStatePropertyAll(
          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}
