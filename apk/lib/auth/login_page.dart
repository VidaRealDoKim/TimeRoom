// lib/auth/login.dart
import 'package:flutter/gestures.dart'; // Import gestures for the clickable link
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowCookieConsent());
  }

  Future<void> _checkAndShowCookieConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final bool consentGiven = prefs.getBool('cookie_consent_given') ?? false;

    if (!consentGiven && mounted) {
      _showCookieConsentBanner();
    }
  }

  void _showCookieConsentBanner() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🍪 Sua Privacidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            // START: Updated text with a clickable link
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Usamos cookies e tecnologias essenciais para o funcionamento do app. Para saber mais, acesse nossa ',
                  ),
                  TextSpan(
                    text: 'Política de Cookies.',
                    style: TextStyle(
                      color: Colors.teal[400],
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    // This makes the text clickable
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CookiePolicyPage()),
                        );
                      },
                  ),
                ],
              ),
            ),
            // END: Updated text
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _handleConsent(accepted: false),
                  child: const Text('REJEITAR'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () => _handleConsent(accepted: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[400],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ACEITAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConsent({required bool accepted}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cookie_consent_given', true);
    print('Consent given. Accepted: $accepted');

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/logo.png',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu e-mail.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    const Text('Senha', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Insira sua senha',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          print('Email: ${_emailController.text}');
                          print('Senha: ${_passwordController.text}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0))),
                      child: const Text('Entrar'),
                    ),
                    const SizedBox(height: 24.0),
                    TextButton(
                      onPressed: () {},
                      child: Text('Esqueci minha senha',
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text('Criar conta',
                          style: TextStyle(color: Colors.grey[600])),
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

// --- NEW WIDGET FOR THE POLICY PAGE ---

class CookiePolicyPage extends StatelessWidget {
  const CookiePolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Helper widget for creating styled text blocks
    Widget buildTextBlock(String title, String content) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Cookies'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTextBlock(
              '1. O que são Cookies?',
              'Cookies são pequenos arquivos de texto que os sites que você visita salvam no seu computador ou dispositivo móvel. Em aplicativos, usamos tecnologias similares de armazenamento local para fazer o app funcionar de forma mais eficiente e para fornecer informações aos desenvolvedores.',
            ),
            buildTextBlock(
              '2. Tipos de Cookies Utilizados',
              '• Cookies necessários: São essenciais para que o aplicativo funcione corretamente, permitindo que você navegue e use suas funcionalidades, como o login. Não precisamos da sua permissão para usar estes.\n\n'
                  '• Cookies de análise (analytics): Fornecem informações anônimas sobre como o app está sendo usado para que possamos melhorar sua experiência.\n\n'
                  '• Cookies de marketing: Utilizados para fornecer conteúdo mais relevante ao seu interesse.',
            ),
            buildTextBlock(
              '3. Cookies de Terceiros',
              'Ocasionalmente, podemos incorporar ferramentas ou conteúdo de outros serviços (terceiros). Esses serviços podem usar seus próprios cookies. Nós não temos controle sobre os cookies definidos por eles.',
            ),
            buildTextBlock(
              '4. Como Recusar Cookies',
              'Você pode ajustar as configurações do seu navegador ou dispositivo para recusar cookies. Se você desativar os cookies, ainda poderá usar o app, mas isso poderá afetar sua capacidade de usar algumas funcionalidades.',
            ),
          buildTextBlock(
              '5. Cookies de Terceiros',
            'Ocasionalmente, podemos incorporar ferramentas ou conteúdo de outros sites (terceiros). Esses sites de terceiros podem usar seus próprios cookies. Nós não temos controle sobre os cookies definidos por outros sites, mesmo que você seja direcionado a eles a partir do nosso site.'
          ),
        ],
        ),
      ),
    );
  }
}