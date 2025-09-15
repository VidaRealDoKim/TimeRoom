import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int minhasReservas = 0;
  int reservasPendentes = 0;
  int reservasConfirmadas = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDashboard();
  }

  Future<void> fetchUserDashboard() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final reservas = await supabase
          .from('reservas')
          .select()
          .eq('user_id', user.id);

      setState(() {
        minhasReservas = reservas.length;
        reservasPendentes = reservas.where((r) => r['status'] == 'pendente').length;
        reservasConfirmadas = reservas.where((r) => r['status'] == 'confirmada').length;
        loading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dashboard do usuário: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Meu Dashboard",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildDashboardCard(
                  "Minhas Reservas", minhasReservas.toString(), Icons.calendar_today, Colors.blue),
              _buildDashboardCard(
                  "Pendentes", reservasPendentes.toString(), Icons.pending, Colors.orange),
              _buildDashboardCard(
                  "Confirmadas", reservasConfirmadas.toString(), Icons.check_circle, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
