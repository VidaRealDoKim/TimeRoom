import 'package:flutter/material.dart';
import '../../perfil/mapa_sala_page.dart';
import 'nova_reserva.dart';

/// Página de detalhes da sala
/// Recebe:
/// - [sala]: um Map com todos os dados da sala (nome, capacidade, descrição, URL, coordenadas, status, etc.)
/// - [dataSelecionada]: a data que o usuário selecionou para a reserva
class DetalhesSalaPage extends StatelessWidget {
  final Map<String, dynamic> sala;
  final DateTime dataSelecionada;

  const DetalhesSalaPage({
    super.key,
    required this.sala,
    required this.dataSelecionada,
  });

  /// Navega para a página de criação de nova reserva
  /// Passa os dados da sala e a data selecionada
  void _reservarSala(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovaReservaPage(
          sala: sala,
          dataSelecionada: dataSelecionada,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define o status da sala com base no campo 'ocupada' do Map
    final status = sala['ocupada'] == true ? "Ocupada" : "Livre";
    final statusColor = sala['ocupada'] == true ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(sala['nome'] ?? 'Detalhes da Sala'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha com o status da sala e capacidade
            Row(
              children: [
                // Indicador de status (ocupada/livre)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status, style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 16),
                // Mostra a capacidade da sala
                Text('Capacidade: ${sala['capacidade'] ?? '-'}'),
              ],
            ),
            const SizedBox(height: 16),
            // Botão para abrir a sala no mapa
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ver no Mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapaSalaPage(
                          latitude: sala['latitude'] ?? -26.9187,
                          longitude: sala['longitude'] ?? -49.0661,
                          nomeSala: sala['nome'] ?? 'Sala',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Descrição da sala
            Text(
              sala['descricao'] ?? '-',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            // Botão de reservar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Desabilita se a sala estiver ocupada
                onPressed: sala['ocupada'] == true ? null : () => _reservarSala(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2CC0AF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Reservar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}