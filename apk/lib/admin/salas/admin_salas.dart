import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_salas_itens.dart'; // <- Importa a tela de itens da sala

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

  /// ===================== FETCH SALAS =====================
  Future<void> fetchSalas() async {
    try {
      final response = await supabase
          .from('salas')
          .select()
          .order('created_at', ascending: false);
      setState(() => salas = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Erro ao buscar salas: $e');
    }
  }

  /// ===================== DELETE SALA =====================
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// ===================== UPDATE SALA =====================
  Future<void> editSala(Map<String, dynamic> sala) async {
    _nomeController.text = sala['nome'] ?? '';
    _capacidadeController.text = sala['capacidade']?.toString() ?? '';
    _localizacaoController.text = sala['localizacao'] ?? '';
    _urlController.text = sala['url'] ?? '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Editar Sala"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextField(_nomeController, "Nome da Sala", Icons.meeting_room),
              buildTextField(_capacidadeController, "Capacidade", Icons.people,
                  keyboardType: TextInputType.number),
              buildTextField(_localizacaoController, "Localização", Icons.place),
              buildTextField(_urlController, "URL da Imagem", Icons.image),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1ABC9C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final nome = _nomeController.text;
              final capacidade = int.tryParse(_capacidadeController.text) ?? 0;
              final localizacao = _localizacaoController.text;
              final url = _urlController.text;

              if (nome.isNotEmpty && capacidade > 0) {
                try {
                  await supabase.from('salas').update({
                    'nome': nome,
                    'capacidade': capacidade,
                    'localizacao': localizacao,
                    'url': url,
                  }).eq('id', sala['id']);

                  Navigator.pop(context);
                  fetchSalas();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sala atualizada com sucesso!")),
                  );
                } catch (e) {
                  debugPrint("Erro ao editar sala: $e");
                }
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  /// ===================== SALA CARD =====================
  Widget buildSalaCard(Map<String, dynamic> sala) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: sala['url'] != null && sala['url'].toString().isNotEmpty
                ? Image.network(
              sala['url'],
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 50),
              ),
            )
                : Container(
              height: 150,
              color: Colors.grey[300],
              child: const Icon(Icons.meeting_room, size: 50),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sala['nome'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Capacidade: ${sala['capacidade']}', style: const TextStyle(fontSize: 14)),
                Text('Localização: ${sala['localizacao'] ?? "-"}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal),
                      onPressed: () => editSala(sala),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => deleteSalaWithConfirm(sala['id'], sala['nome']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.inventory_2, color: Colors.orange),
                      tooltip: 'Gerenciar Itens',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminSalaItensPage(sala: sala),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Gerenciar Salas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
      ),
      body: salas.isEmpty
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
          return buildSalaCard(sala);
        },
      ),
    );
  }

  /// ===================== TEXT FIELD =====================
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
