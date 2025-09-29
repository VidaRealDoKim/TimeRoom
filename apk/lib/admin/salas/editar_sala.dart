import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Import do QR Code Screen ---
import 'qrcode.dart';

final supabase = Supabase.instance.client;

/// Tela para editar uma sala existente, gerenciar seus itens, horários e informações adicionais.
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
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // ===================== ITENS =====================
  List<Map<String, dynamic>> todosItens = [];
  List<Map<String, dynamic>> itensSala = [];
  Map<String, TextEditingController> quantidadeControllers = {};

  // ===================== HORÁRIOS =====================
  List<Map<String, dynamic>> horariosExistentes = [];
  List<Map<String, TextEditingController>> horariosEdicao = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initSala();
  }

  /// Inicializa os campos da sala e carrega dados relacionados (itens e horários)
  Future<void> _initSala() async {
    _nomeController.text = widget.sala['nome'] ?? '';
    _capacidadeController.text = widget.sala['capacidade']?.toString() ?? '';
    _localizacaoController.text = widget.sala['localizacao'] ?? '';
    _urlController.text = widget.sala['url'] ?? '';
    _statusController.text = widget.sala['status'] ?? 'disponível';
    _descricaoController.text = widget.sala['descricao'] ?? '';
    _tagsController.text = widget.sala['tags']?.join(', ') ?? '';
    _latitudeController.text = widget.sala['latitude']?.toString() ?? '';
    _longitudeController.text = widget.sala['longitude']?.toString() ?? '';

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

  /// Busca os itens associados à sala
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
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      horariosExistentes = data;

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
    final descricao = _descricaoController.text.trim();
    final tags = _tagsController.text.split(',').map((e) => e.trim()).toList();
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    if (nome.isEmpty || capacidade <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha os campos obrigatórios!")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Atualiza os dados da sala
      await supabase.from('salas').update({
        'nome': nome,
        'capacidade': capacidade,
        'localizacao': localizacao,
        'url': url,
        'status': status,
        'descricao': descricao,
        'tags': tags,
        'latitude': latitude,
        'longitude': longitude,
      }).eq('id', widget.sala['id']);

      // Atualiza itens
      for (var item in itensSala) {
        final quantidade =
            int.tryParse(quantidadeControllers[item['item_id']]?.text ?? '1') ?? 1;
        await supabase.from('salas_itens').upsert({
          'sala_id': widget.sala['id'],
          'item_id': item['item_id'],
          'quantidade': quantidade,
        });
      }

      // Atualiza horários
      await supabase.from('salas_horarios').delete().eq('sala_id', widget.sala['id']);
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sala atualizada com sucesso!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Erro ao atualizar sala: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Sala"),
        backgroundColor: const Color(0xFF1ABC9C),
        actions: [
          // Botão QR Code
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Gerar QR Code da Sala',
            onPressed: () {
              final String salaId = widget.sala['id'].toString();
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
            buildTextField(_nomeController, "Nome da Sala", Icons.meeting_room),
            buildTextField(_capacidadeController, "Capacidade", Icons.people,
                keyboardType: TextInputType.number),
            buildTextField(_localizacaoController, "Localização", Icons.place),
            buildTextField(_urlController, "URL da Imagem", Icons.image),
            buildTextField(_statusController, "Status", Icons.info),
            buildTextField(_descricaoController, "Descrição", Icons.description),
            buildTextField(_tagsController, "Tags (separadas por vírgula)", Icons.label),
            buildTextField(_latitudeController, "Latitude", Icons.map, keyboardType: TextInputType.number),
            buildTextField(_longitudeController, "Longitude", Icons.map, keyboardType: TextInputType.number),

            const SizedBox(height: 16),

            // ====== HORÁRIOS EXISTENTES ======
            const Text("Horários Atuais da Sala",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (horariosExistentes.isEmpty)
              const Text("Nenhum horário cadastrado.")
            else
              ...horariosExistentes.map(
                    (h) => ListTile(
                  title: Text("${h['horario_inicio']} - ${h['horario_fim']}"),
                  leading: const Icon(Icons.access_time),
                ),
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
                    child: buildTextField(h['inicio']!, "Início (HH:MM)", Icons.access_time),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildTextField(h['fim']!, "Fim (HH:MM)", Icons.access_time),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => removeHorario(index),
                  ),
                ],
              );
            }),

            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: addHorario,
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Horário"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1ABC9C)),
            ),

            const SizedBox(height: 16),

            // ====== ITENS DA SALA ======
            const Text("Itens disponíveis", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
            }),

            const SizedBox(height: 16),
            const Text("Itens da Sala", style: TextStyle(fontWeight: FontWeight.bold)),
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
            }),

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
