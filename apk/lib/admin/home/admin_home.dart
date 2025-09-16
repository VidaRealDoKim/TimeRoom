import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Página inicial corporativa do Admin (Dashboard)
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool loading = true;

  int totalSalas = 0;
  int salasReservadasHoje = 0;
  int salasDisponiveisHoje = 0;
  String salaMenosUsada = "-";
  int totalItens = 0;
  double mediaFeedback = 0.0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  /// ===================== FETCH DASHBOARD DATA =====================
  /// Busca todos os dados necessários para os cards do dashboard
  Future<void> fetchDashboardData() async {
    try {
      // Total de salas cadastradas
      final salasList = await supabase.from('salas').select();
      totalSalas = salasList.length;

      // Total de reservas **ativas hoje** (status 'pendente' ou 'confirmada')
      final reservasHoje = await supabase
          .from('reservas')
          .select()
          .filter('status', 'in', ['pendente', 'confirmada'])
          .eq('data_reserva', DateTime.now().toIso8601String().substring(0, 10));
      salasReservadasHoje = reservasHoje.length;

      // Salas disponíveis hoje
      salasDisponiveisHoje = totalSalas - salasReservadasHoje;

      // Sala menos utilizada (todas as reservas)
      final todasReservas = await supabase.from('reservas').select('sala_id');
      Map<String, int> contagemSalas = {};
      for (var r in todasReservas) {
        final salaId = r['sala_id'] as String;
        contagemSalas[salaId] = (contagemSalas[salaId] ?? 0) + 1;
      }

      if (contagemSalas.isNotEmpty) {
        final menorUsoSalaId =
            contagemSalas.entries.reduce((a, b) => a.value < b.value ? a : b).key;
        final sala = await supabase.from('salas').select('nome').eq('id', menorUsoSalaId).single();
        salaMenosUsada = sala['nome'] ?? "-";
      }

      // Total de itens (somando quantidade de cada item vinculado a salas)
      final itensList = await supabase.from('salas_itens').select();
      totalItens = itensList.fold<int>(0, (sum, item) => sum + (item['quantidade'] as int));

      // Média de feedbacks (nota de 1 a 5)
      final feedbacks = await supabase.from('feedback_salas').select('nota');
      if (feedbacks.isNotEmpty) {
        int soma = feedbacks.fold<int>(0, (sum, f) => sum + (f['nota'] as int));
        mediaFeedback = soma / feedbacks.length;
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dashboard: $e");
      setState(() => loading = false);
    }
  }

  /// ===================== BUILD UI =====================
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resumo Administrativo",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Grid de cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildDashboardCard(
                  title: "Salas Reservadas Hoje",
                  value: salasReservadasHoje.toString(),
                  icon: Icons.meeting_room,
                  color: Colors.orange),
              _buildDashboardCard(
                  title: "Salas Disponíveis Hoje",
                  value: salasDisponiveisHoje.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green),
              _buildDashboardCard(
                  title: "Menos Utilizada",
                  value: salaMenosUsada,
                  icon: Icons.trending_down,
                  color: Colors.red),
              _buildDashboardCard(
                  title: "Total de Salas",
                  value: totalSalas.toString(),
                  icon: Icons.apartment,
                  color: Colors.blue),
              _buildDashboardCard(
                  title: "Total de Itens",
                  value: totalItens.toString(),
                  icon: Icons.tv,
                  color: Colors.purple),
              _buildDashboardCard(
                  title: "Feedback Médio",
                  value: mediaFeedback.toStringAsFixed(1),
                  icon: Icons.star,
                  color: Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  /// ===================== DASHBOARD CARD BUILDER =====================
  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
