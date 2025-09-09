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

  void _onLogout() {
    // Futuramente conectar com Supabase Auth
    // Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logout realizado!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar com menu hamburguer
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      // Drawer lateral
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1ABC9C)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.black87),
              ),
              accountName: const Text("Usuário Exemplo"),
              accountEmail: const Text("usuario@email.com"),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Reservas"),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text("Salas"),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Perfil"),
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),

            const Spacer(),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: _onLogout,
            ),
          ],
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
