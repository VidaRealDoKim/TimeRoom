import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// -----------------------------------------------------------------------------
/// Tela de Confirmação de Reserva com detalhes completos da sala
/// -----------------------------------------------------------------------------
class ConfirmacaoReservaPage extends StatelessWidget {
  /// Dados da reserva e da sala:
  /// {
  ///   'nome_sala': 'Sala A',
  ///   'url': 'imagem da sala',
  ///   'capacidade': 10,
  ///   'localizacao': 'Andar 1',
  ///   'descricao': 'Sala equipada com projetor...',
  ///   'mediaAvaliacoes': 4.2,
  ///   'comentarios': [
  ///     {'usuario': 'João', 'comentario': 'Ótima sala!'},
  ///     {'usuario': 'Maria', 'comentario': 'Muito confortável'}
  ///   ],
  ///   'data_reserva': DateTime,
  ///   'hora_inicio': '14:00',
  ///   'hora_fim': '16:00'
  /// }
  final Map<String, dynamic> reserva;

  const ConfirmacaoReservaPage({super.key, required this.reserva});

  Widget _buildEstrelas(double media) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(Icon(
        i <= media ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 18,
      ));
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    final String nomeSala = reserva['nome_sala'] ?? 'Sala';
    final String url = reserva['url'] ?? '';
    final int capacidade = reserva['capacidade'] ?? 0;
    final String localizacao = reserva['localizacao'] ?? '-';
    final String descricao = reserva['descricao'] ?? '';
    final double mediaAvaliacoes = reserva['mediaAvaliacoes'] ?? 0;
    final List comentarios = reserva['comentarios'] ?? [];
    final DateTime dataReserva = reserva['data_reserva'] ?? DateTime.now();
    final String horaInicio = reserva['hora_inicio'] ?? '';
    final String horaFim = reserva['hora_fim'] ?? '';

    final String dataFormatada = DateFormat('dd/MM/yyyy').format(dataReserva);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserva Confirmada'),
        backgroundColor: const Color(0xFF2CC0AF),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Icon(
                Icons.check_circle_outline,
                color: const Color(0xFF2CC0AF),
                size: 100,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Sua reserva foi realizada com sucesso!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: url.isNotEmpty
                  ? Image.network(
                url,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 180, color: Colors.grey[300]),
              )
                  : Container(height: 180, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Text(nomeSala, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildEstrelas(mediaAvaliacoes),
            const SizedBox(height: 8),
            Text("Capacidade: $capacidade • Local: $localizacao"),
            const SizedBox(height: 8),
            Text(descricao),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Horário da Reserva', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$horaInicio - $horaFim • $dataFormatada'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Comentários de Usuários', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            comentarios.isEmpty
                ? const Text('Nenhum comentário ainda.')
                : Column(
              children: comentarios.map<Widget>((c) {
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(c['usuario'] ?? '-'),
                    subtitle: Text(c['comentario'] ?? ''),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2CC0AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Voltar para Home',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
