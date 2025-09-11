import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminSalasPage extends StatefulWidget {
  const AdminSalasPage({super.key});

  @override
  State<AdminSalasPage> createState() => _AdminSalasPageState();
}

class _AdminSalasPageState extends State<AdminSalasPage> {
  List<Map<String, dynamic>> salas = [];

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _capacidadeController = TextEditingController();
  final TextEditingController _localizacaoController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSalas();
  }

  // ===================== FETCH =====================
  Future<void> fetchSalas() async {
    try {
      final response = await supabase
          .from('salas')
          .select()
          .order('created_at', ascending: false) as List;
      setState(() => salas = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Erro ao buscar salas: $e');
    }
  }

  // ===================== CREATE =====================
  Future<void> createSala(
      String nome, int capacidade, String localizacao, String url) async {
    try {
      await supabase.from('salas').insert({
        'nome': nome,
        'capacidade': capacidade,
        'localizacao': localizacao,
        'url': url,
      });
      fetchSalas();
      _nomeController.clear();
      _capacidadeController.clear();
      _localizacaoController.clear();
      _urlController.clear();
    } catch (e) {
      debugPrint('Erro ao criar sala: $e');
    }
  }

  // ===================== DELETE =====================
  Future<void> deleteSalaWithConfirm(String id, String nome) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Sala'),
        content: Text('Tem certeza que deseja excluir a sala "$nome"?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Excluir'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('salas').delete().eq('id', id);
        fetchSalas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sala excluída com sucesso!')),
        );
      } catch (e) {
        debugPrint('Erro ao deletar sala: $e');
      }
    }
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // fundo claro
      appBar: AppBar(
        title: const Text(
          'Gerenciar Salas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ===================== FORM =====================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  buildTextField(_nomeController, "Nome da Sala", Icons.meeting_room),
                  buildTextField(_capacidadeController, "Capacidade", Icons.people,
                      keyboardType: TextInputType.number),
                  buildTextField(_localizacaoController, "Localização", Icons.place),
                  buildTextField(_urlController, "URL da Imagem", Icons.image),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1ABC9C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final nome = _nomeController.text;
                        final capacidade =
                            int.tryParse(_capacidadeController.text) ?? 0;
                        final localizacao = _localizacaoController.text;
                        final url = _urlController.text;
                        if (nome.isNotEmpty && capacidade > 0) {
                          createSala(nome, capacidade, localizacao, url);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Criar Sala',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ===================== LIST =====================
          Expanded(
            child: salas.isEmpty
                ? const Center(
              child: Text(
                "Nenhuma sala cadastrada",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: salas.length,
              itemBuilder: (context, index) {
                final sala = salas[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: sala['url'] != null &&
                        sala['url'].toString().isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        sala['url'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
                      ),
                    )
                        : const CircleAvatar(
                      backgroundColor: Color(0xFFE0F2F1),
                      radius: 28,
                      child: Icon(Icons.meeting_room,
                          size: 32, color: Colors.teal),
                    ),
                    title: Text(
                      sala['nome'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Capacidade: ${sala['capacidade']}'),
                        Text('Localização: ${sala['localizacao']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          deleteSalaWithConfirm(sala['id'], sala['nome']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===================== INPUT FIELD REUTILIZÁVEL =====================
  Widget buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
