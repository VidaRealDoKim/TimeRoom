import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'salas/admin_salas.dart';
import 'usuarios/admin_usuarios.dart';

/// Instância do Supabase para autenticação e banco de dados
final supabase = Supabase.instance.client;

/// Página principal do Painel Administrativo
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  /// Perfil do usuário logado (retirado da tabela "profiles")
  Map<String, dynamic>? profile;

  /// Indicador de carregamento
  bool loading = true;

  /// Índice da aba selecionada (para BottomNavigationBar)
  int _selectedIndex = 0;

  /// Lista de páginas (conteúdo exibido em cada aba)
  final List<Widget> _pages = const [
    // Página inicial: visão geral
    Center(
      child: Text(
        "Dashboard Corporativo",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
    // Página de salas administrativas
    AdminSalasPage(),
    // Página de usuários administrativos
    AdminUsuariosPage(),
  ];

  @override
  void initState() {
    super.initState();
    fetchProfile(); // Carrega perfil ao iniciar
  }

  /// Busca os dados do perfil no Supabase
  Future<void> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        profile = response;
        loading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
      setState(() => loading = false);
    }
  }

  /// Executa o logout do usuário
  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  /// Atualiza a aba selecionada no BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: loading
            ? const Text(
          "Carregando...",
          style: TextStyle(color: Colors.black87),
        )
            : const Text(
          "Painel Administrativo",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      // Menu lateral (Drawer)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabeçalho do Drawer
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

            // Itens do Drawer
            ListTile(
              leading: const Icon(Icons.dashboard),
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
              leading: const Icon(Icons.person),
              title: const Text("Usuários"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),

            const Divider(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),

      // Corpo da página (conteúdo principal)
      body: _pages[_selectedIndex],

      // Barra inferior de navegação
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF00796B),
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF1ABC9C),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: "Salas",
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
