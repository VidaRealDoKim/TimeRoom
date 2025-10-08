import 'package:flutter/material.dart';
import '../../perfil/mapa_sala_page.dart';
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
        // CORREÇÃO: Cores removidas para obedecer ao tema claro/escuro
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

            // Localização (botão para abrir mapa)
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ver no Mapa'),
                  // CORREÇÃO: Estilo removido para usar o tema da aplicação
                  onPressed: () {
                    // --- CORREÇÃO APLICADA AQUI ---
                    // Usamos os dados REAIS do objeto 'sala' que a página recebeu.
                    // A função auxiliar '_parseDouble' garante que a conversão funciona corretamente.
                    double? _parseDouble(dynamic value) {
                      if (value == null) return null;
                      if (value is double) return value;
                      if (value is int) return value.toDouble();
                      if (value is String) return double.tryParse(value);
                      return null;
                    }

                    final double latitudeDaSala = _parseDouble(sala['latitude']) ?? 0.0;
                    final double longitudeDaSala = _parseDouble(sala['longitude']) ?? 0.0;
                    final String nomeDaSala = sala['nome'] ?? 'Localização Desconhecida';

                    // Verificação para não abrir o mapa se as coordenadas forem 0.0
                    if (latitudeDaSala == 0.0 && longitudeDaSala == 0.0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Localização não disponível para esta sala.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return; // Não continua
                    }

                    // Comando para abrir a página do mapa com os dados corretos.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapaSalaPage(
                          latitude: latitudeDaSala,
                          longitude: longitudeDaSala,
                          nomeSala: nomeDaSala,
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

            // Botão de reservar (ativa apenas se a sala estiver livre)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sala['ocupada'] == true
                    ? null
                    : () => _reservarSala(context),
                // CORREÇÃO: Estilo removido para usar o tema
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

