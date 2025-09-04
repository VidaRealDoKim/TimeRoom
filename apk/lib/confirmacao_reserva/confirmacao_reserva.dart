import 'package:flutter/material.dart';
import '';

// Classe principal que representa a tela de confirmação de reserva.
// Usamos um StatelessWidget pois o conteúdo da tela é estático,
// mas pode ser facilmente convertido para StatefulWidget se precisar gerenciar estado.
class ConfirmacaoReservaScreen extends StatelessWidget {
  const ConfirmacaoReservaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // O Scaffold é o widget base para a estrutura visual de uma tela no Material Design.
    return Scaffold(
      // Define a cor de fundo principal da tela.
      backgroundColor: Colors.teal[300],
      // O corpo da tela é envolvido por um SafeArea para evitar que o conteúdo
      // seja sobreposto por elementos do sistema operacional (como o notch).
      body: SafeArea(
        child: Column(
          children: [
            // Usamos o Expanded para que o conteúdo principal ocupe todo o espaço
            // disponível, empurrando o menu de navegação para o final.
            Expanded(
              child: SingleChildScrollView(
                // Adiciona um padding (espaçamento interno) ao redor do conteúdo.
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Espaçamento no topo da tela.
                    const SizedBox(height: 20),
                    // Cabeçalho da página (invisível na imagem, mas bom para acessibilidade).
                    const Text(
                      'Reserva Confirmada',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Container principal com as informações da reserva.
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
            // Widget da barra de navegação inferior.
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  // Constrói o card de informações da reserva.
  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Parte superior do card com o nome e capacidade da sala.
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sala de reunião 02',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Capacidade para 40 pessoas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Container inferior, mais escuro, com os detalhes.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Cada linha de detalhe é criada por este widget.
                _buildDetailRow(
                    icon: Icons.people_outline,
                    text: '12 Participantes',
                    actionText: 'Editar'),
                _buildDivider(),
                _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    text: '7 de Fevereiro',
                    actionText: 'Editar'),
                _buildDivider(),
                _buildDetailRow(
                    icon: Icons.access_time_outlined,
                    text: 'Início: 13:30',
                    actionText: 'Editar'),
                _buildDivider(),
                _buildDetailRow(
                    icon: Icons.access_time_filled_outlined,
                    text: 'Fim: 15:00',
                    actionText: 'Editar'),
                _buildDivider(),
                _buildDetailRow(
                    icon: Icons.check_circle_outline,
                    text: 'Status: Confirmado',
                    actionText: 'Cancelar',
                    actionColor: Colors.red[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para criar uma linha de detalhe (ícone, texto, ação).
  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required String actionText,
    Color? actionColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          // Botão de texto para as ações (Editar/Cancelar).
          TextButton(
            onPressed: () {
              // Ação do botão aqui
            },
            child: Text(
              actionText,
              style: TextStyle(
                color: actionColor ?? Colors.tealAccent[100],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Divisor customizado para separar as linhas.
  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.2),
      height: 1,
    );
  }

  // Constrói a barra de navegação inferior.
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(icon: Icons.home_outlined, label: 'Início'),
          _buildNavItem(icon: Icons.list_alt_outlined, label: 'Reservas'),
          _buildNavItem(icon: Icons.search, label: 'Salas'),
          // Ícone de Perfil com destaque, como na imagem.
          _buildNavItem(
              icon: Icons.person_outline, label: 'Perfil', isActive: true),
        ],
      ),
    );
  }

  // Constrói um item da barra de navegação.
  Widget _buildNavItem(
      {required IconData icon,
        required String label,
        bool isActive = false}) {
    // Se o item estiver ativo, ele recebe um fundo circular.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.teal.withOpacity(0.8) : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          )
        ],
      ),
    );
  }
}