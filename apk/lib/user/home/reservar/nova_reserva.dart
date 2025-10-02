import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'confirmacao_reserva.dart';

/// Cliente global do Supabase
final supabase = Supabase.instance.client;

/// Página para criar uma nova reserva
class NovaReservaPage extends StatefulWidget {
  /// Dados da sala selecionada
  final Map<String, dynamic> sala;

  /// Data escolhida no calendário
  final DateTime dataSelecionada;

  const NovaReservaPage({
    super.key,
    required this.sala,
    required this.dataSelecionada,
  });

  @override
  State<NovaReservaPage> createState() => _NovaReservaPageState();
}

class _NovaReservaPageState extends State<NovaReservaPage> {
  /// Indica se está carregando (usado para mostrar CircularProgressIndicator)
  bool loading = false;

  /// Controlador de texto para observações opcionais
  final TextEditingController _observacoesController = TextEditingController();

  /// Lista de comentários da sala
  List<Map<String, dynamic>> comentarios = [];

  /// Horários padrão de funcionamento da sala
  List<Map<String, TimeOfDay>> horariosDisponiveis = [];

  /// Horários já reservados nesta data
  List<Map<String, TimeOfDay>> horariosOcupados = [];

  /// Slots de horários livres gerados
  List<TimeOfDay> slotsGerados = [];

  /// Slot selecionado pelo usuário
  TimeOfDay? slotSelecionado;

  /// Duração selecionada da reserva (em minutos)
  int duracaoMinutos = 60;

  /// Durações disponíveis para escolha (15min, 30min e 1h)
  final List<int> duracoesDisponiveis = [15, 30, 60];

  @override
  void initState() {
    super.initState();
    _loadComentarios();
    _loadHorarios();
  }

  // =========================================================================
  // -------------------------- HELPERS --------------------------------------
  // =========================================================================

