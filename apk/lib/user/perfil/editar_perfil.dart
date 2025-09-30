import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/theme_provider.dart';

/// Página de edição de perfil do usuário.
/// Permite editar nome, email, bio, senha e avatar.
class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
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

  /// Busca os dados do usuário no Supabase e inicializa os campos
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
        _loading = false;
      });
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

  /// Faz upload de avatar para Supabase Storage e deleta o anterior, se existir
  Future<void> _uploadAvatar(ImageSource source) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp${path.extension(file.path)}';
      final storage = _supabase.storage.from('avatars');

      // --- Deleta avatar antigo, se existir ---
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        try {
          final uri = Uri.parse(_avatarUrl!);
          final oldFileName = uri.pathSegments.last.split('?').first; // Remove query string
          await storage.remove([oldFileName]);
        } catch (e) {
          print('Não foi possível deletar avatar antigo: $e');
        }
      }

      // Upload da nova imagem
      await storage.upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // URL pública
      final publicUrl = storage.getPublicUrl(fileName);

      // Atualiza no banco de dados
      await _supabase
          .from('profiles')
          .update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', userId);

      if (!mounted) return;
      setState(() => _avatarUrl = publicUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil atualizada!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Remove o avatar atual do Storage e atualiza o banco de dados
  Future<void> _removerAvatar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _avatarUrl == null || _avatarUrl!.isEmpty) return;

    try {
      final storage = _supabase.storage.from('avatars');
      final uri = Uri.parse(_avatarUrl!);
      final fileName = uri.pathSegments.last.split('?').first;

      // Remove do storage
      await storage.remove([fileName]);

      // Atualiza banco de dados
      await _supabase
          .from('profiles')
          .update({'avatar_url': '', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      if (!mounted) return;
      setState(() => _avatarUrl = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto removida com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Atualiza informações do perfil
  Future<void> _updateProfile() async {
    setState(() => _loading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final updates = {
        'name': _nameController.text,
        'email': _emailController.text,
        'bio': _bioController.text,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('profiles').update(updates).eq('id', userId);

      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
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

  /// Altera a senha do usuário
  Future<void> _alterarSenha() async {
    final senha = _senhaController.text;
    if (senha.isEmpty) return;

    try {
      await _supabase.auth.updateUser(UserAttributes(password: senha));
      if (!mounted) return;
      _senhaController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar senha: $e'),
          backgroundColor: Colors.red,
        ),
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
        content: const Text(
          "Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
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
        SnackBar(
          content: Text('Erro ao excluir conta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: colors.primary,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar com opções de upload e remover
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                      _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
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
                          switch (value) {
                            case 'gallery':
                              await _uploadAvatar(ImageSource.gallery);
                              break;
                            case 'camera':
                              await _uploadAvatar(ImageSource.camera);
                              break;
                            case 'remove':
                              await _removerAvatar();
                              break;
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                              value: 'gallery', child: Text("Galeria")),
                          const PopupMenuItem(
                              value: 'camera', child: Text("Câmera")),
                          if (_avatarUrl != null)
                            const PopupMenuItem(
                                value: 'remove', child: Text("Remover Foto")),
                        ],
                        child: CircleAvatar(
                          backgroundColor:
                          colors.primary.withAlpha((0.8 * 255).toInt()),
                          radius: 20,
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card de informações do perfil
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nome',
                          labelStyle: TextStyle(color: colors.onSurface),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          labelStyle: TextStyle(color: colors.onSurface),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          labelStyle: TextStyle(color: colors.onSurface),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_createdAt != null)
                        Text(
                          "Conta criada em: ${_createdAt!.day}/${_createdAt!.month}/${_createdAt!.year}",
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _loading
                            ? CircularProgressIndicator(color: colors.onPrimary)
                            : const Text('Salvar Alterações'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card de alteração de senha
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _senhaController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          labelStyle: TextStyle(color: colors.onSurface),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _alterarSenha,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.secondary,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Alterar Senha'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
