import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../reserva/card/detalhes_sala.dart'; // Importando página de detalhes da sala

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

  /// Construtor a partir de JSON (dados do Supabase)
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

/// Tela principal do aplicativo
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Sala> _salas = []; // Lista completa de salas
  bool _isLoading = true; // Estado de carregamento
  String searchQuery = ''; // Texto da pesquisa
  DateTime _dataSelecionada = DateTime.now(); // Data selecionada
  Set<String> favoritas = {}; // IDs de salas favoritas
  String? userName; // Nome do usuário logado

  @override
  void initState() {
    super.initState();
    _loadUserName(); // Carrega nome do usuário
    _loadSalas(); // Carrega todas as salas
    _loadFavoritas(); // Carrega favoritas do usuário
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

  /// Carrega a lista de salas do Supabase
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
        final itens = itensResponse.map<String>((i) => i['itens']['nome'] as String).toList();

        // Calcula média de avaliações da sala
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

  /// Carrega salas favoritas do usuário
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

  /// Abre o DatePicker para escolher a data
  Future<void> _selecionarData(BuildContext context) async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (dataEscolhida != null) setState(() => _dataSelecionada = dataEscolhida);
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

  /// Alterna entre favoritar e desfavoritar a sala
  void _toggleFavorito(String salaId) async {
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
  }

  @override
  Widget build(BuildContext context) {
    // Tela de carregamento
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Filtra salas conforme pesquisa
    final filteredSalas = _salas
        .where((s) => s.nome.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Olá${userName != null ? ', $userName' : ''}!"),
        backgroundColor: const Color(0xFF2CC0AF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card de resumo das salas disponíveis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2CC0AF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Salas disponíveis",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "${_salas.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selecionarData(context),
                    icon: const Icon(Icons.date_range, color: Colors.white),
                    label: Text(
                      DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Campo de pesquisa inline
            TextField(
              decoration: InputDecoration(
                hintText: "Pesquisar por nome",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
            const SizedBox(height: 16),

            // Grid de salas
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSalas.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
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
      elevation: 3,
      child: InkWell(
        onTap: () {
          // Ao clicar, abre a página de detalhes da sala
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
                  'ocupada': false, // Pode ajustar conforme sua lógica
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
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: sala.url != null
                        ? Image.network(
                      sala.url!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : Container(
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
            ),

            // Informações da sala
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sala.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(sala.localizacao ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildEstrelas(sala.mediaAvaliacoes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
