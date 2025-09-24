import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// -----------------------------------------------------------------------------
// Tela de Perfil do Usuário (Com edição e logout com confirmação)
// -----------------------------------------------------------------------------
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Estado do Widget
  bool _notificacoesAtivadas = true;
  bool _loading = true;
  bool _editMode = false; // Ativa o modo de edição
  String? _avatarUrl;
  String? _name;
  String? _email;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Busca o perfil do usuário logado
  // ---------------------------------------------------------------------------
  Future<void> _fetchUserProfile() async {
    setState(() => _loading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (response != null && mounted) {
        setState(() {
          _name = response['name'] ?? '';
          _email = response['email'] ?? '';
          _avatarUrl = response['avatar_url'];
          _nameController.text = _name!;
          _emailController.text = _email!;
          _avatarController.text = _avatarUrl ?? '';
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
  // Atualiza perfil do usuário no Supabase
  // ---------------------------------------------------------------------------
  Future<void> _updateProfile() async {
    setState(() => _loading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final updates = {
        'name': _nameController.text,
        'email': _emailController.text,
        'avatar_url': _avatarController.text.isNotEmpty
            ? _avatarController.text
            : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('profiles').update(updates).eq('id', userId);

      if (mounted) {
        setState(() {
          _name = _nameController.text;
          _email = _emailController.text;
          _avatarUrl =
          _avatarController.text.isNotEmpty ? _avatarController.text : null;
          _editMode = false;
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar perfil: $e'),
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
          onTap: () {
            setState(() => _editMode = !_editMode);
          },
        ),
        _buildMenuOption(
          icon: Icons.settings_outlined,
          text: 'Configurações',
          // ATUALIZAÇÃO: Navega para a nova tela de configurações.
          onTap: () {
            // Garante que a rota '/config' existe no seu main.dart!
            Navigator.pushNamed(context, '/config');
          },
        ),
        _buildNotificationOption(),
        _buildMenuOption(
          icon: Icons.logout,
          text: 'Log Out',
          onTap: _confirmarLogout,
        ),
        if (_editMode)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1ABC9C),
              ),
              child: const Text('Salvar alterações'),
            ),
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
          child: _editMode
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _avatarController,
                decoration:
                const InputDecoration(labelText: 'URL da Imagem'),
              ),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name ?? '',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                _email ?? '',
                style:
                const TextStyle(fontSize: 14, color: Colors.grey),
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

  // ---------------------------------------------------------------------------
  // Item de notificação
  // ---------------------------------------------------------------------------
  Widget _buildNotificationOption() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading:
      const Icon(Icons.notifications_outlined, color: Colors.black54),
      title: const Text('Notificações', style: TextStyle(fontSize: 16)),
      trailing: Switch(
        value: _notificacoesAtivadas,
        onChanged: (bool value) {
          setState(() => _notificacoesAtivadas = value);
        },
        activeColor: const Color(0xFF1ABC9C),
      ),
    );
  }
}
