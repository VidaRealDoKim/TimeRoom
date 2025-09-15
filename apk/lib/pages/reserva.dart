import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente Supabase
final supabase = Supabase.instance.client;

/// ---------------------------------------------------------------------------
/// 📌 Modelo de Dados da Sala
/// ---------------------------------------------------------------------------
class Sala {
  final String id;             // UUID da sala
  final String nome;           // Nome da sala
  final int capacidade;        // Capacidade máxima
  final String? localizacao;   // Localização física
  final String? url;           // URL de imagem (capa)
  final List<String> itens;    // Lista de itens/amenities
  bool isLiked;                // Curtida pelo usuário
  bool isBookmarked;           // Favoritada pelo usuário

  Sala({
    required this.id,
    required this.nome,
    required this.capacidade,
    this.localizacao,
    this.url,
    required this.itens,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  factory Sala.fromJson(Map<String, dynamic> json, List<String> itens) {
    return Sala(
      id: json['id'],
      nome: json['nome'],
      capacidade: json['capacidade'],
      localizacao: json['localizacao'],
      url: json['url'],
      itens: itens,
    );
  }
}

/// ---------------------------------------------------------------------------
/// 📌 Tela de Reservas
/// ---------------------------------------------------------------------------
class ReservasPage extends StatefulWidget {
  const ReservasPage({super.key});

  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage> {
  List<Sala> _todasAsSalas = [];         // Salas carregadas do BD
  bool _isLoading = true;                // Estado de carregamento
  Sala? _salaSelecionada;                // Sala atual
  DateTime? _dataSelecionada;            // Data da reserva
  final PageController _pageController = PageController();

  /// Inicializa dados
  @override
  void initState() {
    super.initState();
    _loadSalas();
    _dataSelecionada = DateTime.now();
  }

  /// 🔹 Busca salas e seus itens no Supabase
  Future<void> _loadSalas() async {
    try {
      final response = await supabase.from('salas').select();
      List<Sala> salas = [];

      for (final row in response) {
        // Busca itens relacionados à sala
        final itensResponse = await supabase
            .from('salas_itens')
            .select('itens(nome)')
            .eq('sala_id', row['id']);

        final itens = itensResponse
            .map<String>((i) => i['itens']['nome'] as String)
            .toList();

        salas.add(Sala.fromJson(row, itens));
      }

      setState(() {
        _todasAsSalas = salas;
        if (salas.isNotEmpty) {
          _salaSelecionada = salas.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar salas: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Seleciona data no calendário
  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (dataEscolhida != null) {
      setState(() {
        _dataSelecionada = dataEscolhida;
      });
    }
  }

  /// 🔹 Abre o diálogo de feedback
  void _abrirFeedbackDialog() {
    int nota = 3;
    final comentarioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Avaliar Sala"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: nota,
                items: List.generate(5, (i) => i + 1)
                    .map((n) => DropdownMenuItem(value: n, child: Text("$n estrelas")))
                    .toList(),
                onChanged: (value) {
                  if (value != null) nota = value;
                },
              ),
              TextField(
                controller: comentarioController,
                decoration: const InputDecoration(hintText: "Comentário"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_salaSelecionada == null) return;

                await supabase.from('feedback_salas').insert({
                  'sala_id': _salaSelecionada!.id,
                  'usuario_id': supabase.auth.currentUser?.id,
                  'nota': nota,
                  'comentario': comentarioController.text,
                });

                Navigator.pop(context);
              },
              child: const Text("Enviar"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Insere uma nova reserva
  Future<void> _criarReserva() async {
    if (_salaSelecionada == null || _dataSelecionada == null) return;

    try {
      await supabase.from('reservas').insert({
        'sala_id': _salaSelecionada!.id,
        'user_id': supabase.auth.currentUser?.id,
        'data_reserva': DateFormat('yyyy-MM-dd').format(_dataSelecionada!),
        'hora_inicio': '14:00',
        'hora_fim': '16:00',
        'status': 'pendente',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reserva criada com sucesso!")),
      );
    } catch (e) {
      debugPrint("Erro ao criar reserva: $e");
    }
  }

  /// -------------------------------------------------------------------------
  /// Construção da UI
  /// -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_salaSelecionada == null) {
      return const Scaffold(
        body: Center(child: Text("Nenhuma sala disponível")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Reservar Sala"),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review, color: Colors.amber),
            onPressed: _abrirFeedbackDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildImage(),
              const SizedBox(height: 16),
              _buildStatusAndAmenities(),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 24),
              _buildAvailability(),
              const SizedBox(height: 24),
              _buildCtaButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Dropdown para selecionar sala
  Widget _buildHeader() {
    return DropdownButton<Sala>(
      value: _salaSelecionada,
      onChanged: (Sala? novaSala) {
        if (novaSala != null) {
          setState(() {
            _salaSelecionada = novaSala;
          });
        }
      },
      items: _todasAsSalas.map((sala) {
        return DropdownMenuItem(value: sala, child: Text(sala.nome));
      }).toList(),
    );
  }

  /// Exibe imagem da sala
  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Image.network(
        _salaSelecionada?.url ?? '',
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }

  /// Exibe status e itens
  Widget _buildStatusAndAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text("Disponível", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          children: _salaSelecionada!.itens
              .map((item) => Chip(label: Text(item)))
              .toList(),
        ),
      ],
    );
  }

  /// Campos de formulário
  Widget _buildForm() {
    String dataFormatada = _dataSelecionada != null
        ? DateFormat('dd/MM/yyyy').format(_dataSelecionada!)
        : 'Selecione uma data';

    return Column(
      children: [
        TextField(decoration: const InputDecoration(hintText: "Título da reunião")),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selecionarData(context),
          child: AbsorbPointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: dataFormatada,
                prefixIcon: const Icon(Icons.calendar_today),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Horários disponíveis
  Widget _buildAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Disponibilidade"),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTimeSlot("14h-16h"),
            _buildTimeSlot("16h-18h"),
            _buildTimeSlot("19h-21h"),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSlot(String time) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Text(time),
    );
  }

  /// Botão de reservar
  Widget _buildCtaButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check),
        label: const Text("Reservar"),
        onPressed: _criarReserva,
      ),
    );
  }
}
