import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pacote para formatar datas, pode ser necessário adicionar ao pubspec.yaml

// -----------------------------------------------------------------------------
// Modelo de Dados (Data Model)
// -----------------------------------------------------------------------------
class SalaInfo {
  final String nome;
  final int capacidade;
  final String status;

  SalaInfo({
    required this.nome,
    required this.capacidade,
    required this.status,
  });
}

// -----------------------------------------------------------------------------
// Widget da Tela de Lista de Salas - Agora com Funcionalidades
// -----------------------------------------------------------------------------
class SalasDisponiveisPage extends StatefulWidget {
  const SalasDisponiveisPage({super.key});

  @override
  State<SalasDisponiveisPage> createState() => _SalasDisponiveisPageState();
}

class _SalasDisponiveisPageState extends State<SalasDisponiveisPage> {
  // ---------------------------------------------------------------------------
  // Estado do Widget (State) - Variáveis que controlam a tela
  // ---------------------------------------------------------------------------

  // Lista mestre com todas as salas. Nunca será modificada diretamente.
  final List<SalaInfo> _todasAsSalas = [
    SalaInfo(nome: 'Sala de Reunião 01', capacidade: 12, status: 'Disponível'),
    SalaInfo(nome: 'Sala de Reunião 02', capacidade: 40, status: 'Ocupada'),
    SalaInfo(nome: 'Sala de Reunião 03', capacidade: 40, status: 'Disponível'),
    SalaInfo(nome: 'Sala de Reunião 04', capacidade: 48, status: 'Disponível'),
    SalaInfo(nome: 'Sala de Reunião 05', capacidade: 24, status: 'Disponível'),
    SalaInfo(nome: 'Sala de Brainstorm', capacidade: 8, status: 'Ocupada'),
    SalaInfo(nome: 'Auditório Menor', capacidade: 50, status: 'Disponível'),
    SalaInfo(nome: 'Sala de Entrevistas', capacidade: 4, status: 'Disponível'),
    SalaInfo(nome: 'Sala de Foco 01', capacidade: 2, status: 'Ocupada'),
    SalaInfo(nome: 'Sala de Foco 02', capacidade: 2, status: 'Disponível'),
  ];

  // Lista que será exibida na tela. Ela muda de acordo com a busca.
  List<SalaInfo> _listaFiltrada = [];

  // Controlador para o campo de texto da busca.
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ao iniciar a tela, a lista filtrada começa com todas as salas.
    _listaFiltrada = _todasAsSalas;
    // Adiciona um "ouvinte" ao campo de busca para filtrar a lista sempre que o texto mudar.
    _searchController.addListener(_filtrarSalas);
  }

  @override
  void dispose() {
    // É uma boa prática remover o "ouvinte" e limpar o controlador para evitar vazamentos de memória.
    _searchController.removeListener(_filtrarSalas);
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Lógica de Funcionalidades
  // ---------------------------------------------------------------------------

  /// Filtra a lista de salas com base no texto digitado no campo de busca.
  void _filtrarSalas() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _listaFiltrada = _todasAsSalas.where((sala) {
        final nomeSala = sala.nome.toLowerCase();
        final capacidadeSala = sala.capacidade.toString();
        // Retorna true se o nome da sala OU a capacidade contiverem o texto da busca.
        return nomeSala.contains(query) || capacidadeSala.contains(query);
      }).toList();
    });
  }

  /// Abre um seletor de data e exibe a data selecionada.
  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (dataEscolhida != null) {
      // Exibe uma mensagem rápida na parte inferior da tela com a data.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data selecionada: ${DateFormat('dd/MM/yyyy').format(dataEscolhida)}'),
          backgroundColor: const Color(0xFF16A085),
        ),
      );
      // TODO: Adicionar lógica para filtrar as salas com base na data escolhida.
    }
  }

  // ---------------------------------------------------------------------------
  // Build (Construção da Interface)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
      // A barra de navegação foi removida para ser controlada pelo Dashboard.
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: const Icon(Icons.menu, color: Colors.black, size: 30),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(),
          const SizedBox(height: 16),
          _buildSearchBar(), // Campo de busca adicionado aqui
          const SizedBox(height: 20),
          _buildRoomsList(),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Lista de salas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Listagem de todas salas', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        // GestureDetector torna o container clicável.
        GestureDetector(
          onTap: () => _selecionarData(context), // Chama a função do calendário
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1ABC9C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// Constrói o campo de texto para a busca.
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por nome ou capacidade...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Constrói a lista de salas usando a lista filtrada.
  Widget _buildRoomsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _listaFiltrada.length, // Usa a lista filtrada
        itemBuilder: (context, index) {
          final sala = _listaFiltrada[index];
          return _buildSalaCard(sala);
        },
      ),
    );
  }

  /// Constrói o card de uma única sala.
  Widget _buildSalaCard(SalaInfo sala) {
    final bool isDisponivel = sala.status == 'Disponível';
    final Color cardColor = isDisponivel ? const Color(0xFF1ABC9C) : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        // Ao tocar no card, navega para a tela de reservas.
        onTap: () {
          // Utiliza rotas nomeadas para uma navegação mais limpa.
          // Certifique-se de ter a rota '/reservas' configurada no seu main.dart.
          Navigator.pushNamed(context, '/reservas');
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Icon(Icons.workspaces_outline, color: Colors.black54, size: 32),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sala.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sala que comporta ${sala.capacidade} pessoas!',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}