import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Página de Termos de Serviço
// -----------------------------------------------------------------------------
/// Apresenta os termos e condições de uso da aplicação num formato legível.
// -----------------------------------------------------------------------------
class TermosPage extends StatelessWidget {
  const TermosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Serviço'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termos e Condições de Uso – TimeRoom',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildParagraph(
              'Bem-vindo ao TimeRoom! Estes termos e condições descrevem as regras e regulamentos para o uso da aplicação TimeRoom.',
            ),
            _buildParagraph(
              'Ao aceder e utilizar esta aplicação, consideramos que aceita estes termos e condições na sua totalidade. Não continue a usar a aplicação TimeRoom se não concordar com todos os termos e condições declarados nesta página.',
            ),
            _buildSectionTitle(context, '1. Contas de Utilizador'),
            _buildParagraph(
              '1.1. Para utilizar os nossos serviços de reserva, poderá ser necessário criar uma conta. Você é responsável por manter a confidencialidade da sua conta e senha e por restringir o acesso ao seu dispositivo.',
            ),
            _buildParagraph(
              '1.2. Você concorda em aceitar a responsabilidade por todas as atividades que ocorram sob a sua conta ou senha.',
            ),
            _buildSectionTitle(context, '2. Reservas de Salas'),
            _buildParagraph(
              '2.1. A aplicação TimeRoom permite a reserva de salas de reunião de acordo com a disponibilidade. Todas as reservas estão sujeitas a confirmação.',
            ),
            _buildParagraph(
              '2.2. O cancelamento de reservas deve ser feito com a antecedência estipulada nas políticas do seu espaço de trabalho. O não cumprimento pode resultar em penalidades.',
            ),
            _buildSectionTitle(context, '3. Uso Aceitável'),
            _buildParagraph(
              '3.1. Você concorda em não usar a aplicação para qualquer finalidade ilegal ou proibida por estes termos.',
            ),
            _buildParagraph(
              '3.2. É proibido utilizar as salas reservadas para atividades que não estejam em conformidade com as políticas internas da sua empresa ou que perturbem outros utilizadores.',
            ),
            const SizedBox(height: 24),
            Text(
              'Última atualização: 25 de setembro de 2025',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um título de secção formatado.
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Constrói um parágrafo de texto formatado.
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(height: 1.5), // Melhora a legibilidade
      ),
    );
  }
}
