import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminSalaItensPage extends StatefulWidget {
  final Map<String, dynamic> sala;
  const AdminSalaItensPage({super.key, required this.sala});

  @override
  State<AdminSalaItensPage> createState() => _AdminSalaItensPageState();
}

class _AdminSalaItensPageState extends State<AdminSalaItensPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> itensSala = [];
  List<Map<String, dynamic>> todosItens = [];
  Map<String, TextEditingController> quantidadeControllers = {};
  late TabController _tabController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchItens();
  }

  Future<void> fetchItens() async {
    setState(() => _loading = true);
    try {
      final response = await supabase
          .from('salas_itens')
          .select('item_id, quantidade, itens(nome, url)')
          .eq('sala_id', widget.sala['id']);
      itensSala = List<Map<String, dynamic>>.from(response);

      final itensResponse = await supabase.from('itens').select();
      todosItens = List<Map<String, dynamic>>.from(itensResponse);

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

  Future<void> addItem(String itemId) async {
    try {
      final exists = itensSala.any((i) => i['item_id'] == itemId);
      if (!exists) {
        await supabase.from('salas_itens').insert({
          'sala_id': widget.sala['id'],
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
    try {
      await supabase
          .from('salas_itens')
          .delete()
          .eq('sala_id', widget.sala['id'])
          .eq('item_id', itemId);
      fetchItens();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Item removido da sala!')));
    } catch (e) {
      debugPrint('Erro ao remover item: $e');
    }
  }

  Future<void> updateQuantidade(String itemId, int quantidade) async {
    try {
      await supabase
          .from('salas_itens')
          .update({'quantidade': quantidade})
          .eq('sala_id', widget.sala['id'])
          .eq('item_id', itemId);
      FocusScope.of(context).unfocus();
      fetchItens();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Quantidade atualizada!')));
    } catch (e) {
      debugPrint('Erro ao atualizar quantidade: $e');
    }
  }

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
          final nome = item['itens'] != null ? item['itens']['nome'] : 'Item';
          final url = item['itens'] != null ? item['itens']['url'] ?? '' : '';
          final controller = quantidadeControllers[item['item_id']]!;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itens da Sala: ${widget.sala['nome']}'),
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Itens da Sala'),
            Tab(text: 'Itens Disponíveis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildItensDaSala(),
          buildItensDisponiveis(),
        ],
      ),
    );
  }
}
