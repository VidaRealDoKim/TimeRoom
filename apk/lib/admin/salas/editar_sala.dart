import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Tela para criar ou editar uma sala e gerenciar seus itens
/// Caso [sala] seja null, a tela cria uma nova sala
class EditarSalaPage extends StatefulWidget {
  final Map<String, dynamic>? sala;
  const EditarSalaPage({super.key, this.sala});

  @override
  State<EditarSalaPage> createState() => _EditarSalaPageState();
}

class _EditarSalaPageState extends State<EditarSalaPage> {
  // ===================== CONTROLLERS =====================
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _capacidadeController = TextEditingController();
  final TextEditingController _localizacaoController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  // ===================== LISTAS DE ITENS =====================
  List<Map<String, dynamic>> todosItens = []; // Todos os itens do banco
  List<Map<String, dynamic>> itensSala = []; // Itens associados à sala
  Map<String, TextEditingController> quantidadeControllers = {}; // Controladores de quantidade

  bool _loading = false; // Indica carregamento

  @override
  void initState() {
    super.initState();
    _initSala();
    _urlController.addListener(() => setState(() {})); // Atualiza preview da imagem
  }

  // ===================== INICIALIZAÇÃO =====================
  Future<void> _initSala() async {
    if (widget.sala != null) {
      _nomeController.text = widget.sala!['nome'] ?? '';
      _capacidadeController.text = widget.sala!['capacidade']?.toString() ?? '';
      _localizacaoController.text = widget.sala!['localizacao'] ?? '';
      _urlController.text = widget.sala!['url'] ?? '';
      _statusController.text = widget.sala!['status'] ?? 'disponível';
    }
    await fetchTodosItens();
    if (widget.sala != null) await fetchItensSala();
  }

  /// Busca todos os itens cadastrados no banco
  Future<void> fetchTodosItens() async {
    try {
      final response = await supabase.from('itens').select();
      setState(() => todosItens = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Erro ao buscar itens: $e");
    }
  }

  /// Busca os itens já associados à sala
  Future<void> fetchItensSala() async {
    if (widget.sala == null) return;
    try {
      final response = await supabase
          .from('salas_itens')
          .select('item_id, quantidade, itens(nome, url)')
          .eq('sala_id', widget.sala!['id']);
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
  /// Adiciona um item existente à sala
  void addItem(Map<String, dynamic> item) {
    final exists = itensSala.any((i) => i['item_id'] == item['id']);
    if (exists) return; // Não adiciona duplicado
    setState(() {
      itensSala.add({
        'item_id': item['id'],
        'quantidade': 1,
        'itens': {'nome': item['nome'], 'url': item['url'] ?? ''},
      });
      quantidadeControllers[item['id']] = TextEditingController(text: '1');
    });
  }

  /// Remove item da sala
  void removeItem(Map<String, dynamic> item) async {
    if (widget.sala != null) {
      try {
        await supabase
            .from('salas_itens')
            .delete()
            .eq('sala_id', widget.sala!['id'])
            .eq('item_id', item['item_id']);
      } catch (e) {
        debugPrint("Erro ao remover item: $e");
      }
    }
    quantidadeControllers.remove(item['item_id']);
    itensSala.removeWhere((i) => i['item_id'] == item['item_id']);
    setState(() {});
  }

  // ===================== SALVAR SALA =====================
  Future<void> _salvarSala() async {
    final nome = _nomeController.text.trim();
    final capacidade = int.tryParse(_capacidadeController.text.trim()) ?? 0;
    final localizacao = _localizacaoController.text.trim();
    final url = _urlController.text.trim();
    final status = _statusController.text.trim();

    if (nome.isEmpty || capacidade <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Preencha os campos obrigatórios!")));
      return;
    }

    setState(() => _loading = true);
    try {
      String salaId = widget.sala?['id'];
      if (widget.sala != null) {
        await supabase.from('salas').update({
          'nome': nome,
          'capacidade': capacidade,
          'localizacao': localizacao,
          'url': url,
          'status': status,
        }).eq('id', salaId);
      } else {
        final response = await supabase.from('salas').insert({
          'nome': nome,
          'capacidade': capacidade,
          'localizacao': localizacao.isEmpty ? null : localizacao,
          'url': url.isEmpty ? null : url,
          'status': status,
        }).select().single();
        salaId = response['id'];
      }

      // Atualiza itens da sala
      for (var item in itensSala) {
        final quantidade =
            int.tryParse(quantidadeControllers[item['item_id']]?.text ?? '1') ?? 1;
        await supabase.from('salas_itens').upsert({
          'sala_id': salaId,
          'item_id': item['item_id'],
          'quantidade': quantidade,
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Sala salva com sucesso!")));
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Erro ao salvar sala: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ===================== CRIAR ITEM NOVO =====================
  /// Cria novo item diretamente da tela de sala
  Future<void> _criarItem() async {
    final nomeController = TextEditingController();
    final urlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Criar Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Nome")),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: "URL da Imagem")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              final url = urlController.text.trim();
              if (nome.isEmpty) return;

              final response = await supabase.from('itens').insert({
                'nome': nome,
                'url': url.isEmpty ? null : url,
              }).select().single();

              setState(() {
                todosItens.add(response);
                addItem(response); // Adiciona automaticamente à sala
              });

              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sala != null ? "Editar Sala" : "Nova Sala"),
        backgroundColor: const Color(0xFF1ABC9C),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ====== IMAGEM DA SALA ======
            GestureDetector(
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Editar URL da Imagem"),
                    content: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(labelText: "URL da Imagem"),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Salvar")),
                    ],
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _urlController.text.isNotEmpty
                    ? Image.network(_urlController.text,
                    height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100))
                    : Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 100, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ====== CAMPOS DA SALA ======
            buildTextField(_nomeController, "Nome da Sala", Icons.meeting_room),
            buildTextField(_capacidadeController, "Capacidade", Icons.people, keyboardType: TextInputType.number),
            buildTextField(_localizacaoController, "Localização", Icons.place),
            buildTextField(_statusController, "Status", Icons.info),

            const SizedBox(height: 20),
            // ====== ITENS DA SALA ======
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Itens da Sala", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _criarItem,
                  icon: const Icon(Icons.add),
                  label: const Text("Novo Item"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1ABC9C)),
                )
              ],
            ),
            const SizedBox(height: 8),
            ...itensSala.map((item) {
              final controller = quantidadeControllers[item['item_id']]!;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: item['itens']['url'] != null && item['itens']['url'].isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item['itens']['url'], width: 50, height: 50, fit: BoxFit.cover),
                  )
                      : const Icon(Icons.inventory_2),
                  title: Text(item['itens']['nome']),
                  trailing: SizedBox(
                    width: 90,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
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
            // ====== BOTÃO SALVAR ======
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Salvar Sala"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _salvarSala,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== WIDGET DE CAMPO =====================
  Widget buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1ABC9C)),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}
