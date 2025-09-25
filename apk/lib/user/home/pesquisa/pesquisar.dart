import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Página de pesquisa de salas
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _salas = [];
  bool _isLoading = false;

  Future<void> _pesquisarSalas(String termo) async {
    termo = termo.trim();

    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('salas')
          .select('id, nome, capacidade')
          .ilike('nome', '%$termo%')
          .order('nome', ascending: true);

      setState(() {
        _salas = response;
      });
    } catch (e) {
      debugPrint("Erro ao buscar salas: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao buscar salas.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _pesquisarSalas('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesquisar Salas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Barra de pesquisa estilo Google
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _pesquisarSalas,
                decoration: InputDecoration(
                  hintText: "Pesquisar salas...",
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          ),

          // Lista de resultados
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _salas.isEmpty
                ? const Center(child: Text("Nenhuma sala encontrada"))
                : ListView.builder(
              itemCount: _salas.length,
              itemBuilder: (context, index) {
                final sala = _salas[index];
                return ListTile(
                  leading: const Icon(Icons.meeting_room),
                  title: Text(sala['nome'] ?? 'Sem nome'),
                  subtitle:
                  Text("${sala['capacidade'] ?? 0} pessoas"),
                  onTap: () {
                    // TODO: abrir detalhes da sala
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
