// lib/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'cookie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  // Controle de visibilidade da senha
  bool _isPasswordObscured = true;

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => CookieConsent.checkAndShow(context),
    );
    _loadSavedCredentials();
  }

  // Carrega credenciais salvas (opcional)
  Future<void> _loadSavedCredentials() async {
    final savedEmail = await _storage.read(key: 'email');

    if (savedEmail != null) {
      final savedPassword = await _storage.read(key: 'password');
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword ?? '';
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Login Supabase
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Pergunta se deseja salvar credenciais
      final previouslySavedEmail = await _storage.read(key: 'email');
      if (previouslySavedEmail == null || previouslySavedEmail != email) {
        final bool? shouldSave = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Salvar Login'),
            content: const Text('Deseja salvar suas informações de login para a próxima vez?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Não'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salvar'),
              ),
            ],
          ),
        );

        if (shouldSave == true) {
          await _storage.write(key: 'email', value: email);
          await _storage.write(key: 'password', value: password);
        }
      }

      _navigateAfterLogin();

    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Navega de acordo com a role do usuário
  void _navigateAfterLogin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || !mounted) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted || profile == null) return;

    final role = profile['role'] as String;
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admindashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: brightness == Brightness.dark ? Colors.black : Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo dinâmica de acordo com o tema
                    Image.asset(
                      brightness == Brightness.dark
                          ? 'assets/logo.png'
                          : 'assets/logo1.png',
                      height: 100,
                    ),
                    const SizedBox(height: 32.0),
                    const Text('E-mail', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Insira seu e-mail',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Por favor, insira seu e-mail.' : null,
                    ),
                    const SizedBox(height: 16.0),
                    const Text('Senha', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isPasswordObscured,
                      decoration: InputDecoration(
                        hintText: 'Insira sua senha',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Por favor, insira sua senha.' : null,
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Entrar', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 24.0),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/forgot'),
                      child: Text('Esqueci minha senha', style: TextStyle(color: Colors.grey[600])),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: Text('Criar conta', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
