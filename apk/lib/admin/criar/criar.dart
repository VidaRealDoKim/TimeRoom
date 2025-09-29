import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Cores padronizadas do app
final Color primaryColor = const Color(0xFF1ABC9C);
final Color secondaryColor = const Color(0xFF1ABC9C);
final Color bgColor = const Color(0xFFF5F5F5);

class CriarSalaPage extends StatefulWidget {
  final VoidCallback? onSalaCriada; // callback para atualizar aba do dashboard

  const CriarSalaPage({super.key, this.onSalaCriada});

  @override
  State<CriarSalaPage> createState() => _CriarSalaPageState();
}

class _CriarSalaPageState extends State<CriarSalaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ===================== CONTROLLERS DE SALA =====================
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _capacidadeController = TextEditingController();
  final TextEditingController _localizacaoController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _statusController =
  TextEditingController(text: "disponível");

  // ===================== CONTROLLERS DE OBJETO =====================
  final TextEditingController _nomeItemController = TextEditingController();
  final TextEditingController _urlItemController = TextEditingController();
  final TextEditingController _descricaoItemController =
  TextEditingController();

  List<Map<String, dynamic>> todosItens = [];
  List<Map<String, dynamic>> itensSala = [];
  Map<String, TextEditingController> quantidadeControllers = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchTodosItens();
    _urlController.addListener(() => setState(() {}));
  }

  Future<void> fetchTodosItens() async {
    try {
      final response = await supabase.from('itens').select();
      setState(() => todosItens = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Erro ao buscar itens: $e");
    }
  }

  Future<void> _createSala() async {
    final nome = _nomeController.text.trim();
    final capacidade = int.tryParse(_capacidadeController.text.trim()) ?? 0;
    final localizacao = _localizacaoController.text.trim();
    final url = _urlController.text.trim();
    final status = _statusController.text.trim();

    if (nome.isEmpty || capacidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios!")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await supabase.from('salas').insert({
        'nome': nome,
        'capacidade': capacidade,
        'localizacao': localizacao.isEmpty ? null : localizacao,
        'url': url.isEmpty ? null : url,
        'status': status,
      }).select().single();

      if (!mounted) return;
      final salaId = response['id'];

      for (var item in itensSala) {
        final quantidade =
            int.tryParse(quantidadeControllers[item['item_id']]?.text ?? '1') ??
                1;
        await supabase.from('salas_itens').insert({
          'sala_id': salaId,
          'item_id': item['item_id'],
          'quantidade': quantidade,
        });
      }

      if (!mounted) return;

      // DIALOG DE SUCESSO
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Sucesso!"),
          content: const Text("Sala criada com sucesso!"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // fecha o diálogo
                widget.onSalaCriada?.call(); // atualiza aba do dashboard
                Navigator.of(context).pop(); // volta para dashboard
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Erro ao criar sala: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void addItem(Map<String, dynamic> item) {
    final exists = itensSala.any((i) => i['item_id'] == item['id']);
    if (exists) return;
    setState(() {
      itensSala.add({
        'item_id': item['id'],
        'quantidade': 1,
        'itens': {'nome': item['nome'], 'url': item['url'] ?? ''},
      });
      quantidadeControllers[item['id']] = TextEditingController(text: '1');
    });
  }

  void removeItem(Map<String, dynamic> item) {
    quantidadeControllers.remove(item['item_id']);
    itensSala.removeWhere((i) => i['item_id'] == item['item_id']);
    setState(() {});
  }

  Future<void> _criarObjeto() async {
    final nome = _nomeItemController.text.trim();
    final url = _urlItemController.text.trim();
    final descricao = _descricaoItemController.text.trim();

    if (nome.isEmpty) return;

    try {
      final response = await supabase.from('itens').insert({
        'nome': nome,
        'descricao': descricao.isEmpty ? null : descricao,
        'url': url.isEmpty ? null : url,
      }).select().single();

      if (!mounted) return;

      setState(() {
        todosItens.add(response);
        _nomeItemController.clear();
        _urlItemController.clear();
        _descricaoItemController.clear();
      });

      // DIALOG DE SUCESSO PARA OBJETO
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Sucesso!"),
          content: const Text("Objeto criado com sucesso!"),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Erro ao criar objeto: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro ao criar objeto: $e")));
    }
  }

  // ===================== WIDGET BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // TAB BAR PADRONIZADA
          TabBar(
            controller: _tabController,
            indicatorColor: secondaryColor,
            labelColor: secondaryColor,
            unselectedLabelColor: Colors.black54,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.meeting_room), text: "Criar Sala"),
              Tab(icon: Icon(Icons.inventory_2), text: "Criar Objetos"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildImagePreview(_urlController),
                      buildTextField(
                          _urlController, "URL da Imagem da Sala", Icons.image),
                      buildTextField(
                          _nomeController, "Nome da Sala", Icons.meeting_room),
                      buildTextField(_capacidadeController, "Capacidade",
                          Icons.people,
                          keyboardType: TextInputType.number),
                      buildTextField(
                          _localizacaoController, "Localização", Icons.place),
                      buildTextField(_statusController, "Status", Icons.info),
                      ...itensSala.map(buildItemCard),
                      buildActionButton(
                        text: "Criar Sala",
                        icon: Icons.add,
                        loading: _loading,
                        onPressed: _loading ? null : _createSala,
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildImagePreview(_urlItemController),
                      buildTextField(
                          _urlItemController, "URL da Imagem", Icons.image),
                      buildTextField(
                          _nomeItemController, "Nome do Objeto", Icons.inventory_2),
                      buildTextField(_descricaoItemController, "Descrição",
                          Icons.description),
                      buildActionButton(
                        text: "Criar Objeto",
                        icon: Icons.add,
                        onPressed: _criarObjeto,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor),
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget buildImagePreview(TextEditingController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: controller.text.isNotEmpty
          ? Image.network(
        controller.text,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.broken_image, size: 100, color: Colors.grey),
      )
          : Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 100, color: Colors.grey),
      ),
    );
  }

  Widget buildItemCard(Map<String, dynamic> item) {
    final controller = quantidadeControllers[item['item_id']]!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: item['itens']['url'] != null && item['itens']['url'].isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(item['itens']['url'],
              width: 50, height: 50, fit: BoxFit.cover),
        )
            : const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
        title: Text(item['itens']['nome'],
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: SizedBox(
          width: 90,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
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
  }

  Widget buildActionButton({
    required String text,
    required IconData icon,
    bool loading = false,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: loading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Icon(icon),
        label: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
