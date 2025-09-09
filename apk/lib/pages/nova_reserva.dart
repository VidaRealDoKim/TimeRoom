import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class NovaReservaPage extends StatefulWidget {
  const NovaReservaPage({super.key});

  @override
  State<NovaReservaPage> createState() => _NovaReservaPageState();
}

class _NovaReservaPageState extends State<NovaReservaPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1ABC9C), // fundo verde
      appBar: AppBar(
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Nova Reserva",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Calendário
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              "Salas Disponíveis",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const Text(
              "Escolha uma data e selecione uma sala",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),

            // Lista de salas
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _salaCard("Sala de reunião 02", "Sala que comporta 40 pessoas!"),
                  _salaCard("Sala de reunião 23", "Sala que comporta 10 pessoas!"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salaCard(String titulo, String descricao) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.meeting_room, size: 32, color: Colors.black54),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(descricao),
        onTap: () {
          // Futuro: abrir página de detalhes/confirmar reserva
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Você selecionou: $titulo")),
          );
        },
      ),
    );
  }
}
