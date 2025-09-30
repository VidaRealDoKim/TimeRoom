// lib/home/home.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../reserva/pages/detalhes_sala.dart';
import '../home/pesquisa/pesquisar.dart';

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
  // CORREÇÃO 1: Adicionadas as propriedades de localização que faltavam.
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
    // Adicionadas ao construtor.
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
      // CORREÇÃO 2: A latitude e longitude são extraídas do JSON do Supabase.
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

  Future<void> _loadSalas() async {
    try {
      // CORREÇÃO: Usar o '*' garante que as colunas 'latitude' e 'longitude' são buscadas.
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

  Future<void> _selecionarData(BuildContext context) async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (dataEscolhida != null && mounted) setState(() => _dataSelecionada = dataEscolhida);
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
    final brightness = Theme.of(context).brightness;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: brightness == Brightness.dark ? Colors.black : Colors.grey[200],
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text("Olá${userName != null ? ', $userName' : ''}!"),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: brightness == Brightness.dark ? Colors.grey[900] : Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Resumo de salas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: brightness == Brightness.dark ? Colors.grey[850] : Colors.teal[400],
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
                        style: TextStyle(
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.white),
                      ),
                      Text(
                        "${_salas.length}",
                        style: TextStyle(
                          color: brightness == Brightness.dark ? Colors.white : Colors.white,
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

            // Campo de pesquisa
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      "Pesquisar por nome",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
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
                return _buildSalaCard(sala, brightness);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaCard(Sala sala, Brightness brightness) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
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
                  // --- CORREÇÃO 3: As coordenadas da sala agora são incluídas ---
                  // ao navegar para a página de detalhes.
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
                      color: brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sala.nome,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: brightness == Brightness.dark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(sala.localizacao ?? '-',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 12)),
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

