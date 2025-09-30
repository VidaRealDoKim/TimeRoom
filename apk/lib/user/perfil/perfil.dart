import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _avatarUrl;
  String? _name;
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // ---------------------------------------------------------------------------
  // Busca o perfil do usuário logado
  // ---------------------------------------------------------------------------
  Future<void> _fetchUserProfile() async {
    setState(() => _loading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response =
      await _supabase.from('profiles').select().eq('id', userId).single();

      if (response != null && mounted) {
        setState(() {
          _name = response['name'] ?? '';
          _email = response['email'] ?? '';
          _avatarUrl = response['avatar_url'];
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar perfil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Logout com confirmação
  // ---------------------------------------------------------------------------
  Future<void> _confirmarLogout() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Logout'),
          content: const Text('Tem certeza que deseja sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1ABC9C),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
      children: [
        _buildUserInfo(),
        const SizedBox(height: 40),
        _buildMenuOption(
          icon: Icons.person_outline,
          text: 'Editar Perfil',
          onTap: () async {
            // Abre a tela editar_perfil.dart e aguarda retorno
            final atualizado =
            await Navigator.pushNamed(context, '/editarPerfil');
            if (atualizado == true) {
              _fetchUserProfile(); // recarrega os dados ao voltar
            }
          },
        ),
        _buildMenuOption(
          icon: Icons.settings_outlined,
          text: 'Configurações',
          onTap: () {
            Navigator.pushNamed(context, '/config');
          },
        ),
        _buildMenuOption(
          icon: Icons.logout,
          text: 'Log Out',
          onTap: _confirmarLogout,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Seção de informações do usuário
  // ---------------------------------------------------------------------------
  Widget _buildUserInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
              ? NetworkImage(_avatarUrl!)
              : const AssetImage('assets/default_avatar.png') as ImageProvider,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name ?? '',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                _email ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Item de menu
  // ---------------------------------------------------------------------------
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
}
