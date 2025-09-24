// lib/auth/cookie_consent.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Classe utilitária para gerenciar consentimento de cookies
class CookieConsent {
  /// Checa se já existe consentimento e, caso não, mostra o banner
  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final consentGiven = prefs.getBool('cookie_consent_given') ?? false;

    if (!consentGiven && context.mounted) {
      _showCookieConsentBanner(context);
    }
  }

  /// Exibe o banner fixo de consentimento
  static void _showCookieConsentBanner(BuildContext context) {
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

            // Texto com link para a página de política
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
                children: [
                  const TextSpan(
                    text: 'Usamos cookies e tecnologias essenciais para o funcionamento do app. Para saber mais, leia nossa ',
                  ),
                  TextSpan(
                    text: 'Política de Cookies',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CookiePolicyPage()),
                        );
                      },
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _handleConsent(context, accepted: false),
                  child: const Text('REJEITAR'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () => _handleConsent(context, accepted: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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

  /// Salva a escolha do usuário no SharedPreferences
  static Future<void> _handleConsent(BuildContext context, {required bool accepted}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cookie_consent_given', true);
    debugPrint('Consent given. Accepted: $accepted');

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// =======================
/// Página de Política de Cookies
/// =======================
class CookiePolicyPage extends StatelessWidget {
  const CookiePolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget buildTextBlock(String title, String content) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
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
              'Cookies são pequenos arquivos de texto armazenados no dispositivo. Em aplicativos, usamos tecnologias semelhantes para melhorar a experiência.',
            ),
            buildTextBlock(
              '2. Tipos de Cookies Utilizados',
              '• Necessários: fundamentais para o funcionamento do app.\n\n'
                  '• Análise: ajudam a entender como o app é usado.\n\n'
                  '• Marketing: personalizam sua experiência com base no uso.',
            ),
            buildTextBlock(
              '3. Cookies de Terceiros',
              'Podemos utilizar serviços externos que inserem cookies próprios. Não temos controle sobre eles.',
            ),
            buildTextBlock(
              '4. Como Recusar',
              'Você pode desativar cookies nas configurações do dispositivo. Algumas funções podem não funcionar corretamente.',
            ),
          ],
        ),
      ),
    );
  }
}
