import 'package:apk/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Importar o pacote para guardar dados
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// -----------------------------------------------------------------------------
/// Tela de Configurações do Aplicativo
/// -----------------------------------------------------------------------------
/// Permite que o utilizador altere as suas preferências de notificações, tema,
/// e faça a gestão da sua conta.
/// -----------------------------------------------------------------------------
class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  // Variável para guardar o estado atual do switch de notificações.
  bool _notificacoesGerais = true; // Valor inicial padrão

  // initState é chamado uma única vez quando o widget é criado.
  @override
  void initState() {
    super.initState();
    // Quando a tela é aberta, carregamos a última escolha do utilizador.
    _carregarPreferenciaNotificacoes();
  }

  /// Carrega o valor guardado para as notificações a partir do armazenamento local.
  Future<void> _carregarPreferenciaNotificacoes() async {
    final prefs = await SharedPreferences.getInstance();
    // Lemos o valor da chave 'notificacoes_gerais'.
    // Se não existir (??), o valor padrão é 'true'.
    setState(() {
      _notificacoesGerais = prefs.getBool('notificacoes_gerais') ?? true;
    });
  }

  /// Guarda o novo valor para as notificações no armazenamento local.
  Future<void> _guardarPreferenciaNotificacoes(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    // Guardamos o novo valor booleano na chave 'notificacoes_gerais'.
    prefs.setBool('notificacoes_gerais', value);
  }

  @override
  Widget build(BuildContext context) {
    // Acedemos ao ThemeProvider para obter o estado do tema.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Notificações'),
          // --- SwitchListTile agora é totalmente funcional ---
          SwitchListTile(
            title: const Text('Receber notificações gerais'),
            subtitle: const Text('Avisos sobre reservas e novidades.'),
            value: _notificacoesGerais,
            onChanged: (value) {
              // 1. Atualizamos o estado visual do switch imediatamente.
              setState(() => _notificacoesGerais = value);
              // 2. Chamamos a função para guardar permanentemente a nova escolha.
              _guardarPreferenciaNotificacoes(value);

              // Feedback visual para o utilizador.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? 'Notificações ativadas' : 'Notificações desativadas'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),

          _buildSectionHeader('Aparência'),
          ListTile(
            title: const Text('Tema'),
            subtitle: Text(themeProvider.themeModeString),
            leading: const Icon(Icons.palette_outlined),
            onTap: () => _mostrarDialogoDeTema(context, themeProvider),
          ),

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

          _buildSectionHeader('Sobre'),
          ListTile(
            title: const Text('Termos de Serviço'),
            leading: const Icon(Icons.description_outlined),
            onTap: () {
              Navigator.pushNamed(context, '/termos');
            },
          ),
          ListTile(
            title: const Text('Política de Privacidade'),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () {
              Navigator.pushNamed(context, '/politica');
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

  /// Constrói um cabeçalho de secção formatado.
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

  /// Mostra um diálogo para o utilizador escolher o tema, com botão de salvar.
  void _mostrarDialogoDeTema(BuildContext context, ThemeProvider themeProvider) {
    String tempThemeSelection = themeProvider.themeModeString;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Escolha um tema'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['Claro', 'Escuro', 'Sistema'].map((tema) {
                  return RadioListTile<String>(
                    title: Text(tema),
                    value: tema,
                    groupValue: tempThemeSelection,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          tempThemeSelection = value;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    themeProvider.setTheme(tempThemeSelection);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Lógica para alterar a senha (a implementar).
  void _alterarSenha() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Função de alterar senha ainda não implementada.'),
      ),
    );
  }

  /// Mostra um diálogo de confirmação antes de excluir a conta.
  void _confirmarExclusaoConta() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Conta'),
          content: const Text(
              'Esta ação é permanente. Tem a certeza de que deseja continuar?'),
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

  /// Lógica para excluir a conta e todos os dados associados.
  Future<void> _excluirConta() async {
    Navigator.of(context).pop();
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Utilizador não autenticado');
      final userId = user.id;
      await supabase.from('reservas').delete().eq('user_id', userId);
      await supabase.from('reservas_log').delete().eq('usuario_id', userId);
      await supabase.from('feedback_salas').delete().eq('usuario_id', userId);
      await supabase.from('salas_favoritas').delete().eq('usuario_id', userId);
      await supabase.from('profiles').delete().eq('id', userId);
      await supabase.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta excluída com sucesso!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir conta: $e')),
      );
    }
  }
}

