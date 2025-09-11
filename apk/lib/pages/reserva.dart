import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart'; // Pacote para formatar datas. Adicione `intl: ^0.18.1` no seu pubspec.yaml

// -----------------------------------------------------------------------------
// Modelo de Dados (Data Model)
// Usar uma classe para representar a "Sala" organiza o código e facilita
// a manipulação dos dados de cada sala.
// -----------------------------------------------------------------------------
class Sala {
  String nome;
  int capacidade;
  List<String> imagens; // Agora cada sala pode ter várias imagens.
  bool isLiked;
  bool isBookmarked;

  Sala({
    required this.nome,
    required this.capacidade,
    required this.imagens,
    this.isLiked = false,
    this.isBookmarked = false,
  });
}


// -----------------------------------------------------------------------------
// Widget da Tela de Reservas
// Convertido para StatefulWidget para que a tela possa reagir a interações
// do usuário (cliques, seleções, etc.) e mudar seu estado visual.
// -----------------------------------------------------------------------------
class ReservasPage extends StatefulWidget {
  const ReservasPage({super.key});

  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage> {

  // ---------------------------------------------------------------------------
  // Estado do Widget (State)
  // Variáveis que guardam os dados que podem mudar na tela.
  // ---------------------------------------------------------------------------

  // Lista com todas as salas disponíveis. Em um app real, isso viria de um banco de dados.
  final List<Sala> _todasAsSalas = [
    Sala(
      nome: 'Sala Grande',
      capacidade: 40,
      imagens: [
        'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?q=80&w=2832&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1590487988256-5ed24d5e7a2e?q=80&w=2940&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1543269865-cbf427effbad?q=80&w=2940&auto=format&fit=crop',
      ],
    ),
    Sala(
      nome: 'Sala Média',
      capacidade: 20,
      imagens: [
        'https://images.unsplash.com/photo-1521737852577-6860ad4f1nkf?q=80&w=2940&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1552664730-d307ca884978?q=80&w=2940&auto=format&fit=crop',
      ],
    ),
    Sala(
      nome: 'Sala Pequena',
      capacidade: 8,
      imagens: [
        'https://images.unsplash.com/photo-1517048676732-d65bc937f952?q=80&w=2940&auto=format&fit=crop',
      ],
    ),
  ];

  // Guarda a sala que está sendo exibida na tela no momento.
  late Sala _salaSelecionada;

  // Guarda a data que o usuário selecionou no calendário.
  DateTime? _dataSelecionada;

  // Controlador para o carrossel de imagens, permite navegar entre as fotos.
  final PageController _pageController = PageController();


  // O método initState é chamado uma única vez quando o widget é criado.
  // É o lugar ideal para inicializar as variáveis de estado.
  @override
  void initState() {
    super.initState();
    // Inicia a tela exibindo a primeira sala da lista.
    _salaSelecionada = _todasAsSalas.first;
    // Define a data inicial como a data de hoje.
    _dataSelecionada = DateTime.now();
  }


  // ---------------------------------------------------------------------------
  // Funções de Lógica e Interação
  // Métodos que alteram o estado e atualizam a UI.
  // ---------------------------------------------------------------------------

  // Função para abrir o seletor de datas nativo do sistema.
  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(), // Data inicial do calendário
      firstDate: DateTime.now(), // Primeira data que pode ser escolhida
      lastDate: DateTime(2030),    // Última data que pode ser escolhida
    );
    // Se o usuário escolheu uma data, atualizamos o estado.
    if (dataEscolhida != null && dataEscolhida != _dataSelecionada) {
      setState(() { // setState() avisa o Flutter para redesenhar a tela
        _dataSelecionada = dataEscolhida;
      });
    }
  }

  // Função para alternar o estado de "curtido".
  void _toggleLike() {
    setState(() {
      _salaSelecionada.isLiked = !_salaSelecionada.isLiked;
    });
  }

  // Função para alternar o estado de "salvo".
  void _toggleBookmark() {
    setState(() {
      _salaSelecionada.isBookmarked = !_salaSelecionada.isBookmarked;
    });
  }

  // ---------------------------------------------------------------------------
  // Build (Construção da Interface)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // O cabeçalho agora tem um Dropdown para simular a busca/filtro.
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoomTitle(),
                    const SizedBox(height: 16),
                    _buildImageCarousel(),
                    const SizedBox(height: 16),
                    _buildStatusAndAmenities(),
                    const SizedBox(height: 24),
                    _buildFormFields(),
                    const SizedBox(height: 16),
                    _buildAvailability(),
                    const SizedBox(height: 24),
                    _buildCtaButton(
                      icon: Icons.group_add_outlined,
                      text: 'Adicionar Convidados',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Constrói o cabeçalho com a busca/filtro de salas.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dropdown para selecionar a sala, simulando uma busca.
          DropdownButton<Sala>(
            value: _salaSelecionada,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            underline: Container(), // Remove a linha de baixo
            onChanged: (Sala? novaSala) {
              if (novaSala != null) {
                setState(() {
                  _salaSelecionada = novaSala;
                  _pageController.jumpToPage(0); // Volta para a primeira imagem da nova sala
                });
              }
            },
            // Mapeia a lista de salas para os itens do Dropdown.
            items: _todasAsSalas.map<DropdownMenuItem<Sala>>((Sala sala) {
              return DropdownMenuItem<Sala>(
                value: sala,
                child: Text(sala.nome),
              );
            }).toList(),
          ),
          // O ícone de calendário continua aqui, se necessário.
          // IconButton(
          //   icon: const Icon(Icons.calendar_today_outlined, color: Colors.black54),
          //   onPressed: () {},
          // ),
        ],
      ),
    );
  }


  // Constrói o título da sala com botões de like e save funcionais.
  Widget _buildRoomTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _salaSelecionada.nome, // Usa o nome da sala selecionada.
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
        // Botão de Salvar (Bookmark) funcional.
        IconButton(
          icon: Icon(
            _salaSelecionada.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: _salaSelecionada.isBookmarked ? Colors.blue : Colors.black54,
            size: 28,
          ),
          onPressed: _toggleBookmark, // Chama a função para alternar o estado.
        ),
        // Botão de Curtir (Like/Favorite) funcional.
        IconButton(
          icon: Icon(
            _salaSelecionada.isLiked ? Icons.favorite : Icons.favorite_border,
            color: _salaSelecionada.isLiked ? Colors.red : Colors.black54,
            size: 28,
          ),
          onPressed: _toggleLike, // Chama a função para alternar o estado.
        ),
      ],
    );
  }

  // Constrói o carrossel de imagens funcional.
  Widget _buildImageCarousel() {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // PageView permite deslizar entre as imagens.
          PageView.builder(
            controller: _pageController,
            itemCount: _salaSelecionada.imagens.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  _salaSelecionada.imagens[index], // Pega a imagem da sala selecionada
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              );
            },
          ),
          // Botão para voltar a imagem
          Positioned(
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.7),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.black),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
          // Botão para avançar a imagem
          Positioned(
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.7),
              child: IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.black),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Constrói os campos de formulário, agora com o campo de data funcional.
  Widget _buildFormFields() {
    // Formata a data selecionada para o formato brasileiro (dd/MM/yyyy).
    String dataFormatada = _dataSelecionada != null
        ? DateFormat('dd/MM/yyyy').format(_dataSelecionada!)
        : 'Selecione uma data';

    return Column(
      children: [
        _buildTextField(hint: 'Título da Reunião'),
        const SizedBox(height: 12),
        // Campo de data que abre o calendário ao ser tocado.
        GestureDetector(
          onTap: () => _selecionarData(context), // Chama a função do calendário
          child: AbsorbPointer( // Impede que o teclado abra
            child: _buildTextField(
              hint: dataFormatada, // Mostra a data selecionada
              prefixIcon: Icons.calendar_today,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          hint: 'Selecione seu horário',
          prefixIcon: Icons.access_time,
          suffixIcon: Icons.chevron_right,
          isReadOnly: true,
        ),
        const SizedBox(height: 8),
        const Text(
          'Você pode fazer 3 reservas por dia nesta sala. Você ainda tem 3 reservas disponíveis. A duração máxima de cada reserva é de 02h00.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // --- Os widgets auxiliares abaixo permanecem praticamente os mesmos ---

  Widget _buildStatusAndAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Disponível',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            _buildAmenityChip('Água'),
            _buildAmenityChip('Áudio e Vídeo'),
            _buildAmenityChip('Café'),
            _buildAmenityChip('Chá'),
            _buildAmenityChip('Copa'),
            _buildAmenityChip('Elevador'),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenityChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool isReadOnly = false,
  }) {
    return TextField(
      readOnly: isReadOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.blue) : null,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.black54) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Disponibilidade de horário', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTimeSlot('14h-16h', isAvailable: false),
            _buildTimeSlot('16h-18h'),
            _buildTimeSlot('19h-21h'),
          ],
        )
      ],
    );
  }

  Widget _buildTimeSlot(String time, {bool isAvailable = true}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? Colors.green : Colors.grey[400]!,
        ),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: isAvailable ? Colors.green[800] : Colors.grey[600],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCtaButton({required IconData icon, required String text}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}