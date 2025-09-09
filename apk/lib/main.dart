// -----------------------------------------------------------------------------
// Importações principais do Flutter e pacotes externos
// -----------------------------------------------------------------------------
import 'package:apk/pages/confirmacao_reserva.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// -----------------------------------------------------------------------------
// Importações internas (telas principais do projeto)
// -----------------------------------------------------------------------------
import 'pages/dashboard.dart';
import 'pages/nova_reserva.dart';
import './auth/login_page.dart';
import './auth/registro_page.dart';

// -----------------------------------------------------------------------------
// Função principal do aplicativo
// Inicializa configurações essenciais antes de rodar o app.
// -----------------------------------------------------------------------------
Future<void> main() async {
  // Garante que o Flutter esteja completamente inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis de ambiente do arquivo `.env`
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env carregado com sucesso!");
  } catch (e) {
    print("❌ Erro ao carregar .env: $e");
  }

  // Inicializa a conexão com o Supabase usando as variáveis do .env
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,          // URL do projeto Supabase
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // Chave pública do projeto
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
      // Futuramente pode ser alterado para Login
      initialRoute: '/login',

      // -----------------------------------------------------------------------
      // Rotas nomeadas do aplicativo
      // -----------------------------------------------------------------------
      routes: {
        // Telas Auth (ativar futuramente)
        '/login':   (context) => const LoginPage(),
        '/register':(context) => const RegisterPage(),
        // '/forgot':  (context) => const ForgotPasswordPage(),

        // Telas Principais
        '/dashboard': (context) => const DashboardPage(),
        // '/home':    (context) => const HomePage(),
        // '/reservas':(context) => const ReservasPage(),
        // '/salas':   (context) => const SalasPage(),
        // '/perfil':  (context) => const PerfilPage(),

        // Subtelas
        '/nova_reserva':       (context) => const NovaReservaPage(),
        '/confirmacao_reserva':(context) => const ConfirmacaoReservaScreen(),
        // '/salas_disponiveis':(context) => const SalasDisponiveisPage(),
      },
    );
  }
}
