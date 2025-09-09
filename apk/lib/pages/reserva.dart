import 'package:flutter/material.dart';

// Widget principal que representa a tela de reserva de sala.
class ReservasPage extends StatelessWidget {
  const ReservasPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura base da tela.
    return Scaffold(
      // A cor de fundo principal da tela.
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        // SingleChildScrollView permite que a tela role se o conteúdo
        // for maior que a altura do dispositivo (útil quando o teclado aparece).
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho customizado da página.
              _buildHeader(),
              // Corpo principal com todas as informações da sala.
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

  // Constrói o cabeçalho com o título "Busca" e o ícone de calendário.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Busca',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // Constrói a linha de título da sala com os ícones de salvar e favorito.
  Widget _buildRoomTitle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Sala Maior',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.bookmark, color: Colors.blue, size: 28),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.black54, size: 28),
          onPressed: () {},
        ),
      ],
    );
  }

  // Constrói o carrossel de imagens da sala.
  Widget _buildImageCarousel() {
    // Stack permite sobrepor widgets, como as setas sobre a imagem.
    return Stack(
      alignment: Alignment.center,
      children: [
        // Container para a imagem.
        ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Image.network(
            // URL de uma imagem de placeholder. Troque pela imagem real da sala.
            'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?q=80&w=2832&auto=format&fit=crop',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            // Tratamento de erro caso a imagem não carregue.
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              );
            },
          ),
        ),
        // Setas de navegação do carrossel.
        Positioned(
          left: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.8),
            child: const Icon(Icons.chevron_left, color: Colors.black),
          ),
        ),
        Positioned(
          right: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.8),
            child: const Icon(Icons.chevron_right, color: Colors.black),
          ),
        ),
      ],
    );
  }

  // Constrói a barra de status "Disponível" e os chips de amenidades.
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
        // Wrap permite que os chips quebrem a linha se não couberem na tela.
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

  // Widget auxiliar para criar um chip de amenidade.
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

  // Constrói os campos de formulário para reserva.
  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(hint: 'Título da Reunião'),
        const SizedBox(height: 12),
        _buildTextField(
          hint: '21/02/2024', // Valor fixo como na imagem
          prefixIcon: Icons.calendar_today,
          isReadOnly: true,
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

  // Widget auxiliar para criar um campo de texto customizado.
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

  // Constrói a seção de disponibilidade de horário.
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

  // Widget auxiliar para criar um slot de horário.
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

  // Constrói o botão de ação principal (Call To Action).
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