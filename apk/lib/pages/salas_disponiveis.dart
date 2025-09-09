import 'package:flutter/material.dart';

// Classe que representa o modelo de dados para uma sala.
// Usar uma classe ajuda a organizar melhor os dados.
class Sala {
  final String nome;
  final int capacidade;
  final bool estaOcupada;

  Sala({
    required this.nome,
    required this.capacidade,
    this.estaOcupada = false,
  });
}

// Widget principal da tela de listagem de salas.
class SalasDisponiveisScreen extends StatelessWidget {
   SalasDisponiveisScreen({super.key});

  // Lista de dados de exemplo para as salas.
  // Em um aplicativo real, esses dados viriam de uma API ou banco de dados.
  final List<Sala> _listaDeSalas =  [
    Sala(nome: 'Sala de reunião 01', capacidade: 12),
    Sala(nome: 'Sala de reunião 02', capacidade: 40, estaOcupada: true),
    Sala(nome: 'Sala de reunião 03', capacidade: 40),
    Sala(nome: 'Sala de reunião 04', capacidade: 48),
    Sala(nome: 'Sala de reunião 05', capacidade: 24),
    Sala(nome: 'Sala de reunião 06', capacidade: 10),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // A barra de navegação inferior é um widget customizado.
      bottomNavigationBar: _buildCustomBottomNav(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Cabeçalho da página com ícones de menu e calendário.
              _buildHeader(),
              const SizedBox(height: 30),
              // Títulos da página.
              const Text(
                'Lista de salas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Listagem de todas salas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              // A lista de salas ocupa o espaço restante da tela.
              Expanded(
                child: ListView.builder(
                  itemCount: _listaDeSalas.length,
                  itemBuilder: (context, index) {
                    final sala = _listaDeSalas[index];
                    // Constrói um card para cada sala da lista.
                    return _buildSalaCard(sala);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Constrói o cabeçalho.
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.menu, size: 30, color: Colors.black54),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  // Constrói o card de uma sala.
  Widget _buildSalaCard(Sala sala) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      // O GestureDetector permite adicionar uma ação de toque ao card.
      child: GestureDetector(
        onTap: () {
          // Ação ao clicar no card (ex: navegar para detalhes da sala)
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // A cor do card muda se a sala estiver ocupada.
            color: sala.estaOcupada ? Colors.red[700] : Colors.teal[600],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Container do ícone da sala.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                // Ícone que representa a sala. Pode ser trocado por uma imagem customizada.
                child: Icon(
                  Icons.workspaces_outline,
                  color: Colors.grey[600],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Coluna com os textos (nome e capacidade).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sala.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sala que comporta ${sala.capacidade} pessoas!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Constrói a barra de navegação inferior customizada.
  Widget _buildCustomBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(icon: Icons.home_outlined, label: 'Home'),
          _buildNavItem(icon: Icons.calendar_today_outlined, label: 'Reservas'),
          // O item "Salas" é o item ativo e tem um estilo diferente.
          _buildNavItem(
              icon: Icons.meeting_room, label: 'Salas', isActive: true),
          _buildNavItem(icon: Icons.person_outline, label: 'Perfil'),
        ],
      ),
    );
  }

  // Constrói um item da barra de navegação.
  Widget _buildNavItem(
      {required IconData icon, required String label, bool isActive = false}) {
    // Se o item estiver ativo, ele tem um fundo circular destacado.
    return isActive
        ? Container(
      padding: const EdgeInsets.all(16),
      decoration:
      BoxDecoration(shape: BoxShape.circle, color: Colors.teal[700]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    )
        : Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey[500], size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}