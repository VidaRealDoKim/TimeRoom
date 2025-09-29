import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'editar_sala.dart';
import 'admin_salas_itens.dart';

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

  // ===================== CORES PADRONIZADAS =====================
  final Color primaryColor = const Color(0xFF1ABC9C);
  final Color secondaryColor = const Color(0xFF1ABC9C);
  final Color bgColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Apenas uma aba agora
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

  // ===================== CONFIRMAÇÃO DE EXCLUSÃO =====================
  Future<void> confirmDeleteSala(Map<String, dynamic> sala) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar exclusão"),
        content: Text(
          "Deseja realmente excluir a sala '${sala['nome']}'? "
              "Todos os itens, reservas, feedbacks e favoritos relacionados serão removidos.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteSala(sala['id'] as String);
    }
  }

  // ===================== DELETE SALA EM CASCATA =====================
  Future<void> deleteSala(String salaId) async {
    setState(() => _loading = true);
    try {
      await supabase.from('feedback_salas').delete().eq('sala_id', salaId);
      await supabase.from('reservas').delete().eq('sala_id', salaId);
      await supabase.from('salas_favoritas').delete().eq('sala_id', salaId);
      await supabase.from('salas_horarios').delete().eq('sala_id', salaId);
      await supabase.from('salas_itens').delete().eq('sala_id', salaId);
      await supabase.from('salas').delete().eq('id', salaId);

      await fetchSalas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sala excluída com sucesso.")),
        );
      }
    } catch (e) {
      debugPrint("Erro ao deletar sala: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao deletar sala: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===================== CARD DE SALA =====================
  Widget buildSalaCard(Map<String, dynamic> sala) {
    final url = (sala['url'] as String?) ?? '';
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
                image: url.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
                    : null,
              ),
              child: url.isEmpty
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
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
                  onPressed: () => confirmDeleteSala(sala),
                ),
                // Ícone de itens removido do card
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
      body: buildListaSalas(),
    );
  }
}
