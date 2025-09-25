import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- NEW: Import the QR Code screen ---
// Make sure this path is correct for your project structure
import 'qrcode.dart';

final supabase = Supabase.instance.client;

/// Tela para editar uma sala existente, gerenciar seus itens e horários
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
  final TextEditingController _statusController = TextEditingController();

  // ===================== ITENS =====================
  List<Map<String, dynamic>> todosItens = [];
  List<Map<String, dynamic>> itensSala = [];
  Map<String, TextEditingController> quantidadeControllers = {};

  // ===================== HORÁRIOS =====================
  List<Map<String, dynamic>> horariosExistentes = []; // Apenas leitura
  List<Map<String, TextEditingController>> horariosEdicao = []; // Para edição/adicionar

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initSala();
  }

  // ===================== INICIALIZAÇÃO =====================
  Future<void> _initSala() async {
    // Inicializa os campos da sala
    _nomeController.text = widget.sala['nome'] ?? '';
    _capacidadeController.text = widget.sala['capacidade']?.toString() ?? '';
    _localizacaoController.text = widget.sala['localizacao'] ?? '';
    _urlController.text = widget.sala['url'] ?? '';
    _statusController.text = widget.sala['status'] ?? 'disponível';

    // Busca dados do banco
    await fetchTodosItens();
    await fetchItensSala();
    await fetchHorarios();
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

  /// Busca itens associados à sala
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

  /// Busca os horários existentes da sala
  Future<void> fetchHorarios() async {
    try {
      final response = await supabase
          .from('salas_horarios')
          .select()
          .eq('sala_id', widget.sala['id']);
      final List<Map<String, dynamic>> data =
      List<Map<String, dynamic>>.from(response);

      // Horários apenas para exibição
      horariosExistentes = data;

      // Horários para edição/adicionar
      horariosEdicao.clear();
      for (var h in data) {
        horariosEdicao.add({
          'inicio': TextEditingController(text: h['horario_inicio'] ?? ''),
          'fim': TextEditingController(text: h['horario_fim'] ?? ''),
        });
      }

      setState(() {});
    } catch (e) {
      debugPrint("Erro ao buscar horários da sala: $e");
    }
  }

  // ===================== ADICIONAR/REMOVER ITENS =====================
  void addItem(Map<String, dynamic> item) {
    final exists = itensSala.any((i) => i['item_id'] == item['id']);
    if (exists) return;
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

  // ===================== ADICIONAR/REMOVER HORÁRIOS =====================
  void addHorario() {
    setState(() {
      horariosEdicao.add({
        'inicio': TextEditingController(),
        'fim': TextEditingController(),
      });
    });
  }

  void removeHorario(int index) {
    setState(() {
      horariosEdicao.removeAt(index);
    });
  }

  // ===================== SALVAR SALA =====================
  Future<void> _salvarSala() async {
    final nome = _nomeController.text.trim();
    final capacidade = int.tryParse(_capacidadeController.text.trim()) ?? 0;
    final localizacao = _localizacaoController.text.trim();
    final url = _urlController.text.trim();
    final status = _statusController.text.trim();

    if (nome.isEmpty || capacidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha os campos obrigatórios!")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // ===================== ATUALIZA DADOS DA SALA =====================
      await supabase.from('salas').update({
        'nome': nome,
        'capacidade': capacidade,
        'localizacao': localizacao,
        'url': url,
        'status': status,
      }).eq('id', widget.sala['id']);

      // ===================== ATUALIZA ITENS =====================
      for (var item in itensSala) {
        final quantidade =
            int.tryParse(quantidadeControllers[item['item_id']]?.text ?? '1') ??
                1;
        await supabase.from('salas_itens').upsert({
          'sala_id': widget.sala['id'],
          'item_id': item['item_id'],
          'quantidade': quantidade,
        });
      }

      // ===================== ATUALIZA HORÁRIOS =====================
      // Apaga todos os horários antigos
      await supabase.from('salas_horarios').delete().eq('sala_id', widget.sala['id']);

      // Insere os horários novos/editados
      for (var h in horariosEdicao) {
        final inicio = h['inicio']!.text.trim();
        final fim = h['fim']!.text.trim();
        if (inicio.isEmpty || fim.isEmpty) continue;

        await supabase.from('salas_horarios').insert({
          'sala_id': widget.sala['id'],
          'horario_inicio': inicio,
          'horario_fim': fim,
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
        // --- NEW: Add the actions property for the QR code button ---
        actions: [
          IconButton(
            icon: const Icon(Icons.import_contacts), // QR Code Icon
            tooltip: 'Gerar QR Code da Sala', // Text that appears on long press
            onPressed: () {
              // Get the unique ID of the current room
              final String salaId = widget.sala['id'].toString();

              // Navigate to the QRCodeScreen, passing the room ID as data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRCodeScreen(qrData: salaId),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== CAMPOS DA SALA ======
            buildTextField(
                _nomeController, "Nome da Sala", Icons.meeting_room),
            buildTextField(_capacidadeController, "Capacidade", Icons.people,
                keyboardType: TextInputType.number),
            buildTextField(_localizacaoController, "Localização", Icons.place),
            buildTextField(_urlController, "URL da Imagem", Icons.image),
            buildTextField(_statusController, "Status", Icons.info),
            const SizedBox(height: 16),

            // ====== HORÁRIOS EXISTENTES (LISTA) ======
            const Text("Horários Atuais da Sala",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            horariosExistentes.isEmpty
                ? const Text("Nenhum horário cadastrado.")
                : Column(
              children: horariosExistentes
                  .map((h) => ListTile(
                title: Text(
                    "${h['horario_inicio']} - ${h['horario_fim']}"),
                leading: const Icon(Icons.access_time),
              ))
                  .toList(),
            ),
            const Divider(height: 32),

            // ====== CRIAÇÃO / EDIÇÃO DE HORÁRIOS ======
            const Text("Adicionar / Editar Horários",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...horariosEdicao.asMap().entries.map((entry) {
              final index = entry.key;
              final h = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: buildTextField(
                        h['inicio']!, "Início (HH:MM)", Icons.access_time),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildTextField(
                        h['fim']!, "Fim (HH:MM)", Icons.access_time),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => removeHorario(index),
                  ),
                ],
              );
            }).toList(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: addHorario,
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Horário"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C)),
            ),
            const SizedBox(height: 16),

            // ====== ITENS DA SALA ======
            const Text("Itens disponíveis",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...todosItens.map((item) {
              final exists =
              itensSala.any((i) => i['item_id'] == item['id']);
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
            const Text("Itens da Sala",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 6),
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
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1ABC9C)),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}