import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../reserva/card/nova_reserva.dart';
import '../home/pesquisa/pesquisar.dart'; // <- nova tela de pesquisa

// Instância global do Supabase
final supabase = Supabase.instance.client;

/// Modelo que representa uma Sala
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

  /// Construtor a partir de JSON (dados vindos do Supabase)
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

/// Tela principal (HomePage)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Lista de salas carregadas do Supabase
  List<Sala> _salas = [];

  // Estado de carregamento
  bool _isLoading = true;

  // Texto pesquisado
  String searchQuery = '';

  // Data selecionada pelo usuário
  DateTime _dataSelecionada = DateTime.now();

  // Conjunto de IDs das salas favoritas
  Set<String> favoritas = {};

  // Nome do usuário autenticado
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadSalas();
    _loadFavoritas();
  }

  /// Carrega o nome do usuário logado
  Future<void> _loadUserName() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final profile = await supabase
            .from('profiles')
            .select('name')
            .eq('id', userId)
            .single();
        setState(() {
          userName = profile['name'] as String?;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar nome do usuário: $e");
    }
  }

  /// Carrega a lista de salas
  Future<void> _loadSalas() async {
    try {
      final response = await supabase.from('salas').select();
      List<Sala> salas = [];

      for (final row in response) {
        // Busca os itens da sala
        final itensResponse = await supabase
            .from('salas_itens')
            .select('itens(nome)')
            .eq('sala_id', row['id']);
        final itens = itensResponse.map<String>((i) => i['itens']['nome'] as String).toList();

        // Calcula a média das avaliações
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

  /// Carrega as salas favoritas do usuário
  Future<void> _loadFavoritas() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase
          .from('salas_favoritas')
          .select('sala_id')
          .eq('usuario_id', userId);
      setState(() {
        favoritas = data.map<String>((item) => item['sala_id'] as String).toSet();
      });
    } catch (e) {
      debugPrint("Erro ao carregar favoritas: $e");
    }
  }

  /// Abre o DatePicker para escolher uma data
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

  /// Exibe estrelas de avaliação
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

  /// Alterna entre favoritar e desfavoritar uma sala
  void _toggleFavorito(String salaId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      if (favoritas.contains(salaId)) {
        await supabase
            .from('salas_favoritas')
            .delete()
            .match({'usuario_id': userId, 'sala_id': salaId});
        setState(() => favoritas.remove(salaId));
      } else {
        await supabase.from('salas_favoritas').insert({
          'usuario_id': userId,
          'sala_id': salaId,
        });
        setState(() => favoritas.add(salaId));
      }
    } catch (e) {
      debugPrint("Erro ao favoritar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tela de carregamento
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Filtra as salas pelo texto pesquisado
    final filteredSalas = _salas
        .where((s) => s.nome.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Bem-vindo${userName != null ? ', $userName' : ''}!"),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔎 Campo de pesquisa -> abre a tela de busca
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Pesquisar por nome",
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📅 Botão para escolher data
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

            // Lista de salas
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

  /// Card que exibe as informações da sala
  Widget _buildSalaCard(Sala sala) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // Abre a tela de reserva ao clicar na sala
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
            // Imagem da sala + botão de favorito
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

            // Informações da sala
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
