import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// -----------------------------------------------------------------------------
/// Tela de Configurações do Aplicativo
/// -----------------------------------------------------------------------------
/// Permite que o usuário altere suas preferências, tema, senha e exclua sua conta.
/// Apenas afeta o usuário logado (sem privilégios de admin).
/// -----------------------------------------------------------------------------
class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  // ---------------------------------------------------------------------------
  // Estados do Widget
  // ---------------------------------------------------------------------------

  // Controla o switch de notificações.
  bool _notificacoesGerais = true;

  // Tema selecionado pelo usuário.
  String _temaSelecionado = 'Sistema';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: const Color(0xFF1ABC9C),
      ),
      body: ListView(
        children: [
          // ------------------------------ NOTIFICAÇÕES ------------------------------
          _buildSectionHeader('Notificações'),
          SwitchListTile(
            title: const Text('Receber notificações gerais'),
            subtitle: const Text('Avisos sobre reservas e novidades.'),
            value: _notificacoesGerais,
            onChanged: (value) {
              setState(() => _notificacoesGerais = value);
              // TODO: Salvar preferência no Supabase ou local storage
            },
            activeThumbColor: const Color(0xFF1ABC9C),
            activeTrackColor: const Color(0xFF80E5D8),
          ),

          // ------------------------------- APARÊNCIA -------------------------------
          _buildSectionHeader('Aparência'),
          ListTile(
            title: const Text('Tema'),
            subtitle: Text(_temaSelecionado),
            leading: const Icon(Icons.palette_outlined),
            onTap: _mostrarDialogoDeTema,
          ),

          // -------------------------------- CONTA ----------------------------------
          _buildSectionHeader('Conta'),
          ListTile(
            title: const Text('Alterar Senha'),
            leading: const Icon(Icons.lock_outline),
            onTap: _alterarSenha,
          ),
          ListTile(
            title: const Text(
              'Excluir Conta',
              style: TextStyle(color: Colors.red),
            ),
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: _confirmarExclusaoConta,
          ),

          // --------------------------------- SOBRE ----------------------------------
          _buildSectionHeader('Sobre'),
          ListTile(
            title: const Text('Termos de Serviço'),
            leading: const Icon(Icons.description_outlined),
            onTap: () {
              // TODO: Abrir link para os termos
            },
          ),
          ListTile(
            title: const Text('Política de Privacidade'),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () {
              // TODO: Abrir link para a política
            },
          ),
          const ListTile(
            title: Text('Versão do App'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS AUXILIARES
  // ---------------------------------------------------------------------------

  /// Constrói o cabeçalho de cada seção da tela
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

  /// Mostra um diálogo para o usuário escolher o tema
  void _mostrarDialogoDeTema() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escolha um tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Claro', 'Escuro', 'Sistema'].map((tema) {
              return RadioListTile<String>(
                title: Text(tema),
                value: tema,
                groupValue: _temaSelecionado,
                    onChanged: (value) {
                  if (value != null) {
                    setState(() => _temaSelecionado = value);
                    // TODO: Aplicar tema ao app
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Abre a tela ou fluxo para alterar senha do próprio usuário
  void _alterarSenha() {
    // TODO: Implementar tela de alteração de senha
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Função de alterar senha ainda não implementada.'),
      ),
    );
  }

  /// Mostra diálogo de confirmação antes de excluir conta
  void _confirmarExclusaoConta() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Conta'),
          content: const Text(
              'Esta ação é permanente e não pode ser desfeita. Tem certeza que deseja continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _excluirConta,
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // LÓGICA DE NEGÓCIO
  // ---------------------------------------------------------------------------

  /// Exclui todos os dados do usuário e a conta do Supabase
  Future<void> _excluirConta() async {
    Navigator.of(context).pop(); // fecha diálogo primeiro

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final userId = user.id;

      // Excluir dados relacionados
      await supabase.from('reservas').delete().eq('user_id', userId);
      await supabase.from('reservas_log').delete().eq('usuario_id', userId);
      await supabase.from('feedback_salas').delete().eq('usuario_id', userId);
      await supabase.from('salas_favoritas').delete().eq('usuario_id', userId);
      await supabase.from('profiles').delete().eq('id', userId);

      // Excluir usuário do auth
      await supabase.auth.admin.deleteUser(userId);
      await supabase.auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta excluída com sucesso!')),
      );

      Navigator.of(context).pop(); // fecha ConfigPage
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir conta: $e')),
      );
    }
  }
}
