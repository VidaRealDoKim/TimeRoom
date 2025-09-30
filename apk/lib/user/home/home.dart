import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../reserva/card/detalhes_sala.dart';
import '../home/pesquisa/pesquisar.dart'; // Importando a tela de pesquisa

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

  /// Construtor a partir de JSON (dados do Supabase)
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

/// Tela principal do aplicativo
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Sala> _salas = [];
  bool _isLoading = true;
  DateTime _dataSelecionada = DateTime.now();
  Set<String> favoritas = {};
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
        if (mounted) {
          setState(() {
            userName = profile['name'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar nome do usuário: $e");
    }
  }

  /// Carrega a lista de salas
  Future<void> _loadSalas() async {
    try {
      final response = await supabase.from('salas').select('*');
      List<Sala> salas = [];

      for (final row in response) {
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

  /// Carrega salas favoritas
  Future<void> _loadFavoritas() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase
          .from('salas_favoritas')
          .select('sala_id')
          .eq('usuario_id', userId);
      if (mounted) {
        setState(() {
          favoritas = data.map<String>((item) => item['sala_id'] as String).toSet();
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar favoritas: $e");
    }
  }

  /// Abre DatePicker
  Future<void> _selecionarData(BuildContext context) async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (dataEscolhida != null && mounted) setState(() => _dataSelecionada = dataEscolhida);
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

  /// Alterna favorito
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
    // O Dashboard já fornece um Scaffold e AppBar, então esta página
    // só precisa de retornar o seu conteúdo.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensagem de boas-vindas
          Text(
            "Olá${userName != null ? ', $userName' : ''}!",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Resumo de salas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // CORREÇÃO: Usa a cor primária do tema.
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Salas disponíveis",
                      // CORREÇÃO: Usa a cor de texto que contrasta com a cor primária.
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)),
                    ),
                    Text(
                      "${_salas.length}",
                      style: TextStyle(
                        // CORREÇÃO: Usa a cor de texto que contrasta com a cor primária.
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _selecionarData(context),
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                  ),
                  // CORREÇÃO: O estilo do botão agora vem do tema global.
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Campo de pesquisa que leva para SearchPage
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // CORREÇÃO: Usa a cor da superfície do tema (branco no modo claro, cinza escuro no modo escuro).
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Theme.of(context).hintColor),
                  const SizedBox(width: 8),
                  Text(
                    "Pesquisar por nome",
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grid de salas
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _salas.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final sala = _salas[index];
              return _buildSalaCard(sala);
            },
          ),
        ],
      ),
    );
  }

  /// Card da sala
  Widget _buildSalaCard(Sala sala) {
    return Card(
      // CORREÇÃO: A cor do card é agora controlada pelo tema.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
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
                  'ocupada': false,
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (sala.url != null && sala.url!.isNotEmpty)
                      ? Image.network(
                    sala.url!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    // CORREÇÃO: A cor do placeholder vem do tema.
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Center(
                        child: Icon(Icons.meeting_room, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant,)),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sala.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Theme.of(context).hintColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(sala.localizacao ?? '-', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,),
                      ),
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
