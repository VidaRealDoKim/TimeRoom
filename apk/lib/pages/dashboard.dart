import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ---------------------------------------------------------------------------
/// Página de Perfil do Usuário conectada ao Supabase
/// ---------------------------------------------------------------------------
/// Esta tela:
/// - Busca os dados do usuário logado na tabela `profiles`
/// - Permite editar nome e email via popup
/// - Atualiza o Supabase ao salvar alterações
/// - Possui switch de notificações (apenas local por enquanto)
/// - Permite logout
/// ---------------------------------------------------------------------------
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  // Instância do Supabase
  final supabase = Supabase.instance.client;

  /// Controla o estado do Switch de notificações.
  bool _notificacoesAtivadas = true;

  /// Dados do usuário logado
  String _nomeUsuario = "";
  String _emailUsuario = "";
  String? _avatarUrl;

  /// ID do usuário (UUID da tabela profiles)
  String? _userId;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  /// -------------------------------------------------------------------------
  /// Carrega os dados do usuário logado a partir da tabela `profiles`
  /// -------------------------------------------------------------------------
  Future<void> _carregarPerfil() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      _userId = user.id;

      final response = await supabase
          .from('profiles')
          .select('name, email, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _nomeUsuario = response['name'] ?? '';
          _emailUsuario = response['email'] ?? '';
          _avatarUrl = response['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
    }
  }

  /// -------------------------------------------------------------------------
  /// Atualiza o perfil do usuário no Supabase
  /// -------------------------------------------------------------------------
  Future<void> _atualizarPerfil(String nome, String email) async {
    if (_userId == null) return;

    try {
      await supabase.from('profiles').update({
        'name': nome,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _userId!);

      setState(() {
        _nomeUsuario = nome;
        _emailUsuario = email;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil atualizado com sucesso")),
        );
      }
    } catch (e) {
      debugPrint("Erro ao atualizar perfil: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao atualizar perfil: $e")),
        );
      }
    }
  }

  /// -------------------------------------------------------------------------
  /// Faz logout do usuário
  /// -------------------------------------------------------------------------
  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // -------------------------------------------------------------------------
  // Build da tela
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  /// Constrói o corpo principal da tela de perfil.
  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      children: [
        const SizedBox(height: 20),
        _buildUserInfo(),
        const SizedBox(height: 40),

        _buildMenuOption(
          icon: Icons.person_outline,
          text: 'My Profile',
          onTap: () => _abrirPopupEditarPerfil(context),
        ),
        _buildMenuOption(
          icon: Icons.settings_outlined,
          text: 'Settings',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Abrir configurações...")),
            );
          },
        ),
        _buildNotificationOption(),
        _buildMenuOption(
          icon: Icons.logout,
          text: 'Log Out',
          onTap: _logout,
        ),
      ],
    );
  }

  /// Seção com as informações básicas do usuário
  Widget _buildUserInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: _avatarUrl != null
              ? NetworkImage(_avatarUrl!)
              : const NetworkImage(
              'https://ui-avatars.com/api/?name=User&background=1ABC9C&color=fff'),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _nomeUsuario.isNotEmpty ? _nomeUsuario : "Carregando...",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _emailUsuario.isNotEmpty ? _emailUsuario : "Carregando...",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        )
      ],
    );
  }

  /// Item de menu
  Widget _buildMenuOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black54),
      title: Text(text, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  /// Switch de notificações
  Widget _buildNotificationOption() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notifications_outlined, color: Colors.black54),
      title: const Text('Notification', style: TextStyle(fontSize: 16)),
      trailing: Switch(
        value: _notificacoesAtivadas,
        onChanged: (bool value) {
          setState(() {
            _notificacoesAtivadas = value;
          });
        },
        activeColor: const Color(0xFF1ABC9C),
      ),
    );
  }

  /// Popup para editar perfil
  void _abrirPopupEditarPerfil(BuildContext context) {
    final TextEditingController nomeController =
    TextEditingController(text: _nomeUsuario);
    final TextEditingController emailController =
    TextEditingController(text: _emailUsuario);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Editar Perfil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome",
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1ABC9C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Salvar"),
              onPressed: () {
                _atualizarPerfil(nomeController.text, emailController.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
