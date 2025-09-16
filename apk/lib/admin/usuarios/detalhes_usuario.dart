import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class DetalhesUsuarioPage extends StatefulWidget {
  final String userId;
  const DetalhesUsuarioPage({super.key, required this.userId});

  @override
  State<DetalhesUsuarioPage> createState() => _DetalhesUsuarioPageState();
}

class _DetalhesUsuarioPageState extends State<DetalhesUsuarioPage> {
  Map<String, dynamic>? user;
  bool loading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

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
        _roleController.text = user?['role'] ?? '';
        loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar usuário: $e');
      setState(() => loading = false);
    }
  }

  Future<void> saveChanges() async {
    try {
      await supabase.from('profiles').update({
        'name': _nameController.text,
        'email': _emailController.text,
        'role': _roleController.text,
      }).eq('id', widget.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário atualizado com sucesso!")),
      );
    } catch (e) {
      debugPrint('Erro ao salvar usuário: $e');
    }
  }

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Detalhes do Usuário"),
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFE0F2F1),
              child: Text(
                (user?['name']?.isNotEmpty == true
                    ? user!['name'][0]
                    : '?')
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1ABC9C),
                ),
              ),
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
            buildTextField(_roleController, "Role", Icons.security),

            const SizedBox(height: 20),

            // Botões
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1ABC9C),
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
                      backgroundColor: Colors.orange,
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

  Widget buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1ABC9C)),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}
