// -----------------------------------------------------------------------------
// Importações principais do Flutter e pacotes externos
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// -----------------------------------------------------------------------------
// Importações internas (telas principais do projeto)
// -----------------------------------------------------------------------------
import 'pages/dashboard.dart';
import 'pages/perfil.dart';
import 'pages/nova_reserva.dart';
import 'pages/confirmacao_reserva.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/salas_disponiveis.dart';
import 'pages/splash_screen.dart';


// Auth
import 'auth/login_page.dart';
import 'auth/registro_page.dart';
import 'auth/recuperacao_page.dart';

// -----------------------------------------------------------------------------
// Função principal do aplicativo
// -----------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env carregado com sucesso!");
  } catch (e) {
    print("❌ Erro ao carregar .env: $e");
  }

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("✅ Supabase conectado com sucesso!");
  } catch (e) {
    print("❌ Erro ao conectar Supabase: $e");
  }

  runApp(const MyApp());
}

// -----------------------------------------------------------------------------
// Classe principal do aplicativo
// -----------------------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        // Telas Auth
        '/login':    (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot':   (context) => const ForgotPasswordPage(),

        // Telas principais do usuário
        '/splash':    (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/perfil':    (context) => const PerfilPage(),
        '/salas':     (context) => const SalasDisponiveisPage(),

        // Telas Admin
        '/admindashboard': (context) => const AdminDashboardPage(),

        // Subtelas
        '/nova_reserva':        (context) => const NovaReservaPage(),
        '/confirmacao_reserva': (context) => const ConfirmacaoReservaScreen(),
      },
    );
  }
}
