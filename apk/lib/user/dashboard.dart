import 'package:apk/user/perfil/perfil.dart';
import 'package:apk/user/reserva/reservar_salas.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import 'favorito/favoritos.dart';
import 'home/home.dart';
import '../user/reserva/card/detalhes_sala.dart';

final supabase = Supabase.instance.client;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = const [
    HomePage(),
    ReservasPage(),
    SalasFavoritasPage(),
    PerfilPage(),
  ];
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

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
          _profile = response;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
            // CORREÇÃO: O estilo do botão foi removido para usar a cor do tema.
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
  /// QR Code abre diretamente DetalhesSalaPage
  /// =======================
  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRViewPage(
          onScan: (String salaId) async {
            Navigator.pop(context); // fecha scanner

            // Buscar sala pelo ID
            final salaResponse = await supabase
                .from('salas')
                .select()
                .eq('id', salaId)
                .maybeSingle();

            if (salaResponse == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sala não encontrada!")),
              );
              return;
            }

            // A lógica de buscar itens e avaliações permanece a mesma...
            final itensResponse = await supabase.from('salas_itens').select('itens(nome)').eq('sala_id', salaId);
            final itens = itensResponse.map<String>((i) => i['itens']['nome'] as String).toList();
            final avaliacoes = await supabase.from('feedback_salas').select('nota').eq('sala_id', salaId);
            double media = 0;
            if (avaliacoes.isNotEmpty) {
              media = avaliacoes.map((a) => a['nota'] as int).reduce((a, b) => a + b) / avaliacoes.length;
            }

            // Navegar para DetalhesSalaPage
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
    return SafeArea(
      bottom: false,
      child: Scaffold(
        // CORREÇÃO: A AppBar agora busca as suas cores do tema global.
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Image.asset('assets/LogoHorizontal.png', height: 30),
          // As cores 'backgroundColor' e 'iconTheme' foram removidas para usar o tema.
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                // CORREÇÃO: A cor agora vem do tema, para ser consistente no modo claro e escuro.
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
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
                          ? Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary)
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
                title: const Text("Salas"), // Assumindo que o índice 2 é Favoritos/Salas
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
          // CORREÇÃO: A cor do botão agora vem do tema.
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(
            Icons.qr_code_scanner,
            size: 32,
            // CORREÇÃO: A cor do ícone é definida para contrastar com o fundo.
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        // CORREÇÃO: A cor da BottomAppBar agora é controlada pelo tema.
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
    // CORREÇÃO: As cores dos ícones agora vêm do tema da BottomNavigationBar.
    final color = isSelected
        ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
        : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor;

    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () => _onItemTapped(index),
      iconSize: 28,
      padding: const EdgeInsets.all(0),
      constraints: const BoxConstraints(),
    );
  }
}

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
            if (scanData.code != null) {
              // Garante que a função só é chamada uma vez.
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

