// -----------------------------------------------------------------------------
// Importações principais do Flutter e pacotes externos
// -----------------------------------------------------------------------------
import 'package:apk/confirmacao_reserva/confirmacao_reserva.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// -----------------------------------------------------------------------------
// Importações internas (telas principais do projeto)
// -----------------------------------------------------------------------------
import 'dashboard/dashboard.dart';
// import 'auth/login.dart';
// import 'auth/register.dart';
// import 'auth/forgot_password.dart';
import 'nova_reserva/nova_reserva.dart';
// import 'screens/perfil.dart';
// import 'screens/salas_disponiveis.dart';

// -----------------------------------------------------------------------------
// Função principal do aplicativo
// Inicializa configurações essenciais antes de rodar o app.
// -----------------------------------------------------------------------------
Future<void> main() async {
  // Garante que o Flutter esteja completamente inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis de ambiente do arquivo `.env`
  // Necessário para obter as credenciais do Supabase (URL e Anon Key)
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env carregado com sucesso!");
  } catch (e) {
    print("❌ Erro ao carregar .env: $e");
  }

  try {
    // Inicializa a conexão com o Supabase usando as variáveis do .env
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,          // URL do projeto Supabase
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,// Chave pública do projeto
    );
    print("✅ Supabase conectado com sucesso!");
  } catch (e) {
    print("❌ Erro ao conectar Supabase: $e");
  }

  // Executa o aplicativo principal
  runApp(const MyApp());
}

// -----------------------------------------------------------------------------
// Classe principal do aplicativo
// Define a estrutura base (MaterialApp) e o gerenciamento de rotas.
// -----------------------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove a faixa vermelha "DEBUG" no canto superior direito
      debugShowCheckedModeBanner: false,

      // Define a tela inicial ao abrir o app
      initialRoute: '/dashboard',

      // -----------------------------------------------------------------------
      // Rotas nomeadas do aplicativo
      // Cada rota mapeia para uma página específica.
      // -----------------------------------------------------------------------
      routes: {
        '/dashboard': (context) => const DashboardPage(), // Tela Dashboard
        '/confirmacao_reserva': (context) => const ConfirmacaoReservaScreen(),
        // '/login':   (context) => const LoginPage(),          // Tela de Login
        // '/register':(context) => const RegisterPage(),       // Tela de Registro
        // '/forgot':  (context) => const ForgotPasswordPage(), // Tela de Recuperação de Senha
        '/nova_reserva': (context) => const NovaReservaPage(),
        // '/perfil':  (context) => const PerfilPage(),
        // '/salas_disponiveis': (context) => const SalasDisponiveisPage(),
      },
    );
  }
}
