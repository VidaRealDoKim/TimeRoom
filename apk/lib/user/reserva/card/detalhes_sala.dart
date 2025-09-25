import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'nova_reserva.dart';
import 'sala_card.dart'; // importando SalaCard

final supabase = Supabase.instance.client;

/// Página de detalhes da sala
class DetalhesSalaPage extends StatelessWidget {
  final Map<String, dynamic> sala;
  final DateTime dataSelecionada;

  const DetalhesSalaPage({
    super.key,
    required this.sala,
    required this.dataSelecionada,
  });

  /// Navega para NovaReservaPage
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
            // Card da sala usando SalaCard
            SalaCard(
              sala: sala,
              dataSelecionada: dataSelecionada,
              isFavorita: false,
              onToggleFavorito: () {
                // Aqui você pode implementar salvar/remover favoritos
              },
              onTap: null, // já estamos na página de detalhes
            ),
            const SizedBox(height: 16),
            // Status da sala e informações adicionais
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(height: 8),
            Text('Localização: ${sala['localizacao'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Descrição: ${sala['descricao'] ?? '-'}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
