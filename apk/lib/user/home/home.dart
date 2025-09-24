import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sala_card.dart';

final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  List<Map<String, dynamic>> salas = [];
  List<Map<String, dynamic>> filteredSalas = [];
  Set<String> favoritas = {};

  String searchQuery = '';
  int? capacidadeMinima;
  DateTime? dataReserva;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _capacidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSalasDisponiveis();
    fetchFavoritas();
  }

  Future<void> fetchSalasDisponiveis() async {
    try {
      final data = await supabase.from('salas').select();
      setState(() {
        salas = List<Map<String, dynamic>>.from(data);
        filteredSalas = salas;
        loading = false;
      });
      applyFilters();
    } catch (e) {
      debugPrint("Erro ao carregar salas: $e");
      setState(() => loading = false);
    }
  }

  Future<void> fetchFavoritas() async {
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

  Future<void> toggleFavorito(String salaId) async {
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

    if (dataReserva != null) {
      final reservasData = await supabase
          .from('reservas')
          .select()
          .eq('data_reserva', DateFormat('yyyy-MM-dd').format(dataReserva!))
          .not('status', 'eq', 'cancelada');
      final List<Map<String, dynamic>> reservasList =
      List<Map<String, dynamic>>.from(reservasData);
      tempFiltered.removeWhere(
              (sala) => reservasList.any((reserva) => reserva['sala_id'] == sala['id']));
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
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
            if (filteredSalas.isEmpty)
              const Center(
                  child: Text(
                    "Nenhuma sala disponível para os filtros selecionados.",
                    style: TextStyle(color: Colors.grey),
                  )),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSalas.length,
              itemBuilder: (context, index) {
                final sala = filteredSalas[index];
                return SalaCard(
                  sala: sala,
                  isFavorita: favoritas.contains(sala['id']),
                  onToggleFavorito: () => toggleFavorito(sala['id']),
                  dataSelecionada: dataReserva ?? DateTime.now(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