  /// Converte campo de data/hora vindo do banco em [DateTime]
  DateTime? _parseDateTimeField(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (_) {
        try {
          return DateFormat("yyyy-MM-ddTHH:mm:ss").parseUtc(value);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  /// Converte [DateTime] para [TimeOfDay]
  TimeOfDay _timeOfDayFromDateTime(DateTime dt) =>
      TimeOfDay(hour: dt.toLocal().hour, minute: dt.toLocal().minute);

  /// Converte [TimeOfDay] para minutos desde 00:00
  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Verifica se dois intervalos se sobrepõem
  bool _rangesOverlap(int aStart, int aEnd, int bStart, int bEnd) {
    return aStart < bEnd && bStart < aEnd;
  }

  // =========================================================================
  // -------------------------- CARREGAMENTO DE DADOS ------------------------
  // =========================================================================

  /// Carrega comentários e avaliações da sala
  Future<void> _loadComentarios() async {
    final salaId = widget.sala['id'];
    final response = await supabase
        .from('feedback_salas')
        .select('nota, comentario, usuario:profiles(name, avatar_url)')
        .eq('sala_id', salaId)
        .order('created_at', ascending: false);

    setState(() {
      comentarios = List<Map<String, dynamic>>.from(response);
    });
  }

  /// Carrega horários disponíveis e reservas já feitas para a data escolhida
  Future<void> _loadHorarios() async {
    final salaId = widget.sala['id'];
    final dataStr = DateFormat('yyyy-MM-dd').format(widget.dataSelecionada);

    // 1) Horários de funcionamento configurados
    final disponiveis = await supabase
        .from('salas_horarios')
        .select('inicio, fim')
        .eq('sala_id', salaId);

    // 2) Reservas existentes na data
    final ocupados = await supabase
        .from('reservas')
        .select('hora_inicio, hora_fim')
        .eq('sala_id', salaId)
        .eq('data_reserva', dataStr);

    // Normaliza horários disponíveis
    final List<Map<String, TimeOfDay>> disponiveisNormalized = [];
    for (final h in disponiveis) {
      final inicioDt = _parseDateTimeField(h['inicio']);
      final fimDt = _parseDateTimeField(h['fim']);
      if (inicioDt != null && fimDt != null) {
        disponiveisNormalized.add({
          'inicio': _timeOfDayFromDateTime(inicioDt),
          'fim': _timeOfDayFromDateTime(fimDt),
        });
      }
    }

    // Normaliza horários ocupados
    final List<Map<String, TimeOfDay>> ocupadosNormalized = [];
    for (final h in ocupados) {
      try {
        final String rawInicio = (h['hora_inicio'] ?? '').toString();
        final String rawFim = (h['hora_fim'] ?? '').toString();

        final inicioParts = rawInicio.split(':');
        final fimParts = rawFim.split(':');

        if (inicioParts.length >= 2 && fimParts.length >= 2) {
          final inicioTOD = TimeOfDay(
            hour: int.parse(inicioParts[0]),
            minute: int.parse(inicioParts[1]),
          );
          final fimTOD = TimeOfDay(
            hour: int.parse(fimParts[0]),
            minute: int.parse(fimParts[1]),
          );
          ocupadosNormalized.add({'inicio': inicioTOD, 'fim': fimTOD});
        }
      } catch (_) {}
    }

    setState(() {
      horariosDisponiveis = disponiveisNormalized;
      horariosOcupados = ocupadosNormalized;
    });

    _gerarSlotsDisponiveis();
  }

  // =========================================================================
  // -------------------------- GERAÇÃO DE SLOTS -----------------------------
  // =========================================================================

  /// Gera slots de horários livres, considerando reservas existentes
  void _gerarSlotsDisponiveis() {
    final List<TimeOfDay> slots = [];
    const stepMinutes = 30;

    for (final intervalo in horariosDisponiveis) {
      final inicio = intervalo['inicio']!;
      final fim = intervalo['fim']!;
      int cursor = _toMinutes(inicio);
      final end = _toMinutes(fim);

      while (cursor + 15 <= end) {
        final slotStart = TimeOfDay(hour: cursor ~/ 60, minute: cursor % 60);
        final slotStartMin = _toMinutes(slotStart);
        final slotEndMin = slotStartMin + duracaoMinutos;

        // Verifica se cabe no horário da sala e não conflita com reservas
        if (slotEndMin <= end) {
          bool conflitante = false;
          for (final occ in horariosOcupados) {
            final occStart = _toMinutes(occ['inicio']!);
            final occEnd = _toMinutes(occ['fim']!);
            if (_rangesOverlap(slotStartMin, slotEndMin, occStart, occEnd)) {
              conflitante = true;
              break;
            }
          }
          if (!conflitante) slots.add(slotStart);
        }

        cursor += stepMinutes;
      }
    }

    slots.sort((a, b) => _toMinutes(a).compareTo(_toMinutes(b)));

    setState(() {
      slotsGerados = slots;

      // Se o slot selecionado não existe mais, limpa
      if (slotSelecionado != null &&
          !slotsGerados.any((s) => _toMinutes(s) == _toMinutes(slotSelecionado!))) {
        slotSelecionado = null;
      }
    });
  }

  /// Quando usuário muda a duração, regeneramos os slots
  void _onDuracaoChanged(int minutos) {
    setState(() {
      duracaoMinutos = minutos;
    });
    _gerarSlotsDisponiveis();
  }

  // =========================================================================
  // -------------------------- SALVAMENTO DE RESERVA ------------------------
  // =========================================================================

  Future<void> _salvarReserva() async {
    if (slotSelecionado == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione um horário.')));
      return;
    }

    setState(() => loading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw "Usuário não autenticado";

      final horaInicio = slotSelecionado!;
      final inicioMin = _toMinutes(horaInicio);
      final fimMin = inicioMin + duracaoMinutos;

      if (fimMin > 24 * 60) throw "Horário inválido (extrapola o dia)";

      // Verifica conflito com reservas existentes
      for (final occ in horariosOcupados) {
        final occStart = _toMinutes(occ['inicio']!);
        final occEnd = _toMinutes(occ['fim']!);
        if (_rangesOverlap(inicioMin, fimMin, occStart, occEnd)) {
          throw "O horário selecionado conflita com uma reserva já existente.";
        }
      }

      final horaInicioStr =
          '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}';
      final horaFimStr =
          '${(fimMin ~/ 60).toString().padLeft(2, '0')}:${(fimMin % 60).toString().padLeft(2, '0')}';

      // Inserção no Supabase
      final insertResponse = await supabase.from('reservas').insert({
        'user_id': userId,
        'sala_id': widget.sala['id'],
        'data_reserva': DateFormat('yyyy-MM-dd').format(widget.dataSelecionada),
        'hora_inicio': horaInicioStr,
        'hora_fim': horaFimStr,
        'status': 'pendente',
        'titulo': _observacoesController.text.isEmpty
            ? 'Reserva'
            : _observacoesController.text,
      });

      if (insertResponse.isEmpty) {
        throw "Erro ao salvar a reserva.";
      }

      // Navega para página de confirmação
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmacaoReservaPage(
            reserva: {
              'nome_sala': widget.sala['nome'],
              'url': widget.sala['url'],
              'capacidade': widget.sala['capacidade'],
              'localizacao': widget.sala['localizacao'],
              'descricao': widget.sala['descricao'],
              'mediaAvaliacoes': widget.sala['media_avaliacoes'] ?? 0,
              'comentarios': comentarios,
              'data_reserva': widget.dataSelecionada,
              'hora_inicio': horaInicioStr,
              'hora_fim': horaFimStr,
              'observacoes': _observacoesController.text,
            },
            horariosDisponiveis: horariosDisponiveis,
            horariosOcupados: horariosOcupados,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // =========================================================================
  // -------------------------- UI HELPERS ----------------------------------
  // =========================================================================

  /// Mostra avaliação em estrelas
  Widget _buildEstrelas(double media) {
    return Row(
      children: List.generate(
        5,
            (i) => Icon(
          i < media ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }

  /// Formata [TimeOfDay] para "HH:mm"
  String _formatTimeOfDay(TimeOfDay t) {
    final dt = DateTime(2000, 1, 1, t.hour, t.minute);
    return DateFormat.Hm().format(dt);
  }

  // =========================================================================
  // -------------------------- UI PRINCIPAL --------------------------------
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final sala = widget.sala;
    final dataFormatada = DateFormat('dd/MM/yyyy').format(widget.dataSelecionada);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserva - Sala'),
        backgroundColor: const Color(0xFF2CC0AF),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem da sala
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: sala['url'] != null
                  ? Image.network(
                sala['url'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 200, color: Colors.grey[300]),
              )
                  : Container(height: 200, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),

            // Nome e avaliação
            Text(sala['nome'] ?? '',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildEstrelas(sala['media_avaliacoes'] ?? 0),
            const SizedBox(height: 8),
            Text('Capacidade: ${sala['capacidade'] ?? '-'}'),
            Text('Local: ${sala['localizacao'] ?? '-'}'),
            const SizedBox(height: 12),
            Text(sala['descricao'] ?? ''),

            // Data e observações
            const SizedBox(height: 16),
            Text('Data da Reserva: $dataFormatada'),
            const SizedBox(height: 8),
            TextField(
              controller: _observacoesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Observações (opcional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            // Escolha de duração (15min, 30min, 1h)
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Escolha a duração:'),
            const SizedBox(height: 8),
            Row(
              children: duracoesDisponiveis.map((minutos) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      minutos == 15
                          ? '15 min'
                          : minutos == 30
                          ? '30 min'
                          : '${minutos ~/ 60} hora',
                    ),
                    selected: duracaoMinutos == minutos,
                    onSelected: (_) => _onDuracaoChanged(minutos),
                  ),
                );
              }).toList(),
            ),

            // Horários disponíveis
            const SizedBox(height: 16),
            const Text('Horários disponíveis:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (slotsGerados.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nenhum horário disponível para esta data.'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loadHorarios,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar horários'),
                  )
                ],
              )
            else
              Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slotsGerados.map((slot) {
                      final selected = slotSelecionado != null &&
                          _toMinutes(slotSelecionado!) ==
                              _toMinutes(slot);
                      return ChoiceChip(
                        label: Text(_formatTimeOfDay(slot)),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            slotSelecionado = slot;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  if (slotSelecionado != null)
                    Text(
                        'Selecionado: ${_formatTimeOfDay(slotSelecionado!)} → ${_formatTimeOfDay(TimeOfDay(hour: (( _toMinutes(slotSelecionado!) + duracaoMinutos) ~/ 60) % 24, minute: ( _toMinutes(slotSelecionado!) + duracaoMinutos) % 60))}'),
                ],
              ),

            // Comentários
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Comentários',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            comentarios.isEmpty
                ? const Text('Nenhum comentário ainda.')
                : Column(
              children: comentarios.map((c) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: c['usuario']['avatar_url'] != null
                        ? NetworkImage(c['usuario']['avatar_url'])
                        : null,
                    child: c['usuario']['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(c['usuario']['name'] ?? '-'),
                  subtitle: Text(c['comentario'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      c['nota'] ?? 0,
                          (_) => const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Botão confirmar
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvarReserva,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2CC0AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirmar Reserva',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}