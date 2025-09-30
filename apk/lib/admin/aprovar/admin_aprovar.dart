import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Página para o admin aprovar ou rejeitar reservas de salas
class AdminAprovarSalasPage extends StatefulWidget {
  const AdminAprovarSalasPage({super.key});

  @override
  State<AdminAprovarSalasPage> createState() => _AdminAprovarSalasPageState();
}

class _AdminAprovarSalasPageState extends State<AdminAprovarSalasPage> {
  List<Map<String, dynamic>> reservasPendentes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchReservasPendentes();
  }

  /// Busca todas as reservas pendentes do banco
  Future<void> fetchReservasPendentes() async {
    setState(() => loading = true);

    try {
      final data = await supabase
          .from('reservas')
          .select(
          'id, titulo, data_reserva, hora_inicio, hora_fim, sala_id, salas(id, nome, capacidade, localizacao)')
          .eq('status', 'pendente');

      if (!mounted) return;
      setState(() {
        reservasPendentes = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar reservas pendentes: $e');
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao buscar reservas')),
      );
    }
  }

  /// Constrói DateTime a partir de data e hora (time without timezone)
  DateTime buildDateTime(String data, String hora) {
    final dateParts = data.split('-'); // yyyy-mm-dd
    final timeParts = hora.split(':'); // HH:mm

    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  /// Aprova a reserva
  Future<void> aprovarReserva(Map<String, dynamic> reserva) async {
    final reservaId = reserva['id'];
    final salaId = reserva['sala_id'];

    // Constrói os timestamps de início e fim
    final inicio = buildDateTime(reserva['data_reserva'], reserva['hora_inicio']);
    final fim = buildDateTime(reserva['data_reserva'], reserva['hora_fim']);

    try {
      // Verifica conflitos
      final conflitos = await supabase
          .from('salas_horarios')
          .select()
          .eq('sala_id', salaId)
          .lt('horario_inicio', fim.toIso8601String())
          .gt('horario_fim', inicio.toIso8601String());

      if (conflitos.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horário indisponível para esta sala.')),
        );
        return;
      }

      // Atualiza status da reserva
      await supabase.from('reservas').update({'status': 'aceito'}).eq('id', reservaId);

      // Cria registro na tabela salas_horarios
      await supabase.from('salas_horarios').insert({
        'sala_id': salaId,
        'horario_inicio': inicio.toIso8601String(),
        'horario_fim': fim.toIso8601String(),
      });

      if (!mounted) return;
      await fetchReservasPendentes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva aprovada com sucesso!')),
      );
    } catch (e) {
      debugPrint('Erro ao aprovar reserva: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao aprovar reserva')),
      );
    }
  }

  /// Rejeita a reserva
  Future<void> rejeitarReserva(String reservaId) async {
    try {
      await supabase.from('reservas').update({'status': 'rejeitada'}).eq('id', reservaId);
      if (!mounted) return;
      await fetchReservasPendentes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva rejeitada')),
      );
    } catch (e) {
      debugPrint('Erro ao rejeitar reserva: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao rejeitar reserva')),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange.shade200;
      case 'aceito':
        return Colors.green.shade200;
      case 'rejeitada':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas Pendentes'),
        backgroundColor: Colors.blue.shade600,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : reservasPendentes.isEmpty
          ? const Center(child: Text('Não há reservas pendentes'))
          : ListView.builder(
        itemCount: reservasPendentes.length,
        itemBuilder: (context, index) {
          final reserva = reservasPendentes[index];
          final sala = reserva['salas'] ?? {};

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: getStatusColor(reserva['status'] ?? 'pendente'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reserva['titulo'] ?? 'Reserva',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Sala: ${sala['nome'] ?? 'Desconhecida'}'),
                  Text('Data: ${reserva['data_reserva']}'),
                  Text('Horário: ${reserva['hora_inicio']} - ${reserva['hora_fim']}'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => aprovarReserva(reserva),
                        tooltip: 'Aprovar reserva',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => rejeitarReserva(reserva['id']),
                        tooltip: 'Rejeitar reserva',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
