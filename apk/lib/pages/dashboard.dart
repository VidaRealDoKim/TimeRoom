import 'package:flutter/material.dart';
import 'package:apk/pages/nova_reserva.dart';

// Telas de exemplo
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Página Home", style: TextStyle(fontSize: 20)),
    );
  }
}

class ReservasPage extends StatelessWidget {
  const ReservasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Minhas Reservas", style: TextStyle(fontSize: 20)),
    );
  }
}

class SalasPage extends StatelessWidget {
  const SalasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Salas Disponíveis", style: TextStyle(fontSize: 20)),
    );
  }
}

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Meu Perfil", style: TextStyle(fontSize: 20)),
    );
  }
}

// Dashboard principal
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Lista de telas que serão exibidas
  final List<Widget> _pages = const [
    HomePage(),
    ReservasPage(),
    SalasPage(),
    PerfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
      ),

      // Conteúdo da tela muda conforme a aba
      body: _pages[_selectedIndex],

      // Botão de Nova Reserva
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovaReservaPage()),
          );
        },
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "NOVA RESERVA",
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Barra inferior
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF00796B),
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF1ABC9C),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Reservas"),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: "Salas"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
