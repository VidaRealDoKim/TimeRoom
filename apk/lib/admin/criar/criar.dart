import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Instância global do Supabase
final supabase = Supabase.instance.client;

/// Cores padronizadas do app
final Color primaryColor = const Color(0xFF1ABC9C);
final Color secondaryColor = const Color(0xFF1ABC9C);
final Color bgColor = const Color(0xFFF5F5F5);

/// Página principal para criar salas e objetos
/// Possui duas abas: "Criar Sala" e "Criar Objetos"
class CriarSalaPage extends StatefulWidget {
  const CriarSalaPage({super.key});

  @override
  State<CriarSalaPage> createState() => _CriarSalaPageState();
}

class _CriarSalaPageState extends State<CriarSalaPage>
    with SingleTickerProviderStateMixin {

  /// Controller para gerenciar as abas
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
  final TextEditingController _descricaoItemController = TextEditingController();

  // ===================== LISTAS DE ITENS =====================
  List<Map<String, dynamic>> todosItens = []; // Lista de todos os objetos cadastrados
  List<Map<String, dynamic>> itensSala = []; // Itens adicionados à sala
  Map<String, TextEditingController> quantidadeControllers = {}; // Controladores de quantidade para cada item

  /// Flag para indicar carregamento de botões
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa o TabController com 2 abas
    _tabController = TabController(length: 2, vsync: this);
    // Busca todos os objetos cadastrados no Supabase
    fetchTodosItens();
    // Atualiza preview de imagem sempre que a URL mudar
    _urlController.addListener(() => setState(() {}));
  }

  /// Busca todos os itens cadastrados no Supabase
  Future<void> fetchTodosItens() async {
    try {
      final response = await supabase.from('itens').select();
      setState(() => todosItens = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Erro ao buscar itens: $e");
    }
  }

  /// Cria uma nova sala no banco e associa os itens selecionados
  Future<void> _createSala() async {
    final nome = _nomeController.text.trim();
    final capacidade = int.tryParse(_capacidadeController.text.trim()) ?? 0;
    final localizacao = _localizacaoController.text.trim();
    final url = _urlController.text.trim();
    final status = _statusController.text.trim();

    // Validação básica
    if (nome.isEmpty || capacidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios!")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Insere a sala no banco
      final response = await supabase.from('salas').insert({
        'nome': nome,
        'capacidade': capacidade,
        'localizacao': localizacao.isEmpty ? null : localizacao,
        'url': url.isEmpty ? null : url,
        'status': status,
      }).select().single();

      if (!mounted) return;
      final salaId = response['id'];

      // Insere os itens associados à sala
      for (var item in itensSala) {
        final quantidade = int.tryParse(
            quantidadeControllers[item['item_id']]?.text ?? '1') ??
            1;
        await supabase.from('salas_itens').insert({
          'sala_id': salaId,
          'item_id': item['item_id'],
          'quantidade': quantidade,
        });
      }

      if (!mounted) return;

      // Feedback de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sala criada com sucesso!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Erro ao criar sala: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Adiciona um item à lista de itens da sala
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

  /// Remove um item da lista da sala
  void removeItem(Map<String, dynamic> item) {
    quantidadeControllers.remove(item['item_id']);
    itensSala.removeWhere((i) => i['item_id'] == item['item_id']);
    setState(() {});
  }

  /// Cria um novo objeto diretamente na aba de objetos
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

      // Atualiza lista local e limpa campos
      setState(() {
        todosItens.add(response);
        _nomeItemController.clear();
        _urlItemController.clear();
        _descricaoItemController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Objeto criado com sucesso!")),
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
          // ===================== TAB BAR =====================
          Container(
            color: primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Criar Sala", icon: Icon(Icons.meeting_room)),
                Tab(text: "Criar Objetos", icon: Icon(Icons.inventory_2)),
              ],
            ),
          ),
          // ===================== TAB BAR VIEW =====================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ====== ABA CRIAR SALA ======
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildImagePreview(_urlController),
                      buildTextField(_urlController, "URL da Imagem da Sala", Icons.image),
                      buildTextField(_nomeController, "Nome da Sala", Icons.meeting_room),
                      buildTextField(
                          _capacidadeController, "Capacidade", Icons.people,
                          keyboardType: TextInputType.number),
                      buildTextField(_localizacaoController, "Localização", Icons.place),
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
                // ====== ABA CRIAR OBJETOS ======
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildImagePreview(_urlItemController),
                      buildTextField(_urlItemController, "URL da Imagem", Icons.image),
                      buildTextField(_nomeItemController, "Nome do Objeto", Icons.inventory_2),
                      buildTextField(_descricaoItemController, "Descrição", Icons.description),
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

  /// Cria um TextField customizado com ícone e label
  Widget buildTextField(TextEditingController controller, String label, IconData icon,
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

  /// Exibe o preview da imagem da sala ou objeto
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

  /// Card do item dentro da sala, com opção de alterar quantidade e remover
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
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

  /// Botão de ação padronizado para criar salas ou objetos
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
        label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
