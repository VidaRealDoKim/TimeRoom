import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminSalaItensPage extends StatefulWidget {
  final Map<String, dynamic>? sala; // Pode ser nula para listar todos itens
  const AdminSalaItensPage({super.key, this.sala});

  @override
  State<AdminSalaItensPage> createState() => _AdminSalaItensPageState();
}

class _AdminSalaItensPageState extends State<AdminSalaItensPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> itensSala = [];
  List<Map<String, dynamic>> todosItens = [];
  List<Map<String, dynamic>> itensComSalas = [];
  Map<String, TextEditingController> quantidadeControllers = {};
  late TabController _tabController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchItens();
    fetchTodosItens();
  }

  // ================== FETCH ==================
  Future<void> fetchItens() async {
    if (widget.sala == null) return;

    setState(() => _loading = true);
    try {
      // Itens da sala
      final response = await supabase
          .from('salas_itens')
          .select('item_id, quantidade, itens(nome, url)')
          .eq('sala_id', widget.sala!['id']);
      itensSala = List<Map<String, dynamic>>.from(response);

      // Todos os itens
      final itensResponse = await supabase.from('itens').select();
      todosItens = List<Map<String, dynamic>>.from(itensResponse);

      // Controllers
      quantidadeControllers.clear();
      for (var item in itensSala) {
        quantidadeControllers[item['item_id']] =
            TextEditingController(text: item['quantidade'].toString());
      }
    } catch (e) {
      debugPrint('Erro ao buscar itens: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> fetchTodosItens() async {
    try {
      final response = await supabase
          .from('salas_itens')
          .select('quantidade, itens(id, nome, url, descricao), salas(id, nome)')
          .order('salas', ascending: true);
      itensComSalas = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erro ao buscar itens de todas as salas: $e');
    } finally {
      setState(() {});
    }
  }

  // ================== MANIPULAÇÃO ==================
  Future<void> addItem(String itemId) async {
    if (widget.sala == null) return;

    try {
      final exists = itensSala.any((i) => i['item_id'] == itemId);
      if (!exists) {
        await supabase.from('salas_itens').insert({
          'sala_id': widget.sala!['id'],
          'item_id': itemId,
          'quantidade': 1,
        });
        fetchItens();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Item adicionado à sala!')));
      }
    } catch (e) {
      debugPrint('Erro ao adicionar item: $e');
    }
  }

  Future<void> removeItem(String itemId) async {
    if (widget.sala == null) return;

    try {
      await supabase
          .from('salas_itens')
          .delete()
          .eq('sala_id', widget.sala!['id'])
          .eq('item_id', itemId);
      fetchItens();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Item removido da sala!')));
    } catch (e) {
      debugPrint('Erro ao remover item: $e');
    }
  }

  Future<void> updateQuantidade(String itemId, int quantidade) async {
    if (widget.sala == null) return;

    try {
      await supabase
          .from('salas_itens')
          .update({'quantidade': quantidade})
          .eq('sala_id', widget.sala!['id'])
          .eq('item_id', itemId);
      FocusScope.of(context).unfocus();
      fetchItens();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Quantidade atualizada!')));
    } catch (e) {
      debugPrint('Erro ao atualizar quantidade: $e');
    }
  }

  // ================== WIDGETS ==================
  Widget buildItensDaSala() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (itensSala.isEmpty) return const Center(child: Text('Nenhum item nesta sala.'));

    return RefreshIndicator(
      onRefresh: fetchItens,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itensSala.length,
        itemBuilder: (_, index) {
          final item = itensSala[index];
          final nome = item['itens']?['nome'] ?? 'Item';
          final url = item['itens']?['url'] ?? '';
          final controller = quantidadeControllers[item['item_id']]!;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              leading: url.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url,
                    width: 50, height: 50, fit: BoxFit.cover),
              )
                  : const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
              title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: SizedBox(
                width: 120,
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
                        onSubmitted: (value) {
                          final qtd = int.tryParse(value) ?? 1;
                          updateQuantidade(item['item_id'], qtd);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => removeItem(item['item_id']),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildItensDisponiveis() {
    final disponiveis = todosItens
        .where((item) => !itensSala.any((i) => i['item_id'] == item['id']))
        .toList();

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (disponiveis.isEmpty) return const Center(child: Text('Todos os itens já estão nesta sala.'));

    return RefreshIndicator(
      onRefresh: fetchItens,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: disponiveis.length,
        itemBuilder: (_, index) {
          final item = disponiveis[index];
          final url = item['url'] ?? '';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              leading: url.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url,
                    width: 50, height: 50, fit: BoxFit.cover),
              )
                  : const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
              title: Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                onPressed: () => addItem(item['id']),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTodosItens() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (itensComSalas.isEmpty) return const Center(child: Text('Nenhum item cadastrado em nenhuma sala.'));

    return RefreshIndicator(
      onRefresh: fetchTodosItens,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itensComSalas.length,
        itemBuilder: (_, index) {
          final itemSala = itensComSalas[index];
          final item = itemSala['itens'] ?? {};
          final sala = itemSala['salas'] ?? {};
          final url = item['url'] ?? '';
          final nomeItem = item['nome'] ?? 'Item';
          final descricao = item['descricao'] ?? 'Sem descrição';
          final nomeSala = sala['nome'] ?? 'Sala desconhecida';
          final quantidade = itemSala['quantidade'] ?? 1;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              leading: url.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url,
                    width: 50, height: 50, fit: BoxFit.cover),
              )
                  : const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
              title: Text(nomeItem, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Sala: $nomeSala\nDescrição: $descricao\nQuantidade: $quantidade'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sala != null
            ? 'Itens da Sala: ${widget.sala!['nome']}'
            : 'Todos os Itens'),
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Itens da Sala'),
            Tab(text: 'Itens Disponíveis'),
            Tab(text: 'Todos os Itens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildItensDaSala(),
          buildItensDisponiveis(),
          buildTodosItens(),
        ],
      ),
    );
  }
}
