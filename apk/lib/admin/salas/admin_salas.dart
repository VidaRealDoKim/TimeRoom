import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'editar_sala.dart';
import 'admin_salas_itens.dart'; // Tela de itens da sala

final supabase = Supabase.instance.client;

/// Tela de gerenciamento de salas em formato de lista (cards grandes), sem AppBar
class AdminSalasPage extends StatefulWidget {
  const AdminSalasPage({super.key});

  @override
  State<AdminSalasPage> createState() => _AdminSalasPageState();
}

class _AdminSalasPageState extends State<AdminSalasPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> salas = [];
  bool _loading = false;
  late TabController _tabController;
  Map<String, dynamic>? salaSelecionada;

  // ===================== CORES PADRONIZADAS =====================
  final Color primaryColor = const Color(0xFF1ABC9C);
  final Color secondaryColor = const Color(0xFF1ABC9C);
  final Color bgColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchSalas();
  }

  // ===================== FETCH SALAS =====================
  Future<void> fetchSalas() async {
    setState(() => _loading = true);
    try {
      final response = await supabase.from('salas').select();
      setState(() {
        salas = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Erro ao buscar salas: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ===================== DELETE SALA =====================
  Future<void> deleteSala(int salaId) async {
    try {
      await supabase.from('salas').delete().eq('id', salaId);
      fetchSalas();
    } catch (e) {
      debugPrint("Erro ao deletar sala: $e");
    }
  }

  // ===================== CARD DE SALA =====================
  Widget buildSalaCard(Map<String, dynamic> sala) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem ou ícone da sala
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: primaryColor.withOpacity(0.2),
                image: sala['url'] != null && sala['url'].isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(sala['url']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: sala['url'] == null || sala['url'].isEmpty
                  ? const Center(
                child: Icon(Icons.meeting_room, size: 60, color: Color(0xFF1ABC9C)),
              )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              sala['nome'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Capacidade: ${sala['capacidade']}",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Editar sala
                IconButton(
                  icon: Icon(Icons.edit, color: primaryColor, size: 28),
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditarSalaPage(sala: sala),
                      ),
                    );
                    if (updated == true) fetchSalas();
                  },
                ),
                // Deletar sala
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
                  onPressed: () => deleteSala(sala['id']),
                ),
                // Itens da sala
                IconButton(
                  icon: Icon(Icons.inventory_2, color: secondaryColor, size: 28),
                  onPressed: () {
                    setState(() {
                      salaSelecionada = sala;
                      _tabController.index = 1;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== LISTA DE SALAS =====================
  Widget buildListaSalas() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (salas.isEmpty) return const Center(child: Text("Nenhuma sala cadastrada"));

    return RefreshIndicator(
      onRefresh: fetchSalas,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: salas.length,
        itemBuilder: (context, index) {
          return buildSalaCard(salas[index]);
        },
      ),
    );
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Tabs para alternar entre salas e itens
          TabBar(
            controller: _tabController,
            indicatorColor: secondaryColor,
            labelColor: secondaryColor,
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'Salas'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Itens'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildListaSalas(),
                salaSelecionada != null
                    ? AdminSalaItensPage(sala: salaSelecionada!)
                    : const Center(
                  child: Text(
                    "Selecione uma sala na aba de Salas",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
