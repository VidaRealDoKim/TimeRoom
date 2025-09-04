import 'package:flutter/material.dart';
import 'package:apk/nova_reserva/nova_reserva.dart';
// import 'perfil.dart';
// import 'salas_disponiveis.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        "icon": Icons.add_circle,
        "title": "Nova Reserva",
        "route": const NovaReservaPage(),
      },
      {
        "icon": Icons.meeting_room,
        "title": "Minhas Reservas",
        "route": null, // depois troca por tela real
      },
      {
        "icon": Icons.apartment,
        "title": "Salas Disponíveis",
        "route": null, // depois troca por tela real
      },
      {
        "icon": Icons.person,
        "title": "Perfil",
        "route": null, // depois troca por tela real
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return _DashboardCard(
            icon: menuItems[index]["icon"],
            title: menuItems[index]["title"],
            onTap: () {
              if (menuItems[index]["route"] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => menuItems[index]["route"],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Clicou em ${menuItems[index]["title"]}")),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
