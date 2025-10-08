// lib/home/home.dart
import 'package:apk/user/home/reservar/detalhes_sala.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/pesquisa/pesquisar.dart';
import 'selecionar_datas.dart';

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
  // Propriedades de localização para o mapa.
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
    // Função auxiliar para converter os dados de localização de forma segura.
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
  DateTime _dataEntrada = DateTime.now();
  DateTime _dataSaida = DateTime.now().add(const Duration(days: 1));
  Set<String> favoritas = {};
  String? userName;

  // -------------------- Ciclo de Vida --------------------
  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadSalas();
    _loadFavoritas();
  }

  // -------------------- Carregamento de Dados --------------------

  /// Carrega o nome do usuário logado
  Future<void> _loadUserName() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final profile =
        await supabase.from('profiles').select('name').eq('id', userId).single();
        if (mounted) setState(() => userName = profile['name'] as String?);
      }
    } catch (e) {
      debugPrint("Erro ao carregar nome do usuário: $e");
    }
  }

  /// Carrega as salas do banco de dados
  Future<void> _loadSalas() async {
    try {
      // Usar o '*' garante que as colunas 'latitude' e 'longitude' são buscadas.
      final response = await supabase.from('salas').select('*');
      List<Sala> salas = [];

      for (final row in response) {
        // Itens da sala
        final itensResponse = await supabase
            .from('salas_itens')
            .select('itens(nome)')
            .eq('sala_id', row['id']);
        final itens = itensResponse.map<String>((i) => i['itens']['nome'] as String).toList();

        // Média de avaliações
        final avaliacoes =
        await supabase.from('feedback_salas').select('nota').eq('sala_id', row['id']);
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
      if (mounted) setState(() => _isLoading = false);
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
      if (mounted) {
        setState(() {
          favoritas = data.map<String>((item) => item['sala_id'] as String).toSet();
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar favoritas: $e");
    }
  }

  // -------------------- Ações do Usuário --------------------

  /// Abre a página de seleção de datas
  Future<void> _selecionarData(BuildContext context) async {
    final resultado = await Navigator.push<Map<String, DateTime>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelecionarDataPage(
          dataInicial: _dataEntrada,
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        _dataEntrada = resultado['entrada']!;
        _dataSaida = resultado['saida']!;
      });
    }
  }

  /// Marca ou desmarca uma sala como favorita
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
      await supabase
          .from('salas_favoritas')
          .insert({'usuario_id': userId, 'sala_id': salaId});
      setState(() => favoritas.add(salaId));
    }
  }

  // -------------------- Widgets de Apoio --------------------

  /// Constrói estrelas de avaliação
  Widget _buildEstrelas(double media) {
    return Row(
      children: List.generate(
        5,
            (i) => Icon(
          i < media ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 14,
        ),
      ),
    );
  }

  /// Lista horizontal de salas
  Widget _buildHorizontalList(List<Sala> salas) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: salas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final sala = salas[index];
          return SizedBox(
            width: 200,
            child: _buildSalaCard(sala),
          );
        },
      ),
    );
  }

  /// Card individual de sala
  Widget _buildSalaCard(Sala sala) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      // A cor do card é controlada pelo `cardColor` do tema.
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
                dataSelecionada: _dataEntrada,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 140,
                    child: sala.url != null
                        ? Image.network(sala.url!, fit: BoxFit.cover)
                        : Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(Icons.meeting_room, size: 50, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                // Conteúdo
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sala.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: theme.hintColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sala.localizacao ?? '-',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
            // Botão Favorito
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  favoritas.contains(sala.id) ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () => _toggleFavorito(sala.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Build Principal --------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final populares = List<Sala>.from(_salas)
      ..sort((a, b) => b.mediaAvaliacoes.compareTo(a.mediaAvaliacoes));
    final favoritasList = _salas.where((s) => favoritas.contains(s.id)).toList();
    final todas = List<Sala>.from(_salas);

    return Scaffold(
      // CORREÇÃO: Cor de fundo removida para usar o `scaffoldBackgroundColor` do tema.
      appBar: AppBar(
        // CORREÇÃO: Cor de fundo removida para usar o `appBarTheme` do tema.
        elevation: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              // A saudação ao utilizador é mantida.
              child: Text(
                "Olá${userName != null ? ', $userName' : ''}!",
                style: const TextStyle(
                  fontWeight: FontWeight.bold, // Adicione esta linha para o negrito
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seletor de Data
            GestureDetector(
              onTap: () => _selecionarData(context),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  // CORREÇÃO: Usa a cor de superfície do tema.
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, color: colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Text(
                      "${DateFormat('dd/MM/yyyy').format(_dataEntrada)} - "
                          "${DateFormat('dd/MM/yyyy').format(_dataSaida)}",
                      style:
                      TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Campo de Pesquisa
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const SearchPage()));
              },
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Text(
                      "Pesquisar por nome",
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Carrosséis
            if (favoritasList.isNotEmpty) ...[
              Text("Suas favoritas",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildHorizontalList(favoritasList),
              const SizedBox(height: 24),
            ],
            Text("Populares",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildHorizontalList(populares),
            const SizedBox(height: 24),
            Text("Todas as salas",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildHorizontalList(todas),
          ],
        ),
      ),
    );
  }
}

