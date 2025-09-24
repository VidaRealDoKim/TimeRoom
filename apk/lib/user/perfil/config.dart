import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Tela de Configurações do Aplicativo
// -----------------------------------------------------------------------------
class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  // ---------------------------------------------------------------------------
  // Estado do Widget (State)
  // Variáveis que controlam os valores das configurações na tela.
  // ---------------------------------------------------------------------------

  // Controla o estado do switch de notificações.
  bool _notificacoesGerais = true;
  // Controla o tema selecionado (exemplo, não muda o app inteiro ainda).
  String _temaSelecionado = 'Sistema';

  // ---------------------------------------------------------------------------
  // Build (Construção da Interface)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Título da página.
        title: const Text('Configurações'),
        // Cor de fundo da AppBar.
        backgroundColor: const Color(0xFF1ABC9C),
      ),
      body: ListView(
        // ListView permite que a tela role se houver muitas opções.
        children: [
          // Seção de Notificações
          _buildSectionHeader('Notificações'),
          SwitchListTile(
            title: const Text('Receber notificações gerais'),
            subtitle: const Text('Avisos sobre reservas e novidades.'),
            value: _notificacoesGerais,
            onChanged: (bool value) {
              setState(() {
                _notificacoesGerais = value;
              });
              // TODO: Salvar esta preferência no dispositivo ou no perfil do usuário.
            },
            activeColor: const Color(0xFF1ABC9C),
          ),

          // Seção de Aparência
          _buildSectionHeader('Aparência'),
          ListTile(
            title: const Text('Tema'),
            subtitle: Text(_temaSelecionado),
            onTap: _mostrarDialogoDeTema,
            leading: const Icon(Icons.palette_outlined),
          ),

          // Seção de Conta
          _buildSectionHeader('Conta'),
          ListTile(
            title: const Text('Alterar Senha'),
            leading: const Icon(Icons.lock_outline),
            onTap: () {
              // TODO: Navegar para uma tela específica de alteração de senha.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Função de alterar senha a ser implementada.')),
              );
            },
          ),
          ListTile(
            title: const Text('Excluir Conta', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: _confirmarExclusaoConta,
          ),

          // Seção Sobre
          _buildSectionHeader('Sobre'),
          ListTile(
            title: const Text('Termos de Serviço'),
            leading: const Icon(Icons.description_outlined),
            onTap: () { /* TODO: Abrir link para os termos */ },
          ),
          ListTile(
            title: const Text('Política de Privacidade'),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () { /* TODO: Abrir link para a política */ },
          ),
          const ListTile(
            title: Text('Versão do App'),
            subtitle: Text('1.0.0'), // Exemplo de versão
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets Auxiliares e Lógica
  // ---------------------------------------------------------------------------

  // Constrói um cabeçalho de seção para organizar as opções.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Mostra um pop-up (AlertDialog) para o usuário escolher o tema.
  void _mostrarDialogoDeTema() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escolha um tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Claro'),
                value: 'Claro',
                groupValue: _temaSelecionado,
                onChanged: (value) => _selecionarTema(value!),
              ),
              RadioListTile<String>(
                title: const Text('Escuro'),
                value: 'Escuro',
                groupValue: _temaSelecionado,
                onChanged: (value) => _selecionarTema(value!),
              ),
              RadioListTile<String>(
                title: const Text('Padrão do Sistema'),
                value: 'Sistema',
                groupValue: _temaSelecionado,
                onChanged: (value) => _selecionarTema(value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            )
          ],
        );
      },
    );
  }

  // Atualiza o estado do tema selecionado e fecha o diálogo.
  void _selecionarTema(String tema) {
    setState(() {
      _temaSelecionado = tema;
    });
    // TODO: Adicionar lógica para de fato mudar o tema do aplicativo.
    Navigator.of(context).pop();
  }

  // Mostra um diálogo de confirmação antes de uma ação destrutiva como excluir a conta.
  void _confirmarExclusaoConta() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Conta'),
          content: const Text('Esta ação é permanente e não pode ser desfeita. Tem certeza que deseja continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implementar a lógica real de exclusão de conta no Supabase.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conta excluída (simulação).')),
                );
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}
