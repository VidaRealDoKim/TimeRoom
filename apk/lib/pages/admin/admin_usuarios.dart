import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detalhes_usuario.dart';

final supabase = Supabase.instance.client;

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // ===================== FETCH =====================
  Future<void> fetchUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false) as List;
      setState(() => users = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Erro ao buscar usuários: $e');
    }
  }

  // ===================== UPDATE ROLE =====================
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
      fetchUsers();
    } catch (e) {
      debugPrint('Erro ao atualizar role: $e');
    }
  }

  // ===================== DELETE =====================
  Future<void> deleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Usuário'),
        content: const Text('Tem certeza que deseja excluir este usuário?'),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('profiles').delete().eq('id', userId);
        fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuário excluído com sucesso!")),
        );
      } catch (e) {
        debugPrint('Erro ao deletar usuário: $e');
      }
    }
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Gerenciar Usuários',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
      ),
      body: users.isEmpty
          ? const Center(
        child: Text(
          "Nenhum usuário encontrado",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalhesUsuarioPage(userId: user['id']),
                ),
              ).then((_) => fetchUsers()); // Atualiza ao voltar
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar do usuário
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE0F2F1),
                    child: Text(
                      (user['name']?.isNotEmpty == true
                          ? user['name'][0]
                          : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1ABC9C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Informações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Sem nome',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user['email'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Role: ${user['role']}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ações rápidas
                  Column(
                    children: [
                      DropdownButton<String>(
                        value: user['role'],
                        underline: const SizedBox(),
                        items: ['user', 'admin']
                            .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            updateUserRole(user['id'], val);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteUser(user['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
