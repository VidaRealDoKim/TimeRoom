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
      debugShowCheckedModeBanner: true,

      // Define a tela inicial ao abrir o app

      //futuramente vai para login.
      initialRoute: '/dashboard',

      // -----------------------------------------------------------------------
      // Rotas nomeadas do aplicativo
      // Cada rota mapeia para uma página específica.
      // -----------------------------------------------------------------------

      routes: {

        //Telas Auth
        // '/login':   (context) => const LoginPage(),          // Tela de Login
        // '/register':(context) => const RegisterPage(),       // Tela de Registro
        // '/forgot':  (context) => const ForgotPasswordPage(), // Tela de Recuperação de Senha


        //Telas Principais
        '/dashboard':    (context) => const DashboardPage(),    // Tela Dashboard
        // '/home':      (context) => const HomePage(),         // Tela de Inicio
        // '/reservas':  (context) => const ReservasPage(),     // Tela de Reservas
        // '/salas':     (context) => const SalasPage(),        // Tela de Salas
        // '/perfil':  (context)   => const PerfilPage(),       // Tela de Perfil

        //Subtelas
        '/nova_reserva': (context) => const NovaReservaPage(),  // Tela de Nova Reserva
        '/confirmacao_reserva': (context) => const ConfirmacaoReservaScreen(),
        // '/salas_disponiveis': (context) => const SalasDisponiveisPage(),


      },
    );
  }
}
