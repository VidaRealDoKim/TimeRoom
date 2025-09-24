import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalaCard extends StatelessWidget {
  final Map<String, dynamic>? sala; // para HomePage/DetalhesSalaPage
  final Sala? salaObj; // para ReservasPage
  final DateTime dataSelecionada;
  final bool isFavorita;
  final VoidCallback onToggleFavorito;
  final VoidCallback? onTap;

  const SalaCard({
    super.key,
    this.sala,
    this.salaObj,
    required this.dataSelecionada,
    required this.isFavorita,
    required this.onToggleFavorito,
    this.onTap,
  });

  Widget _buildEstrelas(double media) {
    return Row(
      children: List.generate(
        5,
            (i) => Icon(
          i < media ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Decide se vai usar Map<String,dynamic> ou Sala
    final imageUrl = sala != null ? sala!['url'] : salaObj?.url;
    final nome = sala != null ? sala!['nome'] : salaObj?.nome ?? '';
    final capacidade = sala != null ? sala!['capacidade'] : salaObj?.capacidade ?? 0;
    final localizacao = sala != null ? sala!['localizacao'] : salaObj?.localizacao ?? '-';
    final itens = salaObj?.itens ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(
                        child: Icon(Icons.meeting_room, size: 50)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isFavorita ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: onToggleFavorito,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        localizacao,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Capacidade: $capacidade"),
                  const SizedBox(height: 4),
                  if (salaObj != null)
                    Row(
                      children: [
                        _buildEstrelas(salaObj!.mediaAvaliacoes),
                        const SizedBox(width: 8),
                        Text(
                          "(${itens.length} avaliações)",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Classe modelo usada em ReservasPage
class Sala {
  final String id;
  final String nome;
  final int capacidade;
  final String? localizacao;
  final String? url;
  final List<String> itens;
  final double mediaAvaliacoes;

  Sala({
    required this.id,
    required this.nome,
    required this.capacidade,
    this.localizacao,
    this.url,
    required this.itens,
    required this.mediaAvaliacoes,
  });
}
