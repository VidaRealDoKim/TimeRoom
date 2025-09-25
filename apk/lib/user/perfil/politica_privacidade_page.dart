import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Página de Política de Privacidade
// -----------------------------------------------------------------------------
/// Apresenta a política de privacidade da aplicação num formato claro e legível.
// -----------------------------------------------------------------------------
class PoliticaPrivacidadePage extends StatelessWidget {
  const PoliticaPrivacidadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título principal da página
            Text(
              'Política de Privacidade – TimeRoom',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Parágrafos de introdução
            _buildParagraph(
              'A sua privacidade é importante para nós. É política do TimeRoom respeitar a sua privacidade em relação a qualquer informação sua que possamos coletar na nossa aplicação.',
            ),

            // Secções do documento
            _buildSectionTitle(context, '1. Informações que Coletamos'),
            _buildParagraph(
              '1.1. Coletamos informações pessoais que você nos fornece diretamente ao criar uma conta, como nome, endereço de e-mail e informações de perfil.',
            ),
            _buildParagraph(
              '1.2. Também coletamos dados de uso, como informações sobre as reservas que você faz, incluindo datas, horários e salas selecionadas.',
            ),

            _buildSectionTitle(context, '2. Como Usamos as Suas Informações'),
            _buildParagraph(
              '2.1. Usamos as informações que coletamos para operar, manter e fornecer os recursos e a funcionalidade da aplicação, processar as suas reservas e comunicar consigo sobre as mesmas.',
            ),

            _buildSectionTitle(context, '3. Segurança dos Dados'),
            _buildParagraph(
              '3.1. A segurança das suas informações pessoais é importante para nós, mas lembre-se que nenhum método de transmissão pela Internet ou método de armazenamento eletrónico é 100% seguro. Embora nos esforcemos para usar meios comercialmente aceitáveis para proteger as suas informações pessoais, não podemos garantir a sua segurança absoluta.',
            ),
            const SizedBox(height: 24),

            // Data da última atualização
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

  /// Constrói um parágrafo de texto formatado para melhor legibilidade.
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        textAlign: TextAlign.justify, // Alinhamento justificado
        style: const TextStyle(height: 1.5), // Espaçamento entre linhas
      ),
    );
  }
}