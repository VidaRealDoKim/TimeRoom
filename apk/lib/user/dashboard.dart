import 'package:apk/user/perfil/perfil.dart';
import 'package:apk/user/reserva/reservar_salas.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart'; // pacote atualizado

import 'favorito/favoritos.dart';

import 'home/home.dart';
import 'home/home.dart';
import 'reserva/reservar_salas.dart';
import 'favorito/favoritos.dart';
import 'perfil/perfil.dart';

/// Instância global do Supabase
final supabase = Supabase.instance.client;

/// =======================
/// Dashboard principal
/// =======================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// Aba atualmente selecionada
  int _selectedIndex = 0;

  /// Lista de páginas correspondentes às abas
  final List<Widget> _pages = const [
    HomePage(),
    ReservasPage(),
    SalasFavoritasPage(),
    PerfilPage(),
  ];

  /// Dados do perfil do usuário logado
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// =======================
  /// Buscar dados do usuário logado
  /// =======================
  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _profile = response;
      });
    }
  }

  /// =======================
  /// Alterar aba selecionada
  /// =======================
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// =======================
  /// Logout com confirmação
  /// =======================
  Future<void> _logout() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Logout"),
        content: const Text("Você realmente deseja sair da sua conta?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1ABC9C),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Sair"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  /// =======================
  /// Abrir tela de QR Code
  /// =======================
  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRViewPage(
          onScan: (String result) {
            Navigator.pop(context); // fecha a tela após ler
            // aqui você pode tratar o resultado (ex: navegar, salvar no banco, etc.)
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        // =======================
        // AppBar com logo centralizado
        // =======================
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Image.asset('assets/LogoHorizontal.png', height: 30),
          iconTheme: const IconThemeData(color: Colors.black),
        ),

        // =======================
        // Drawer lateral
        // =======================
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF1ABC9C)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: _profile?['avatar_url'] != null
                          ? NetworkImage(_profile!['avatar_url'])
                          : null,
                      child: _profile?['avatar_url'] == null
                          ? const Icon(Icons.person,
                          size: 40, color: Color(0xFF1ABC9C))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profile?['name'] ?? "Usuário",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _profile?['email'] ?? "",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Home"),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Reservas"),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text("Salas"),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Perfil"),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(3);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: _logout,
              ),
            ],
          ),
        ),

        // =======================
        // Conteúdo da aba atual
        // =======================
        body: _pages[_selectedIndex],

        // =======================
        // FAB central (QR Code)
        // =======================
        floatingActionButton: FloatingActionButton(
          onPressed: _openQRScanner,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1ABC9C),
            ),
            child: const Icon(Icons.qr_code_scanner,
                size: 32, color: Colors.white),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // =======================
        // BottomAppBar apenas com ícones
        // =======================
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          color: const Color(0xFF1ABC9C),
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 0),
                  _buildNavItem(Icons.calendar_today, 1),
                  const SizedBox(width: 40),
                  _buildNavItem(Icons.star, 2),
                  _buildNavItem(Icons.person, 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// =======================
  /// Cria item do BottomAppBar (somente ícone)
  /// =======================
  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      onPressed: () => _onItemTapped(index),
      iconSize: 28,
      padding: const EdgeInsets.all(0),
      constraints: const BoxConstraints(),
    );
  }
}

/// =======================
/// Tela de leitura de QR Code
/// =======================
class QRViewPage extends StatefulWidget {
  final Function(String) onScan;

  const QRViewPage({super.key, required this.onScan});

  @override
  State<QRViewPage> createState() => _QRViewPageState();
}

class _QRViewPageState extends State<QRViewPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR Code')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: (QRViewController controller) {
          this.controller = controller;
          controller.scannedDataStream.listen((scanData) {
            widget.onScan(scanData.code!);
          });
        },
      ),
    );
  }
}
