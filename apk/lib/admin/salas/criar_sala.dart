import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Instância global do Supabase
final supabase = Supabase.instance.client;

/// Tela para criar uma nova sala e adicionar itens disponíveis
class CriarSalaPage extends StatefulWidget {
  const CriarSalaPage({super.key});

  @override
  State<CriarSalaPage> createState() => _CriarSalaPageState();
}

class _CriarSalaPageState extends State<CriarSalaPage> {
  // ===================== CONTROLLERS =====================
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _capacidadeController = TextEditingController();
  final TextEditingController _localizacaoController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _horarioInicioController = TextEditingController();
  final TextEditingController _horarioFimController = TextEditingController();

  // ===================== ITENS =====================
  List<Map<String, dynamic>> todosItens = []; // Lista de todos os itens disponíveis
  List<Map<String, dynamic>> itensSelecionados = []; // Lista de itens escolhidos para a sala
  Map<String, TextEditingController> quantidadeControllers = {}; // Quantidade por item

  // ===================== LOADING =====================
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    fetchTodosItens(); // Busca todos os itens disponíveis ao iniciar a tela
  }

  // ===================== FETCH ITENS =====================
  /// Busca todos os itens disponíveis no banco
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

  // ===================== CRIAR SALA =====================
  /// Cria a sala e associa os itens selecionados com suas quantidades
  Future<void> _createSala() async {
    final nome = _nomeController.text.trim();
    final capacidade = int.tryParse(_capacidadeController.text.trim()) ?? 0;
    final localizacao = _localizacaoController.text.trim();
    final url = _urlController.text.trim();
    final horarioInicio = _horarioInicioController.text.trim();
    final horarioFim = _horarioFimController.text.trim();

    if (nome.isEmpty || capacidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha os campos obrigatórios!")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Cria a sala no Supabase
      final salaResponse = await supabase.from('salas').insert({
        'nome': nome,
        'capacidade': capacidade,
        'localizacao': localizacao,
        'url': url,
        'horario_inicio': horarioInicio,
        'horario_fim': horarioFim,
      }).select().single();

      final salaId = salaResponse['id'];

      // Adiciona os itens selecionados com quantidade
      for (var item in itensSelecionados) {
        final quantidade = int.tryParse(quantidadeControllers[item['id']]?.text ?? '1') ?? 1;
        await supabase.from('salas_itens').insert({
          'sala_id': salaId,
          'item_id': item['id'],
          'quantidade': quantidade,
        });
      }

      // Feedback de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sala criada com sucesso!")),
      );

      // Limpa todos os campos e listas
      _nomeController.clear();
      _capacidadeController.clear();
      _localizacaoController.clear();
      _urlController.clear();
      _horarioInicioController.clear();
      _horarioFimController.clear();
      itensSelecionados.clear();
      quantidadeControllers.clear();
      setState(() {});
    } catch (e) {
      debugPrint("Erro ao criar sala: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ===================== SELECIONAR/REMOVER ITENS =====================
  void addItem(Map<String, dynamic> item) {
    setState(() {
      itensSelecionados.add(item);
      quantidadeControllers[item['id']] = TextEditingController(text: '1');
    });
  }

  void removeItem(Map<String, dynamic> item) {
    setState(() {
      itensSelecionados.removeWhere((i) => i['id'] == item['id']);
      quantidadeControllers.remove(item['id']);
    });
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar Nova Sala"),
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===================== CAMPOS DA SALA =====================
            buildTextField(_nomeController, "Nome da Sala", Icons.meeting_room),
            buildTextField(
                _capacidadeController, "Capacidade", Icons.people,
                keyboardType: TextInputType.number),
            buildTextField(_localizacaoController, "Localização", Icons.place),
            buildTextField(_urlController, "URL da Imagem", Icons.image),
            buildTextField(_horarioInicioController, "Horário Início (HH:MM)", Icons.access_time),
            buildTextField(_horarioFimController, "Horário Fim (HH:MM)", Icons.access_time),

            const SizedBox(height: 16),
            const Text(
              "Itens disponíveis para a sala",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // ===================== LISTA DE ITENS DISPONÍVEIS =====================
            ...todosItens.map((item) {
              final isSelected = itensSelecionados.any((i) => i['id'] == item['id']);
              if (isSelected) return Container();
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(item['nome']),
                  trailing: IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => addItem(item),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 12),

            // ===================== ITENS SELECIONADOS =====================
            if (itensSelecionados.isNotEmpty)
              const Text(
                "Itens selecionados",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 8),
            ...itensSelecionados.map((item) {
              final controller = quantidadeControllers[item['id']]!;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(item['nome']),
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
            // ===================== BOTÃO CRIAR SALA =====================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _createSala,
                icon: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.add),
                label: Text(
                  _loading ? "Salvando..." : "Criar Sala",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== CAMPO DE TEXTO REUTILIZÁVEL =====================
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
