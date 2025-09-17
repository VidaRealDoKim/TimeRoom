import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';
import 'reservar_salas.dart';
import 'favoritos.dart';
import 'nova_reserva.dart';
import 'perfil.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  List<Widget> _pages() => [
    const HomePage(),
    const ReservasPage(),
    const SalasFavoritasPage(),
    const PerfilPage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NovaReservaPage(
            sala: {
              'id': 0,
              'nome': 'Sala Exemplo',
              'capacidade': 10,
              'localizacao': 'Local'
            },
            dataSelecionada: DateTime.now(),
          ),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index > 2 ? index - 1 : index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset(
          'assets/LogoHorizontal.png',
          height: 30,
        ),
        iconTheme: const IconThemeData(color: Colors.black), // Ícone do Drawer
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1ABC9C)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person,
                        size: 40, color: Color(0xFF1ABC9C)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Time Room",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Reservas"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text("Salas"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Perfil"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NovaReservaPage(
                sala: {
                  'id': 0,
                  'nome': 'Sala Exemplo',
                  'capacidade': 10,
                  'localizacao': 'Local'
                },
                dataSelecionada: DateTime.now(),
              ),
            ),
          );
        },
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: const Color(0xFF1ABC9C),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () => _onItemTapped(0)),
              IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: () => _onItemTapped(1)),
              const SizedBox(width: 40),
              IconButton(
                  icon: const Icon(Icons.meeting_room, color: Colors.white),
                  onPressed: () => _onItemTapped(3)),
              IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () => _onItemTapped(4)),
            ],
          ),
        ),
      ),
    );
  }
}
