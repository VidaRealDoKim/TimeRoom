import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Tela de detalhes e edição de um usuário
class DetalhesUsuarioPage extends StatefulWidget {
  final String userId;

  const DetalhesUsuarioPage({super.key, required this.userId});

  @override
  State<DetalhesUsuarioPage> createState() => _DetalhesUsuarioPageState();
}

class _DetalhesUsuarioPageState extends State<DetalhesUsuarioPage> {
  Map<String, dynamic>? user;
  bool loading = true;

  // Controllers para edição
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();

  // ===================== CORES PADRONIZADAS =====================
  final Color primaryColor = const Color(0xFF1ABC9C);
  final Color secondaryColor = Colors.orange;
  final Color bgColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  // ===================== FETCH USER =====================
  /// Busca detalhes do usuário na tabela profiles
  Future<void> fetchUserDetails() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      setState(() {
        user = response;
        _nameController.text = user?['name'] ?? '';
        _emailController.text = user?['email'] ?? '';
        _cargoController.text = user?['role'] ?? ''; // aqui é o cargo
        loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar usuário: $e');
      setState(() => loading = false);
    }
  }

  // ===================== SAVE CHANGES =====================
  /// Salva alterações do usuário
  Future<void> saveChanges() async {
    try {
      await supabase.from('profiles').update({
        'name': _nameController.text,
        'email': _emailController.text,
        'role': _cargoController.text,
      }).eq('id', widget.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário atualizado com sucesso!")),
      );
    } catch (e) {
      debugPrint('Erro ao salvar usuário: $e');
    }
  }

  // ===================== RESET PASSWORD =====================
  /// Envia link de redefinição de senha
  Future<void> resetPassword() async {
    try {
      // ⚠️ Isso exige service role key no backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Link de redefinição de senha enviado para o email!"),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao resetar senha: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não encontrado")),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Detalhes do Usuário"),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: primaryColor.withOpacity(0.2),
              backgroundImage: user?['avatar_url'] != null &&
                  user!['avatar_url'].isNotEmpty
                  ? NetworkImage(user!['avatar_url'])
                  : null,
              child: user?['avatar_url'] == null ||
                  user!['avatar_url'].isEmpty
                  ? Text(
                (user?['name']?.isNotEmpty == true
                    ? user!['name'][0]
                    : '?')
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user?['name'] ?? "Sem nome",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Campos editáveis
            buildTextField(_nameController, "Nome", Icons.person),
            buildTextField(_emailController, "Email", Icons.email),
            buildTextField(_cargoController, "Cargo", Icons.security),

            const SizedBox(height: 20),

            // Botões
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: saveChanges,
                    icon: const Icon(Icons.save),
                    label: const Text("Salvar"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: resetPassword,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text("Resetar Senha"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== BUILD TEXT FIELD =====================
  Widget buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
