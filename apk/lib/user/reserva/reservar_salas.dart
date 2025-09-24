import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'nova_reserva.dart';

final supabase = Supabase.instance.client;

class Sala {
  final String id;
  final String nome;
  final int capacidade;
  final String? localizacao;
  final String? url;
  final List<String> itens;
  final double mediaAvaliacoes;

  Sala({
    required this.id,
    required this.nome,
    required this.capacidade,
    this.localizacao,
    this.url,
    required this.itens,
    required this.mediaAvaliacoes,
  });

  factory Sala.fromJson(Map<String, dynamic> json, List<String> itens, double media) {
    return Sala(
      id: json['id'],
      nome: json['nome'],
      capacidade: json['capacidade'],
      localizacao: json['localizacao'],
      url: json['url'],
      itens: itens,
      mediaAvaliacoes: media,
    );
  }
}

class ReservasPage extends StatefulWidget {
  const ReservasPage({super.key});

  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage> {
  List<Sala> _salas = [];
  bool _isLoading = true;
  String searchQuery = '';
  DateTime _dataSelecionada = DateTime.now();
  Set<String> favoritas = {};

  @override
  void initState() {
    super.initState();
    _loadSalas();
  }

  Future<void> _loadSalas() async {
    try {
      final response = await supabase.from('salas').select();
      List<Sala> salas = [];

      for (final row in response) {
        // Itens da sala
        final itensResponse = await supabase
            .from('salas_itens')
            .select('itens(nome)')
            .eq('sala_id', row['id']);
        final itens = itensResponse.map<String>((i) => i['itens']['nome'] as String).toList();

        // Média das avaliações
        final avaliacoes = await supabase
            .from('feedback_salas')
            .select('nota')
            .eq('sala_id', row['id']);
        double media = 0;
        if (avaliacoes.isNotEmpty) {
          media = avaliacoes.map((a) => a['nota'] as int).reduce((a, b) => a + b) /
              avaliacoes.length;
        }

        salas.add(Sala.fromJson(row, itens, media));
      }

      setState(() {
        _salas = salas;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar salas: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (dataEscolhida != null) {
      setState(() => _dataSelecionada = dataEscolhida);
    }
  }

  Widget _buildEstrelas(double media) {
    return Row(
      children: List.generate(
        5,
            (i) => Icon(
          i < media ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        ),
      ),
    );
  }

  void _toggleFavorito(String salaId) {
    setState(() {
      if (favoritas.contains(salaId)) {
        favoritas.remove(salaId);
      } else {
        favoritas.add(salaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredSalas = _salas
        .where((s) => s.nome.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservar Sala"),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: "Pesquisar por nome",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selecionarData(context),
                  icon: const Icon(Icons.date_range),
                  label: Text(DateFormat('dd/MM/yyyy').format(_dataSelecionada)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2CC0AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSalas.length,
              itemBuilder: (context, index) {
                final sala = filteredSalas[index];
                return _buildSalaCard(sala);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaCard(Sala sala) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NovaReservaPage(
                sala: {
                  'id': sala.id,
                  'nome': sala.nome,
                  'capacidade': sala.capacidade,
                  'localizacao': sala.localizacao,
                  'url': sala.url,
                  'descricao': sala.itens.join(', '),
                  'media_avaliacoes': sala.mediaAvaliacoes,
                },
                dataSelecionada: _dataSelecionada,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: sala.url != null
                      ? Image.network(
                    sala.url!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(
                        child: Icon(Icons.meeting_room, size: 50)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      favoritas.contains(sala.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: () => _toggleFavorito(sala.id),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sala.nome,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        sala.localizacao ?? '-',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Capacidade: ${sala.capacidade}"),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildEstrelas(sala.mediaAvaliacoes),
                      const SizedBox(width: 8),
                      Text(
                        "(${sala.itens.length} avaliações)",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
