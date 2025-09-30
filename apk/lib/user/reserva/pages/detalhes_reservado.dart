import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class DetalhesReservadoPage extends StatefulWidget {
  final Map<String, dynamic> reserva;

  const DetalhesReservadoPage({super.key, required this.reserva});

  @override
  State<DetalhesReservadoPage> createState() => _DetalhesReservadoPageState();
}

class _DetalhesReservadoPageState extends State<DetalhesReservadoPage> {
  bool confirmado = false;

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reserva;
    final status = reserva['status'] ?? '-';
    final statusColor = status == 'aceito'
        ? Colors.green
        : status == 'recusado'
        ? Colors.red
        : Colors.orange;

    DateTime dataReserva = reserva['data'];
    DateTime horarioInicio = DateTime(
      dataReserva.year,
      dataReserva.month,
      dataReserva.day,
      int.parse(reserva['horaInicio'].split(":")[0]),
      int.parse(reserva['horaInicio'].split(":")[1]),
    );

    final agora = DateTime.now();
    final podeConfirmar = status == 'aceito' &&
        !confirmado &&
        agora.isAfter(horarioInicio.subtract(const Duration(hours: 1))) &&
        agora.isBefore(horarioInicio.add(const Duration(hours: 2)));

    void confirmarPresenca() {
      setState(() {
        confirmado = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Reserva confirmada com sucesso! Você pode acessar a sala.'),
        ),
      );
      // Aqui você pode atualizar no banco que a presença foi confirmada
    }

    void compartilharReserva() {
      final text =
          'Minha reserva na sala ${reserva['nome']} em ${DateFormat('dd/MM/yyyy').format(reserva['data'])} das ${reserva['horaInicio']} às ${reserva['horaFim']} foi confirmada!';
      SharePlus.instance.share(text as ShareParams);
    }

    Future<void> cancelarReserva() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancelar Reserva'),
          content: const Text('Deseja realmente cancelar esta reserva?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sim'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (confirm == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada com sucesso')),
        );
        Navigator.pop(context);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes da Reserva"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: reserva['url'] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      reserva['url'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.meeting_room, size: 100),
                ),
                const SizedBox(height: 16),
                Text(
                  reserva['nome'] ?? '-',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Capacidade: ${reserva['capacidade'] ?? '-'}"),
                Text("Localização: ${reserva['localizacao'] ?? '-'}"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Status: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Data: ${DateFormat('dd/MM/yyyy').format(reserva['data'])}",
                ),
                Text("Horário: ${reserva['horaInicio']} - ${reserva['horaFim']}"),
                const SizedBox(height: 16),
                const Text(
                  "Descrição:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(reserva['descricao'] ?? '-'),
                const SizedBox(height: 24),
                // Botões de ação
                if (status == 'pendente')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: cancelarReserva,
                      icon: const Icon(Icons.cancel),
                      label: const Text("Cancelar Reserva"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (status == 'aceito') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: compartilharReserva,
                      icon: const Icon(Icons.share),
                      label: const Text("Compartilhar Reserva"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (podeConfirmar)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: confirmarPresenca,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Confirmar Presença"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  if (!confirmado && !podeConfirmar)
                    Text(
                      "Botão de confirmação disponível 1 hora antes da reserva",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  if (confirmado)
                    Text(
                      "Presença confirmada ✅ Você pode acessar a sala.",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
