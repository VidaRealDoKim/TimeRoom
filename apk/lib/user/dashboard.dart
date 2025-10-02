// -----------------------------------------------------------------------------
// dashboard.dart
// Tela principal do usuário com BottomAppBar, Drawer lateral, tema claro/escuro
// e integração com Supabase.
// -----------------------------------------------------------------------------

import 'package:apk/user/perfil/perfil.dart';
import 'package:apk/user/reserva/pages/minhas_reservas.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

// Telas importadas
import 'favorito/favoritos.dart';
import 'home/home.dart';
import 'home/reservar/detalhes_sala.dart';

final supabase = Supabase.instance.client;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Páginas principais
  final List<Widget> _pages = const [
    HomePage(),
    MinhasReservasPage(), // corrigido de ReservasPage
    SalasFavoritasPage(),
    PerfilPage(),
  ];

  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Carrega perfil do usuário
  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _profile = response as Map<String, dynamic>?;
        });
      }
    }
  }

  // Controle de navegação inferior
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logout com confirmação
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
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Sair"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // Scanner de QR Code -> Detalhes da sala
  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRViewPage(
          onScan: (String salaId) async {
            Navigator.pop(context); // fecha scanner

            // Buscar sala
            final salaResponse = await supabase
                .from('salas')
                .select()
                .eq('id', salaId)
                .maybeSingle();

            if (salaResponse == null) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sala não encontrada!")),
              );
              return;
            }

            // Buscar itens
            final itensResponse = await supabase
                .from('salas_itens')
                .select('itens(nome)')
                .eq('sala_id', salaId);
            final itens = itensResponse
                .map<String>((i) => i['itens']['nome'] as String)
                .toList();

            // Buscar avaliações
            final avaliacoes = await supabase
                .from('feedback_salas')
                .select('nota')
                .eq('sala_id', salaId);
            double media = 0;
            if (avaliacoes.isNotEmpty) {
              media = avaliacoes
                  .map((a) => a['nota'] as int)
                  .reduce((a, b) => a + b) /
                  avaliacoes.length;
            }

            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetalhesSalaPage(
                  sala: {
                    'id': salaResponse['id'],
                    'nome': salaResponse['nome'],
                    'capacidade': salaResponse['capacidade'],
                    'localizacao': salaResponse['localizacao'],
                    'url': salaResponse['url'],
                    'descricao': itens.join(', '),
                    'media_avaliacoes': media,
                    'ocupada': false,
                    'latitude': salaResponse['latitude'],
                    'longitude': salaResponse['longitude'],
                  },
                  dataSelecionada: DateTime.now(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Image.asset('assets/LogoHorizontal.png', height: 30),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: theme.colorScheme.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.onPrimary,
                      backgroundImage: _profile?['avatar_url'] != null
                          ? NetworkImage(_profile!['avatar_url'])
                          : null,
                      child: _profile?['avatar_url'] == null
                          ? Icon(Icons.person,
                          size: 40, color: theme.colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profile?['name'] ?? "Usuário",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _profile?['email'] ?? "",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withOpacity(0.7),
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
        body: _pages[_selectedIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: _openQRScanner,
          backgroundColor: theme.colorScheme.primary,
          child: Icon(Icons.qr_code_scanner,
              size: 32, color: theme.colorScheme.onPrimary),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
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
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.bottomNavigationBarTheme.selectedItemColor
        : theme.bottomNavigationBarTheme.unselectedItemColor;

    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () => _onItemTapped(index),
      iconSize: 28,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

// -----------------------------------------------------------------------------
// Página para leitura do QR Code
// -----------------------------------------------------------------------------
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
        onQRViewCreated: (controller) {
          this.controller = controller;
          controller.scannedDataStream.listen((scanData) {
            if (scanData.code != null) {
              controller.pauseCamera();
              widget.onScan(scanData.code!);
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
