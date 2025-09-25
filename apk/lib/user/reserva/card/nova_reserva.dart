import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'confirmacao_reserva.dart';

final supabase = Supabase.instance.client;

class NovaReservaPage extends StatefulWidget {
  final Map<String, dynamic> sala;
  final DateTime dataSelecionada;

  const NovaReservaPage({
    super.key,
    required this.sala,
    required this.dataSelecionada,
  });

  @override
  State<NovaReservaPage> createState() => _NovaReservaPageState();
}

class _NovaReservaPageState extends State<NovaReservaPage> {
  bool loading = false;
  final TextEditingController _observacoesController = TextEditingController();
  List<Map<String, dynamic>> comentarios = [];

  @override
  void initState() {
    super.initState();
    _loadComentarios();
  }

  Future<void> _loadComentarios() async {
    final salaId = widget.sala['id'];
    final response = await supabase
        .from('feedback_salas')
        .select('nota, comentario, usuario:profiles(name, avatar_url)')
        .eq('sala_id', salaId)
        .order('created_at', ascending: false);

    setState(() {
      comentarios = List<Map<String, dynamic>>.from(response);
    });
  }

  Widget _buildEstrelas(double media) {
    return Row(
      children: List.generate(
        5,
            (i) => Icon(
          i < media ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }

  Future<void> _salvarReserva() async {
    setState(() => loading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw "Usuário não autenticado";

      final horaInicio = TimeOfDay.now();
      final horaFim = TimeOfDay(hour: horaInicio.hour + 2, minute: horaInicio.minute);

      await supabase.from('reservas').insert({
        'user_id': userId,
        'sala_id': widget.sala['id'],
        'data_reserva': widget.dataSelecionada.toIso8601String().split('T')[0],
        'hora_inicio':
        '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
        'hora_fim':
        '${horaFim.hour.toString().padLeft(2, '0')}:${horaFim.minute.toString().padLeft(2, '0')}',
        'status': 'pendente',
        'titulo': _observacoesController.text.isEmpty ? 'Reserva' : _observacoesController.text,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmacaoReservaPage(
            reserva: {
              'nome_sala': widget.sala['nome'],
              'url': widget.sala['url'],
              'capacidade': widget.sala['capacidade'],
              'localizacao': widget.sala['localizacao'],
              'descricao': widget.sala['descricao'],
              'mediaAvaliacoes': widget.sala['media_avaliacoes'] ?? 0,
              'comentarios': comentarios,
              'data_reserva': widget.dataSelecionada,
              'hora_inicio': '${horaInicio.hour.toString().padLeft(2,'0')}:${horaInicio.minute.toString().padLeft(2,'0')}',
              'hora_fim': '${horaFim.hour.toString().padLeft(2,'0')}:${horaFim.minute.toString().padLeft(2,'0')}',
              'observacoes': _observacoesController.text,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sala = widget.sala;
    final dataFormatada = DateFormat('dd/MM/yyyy').format(widget.dataSelecionada);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserva - Sala'),
        backgroundColor: const Color(0xFF2CC0AF),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: sala['url'] != null
                  ? Image.network(
                sala['url'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 200, color: Colors.grey[300]),
              )
                  : Container(height: 200, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Text(sala['nome'] ?? '',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildEstrelas(sala['media_avaliacoes'] ?? 0),
            const SizedBox(height: 8),
            Text('Capacidade: ${sala['capacidade'] ?? '-'}'),
            Text('Local: ${sala['localizacao'] ?? '-'}'),
            const SizedBox(height: 12),
            Text(sala['descricao'] ?? ''),
            const SizedBox(height: 16),
            Text('Data da Reserva: $dataFormatada'),
            const SizedBox(height: 8),
            TextField(
              controller: _observacoesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Observações (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Text('Comentários', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            comentarios.isEmpty
                ? const Text('Nenhum comentário ainda.')
                : Column(
              children: comentarios.map((c) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: c['usuario']['avatar_url'] != null
                        ? NetworkImage(c['usuario']['avatar_url'])
                        : null,
                    child: c['usuario']['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(c['usuario']['name'] ?? '-'),
                  subtitle: Text(c['comentario'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      c['nota'] ?? 0,
                          (_) => const Icon(Icons.star, color: Colors.amber, size: 16),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvarReserva,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2CC0AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirmar Reserva',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
