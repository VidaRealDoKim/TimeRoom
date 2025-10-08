import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Cliente global do Supabase
final supabase = Supabase.instance.client;

/// Modelo de dados para Reserva
class Reserva {
  final String id;
  final String salaId;
  final String salaNome;
  final String? salaLocalizacao;
  final String? salaUrl;
  final int? salaCapacidade;
  final String? salaDescricao;
  final double? salaLatitude;
  final double? salaLongitude;
  final DateTime dataReserva;
  final String horaInicio;
  final String horaFim;
  final String status;

  Reserva({
    required this.id,
    required this.salaId,
    required this.salaNome,
    this.salaLocalizacao,
    this.salaUrl,
    this.salaCapacidade,
    this.salaDescricao,
    this.salaLatitude,
    this.salaLongitude,
    required this.dataReserva,
    required this.horaInicio,
    required this.horaFim,
    required this.status,
  });

  /// Construtor que transforma o JSON retornado pelo Supabase em objeto Reserva
  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'],
      salaId: json['sala_id'],
      salaNome: json['salas']['nome'],
      salaLocalizacao: json['salas']['localizacao'],
      salaUrl: json['salas']['url'],
      salaCapacidade: json['salas']['capacidade'],
      salaDescricao: json['salas']['descricao'],
      salaLatitude: json['salas']['latitude'] != null
          ? double.tryParse(json['salas']['latitude'].toString())
          : null,
      salaLongitude: json['salas']['longitude'] != null
          ? double.tryParse(json['salas']['longitude'].toString())
          : null,
      dataReserva: DateTime.parse(json['data_reserva']),
      horaInicio: json['hora_inicio'],
      horaFim: json['hora_fim'],
      status: json['status'],
    );
  }
}

/// Página principal que lista todas as reservas do usuário
class MinhasReservasPage extends StatefulWidget {
  const MinhasReservasPage({super.key});

  @override
  State<MinhasReservasPage> createState() => _MinhasReservasPageState();
}

class _MinhasReservasPageState extends State<MinhasReservasPage> {
  List<Reserva> _reservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  /// Carrega reservas do usuário logado
  Future<void> _loadReservas() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('reservas')
          .select(
        '*, salas(id, nome, localizacao, url, capacidade, descricao, latitude, longitude)',
      )
          .eq('user_id', userId)
          .order('data_reserva', ascending: false);

      final reservas = (response as List)
          .map<Reserva>((r) => Reserva.fromJson(r as Map<String, dynamic>))
          .toList();

      setState(() {
        _reservas = reservas;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar reservas: $e");
      setState(() => _isLoading = false);
    }
  }

  /// Constrói o card de cada reserva
  Widget _buildReservaCard(Reserva reserva) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalhesReservadoPage(
              reserva: {
                'id': reserva.id,
                'nome': reserva.salaNome,
                'localizacao': reserva.salaLocalizacao,
                'url': reserva.salaUrl,
                'capacidade': reserva.salaCapacidade ?? 0,
                'descricao': reserva.salaDescricao ?? '-',
                'latitude': reserva.salaLatitude ?? -26.9187,
                'longitude': reserva.salaLongitude ?? -49.0661,
                'data_reserva': reserva.dataReserva,
                'hora_inicio': reserva.horaInicio,
                'hora_fim': reserva.horaFim,
                'status': reserva.status,
              },
            ),
          ),
        );

        // Atualiza lista se o usuário cancelou ou confirmou presença
        if (result == true) {
          _loadReservas();
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 3,
        child: Row(
          children: [
            // Imagem da sala
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.all(8),
              child: reserva.salaUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  reserva.salaUrl!,
                  fit: BoxFit.cover,
                ),
              )
                  : const Icon(Icons.meeting_room, size: 60),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reserva.salaNome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        "Data: ${DateFormat('dd/MM/yyyy').format(reserva.dataReserva)}"),
                    Text("Horário: ${reserva.horaInicio} - ${reserva.horaFim}"),
                    const SizedBox(height: 4),
                    Text(
                      "Status: ${reserva.status}",
                      style: TextStyle(
                        color: reserva.status == 'aceito'
                            ? Colors.green
                            : reserva.status == 'recusado'
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Reservas"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _reservas.isEmpty
          ? const Center(
        child: Text(
          "Você ainda não fez nenhuma reserva.",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reservas.length,
        itemBuilder: (context, index) {
          final reserva = _reservas[index];
          return _buildReservaCard(reserva);
        },
      ),
    );
  }
}

/// Página de detalhes de uma reserva já realizada
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

    final dataReserva = reserva['data_reserva'] as DateTime;
    final horarioInicio = DateTime(
      dataReserva.year,
      dataReserva.month,
      dataReserva.day,
      int.parse(reserva['hora_inicio'].toString().split(":")[0]),
      int.parse(reserva['hora_inicio'].toString().split(":")[1]),
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
    }

    void compartilharReserva() {
      final text =
          'Minha reserva na sala ${reserva['nome']} em ${DateFormat('dd/MM/yyyy').format(dataReserva)} '
          'das ${reserva['hora_inicio']} às ${reserva['hora_fim']} foi confirmada!';
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

      if (confirm != true) return;

      try {
        final deleted = await supabase
            .from('reservas')
            .delete()
            .eq('id', reserva['id']);

        if (deleted.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível cancelar a reserva.')),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada com sucesso!')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cancelar: $e')),
        );
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
                Text("Data: ${DateFormat('dd/MM/yyyy').format(dataReserva)}"),
                Text("Horário: ${reserva['hora_inicio']} - ${reserva['hora_fim']}"),
                const SizedBox(height: 16),
                const Text(
                  "Descrição:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(reserva['descricao'] ?? '-'),
                const SizedBox(height: 24),
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