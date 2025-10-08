// -----------------------------------------------------------------------------
// dashboard.dart
// Tela principal do usuário com BottomAppBar, Drawer lateral, tema claro/escuro
// e integração com Supabase + Provider para controle de tema.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

// Providers e páginas
import 'package:apk/providers/theme_provider.dart';
import 'package:apk/user/perfil/perfil.dart';
import 'package:apk/user/reserva/pages/minhas_reservas.dart';
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
  Map<String, dynamic>? _profile;

  // Páginas principais
  final List<Widget> _pages = const [
    HomePage(),
    MinhasReservasPage(),
    SalasFavoritasPage(),
    PerfilPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // -----------------------------------------------------------------------------
  // Carrega perfil do usuário logado no Supabase
  // -----------------------------------------------------------------------------
  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) setState(() => _profile = response as Map<String, dynamic>?);
    }
  }

  // -----------------------------------------------------------------------------
  // Controle de navegação inferior
  // -----------------------------------------------------------------------------
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  // -----------------------------------------------------------------------------
  // Logout com confirmação
  // -----------------------------------------------------------------------------
  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Logout"),
        content: const Text("Você realmente deseja sair da sua conta?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

  // -----------------------------------------------------------------------------
  // Scanner de QR Code -> abre Detalhes da sala
  // -----------------------------------------------------------------------------
  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRViewPage(
          onScan: (String salaId) async {
            Navigator.pop(context); // fecha scanner

            // Buscar dados da sala
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

  // -----------------------------------------------------------------------------
  // Construção da interface principal
  // -----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          centerTitle: true,
          title: Image.asset('assets/LogoHorizontal.png', height: 30),
        ),

        // Drawer lateral com dados do usuário e logout
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
                title: const Text("Salas Favoritas"),
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

        // Conteúdo dinâmico das páginas
        body: _pages[_selectedIndex],

        // Botão de escanear QR Code
        floatingActionButton: FloatingActionButton(
          onPressed: _openQRScanner,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: const Icon(Icons.qr_code_scanner, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // BottomAppBar com integração ao tema
        bottomNavigationBar: BottomAppBar(
          color: theme.colorScheme.primary, // fundo dinâmico
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          elevation: 6,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 0, theme),
                _buildNavItem(Icons.calendar_today, 1, theme),
                const SizedBox(width: 40),
                _buildNavItem(Icons.star, 2, theme),
                _buildNavItem(Icons.person, 3, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // Ícones da BottomAppBar com cores de acordo com o tema
  // -----------------------------------------------------------------------------
  Widget _buildNavItem(IconData icon, int index, ThemeData theme) {
    final isSelected = _selectedIndex == index;

    return IconButton(
      icon: Icon(
        icon,
        color: Colors.white,
      ),
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
