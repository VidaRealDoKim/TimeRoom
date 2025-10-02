import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Página de edição de perfil do usuário.
/// - Permite editar nome, email, bio e senha.
/// - Permite trocar/remover avatar.
/// - Permite excluir a conta.
class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loadingPerfil = true;
  bool _salvando = false;

  String? _avatarUrl;
  String? _name;
  String? _email;
  String? _bio;
  DateTime? _createdAt;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  /// Busca os dados do usuário logado
  Future<void> _fetchUserProfile() async {
    setState(() => _loadingPerfil = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (!mounted) return;

      setState(() {
        _name = response['name'] ?? '';
        _email = response['email'] ?? '';
        _avatarUrl = response['avatar_url'];
        _bio = response['bio'] ?? '';
        _createdAt = DateTime.tryParse(response['created_at'] ?? '');

        _nameController.text = _name!;
        _emailController.text = _email!;
        _bioController.text = _bio!;
        _loadingPerfil = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPerfil = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Faz upload de avatar no Supabase e deleta o antigo
  Future<void> _uploadAvatar(ImageSource source) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final storage = _supabase.storage.from('avatars');

      // Deleta avatar antigo
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        try {
          final oldName = Uri.parse(_avatarUrl!).pathSegments.last.split('?').first;
          await storage.remove([oldName]);
        } catch (_) {}
      }

      // Upload novo
      await storage.upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = storage.getPublicUrl(fileName);

      await _supabase.from('profiles').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (!mounted) return;
      setState(() => _avatarUrl = publicUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto atualizada!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no upload: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Remove avatar atual
  Future<void> _removerAvatar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _avatarUrl == null || _avatarUrl!.isEmpty) return;

    try {
      final storage = _supabase.storage.from('avatars');
      final fileName = Uri.parse(_avatarUrl!).pathSegments.last.split('?').first;

      await storage.remove([fileName]);

      await _supabase
          .from('profiles')
          .update({'avatar_url': '', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      if (!mounted) return;
      setState(() => _avatarUrl = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto removida!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover foto: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Atualiza informações do perfil
  Future<void> _updateProfile() async {
    setState(() => _salvando = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update({
        'name': _nameController.text,
        'email': _emailController.text,
        'bio': _bioController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (!mounted) return;
      setState(() => _salvando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Atualiza senha
  Future<void> _alterarSenha() async {
    final senha = _senhaController.text;
    if (senha.isEmpty) return;

    try {
      await _supabase.auth.updateUser(UserAttributes(password: senha));
      if (!mounted) return;
      _senhaController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao alterar senha: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Exclui a conta do usuário
  Future<void> _excluirConta() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir conta"),
        content: const Text("Tem certeza? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('profiles').delete().eq('id', user.id);
      await _supabase.auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_loadingPerfil) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: colors.surface, // ✅ corrigido (antes era background)
        actions: [
          IconButton(
            onPressed: _excluirConta,
            icon: Icon(Icons.delete_forever, color: colors.error),
            tooltip: "Excluir Conta",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? Icon(Icons.person, size: 50, color: colors.onSurface)
                          : null,
                      backgroundColor: colors.surface,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'gallery') await _uploadAvatar(ImageSource.gallery);
                          if (value == 'camera') await _uploadAvatar(ImageSource.camera);
                          if (value == 'remove') await _removerAvatar();
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'gallery', child: Text("Galeria")),
                          const PopupMenuItem(value: 'camera', child: Text("Câmera")),
                          if (_avatarUrl != null) const PopupMenuItem(value: 'remove', child: Text("Remover Foto")),
                        ],
                        child: CircleAvatar(
                          backgroundColor: colors.primary.withAlpha(200),
                          radius: 20,
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Formulário
              _buildProfileForm(colors),

              const SizedBox(height: 24),

              // Alterar senha
              _buildPasswordForm(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm(ColorScheme colors) {
    return Card(
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Nome", border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: "E-mail", border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _bioController, decoration: InputDecoration(labelText: "Bio", border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            if (_createdAt != null)
              Text("Conta criada em: ${_createdAt!.day}/${_createdAt!.month}/${_createdAt!.year}", style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _salvando ? null : _updateProfile,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: _salvando
                  ? CircularProgressIndicator(color: colors.onPrimary)
                  : const Text("Salvar Alterações"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm(ColorScheme colors) {
    return Card(
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _senhaController, obscureText: true, decoration: const InputDecoration(labelText: "Nova Senha", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _alterarSenha,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("Alterar Senha"),
            ),
          ],
        ),
      ),
    );
  }
}
