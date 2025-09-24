import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Widget da Tela de Splash (tela de abertura)
// ** VERSÃO ATUALIZADA COM O PONTEIRO DA LOGO ANIMADO **
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Adicionamos o "SingleTickerProviderStateMixin" para permitir a criação de animações.
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controlador da animação. Ele gerencia o tempo e o estado da animação.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Inicializa o controlador da animação.
    // Duração de 3 segundos para uma volta completa do ponteiro.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();// O '..repeat()' faz a animação ficar em loop contínuo.

    // Inicia o timer para navegar para a próxima tela automaticamente.
    _navegarParaProximaTela();
  }

  // Função que aguarda um tempo e depois navega para a tela de login.
  void _navegarParaProximaTela() {
    // Aumentei o tempo para 4 segundos para dar tempo de ver a animação.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    // É muito importante "descartar" o controlador quando a tela for destruída
    // para evitar vazamentos de memória.
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build (Construção da Interface)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.teal[400],
      body: Center(
        // Usamos um Stack para sobrepor as duas partes da imagem.
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. A IMAGEM DE FUNDO (SEM O PONTEIRO)
            // Esta imagem deve ser a logo completa, mas sem o ponteiro do relógio.
            Image.asset(
              'assets/logo_fundo.png',
              width: 300, // Ajuste o tamanho conforme necessário
            ),

            // 2. O PONTEIRO ANIMADO
            // RotationTransition é um widget que aplica uma animação de rotação
            // a seu filho (child).
            RotationTransition(
              // 'turns' define quantas voltas o widget dará.
              // Usamos o nosso controlador para animar este valor continuamente.
              turns: _controller,
              child: Image.asset(
                // Esta imagem deve ser APENAS o ponteiro do relógio, com fundo transparente.
                'assets/logo_ponteiro.png',
                width: 80, // O tamanho deve ser o mesmo da imagem de fundo
              ),
            ),
          ],
        ),
      ),
    );
  }
}

