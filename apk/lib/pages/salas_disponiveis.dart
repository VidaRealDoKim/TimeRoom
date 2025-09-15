import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// -----------------------------------------------------------------------------
// Modelo de Dados (Sala)
// -----------------------------------------------------------------------------
class SalaInfo {
  final String id;
  final String nome;
  final int capacidade;
  final String status;
  final String? url; // URL da imagem da sala

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
      status: 'Disponível', // default
      url: map['url'],
    );
  }
}

// -----------------------------------------------------------------------------
// Tela de Salas Disponíveis
// -----------------------------------------------------------------------------
class SalasDisponiveisPage extends StatefulWidget {
  const SalasDisponiveisPage({super.key});

  @override
  State<SalasDisponiveisPage> createState() => _SalasDisponiveisPageState();
}

class _SalasDisponiveisPageState extends State<SalasDisponiveisPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<SalaInfo> _todasAsSalas = [];
  List<SalaInfo> _listaFiltrada = [];

  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarSalas);
    _fetchSalas();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrarSalas);
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Busca as salas no Supabase
  // ---------------------------------------------------------------------------
  Future<void> _fetchSalas() async {
    setState(() => _loading = true);

    try {
      final response = await _supabase.from('salas').select().order('nome');

      final List<SalaInfo> salas = (response as List<dynamic>)
          .map((e) => SalaInfo.fromMap(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        _todasAsSalas = salas;
        _listaFiltrada = salas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar salas: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Filtra salas por nome ou capacidade
  // ---------------------------------------------------------------------------
  void _filtrarSalas() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _listaFiltrada = _todasAsSalas.where((sala) {
        final nomeSala = sala.nome.toLowerCase();
        final capacidade = sala.capacidade.toString();
        return nomeSala.contains(query) || capacidade.contains(query);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Seleciona data (opcional)
  // ---------------------------------------------------------------------------
  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (dataEscolhida != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data selecionada: ${DateFormat('dd/MM/yyyy').format(dataEscolhida)}'),
          backgroundColor: const Color(0xFF16A085),
        ),
      );
      // TODO: filtrar salas por data escolhida
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleSection(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildRoomsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Lista de salas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () => _selecionarData(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1ABC9C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por nome ou capacidade...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    return Expanded(
      child: _listaFiltrada.isEmpty
          ? const Center(child: Text('Nenhuma sala encontrada'))
          : ListView.builder(
        itemCount: _listaFiltrada.length,
        itemBuilder: (context, index) {
          final sala = _listaFiltrada[index];
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
          Navigator.pushNamed(context, '/reservas', arguments: sala);
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
                    ? const Icon(Icons.meeting_room, color: Colors.white, size: 40)
                    : null,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
