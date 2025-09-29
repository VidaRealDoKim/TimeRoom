import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'card/detalhes_sala.dart';

final supabase = Supabase.instance.client;

class Sala {
  final String id;
  final String nome;
  final int capacidade;
  final String? localizacao;
  final String? url;
  final List<String> itens;
  final double mediaAvaliacoes;
  final double? latitude;
  final double? longitude;

  Sala({
    required this.id,
    required this.nome,
    required this.capacidade,
    this.localizacao,
    this.url,
    required this.itens,
    required this.mediaAvaliacoes,
    this.latitude,
    this.longitude,
  });

  factory Sala.fromJson(Map<String, dynamic> json, List<String> itens, double media) {
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Sala(
      id: json['id'],
      nome: json['nome'],
      capacidade: json['capacidade'],
      localizacao: json['localizacao'],
      url: json['url'],
      itens: itens,
      mediaAvaliacoes: media,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
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
      final response = await supabase.from('salas').select('*');
      List<Sala> salas = [];

      for (final row in response) {
        debugPrint("Dados da sala recebidos do Supabase: $row");

        final itensResponse = await supabase
            .from('salas_itens')
            .select('itens(nome)')
            .eq('sala_id', row['id']);
        final itens = itensResponse.map<String>((i) => i['itens']['nome'] as String).toList();

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

      if (mounted) {
        setState(() {
          _salas = salas;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar salas: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (dataEscolhida != null && mounted) {
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
      // O Scaffold é necessário aqui para o ecrã de carregamento.
      // O tema já define a cor de fundo correta.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredSalas = _salas
        .where((s) => s.nome.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    // Esta página não precisa de um Scaffold ou AppBar, pois ela é mostrada
    // dentro do Dashboard, que já tem a estrutura principal.
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          // Usamos um Align para garantir que o botão fica à esquerda.
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () => _selecionarData(context),
              icon: const Icon(Icons.date_range),
              label: Text(DateFormat('dd/MM/yyyy').format(_dataSelecionada)),
              // CORREÇÃO: O estilo do botão foi removido. Agora ele usa
              // as cores definidas no ThemeProvider para o modo claro e escuro.
            ),
          ),
          const SizedBox(height: 16),
          // A lista agora está envolvida num Expanded para ocupar o espaço
          // restante de forma segura e evitar erros de layout.
          Expanded(
            child: ListView.builder(
              itemCount: filteredSalas.length,
              itemBuilder: (context, index) {
                final sala = filteredSalas[index];
                return _buildSalaCard(sala);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaCard(Sala sala) {
    return Card(
      // CORREÇÃO: A cor do Card agora é definida pelo tema,
      // tornando-o mais escuro no modo escuro.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      clipBehavior: Clip.antiAlias, // Garante que o conteúdo respeita as bordas arredondadas.
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalhesSalaPage(
                sala: {
                  'id': sala.id,
                  'nome': sala.nome,
                  'capacidade': sala.capacidade,
                  'localizacao': sala.localizacao,
                  'url': sala.url,
                  'descricao': sala.itens.join(', '),
                  'media_avaliacoes': sala.mediaAvaliacoes,
                  'ocupada': false, // Adicionar lógica se necessário
                  'latitude': sala.latitude,
                  'longitude': sala.longitude,
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
                (sala.url != null && sala.url!.isNotEmpty)
                    ? Image.network(
                  sala.url!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Adiciona um ecrã de carregamento e de erro para a imagem.
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Center(
                          child: Icon(Icons.image_not_supported,
                              size: 50,
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    );
                  },
                )
                    : Container(
                  height: 180,
                  // CORREÇÃO: Usamos uma cor do tema para o placeholder.
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Center(
                      child: Icon(Icons.meeting_room,
                          size: 50,
                          // CORREÇÃO: Cor do ícone também vem do tema.
                          // DEIXAR ESSES THEME.OF PQ ELE É DO TEMA ESCURO
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      favoritas.contains(sala.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red, // Cores de destaque como esta podem ser mantidas
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
                      // ... (código das avaliações)
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

