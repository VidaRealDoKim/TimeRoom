import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../perfil/mapa_sala_page.dart';
import 'nova_reserva.dart';
import 'package:apk/providers/theme_provider.dart';

/// Página de detalhes da sala.
/// Mostra imagem, status e permite reserva com cores dependentes do tema.
class DetalhesSalaPage extends StatelessWidget {
  final Map<String, dynamic> sala;
  final DateTime dataSelecionada;

  const DetalhesSalaPage({
    super.key,
    required this.sala,
    required this.dataSelecionada,
  });

  void _reservarSala(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovaReservaPage(
          sala: sala,
          dataSelecionada: dataSelecionada,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final status = sala['ocupada'] == true ? "Ocupada" : "Livre";
    final statusColor =
    sala['ocupada'] == true ? Colors.redAccent : colors.primary;

    final imageUrl = sala['url'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(sala['nome'] ?? 'Detalhes da Sala'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGEM DA SALA ---
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  height: 200,
                  alignment: Alignment.center,
                  child: Icon(Icons.image_not_supported,
                      size: 60,
                      color: isDark
                          ? Colors.grey[700]
                          : Colors.grey[600]),
                ),
              )
                  : Container(
                color: Colors.grey[300],
                height: 200,
                alignment: Alignment.center,
                child: Icon(Icons.image,
                    size: 60,
                    color:
                    isDark ? Colors.grey[700] : Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),

            // --- STATUS E CAPACIDADE ---
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Capacidade: ${sala['capacidade'] ?? '-'} pessoas',
                  style: TextStyle(fontSize: 16, color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- BOTÃO VER NO MAPA ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text(
                  'Ver no Mapa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapaSalaPage(
                        latitude: sala['latitude'] ?? -26.9187,
                        longitude: sala['longitude'] ?? -49.0661,
                        nomeSala: sala['nome'] ?? 'Sala',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- DESCRIÇÃO ---
            Text(
              'Descrição:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sala['descricao'] ?? 'Sem descrição disponível.',
              style: TextStyle(fontSize: 16, height: 1.4, color: colors.onSurface),
            ),
            const SizedBox(height: 32),

            // --- BOTÃO RESERVAR ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sala['ocupada'] == true
                    ? null
                    : () => _reservarSala(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  disabledBackgroundColor: Colors.grey[600],
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Reservar Sala',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
