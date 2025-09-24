import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// -----------------------------------------------------------------------------
// Classe que define os temas (Claro e Escuro) para o aplicativo.
// -----------------------------------------------------------------------------
class MyThemes {
  // Cor primária do aplicativo, usada em botões, appbars, etc.
  static const primaryColor = Color(0xFF1ABC9C);

  // Definição do TEMA CLARO
  static final lightTheme = ThemeData(
    // Esquema de cores principal para o tema claro.
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: Colors.tealAccent,
    ),
    // Define a cor de fundo padrão para os Scaffolds.
    scaffoldBackgroundColor: Colors.white,
    // Estilo padrão para as AppBars.
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white, // Cor do título e ícones
    ),
    // Estilo padrão para botões elevados.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
  );

  // Definição do TEMA ESCURO
  static final darkTheme = ThemeData(
    // Esquema de cores principal para o tema escuro.
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: Colors.tealAccent,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// A "Central de Controle" do Tema.
// Usa ChangeNotifier para "avisar" o aplicativo quando o tema muda.
// -----------------------------------------------------------------------------
class ThemeProvider extends ChangeNotifier {
  // Chave usada para salvar a preferência do usuário no dispositivo.
  static const _themePrefKey = 'theme_mode';

  // Variável que guarda o modo de tema atual.
  ThemeMode _themeMode = ThemeMode.system;

  // Getter público para que outras partes do app possam ler o tema atual.
  ThemeMode get themeMode => _themeMode;

  // Construtor: carrega a preferência de tema salva assim que o app inicia.
  ThemeProvider() {
    _loadThemePreference();
  }

  // Carrega a preferência de tema do armazenamento local.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themePrefKey) ?? 'System';

    if (themeString == 'Light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'Dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    // Avisa os "ouvintes" (o app) que o estado foi carregado.
    notifyListeners();
  }

  // Salva a preferência de tema no armazenamento local.
  Future<void> _saveThemePreference(String themeString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, themeString);
  }

  // Função chamada pela tela de Configurações para alterar o tema.
  void setTheme(String theme) {
    ThemeMode newThemeMode;
    String themeString;

    if (theme == 'Claro') {
      newThemeMode = ThemeMode.light;
      themeString = 'Light';
    } else if (theme == 'Escuro') {
      newThemeMode = ThemeMode.dark;
      themeString = 'Dark';
    } else {
      newThemeMode = ThemeMode.system;
      themeString = 'System';
    }

    // Se o tema realmente mudou, atualiza o estado e avisa o app
    if (newThemeMode != _themeMode) {
      _themeMode = newThemeMode;
      _saveThemePreference(themeString);
      // A "mágica" acontece aqui: notifica toda a árvore de widgets para se redesenhar
      notifyListeners();
    }
  }

  // Converte o ThemeMode atual para uma String legível para a UI.
  String get themeModeString {
    if (_themeMode == ThemeMode.light) return 'Claro';
    if (_themeMode == ThemeMode.dark) return 'Escuro';
    return 'Sistema';
  }
}
