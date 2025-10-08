import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:apk/providers/theme_provider.dart';
import 'package:apk/user/home/reservar/detalhes_sala.dart';

final supabase = Supabase.instance.client;

/// Tela de seleção de datas do TimeRoom
class SelecionarDataPage extends StatefulWidget {
  final DateTime dataInicial;
  final String? salaId;

  const SelecionarDataPage({super.key, required this.dataInicial, this.salaId});

  @override
  State<SelecionarDataPage> createState() => _SelecionarDataPageState();
}

class _SelecionarDataPageState extends State<SelecionarDataPage>
    with TickerProviderStateMixin {
  DateTime? _dataEntrada;
  DateTime? _dataSaida;
  int _quantidadePessoas = 1;
  late TabController _tabController;
  Set<DateTime> _diasOcupados = {};

  @override
  void initState() {
    super.initState();

    initializeDateFormatting('pt_BR', null);

    _dataEntrada = widget.dataInicial;
    _dataSaida = widget.dataInicial.add(const Duration(days: 1));
    _tabController = TabController(length: 2, vsync: this);

    if (widget.salaId != null) {
      _carregarDiasOcupados(widget.salaId!);
    }
  }

  Future<void> _carregarDiasOcupados(String salaId) async {
    try {
      final response = await supabase
          .from('reservas')
          .select('data_reserva')
          .eq('sala_id', salaId)
          .filter('status', 'in', ['aceito', 'pendente']);

      setState(() {
        _diasOcupados = response
            .map<DateTime>((e) => DateTime.parse(e['data_reserva'] as String))
            .toSet();
      });
    } catch (e) {
      debugPrint("Erro ao carregar dias ocupados: $e");
    }
  }

  String get _periodoSelecionado {
    if (_dataEntrada == null || _dataSaida == null) return "-";
    final dias = _dataSaida!.difference(_dataEntrada!).inDays;
    return "${DateFormat('dd MMM', 'pt_BR').format(_dataEntrada!)} - "
        "${DateFormat('dd MMM', 'pt_BR').format(_dataSaida!)} "
        "($dias ${dias == 1 ? 'diária' : 'diárias'})";
  }

  void _onDaySelected(DateTime dia, DateTime focusedDay) {
    if (_diasOcupados.contains(dia)) return;
    setState(() {
      if (_dataEntrada == null || (_dataEntrada != null && _dataSaida != null)) {
        _dataEntrada = dia;
        _dataSaida = null;
      } else {
        if (dia.isBefore(_dataEntrada!)) {
          _dataSaida = _dataEntrada;
          _dataEntrada = dia;
        } else {
          _dataSaida = dia;
        }
      }
    });
  }

  Widget _buildFlexibilidade() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = themeProvider.themeMode == ThemeMode.dark
        ? Colors.grey[800]!
        : Colors.grey[200]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Número de pessoas:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (_quantidadePessoas > 1) {
                  setState(() {
                    _quantidadePessoas--;
                  });
                }
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_quantidadePessoas',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  _quantidadePessoas++;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _periodoSelecionado,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCalendario() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final primaryColor = themeProvider.themeMode == ThemeMode.dark
        ? Colors.blueAccent
        : theme.colorScheme.primary;

    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime(2030, 12, 31),
      focusedDay: _dataEntrada ?? DateTime.now(),
      selectedDayPredicate: (day) =>
      (day.isAtSameMomentAs(_dataEntrada ?? DateTime(0))) ||
          (day.isAtSameMomentAs(_dataSaida ?? DateTime(0))),
      onDaySelected: _onDaySelected,
      calendarFormat: CalendarFormat.month,
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      calendarStyle: CalendarStyle(
        rangeHighlightColor: primaryColor.withAlpha(75),
        rangeStartDecoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: primaryColor.withAlpha(75),
          shape: BoxShape.circle,
        ),
        disabledTextStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(75)),
      ),
      enabledDayPredicate: (day) => !_diasOcupados.contains(day),
      rangeStartDay: _dataEntrada,
      rangeEndDay: _dataSaida,
      availableGestures: AvailableGestures.all,
    );
  }

  Future<List<Map<String, dynamic>>> _buscarSalasDisponiveis() async {
    // Consulta simulada: filtra salas com capacidade >= _quantidadePessoas
    final response = await supabase
        .from('salas')
        .select()
        .gte('capacidade', _quantidadePessoas);
    return List<Map<String, dynamic>>.from(response);
  }

  void _abrirSalasDisponiveis() async {
    if (_dataEntrada == null || _dataSaida == null) return;

    final salas = await _buscarSalasDisponiveis();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SalasDisponiveisPage(
          salas: salas,
          entrada: _dataEntrada!,
          saida: _dataSaida!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecionar datas"),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Calendário"),
              Tab(text: "Filtrar por pessoas"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCalendario(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildFlexibilidade(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _abrirSalasDisponiveis,
                child: const Text("Buscar salas disponíveis"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Página de exibição das salas disponíveis
class SalasDisponiveisPage extends StatelessWidget {
  final List<Map<String, dynamic>> salas;
  final DateTime entrada;
  final DateTime saida;

  const SalasDisponiveisPage(
      {super.key, required this.salas, required this.entrada, required this.saida});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Salas disponíveis"),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: ListView.builder(
        itemCount: salas.length,
        itemBuilder: (context, index) {
          final sala = salas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(sala['nome'] ?? 'Sala sem nome'),
              subtitle: Text(
                  "Capacidade: ${sala['capacidade'] ?? '-'} pessoas\nLocal: ${sala['localizacao'] ?? '-'}"),
              trailing: Icon(Icons.arrow_forward, color: colorScheme.primary),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalhesSalaPage(
                      sala: sala,
                      dataSelecionada: entrada,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
