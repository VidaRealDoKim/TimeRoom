import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'salas/admin_salas.dart';
import 'criar/criar.dart';
import 'usuarios/admin_usuarios.dart';
import 'home/admin_home.dart';

/// Instância do Supabase
final supabase = Supabase.instance.client;

/// Página principal do Painel Administrativo
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? profile;
  bool loading = true;
  int _selectedIndex = 0;

  /// Lista de páginas exibidas nas abas
  final List<Widget> _pages = const [
    AdminHomePage(),     // Aba 0 - Início
    AdminSalasPage(),    // Aba 1 - Listar/Editar Salas
    CriarSalaPage(),     // Aba 2 - Criar Sala (nova aba)
    AdminUsuariosPage(), // Aba 3 - Usuários
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true, // <-- Centraliza a logo
        title: Image.asset(
          "assets/LogoHorizontal.png",
          height: 30, // ajusta o tamanho da logo
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
                setState(() => _selectedIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text("Salas"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_business),
              title: const Text("Criar Sala"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Usuários"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
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

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF00796B),
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF1ABC9C),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Início",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: "Salas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_business),
            label: "Criar Sala",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Usuários",
          ),
        ],
      ),
    );
  }
}
