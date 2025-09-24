import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Widget da Tela de Splash (tela de abertura)
// ** VERSÃO ATUALIZADA COM DOIS PONTEIROS EM VELOCIDADES DIFERENTES **
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Trocamos para "TickerProviderStateMixin" para permitir múltiplos AnimationControllers.
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // --- DOIS CONTROLADORES PARA DUAS VELOCIDADES ---
  // A chave para ter velocidades diferentes é criar um controlador para cada animação.

  // Controlador para a animação do ponteiro RÁPIDO.
  late final AnimationController _fastController;
  // Controlador para a animação do ponteiro DEVAGAR.
  late final AnimationController _slowController;

  @override
  void initState() {
    super.initState();
    // 1. Inicializa o controlador do ponteiro rápido (menor).
    // Uma volta completa a cada 3 segundos.
    _fastController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(); // '..repeat()' faz a animação ficar em loop.

    // 2. Inicializa o controlador do ponteiro devagar (maior).
    // Uma volta completa a cada 36 segundos (12x mais lento, como um relógio).
    _slowController = AnimationController(
      duration: const Duration(seconds: 36),
      vsync: this,
    )..repeat();

    // Inicia o timer para navegar para a próxima tela automaticamente.
    _navegarParaProximaTela();
  }

  // Função que aguarda um tempo e depois navega para a tela de login.
  void _navegarParaProximaTela() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    // É muito importante "descartar" ambos os controladores para evitar vazamentos de memória.
    _fastController.dispose();
    _slowController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build (Construção da Interface)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Definimos um tamanho base para o logo, para que todos os widgets
    // na Stack tenham a mesma dimensão, garantindo o alinhamento.
    const double logoSize = 250.0;

    return Scaffold(
      backgroundColor: const Color(0xFF2CC0AF),
      body: Center(
        // Usamos um Stack para sobrepor as quatro partes da imagem em camadas.
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Camada 1 (Fundo): A imagem de base.
            Image.asset(
              'assets/logo_fundo.png',
              width: logoSize, // Ajuste o tamanho conforme necessário
            ),

            // Camada 2: O ponteiro maior, que usa o controlador LENTO.
            RotationTransition(
              turns: _slowController,
              child: SizedBox(
                width: logoSize,
                height: logoSize,
                // AJUSTE: Usamos um Stack para posicionar a base do ponteiro no centro.
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: logoSize / 2, // Alinha a base do ponteiro no meio vertical
                      child: SizedBox(
                        width: 16, // Largura do ponteiro
                        height: 95, // Metade do comprimento original (a parte visível)
                        child: Image.asset(
                          'assets/logo_retangulo.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Camada 3: O ponteiro menor, que usa o controlador RÁPIDO.
            RotationTransition(
              turns: _fastController,
              child: SizedBox(
                width: logoSize,
                height: logoSize,
                // AJUSTE: Mesma lógica do ponteiro maior.
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: logoSize / 2, // Alinha a base do ponteiro no meio vertical
                      child: SizedBox(
                        width: 16, // Largura do ponteiro
                        height: 75, // Metade do comprimento original (a parte visível)
                        child: Image.asset(
                          'assets/logo_retangulo.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Camada 4 (Topo): A imagem do círculo, que fica por cima dos ponteiros.
            Image.asset(
              'assets/logo_ellipse.png',
              width: 50,
            ),
          ],
        ),
      ),
    );
  }
}

