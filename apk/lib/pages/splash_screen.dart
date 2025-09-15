import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Widget da Tela de Splash (tela de abertura)
// ** VERSÃO ATUALIZADA USANDO A IMAGEM OFICIAL DA LOGO **
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Inicia um timer para navegar para a próxima tela automaticamente.
    _navegarParaProximaTela();
  }

  // Função que aguarda um tempo e depois navega para a tela de login.
  void _navegarParaProximaTela() {
    Future.delayed(const Duration(seconds: 3), () {
      // O 'pushReplacementNamed' substitui a splash screen, assim o usuário
      // não consegue voltar para ela apertando o botão "voltar" do celular.
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build (Construção da Interface)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A cor de fundo foi alterada para preto para combinar com a imagem da
      // logo que você enviou, que tem um fundo preto.
      backgroundColor: const Color(0xFF00796B),
      body: Center(
        // O Center garante que a logo fique perfeitamente centralizada.
        child: Padding(
          // Adiciona um espaçamento nas laterais para a logo não ficar colada
          // nas bordas em telas menores.
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Image.asset(
            // Este é o caminho para a sua imagem dentro do projeto.
            // Siga os passos na conversa para que o Flutter encontre a imagem.
            'assets/logo3.png',
          ),
        ),
      ),
    );
  }
}

