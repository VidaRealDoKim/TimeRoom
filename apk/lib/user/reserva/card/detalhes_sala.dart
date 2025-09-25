import 'package:flutter/material.dart';
import 'nova_reserva.dart';

/// Página de detalhes da sala
/// Recebe um Map com os dados da sala e a data selecionada
class DetalhesSalaPage extends StatelessWidget {
  final Map<String, dynamic> sala;
  final DateTime dataSelecionada;

  const DetalhesSalaPage({
    super.key,
    required this.sala,
    required this.dataSelecionada,
  });

  /// Função para navegar para a página de reserva
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
    // Status da sala (ocupada ou livre) e cor do indicador
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
            // Status da sala e capacidade
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Capacidade: ${sala['capacidade'] ?? '-'}'),
              ],
            ),
            const SizedBox(height: 16),

            // Localização (apenas botão clicável para abrir mapa)
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Aqui será implementado o abrir do Google Maps
                  },
                  icon: const Icon(Icons.location_on),
                  label: Text(sala['localizacao'] ?? 'Localização'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
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

            // Botão de reservar (ativa apenas se a sala estiver livre)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sala['ocupada'] == true
                    ? null
                    : () => _reservarSala(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2CC0AF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
