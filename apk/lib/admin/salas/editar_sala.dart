import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Tela para editar uma sala existente e gerenciar seus itens
class EditarSalaPage extends StatefulWidget {
  final Map<String, dynamic> sala;

  const EditarSalaPage({super.key, required this.sala});

  @override
  State<EditarSalaPage> createState() => _EditarSalaPageState();
}

class _EditarSalaPageState extends State<EditarSalaPage> {
  // ===================== CONTROLLERS =====================
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _capacidadeController = TextEditingController();
  final TextEditingController _localizacaoController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _horarioInicioController = TextEditingController();
  final TextEditingController _horarioFimController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  // ===================== ITENS =====================
  List<Map<String, dynamic>> todosItens = [];
  List<Map<String, dynamic>> itensSala = [];
  Map<String, TextEditingController> quantidadeControllers = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initSala();
  }

  /// Inicializa campos da sala e busca itens
  Future<void> _initSala() async {
    _nomeController.text = widget.sala['nome'] ?? '';
    _capacidadeController.text = widget.sala['capacidade']?.toString() ?? '';
    _localizacaoController.text = widget.sala['localizacao'] ?? '';
    _urlController.text = widget.sala['url'] ?? '';
    _horarioInicioController.text = widget.sala['horario_inicio'] ?? '';
    _horarioFimController.text = widget.sala['horario_fim'] ?? '';
    _statusController.text = widget.sala['status'] ?? 'disponível';

    await fetchTodosItens();
    await fetchItensSala();
  }

  /// Busca todos os itens disponíveis
  Future<void> fetchTodosItens() async {
    try {
      final response = await supabase.from('itens').select();
      setState(() {
        todosItens = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Erro ao buscar itens: $e");
    }
  }

  /// Busca os itens já associados à sala
  Future<void> fetchItensSala() async {
    try {
      final response = await supabase
          .from('salas_itens')
          .select('item_id, quantidade, itens(nome)')
          .eq('sala_id', widget.sala['id']);
      itensSala = List<Map<String, dynamic>>.from(response);

      quantidadeControllers.clear();
      for (var item in itensSala) {
        quantidadeControllers[item['item_id']] =
            TextEditingController(text: item['quantidade']?.toString() ?? '1');
      }

      setState(() {});
    } catch (e) {
      debugPrint("Erro ao buscar itens da sala: $e");
    }
  }

  // ===================== ADICIONAR/REMOVER ITENS =====================
  void addItem(Map<String, dynamic> item) {
    setState(() {
      itensSala.add({
        'item_id': item['id'],
        'quantidade': 1,
        'itens': {'nome': item['nome']},
      });
      quantidadeControllers[item['id']] = TextEditingController(text: '1');
    });
  }

  void removeItem(Map<String, dynamic> item) async {
    try {
      await supabase
          .from('salas_itens')
          .delete()
          .eq('sala_id', widget.sala['id'])
          .eq('item_id', item['item_id']);
      quantidadeControllers.remove(item['item_id']);
      itensSala.removeWhere((i) => i['item_id'] == item['item_id']);
      setState(() {});
    } catch (e) {
      debugPrint("Erro ao remover item: $e");
    }
  }

  // ===================== SALVAR ALTERAÇÕES =====================
  Future<void> _salvarSala() async {
    final nome = _nomeController.text.trim();
    final capacidade = int.tryParse(_capacidadeController.text.trim()) ?? 0;
    final localizacao = _localizacaoController.text.trim();
    final url = _urlController.text.trim();
    final horarioInicio = _horarioInicioController.text.trim();
    final horarioFim = _horarioFimController.text.trim();
    final status = _statusController.text.trim();

    if (nome.isEmpty || capacidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha os campos obrigatórios!")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Atualiza dados da sala
      await supabase.from('salas').update({
        'nome': nome,
        'capacidade': capacidade,
        'localizacao': localizacao,
        'url': url,
        'horario_inicio': horarioInicio,
        'horario_fim': horarioFim,
        'status': status,
      }).eq('id', widget.sala['id']);

      // Atualiza ou insere itens da sala
      for (var item in itensSala) {
        final quantidade = int.tryParse(quantidadeControllers[item['item_id']]?.text ?? '1') ?? 1;

        await supabase.from('salas_itens').upsert({
          'sala_id': widget.sala['id'],
          'item_id': item['item_id'],
          'quantidade': quantidade,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sala atualizada com sucesso!")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Erro ao atualizar sala: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Sala"),
        backgroundColor: const Color(0xFF1ABC9C),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ====== CAMPOS DA SALA ======
            buildTextField(_nomeController, "Nome da Sala", Icons.meeting_room),
            buildTextField(_capacidadeController, "Capacidade", Icons.people,
                keyboardType: TextInputType.number),
            buildTextField(_localizacaoController, "Localização", Icons.place),
            buildTextField(_urlController, "URL da Imagem", Icons.image),
            buildTextField(_horarioInicioController, "Horário Início (HH:MM)", Icons.access_time),
            buildTextField(_horarioFimController, "Horário Fim (HH:MM)", Icons.access_time),
            buildTextField(_statusController, "Status", Icons.info),

            const SizedBox(height: 16),
            const Text("Itens disponíveis", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Lista de itens disponíveis
            ...todosItens.map((item) {
              final exists = itensSala.any((i) => i['item_id'] == item['id']);
              if (exists) return Container();
              return Card(
                child: ListTile(
                  title: Text(item['nome']),
                  trailing: IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => addItem(item),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),
            const Text("Itens da sala", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Lista de itens da sala
            ...itensSala.map((item) {
              final controller = quantidadeControllers[item['item_id']]!;
              return Card(
                child: ListTile(
                  title: Text(item['itens']['nome']),
                  trailing: SizedBox(
                    width: 80,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => removeItem(item),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Salvar Alterações"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _salvarSala,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TEXT FIELD REUTILIZÁVEL =====================
  Widget buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
      }) {
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
