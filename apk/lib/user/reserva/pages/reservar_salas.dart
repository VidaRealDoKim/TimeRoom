import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detalhes_reservado.dart'; // Nova página de detalhes da reserva

final supabase = Supabase.instance.client;

/// Modelo de dados para uma Reserva
/// Contém informações da sala associada, data, horário e status
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
      salaLatitude: (json['salas']['latitude'] != null)
          ? double.tryParse(json['salas']['latitude'].toString())
          : null,
      salaLongitude: (json['salas']['longitude'] != null)
          ? double.tryParse(json['salas']['longitude'].toString())
          : null,
      dataReserva: DateTime.parse(json['data_reserva']),
      horaInicio: json['hora_inicio'],
      horaFim: json['hora_fim'],
      status: json['status'],
    );
  }
}

/// Página para listar todas as reservas do usuário logado
/// Cada card mostra a sala, data, horário e status
/// Ao clicar no card, navega para a página de detalhes da reserva
class ReservasPage extends StatefulWidget {
  const ReservasPage({super.key});

  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage> {
  List<Reserva> _reservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  /// Carrega todas as reservas do usuário logado do Supabase
  /// Faz o JOIN para trazer também os dados da sala
  Future<void> _loadReservas() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('reservas')
          .select(
        '*, salas(id, nome, localizacao, url, capacidade, descricao, latitude, longitude)',
      )
          .eq('user_id', userId)
          .order('data_reserva', ascending: false);

      debugPrint("Reservas do usuário: $response");

      List<Reserva> reservas =
      response.map<Reserva>((r) => Reserva.fromJson(r)).toList();

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
  /// Ao clicar, navega para a página de detalhes da reserva (`DetalhesReservadoPage`)
  Widget _buildReservaCard(Reserva reserva) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
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
                'data': reserva.dataReserva,
                'horaInicio': reserva.horaInicio,
                'horaFim': reserva.horaFim,
                'status': reserva.status,
              },
            ),
          ),
        );
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
                      "Data: ${DateFormat('dd/MM/yyyy').format(reserva.dataReserva)}",
                    ),
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
        //backgroundColor: const Color(0xFFFFFFFF),
        //foregroundColor: Colors.black,
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
