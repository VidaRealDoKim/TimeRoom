import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../perfil/mapa_sala_page.dart';

final supabase = Supabase.instance.client;

class DetalhesReservadoPage extends StatefulWidget {
  final Map<String, dynamic> reserva;

  const DetalhesReservadoPage({super.key, required this.reserva});

  @override
  State<DetalhesReservadoPage> createState() => _DetalhesReservadoPageState();
}

class _DetalhesReservadoPageState extends State<DetalhesReservadoPage> {
  bool confirmado = false;
  bool isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reserva;
    final status = reserva['status'] ?? '-';
    final statusColor = status == 'aceito'
        ? Colors.green
        : status == 'recusado'
        ? Colors.red
        : Colors.orange;

    DateTime dataReserva;
    if (reserva['data_reserva'] is String) {
      dataReserva = DateTime.parse(reserva['data_reserva']);
    } else if (reserva['data_reserva'] is DateTime) {
      dataReserva = reserva['data_reserva'];
    } else {
      dataReserva = DateTime.now();
    }

    DateTime horarioInicio = DateTime(
      dataReserva.year,
      dataReserva.month,
      dataReserva.day,
      int.parse(reserva['hora_inicio'].split(":")[0]),
      int.parse(reserva['hora_inicio'].split(":")[1]),
    );

    final agora = DateTime.now();
    final podeConfirmar = status == 'aceito' &&
        !confirmado &&
        agora.isAfter(horarioInicio.subtract(const Duration(hours: 1))) &&
        agora.isBefore(horarioInicio.add(const Duration(hours: 2)));

    void confirmarPresenca() {
      setState(() => confirmado = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presença confirmada! Você pode acessar à sala.'),
        ),
      );
    }

    void compartilharReserva() {
      final text =
          'Minha reserva na sala ${reserva['nome']} em ${DateFormat('dd/MM/yyyy').format(dataReserva)} das ${reserva['hora_inicio']} às ${reserva['hora_fim']} foi confirmada!';
      Share.share(text);
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

      if (!mounted || confirm != true) return;

      setState(() => isCancelling = true);

      try {
        final idReserva = reserva['id'];
        final userId = reserva['user_id'];

        // 1️⃣ Deletar reserva
        final deleted = await supabase
            .from('reservas')
            .delete()
            .eq('id', idReserva)
            .select(); // retorna os dados deletados

        if (deleted == null || deleted.isEmpty) {
          throw 'Não foi possível cancelar a reserva.';
        }

        // 2️⃣ Criar log no reservas_log
        await supabase.from('reservas_log').insert({
          'reserva_id': idReserva,
          'acao': 'cancelada',
          'usuario_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Depois de mostrar a mensagem, fechar a tela
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => isCancelling = false);
      }
    }


    Widget buildActionButton({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
      Color? color,
    }) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Detalhes da Reserva")),
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
                  child: reserva['url'] != null && reserva['url'] != ''
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
                Text(reserva['nome'] ?? '-',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Capacidade: ${reserva['capacidade'] ?? '-'}"),
                Text("Localização: ${reserva['localizacao'] ?? '-'}"),
                const SizedBox(height: 16),

                buildActionButton(
                  label: 'Ver no Mapa',
                  icon: Icons.map_outlined,
                  onPressed: () {
                    double? _parseDouble(dynamic value) {
                      if (value == null) return null;
                      if (value is double) return value;
                      if (value is int) return value.toDouble();
                      if (value is String) return double.tryParse(value);
                      return null;
                    }

                    final double latitude =
                        _parseDouble(reserva['latitude']) ?? 0.0;
                    final double longitude =
                        _parseDouble(reserva['longitude']) ?? 0.0;
                    if (latitude == 0.0 && longitude == 0.0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Localização não disponível.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapaSalaPage(
                          latitude: latitude,
                          longitude: longitude,
                          nomeSala: reserva['nome'] ?? 'Sala',
                        ),
                      ),
                    );
                  },
                  color: Colors.teal,
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("Status: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(status,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Data: ${DateFormat('dd/MM/yyyy').format(dataReserva)}"),
                Text("Horário: ${reserva['hora_inicio']} - ${reserva['hora_fim']}"),
                const SizedBox(height: 16),
                const Text("Descrição:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(reserva['descricao'] ?? '-'),
                const SizedBox(height: 24),

                if (status == 'pendente')
                  buildActionButton(
                    label: isCancelling ? 'Cancelando...' : 'Cancelar Reserva',
                    icon: Icons.cancel,
                    onPressed: isCancelling ? () {} : cancelarReserva,
                    color: Colors.red,
                  ),
                if (status == 'aceito') ...[
                  buildActionButton(
                      label: 'Compartilhar Reserva',
                      icon: Icons.share,
                      onPressed: compartilharReserva,
                      color: Colors.green),
                  const SizedBox(height: 12),
                  if (podeConfirmar)
                    buildActionButton(
                        label: 'Confirmar Presença',
                        icon: Icons.check_circle,
                        onPressed: confirmarPresenca,
                        color: Colors.blue),
                  if (!confirmado && !podeConfirmar)
                    Text("Botão disponível 1h antes da reserva",
                        style: TextStyle(color: Colors.grey[600])),
                  if (confirmado)
                    Text("Presença confirmada ✅ Você pode acessar à sala.",
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
