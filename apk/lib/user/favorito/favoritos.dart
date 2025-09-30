import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../reserva/pages/nova_reserva.dart';

// -----------------------------------------------------------------------------
// Modelo de Dados (Sala)
// -----------------------------------------------------------------------------
class SalaInfo {
  final String id;
  final String nome;
  final int capacidade;
  final String status;
  final String? url;

  SalaInfo({
    required this.id,
    required this.nome,
    required this.capacidade,
    required this.status,
    this.url,
  });

  factory SalaInfo.fromMap(Map<String, dynamic> map) {
    return SalaInfo(
      id: map['id'],
      nome: map['nome'],
      capacidade: map['capacidade'] ?? 0,
      status: map['status'] ?? 'disponível',
      url: map['url'],
    );
  }
}

// -----------------------------------------------------------------------------
// Tela de Salas Favoritas
// -----------------------------------------------------------------------------
class SalasFavoritasPage extends StatefulWidget {
  const SalasFavoritasPage({super.key});

  @override
  State<SalasFavoritasPage> createState() => _SalasFavoritasPageState();
}

class _SalasFavoritasPageState extends State<SalasFavoritasPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<SalaInfo> _favoritas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavoritas();
  }

  // ---------------------------------------------------------------------------
  // Busca as salas favoritas do usuário logado
  // ---------------------------------------------------------------------------
  Future<void> _fetchFavoritas() async {
    setState(() => _loading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não logado');

      // Busca salas favoritas do usuário
      final response = await _supabase
          .from('salas_favoritas')
          .select('salas(*)')
          .eq('usuario_id', user.id);

      final List<SalaInfo> salas = (response as List<dynamic>)
          .map((e) => SalaInfo.fromMap(e['salas'] as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        _favoritas = salas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar favoritas: $e')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleSection(),
            const SizedBox(height: 20),
            _buildRoomsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return const Text(
      'Salas Favoritas',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRoomsList() {
    return Expanded(
      child: _favoritas.isEmpty
          ? const Center(child: Text('Nenhuma sala favoritada'))
          : ListView.builder(
        itemCount: _favoritas.length,
        itemBuilder: (context, index) {
          final sala = _favoritas[index];
          return _buildSalaCard(sala);
        },
      ),
    );
  }

  Widget _buildSalaCard(SalaInfo sala) {
    final bool isDisponivel = sala.status.toLowerCase() == 'disponível';
    final Color cardColor = isDisponivel ? const Color(0xFF1ABC9C) : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: isDisponivel
            ? () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NovaReservaPage(
                sala: {
                  'id': sala.id,
                  'nome': sala.nome,
                  'capacidade': sala.capacidade,
                  'url': sala.url,
                },
                dataSelecionada: DateTime.now(), // data padrão
              ),
            ),
          );
        }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Imagem da sala
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  image: sala.url != null
                      ? DecorationImage(
                    image: NetworkImage(sala.url!),
                    fit: BoxFit.cover,
                  )
                      : null,
                  color: sala.url == null ? Colors.black12 : null,
                ),
                child: sala.url == null
                    ? const Icon(Icons.meeting_room,
                    color: Colors.white, size: 40)
                    : null,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sala.nome,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sala que comporta ${sala.capacidade} pessoas',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
