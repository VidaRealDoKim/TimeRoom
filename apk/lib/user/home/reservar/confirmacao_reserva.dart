import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConfirmacaoReservaPage extends StatelessWidget {
  final Map<String, dynamic> reserva;

  /// Horários disponíveis da sala
  final List<Map<String, TimeOfDay>> horariosDisponiveis;

  /// Horários já reservados da sala
  final List<Map<String, TimeOfDay>> horariosOcupados;

  const ConfirmacaoReservaPage({
    super.key,
    required this.reserva,
    required this.horariosDisponiveis,
    required this.horariosOcupados,
  });

  Widget _buildHorarioItem(BuildContext context, TimeOfDay inicio, TimeOfDay fim, bool ocupado, bool atual) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: atual
            ? Colors.blue
            : ocupado
            ? Colors.red[200]
            : Colors.green[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${inicio.format(context)} - ${fim.format(context)}',
        style: TextStyle(
          color: Colors.black,
          fontWeight: atual ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  bool _isReservaNoHorario(TimeOfDay inicio, TimeOfDay fim, TimeOfDay reservaInicio, TimeOfDay reservaFim) {
    final inicioMin = inicio.hour * 60 + inicio.minute;
    final fimMin = fim.hour * 60 + fim.minute;
    final resInicioMin = reservaInicio.hour * 60 + reservaInicio.minute;
    final resFimMin = reservaFim.hour * 60 + reservaFim.minute;
    return resInicioMin < fimMin && resFimMin > inicioMin; // overlap
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
    final TimeOfDay horaInicio = TimeOfDay(
      hour: int.parse(reserva['hora_inicio'].split(":")[0]),
      minute: int.parse(reserva['hora_inicio'].split(":")[1]),
    );
    final TimeOfDay horaFim = TimeOfDay(
      hour: int.parse(reserva['hora_fim'].split(":")[0]),
      minute: int.parse(reserva['hora_fim'].split(":")[1]),
    );

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
                errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[300]),
              )
                  : Container(height: 180, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Text(nomeSala, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                    (i) => Icon(
                  i < mediaAvaliacoes ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
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
                    Text('${reserva['hora_inicio']} - ${reserva['hora_fim']} • $dataFormatada'),
                    const SizedBox(height: 12),
                    const Text('Horários da Sala', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Column(
                      children: horariosDisponiveis.map((h) {
                        bool ocupado = horariosOcupados.any((o) =>
                            _isReservaNoHorario(h['inicio']!, h['fim']!, o['inicio']!, o['fim']!));
                        bool atual = _isReservaNoHorario(h['inicio']!, h['fim']!, horaInicio, horaFim);
                        return _buildHorarioItem(context, h['inicio']!, h['fim']!, ocupado, atual);
                      }).toList(),
                    )
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