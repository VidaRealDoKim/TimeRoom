import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'nova_reserva.dart';
import 'confirmacao_reserva.dart';

final supabase = Supabase.instance.client;

/// HomePage: Lista de salas disponíveis, filtros e fluxo de reservas
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  List<Map<String, dynamic>> salas = [];
  List<Map<String, dynamic>> filteredSalas = [];

  // Filtros
  String searchQuery = '';
  int? capacidadeMinima;
  DateTime? dataReserva;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _capacidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSalasDisponiveis();
  }

  /// Busca todas as salas no Supabase
  Future<void> fetchSalasDisponiveis() async {
    try {
      final data = await supabase.from('salas').select();
      setState(() {
        salas = List<Map<String, dynamic>>.from(data);
        filteredSalas = salas;
        loading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar salas: $e");
      setState(() => loading = false);
    }
  }

  /// Aplica filtros de pesquisa, capacidade e data
  Future<void> applyFilters() async {
    List<Map<String, dynamic>> tempFiltered = salas.where((sala) {
      final matchesName = sala['nome']
          ?.toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase()) ??
          true;
      final matchesCapacity = capacidadeMinima == null
          ? true
          : (sala['capacidade'] ?? 0) >= capacidadeMinima!;
      return matchesName && matchesCapacity;
    }).toList();

    // Se tiver data selecionada, checar reservas para aquela data
    if (dataReserva != null) {
      final reservasData = await supabase
          .from('reservas')
          .select()
          .eq('data_reserva', DateFormat('yyyy-MM-dd').format(dataReserva!));

      final List<Map<String, dynamic>> reservasList =
      List<Map<String, dynamic>>.from(reservasData);

      for (var sala in tempFiltered) {
        final isOcupada = reservasList.any((reserva) =>
        reserva['sala_id'] == sala['id'] &&
            reserva['status'] != 'cancelada');
        sala['ocupada'] = isOcupada;
      }
    } else {
      for (var sala in tempFiltered) {
        sala['ocupada'] = sala['status'] != 'disponível';
      }
    }

    setState(() => filteredSalas = tempFiltered);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Reserve sua Sala",
          style: TextStyle(
            color: Color(0xFF272525),
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------
            // Filtros de pesquisa
            // -------------------------
            const Text(
              "Filtrar Salas",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF272525),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Pesquisar por nome",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                searchQuery = value;
                applyFilters();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacidadeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Capacidade mínima",
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      capacidadeMinima = int.tryParse(value);
                      applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dataReserva ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => dataReserva = picked);
                        await applyFilters();
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      dataReserva == null
                          ? "Selecionar data"
                          : DateFormat('dd/MM/yyyy').format(dataReserva!),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2CC0AF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // -------------------------
            // Lista de salas disponíveis
            // -------------------------
            const Text(
              "Salas Disponíveis",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF272525),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
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

  /// Card de cada sala, agora apenas abre a tela de detalhes
  Widget _buildSalaCard(Map<String, dynamic> sala) {
    final status = sala['ocupada'] == true ? "Ocupada" : "Livre";
    final statusColor = sala['ocupada'] == true ? Colors.red : Colors.green;
    final imageUrl =
        sala['url'] ?? "https://via.placeholder.com/150"; // Placeholder

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalhesSalaPage(
              sala: sala,
              dataSelecionada: dataReserva ?? DateTime.now(),
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 150, color: Colors.grey[300]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sala['nome'] ?? 'Sala',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Poppins'),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Poppins'),
                    ),
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

/// Página de detalhes da sala
class DetalhesSalaPage extends StatelessWidget {
  final Map<String, dynamic> sala;
  final DateTime dataSelecionada;

  const DetalhesSalaPage(
      {super.key, required this.sala, required this.dataSelecionada});

  /// Navega para NovaReservaPage e depois ConfirmacaoReservaPage
  void _reservarSala(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovaReservaPage(
          sala: sala,
          dataSelecionada: dataSelecionada,
        ),
      ),
    );

    if (result == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmacaoReservaPage(
            reserva: {
              'nome_sala': sala['nome'],
              'data_reserva': dataSelecionada,
              'observacoes': '',
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = sala['ocupada'] == true ? "Ocupada" : "Livre";
    final statusColor = sala['ocupada'] == true ? Colors.red : Colors.green;
    final imageUrl = sala['url'] ?? "https://via.placeholder.com/300";

    return Scaffold(
      appBar: AppBar(
        title: Text(sala['nome'] ?? 'Detalhes da Sala'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sala['nome'] ?? 'Sala',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Capacidade: ${sala['capacidade'] ?? '-'}"),
                  const SizedBox(height: 8),
                  Text("Localização: ${sala['localizacao'] ?? '-'}"),
                  const SizedBox(height: 8),
                  Text("Descrição: ${sala['descricao'] ?? '-'}"),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: sala['ocupada'] == true
                          ? null
                          : () => _reservarSala(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2CC0AF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Reservar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
