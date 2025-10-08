// -----------------------------------------------------------------------------
// minhas_reservas.dart
// Lista as reservas do usuário logado, incluindo pendentes.
// Cores integradas ao ThemeProvider.
// Ao clicar, abre detalhes_reservado.dart
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:apk/providers/theme_provider.dart';
import 'detalhes_reservado.dart';

final supabase = Supabase.instance.client;

/// Modelo de dados simplificado para Reserva + Sala
class ReservaSala {
  final String reservaId;
  final String salaId;
  final String salaNome;
  final String? salaLocalizacao;
  final String? salaUrl;
  final int? salaCapacidade;
  final String? salaDescricao;
  final DateTime dataReserva;
  final String horaInicio;
  final String horaFim;
  final String status;

  ReservaSala({
    required this.reservaId,
    required this.salaId,
    required this.salaNome,
    this.salaLocalizacao,
    this.salaUrl,
    this.salaCapacidade,
    this.salaDescricao,
    required this.dataReserva,
    required this.horaInicio,
    required this.horaFim,
    required this.status,
  });

  factory ReservaSala.fromJson(Map<String, dynamic> json) {
    // Transformar status nulo em "pendente"
    String status;
    if (json['status'] == null) {
      status = 'pendente';
    } else if (json['status'] == true) {
      status = 'aceito';
    } else {
      status = 'recusado';
    }

    return ReservaSala(
      reservaId: json['id'],
      salaId: json['salas']['id'],
      salaNome: json['salas']['nome'],
      salaLocalizacao: json['salas']['localizacao'],
      salaUrl: json['salas']['url'],
      salaCapacidade: json['salas']['capacidade'],
      salaDescricao: json['salas']['descricao'],
      dataReserva: DateTime.parse(json['data_reserva']),
      horaInicio: json['hora_inicio'],
      horaFim: json['hora_fim'],
      status: status,
    );
  }
}

class MinhasReservasPage extends StatefulWidget {
  const MinhasReservasPage({super.key});

  @override
  State<MinhasReservasPage> createState() => _MinhasReservasPageState();
}

class _MinhasReservasPageState extends State<MinhasReservasPage> {
  List<ReservaSala> _reservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  Future<void> _loadReservas() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('reservas')
          .select('*, salas(id, nome, localizacao, url, capacidade, descricao)')
          .eq('user_id', userId)
          .order('data_reserva', ascending: false);

      final reservas = (response as List)
          .map<ReservaSala>((r) => ReservaSala.fromJson(r as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _reservas = reservas;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar reservas: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildReservaCard(ReservaSala reserva, ThemeProvider themeProvider) {
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalhesReservadoPage(
              reserva: {
                'id': reserva.reservaId,
                'nome': reserva.salaNome,
                'localizacao': reserva.salaLocalizacao ?? '-',
                'url': reserva.salaUrl ?? '',
                'capacidade': reserva.salaCapacidade ?? 0,
                'descricao': reserva.salaDescricao ?? '-',
                'data_reserva': reserva.dataReserva,
                'hora_inicio': reserva.horaInicio,
                'hora_fim': reserva.horaFim,
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
        color: isDark
            ? ThemeProvider.darkTheme.colorScheme.surfaceContainerHighest
            : ThemeProvider.lightTheme.colorScheme.surface,
        child: Row(
          children: [
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
                  : Icon(
                Icons.meeting_room,
                size: 60,
                color: isDark
                    ? ThemeProvider.darkTheme.colorScheme.onSurfaceVariant
                    : ThemeProvider.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reserva.salaNome,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark
                            ? ThemeProvider.darkTheme.colorScheme.onSurface
                            : ThemeProvider.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Data: ${DateFormat('dd/MM/yyyy').format(reserva.dataReserva)}",
                      style: TextStyle(
                        color: isDark
                            ? ThemeProvider.darkTheme.colorScheme.onSurfaceVariant
                            : ThemeProvider.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      "Horário: ${reserva.horaInicio} - ${reserva.horaFim}",
                      style: TextStyle(
                        color: isDark
                            ? ThemeProvider.darkTheme.colorScheme.onSurfaceVariant
                            : ThemeProvider.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Status: ${reserva.status}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: reserva.status == 'aceito'
                            ? Colors.green
                            : reserva.status == 'recusado'
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _reservas.isEmpty
          ? const Center(
        child: Text(
          "Você ainda não fez nenhuma reserva.",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _reservas.length,
        itemBuilder: (context, index) {
          final reserva = _reservas[index];
          return _buildReservaCard(reserva, themeProvider);
        },
      ),
    );
  }
}
