import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'salas/admin_salas.dart';
import 'criar/criar.dart';
import 'usuarios/admin_usuarios.dart';
import 'home/admin_home.dart';

final supabase = Supabase.instance.client;

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? profile;
  bool loading = true;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminHomePage(),     // Aba 0 - Início
    const AdminSalasPage(),    // Aba 1 - Salas
    const AdminUsuariosPage(), // Aba 2 - Usuários
    const Center(child: Text("Itens")), // Aba 3 - Itens
  ];

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response =
      await supabase.from('profiles').select().eq('id', user.id).single();

      setState(() {
        profile = response;
        loading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openCriarSala() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CriarSalaPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset(
          "assets/LogoHorizontal.png",
          height: 30,
          fit: BoxFit.contain,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.black87,
              size: 28,
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1ABC9C)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Color(0xFF1ABC9C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?['name'] ?? "Administrador",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text("Salas"),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Usuários"),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text("Itens"),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCriarSala,
        backgroundColor: const Color(0xFF1ABC9C),
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: const Color(0xFF1ABC9C),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onItemTapped(0),
                  borderRadius: BorderRadius.circular(30),
                  splashColor: Colors.white24,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.home, color: Colors.white),
                  ),
                ),
              ),
              // Salas
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onItemTapped(1),
                  borderRadius: BorderRadius.circular(30),
                  splashColor: Colors.white24,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.meeting_room, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 48), // espaço para FAB
              // Itens
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onItemTapped(3),
                  borderRadius: BorderRadius.circular(30),
                  splashColor: Colors.white24,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.inventory_2, color: Colors.white),
                  ),
                ),
              ),
              // Perfil
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onItemTapped(2),
                  borderRadius: BorderRadius.circular(30),
                  splashColor: Colors.white24,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
