import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detalhes_usuario.dart';

final supabase = Supabase.instance.client;

/// Tela de administração de usuários
class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  List<Map<String, dynamic>> users = [];
  bool _loading = false;

  // Controllers para criar novo usuário
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  String _roleSelecionada = 'user';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // ===================== FETCH USERS =====================
  /// Busca todos os usuários no Supabase
  Future<void> fetchUsers() async {
    setState(() => _loading = true);
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false) as List;
      setState(() => users = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Erro ao buscar usuários: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ===================== UPDATE ROLE =====================
  /// Atualiza a role de um usuário
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
      fetchUsers();
    } catch (e) {
      debugPrint('Erro ao atualizar role: $e');
    }
  }

  // ===================== DELETE USER =====================
  /// Deleta um usuário da tabela profiles
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

  // ===================== CREATE USER =====================
  /// Cria um novo usuário via Supabase Auth e insere no profile
  Future<void> criarUsuario() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final nome = _nomeController.text.trim();
    final role = _roleSelecionada;

    if (email.isEmpty || senha.isEmpty || nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos!")),
      );
      return;
    }

    try {
      // Cria usuário via Supabase Admin
      final response = await supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: senha,
          userMetadata: {'name': nome, 'role': role},
        ),
      );

      // Adiciona perfil na tabela profiles
      await supabase.from('profiles').insert({
        'id': response.user?.id,
        'name': nome,
        'email': email,
        'role': role,
      });

      // Limpa campos
      _emailController.clear();
      _senhaController.clear();
      _nomeController.clear();
      _roleSelecionada = 'user';

      fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário criado com sucesso!")),
      );
    } catch (e) {
      debugPrint('Erro ao criar usuário: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao criar usuário: $e")),
      );
    }
  }

  // ===================== BUILD USER CARD =====================
  Widget buildUserCard(Map<String, dynamic> user) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalhesUsuarioPage(userId: user['id']),
          ),
        ).then((_) => fetchUsers());
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
            // Avatar real ou letra inicial
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE0F2F1),
              backgroundImage: user['avatar_url'] != null &&
                  user['avatar_url'].isNotEmpty
                  ? NetworkImage(user['avatar_url'])
                  : null,
              child: user['avatar_url'] == null || user['avatar_url'].isEmpty
                  ? Text(
                (user['name']?.isNotEmpty == true ? user['name'][0] : '?')
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1ABC9C),
                ),
              )
                  : null,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Abre modal para criar usuário
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text("Criar Novo Usuário"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                              labelText: "Nome", prefixIcon: Icon(Icons.person)),
                        ),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                              labelText: "Email", prefixIcon: Icon(Icons.email)),
                        ),
                        TextField(
                          controller: _senhaController,
                          decoration: const InputDecoration(
                              labelText: "Senha", prefixIcon: Icon(Icons.lock)),
                          obscureText: true,
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: _roleSelecionada,
                          items: ['user', 'admin']
                              .map((r) =>
                              DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _roleSelecionada = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        criarUsuario();
                      },
                      child: const Text("Criar"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(
        child: Text(
          "Nenhum usuário encontrado",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return buildUserCard(user);
          },
        ),
      ),
    );
  }
}
