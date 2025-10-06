import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

// Providers
import 'package:apk/providers/theme_provider.dart';

// Notification services
import 'package:apk/user/perfil/notification_service.dart';
import 'package:apk/user/perfil/firebase_notification_service.dart';

// Auth pages
import 'auth/login_page.dart';
import 'auth/registro_page.dart';
import 'auth/recuperacao_page.dart';

// Main screens
import 'user/splash_screen.dart';
import 'user/dashboard.dart';
import 'user/perfil/perfil.dart';
import 'user/favorito/favoritos.dart';
import 'user/perfil/config.dart';
import 'admin/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Load environment variables (.env)
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded successfully!");
  } catch (e) {
    print("❌ Error loading .env: $e");
  }

  // 2️⃣ Initialize Supabase
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("✅ Supabase connected successfully!");
  } catch (e) {
    print("❌ Error connecting to Supabase: $e");
  }

  // 3️⃣ Initialize local notifications
  try {
    await NotificationService().init();
    print("✅ Local Notification Service initialized successfully!");
  } catch (e) {
    print("❌ Error initializing Notification Service: $e");
  }

  // 4️⃣ Initialize Firebase and FCM
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully!");

    await FirebaseNotificationService.initFirebaseMessaging();
    print("✅ Firebase Cloud Messaging initialized successfully!");
  } catch (e) {
    print("❌ Error initializing Firebase or FCM: $e");
  }

  // 5️⃣ Run the app
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/splash': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/perfil': (context) => const PerfilPage(),
        '/salas': (context) => const SalasFavoritasPage(),
        '/config': (context) => const ConfigPage(),
        '/admindashboard': (context) => const AdminDashboardPage(),
      },
    );
  }
}
