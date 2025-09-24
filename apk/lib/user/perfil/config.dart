import 'package:apk/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// -----------------------------------------------------------------------------
// Tela de Configurações do Aplicativo (Versão com botão Salvar)
// ** ATUALIZADO para StatefulWidget para gerenciar a seleção temporária do tema **
// -----------------------------------------------------------------------------
class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  // ---------------------------------------------------------------------------
  // Build (Construção da Interface)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Acessamos o ThemeProvider para obter o estado atual
    // e para chamar a função que muda o tema.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          // Seção de Notificações (exemplo)
          _buildSectionHeader('Notificações'),
          SwitchListTile(
            title: const Text('Receber notificações gerais'),
            value: true, // Lógica a ser implementada
            onChanged: (bool value) {},
            activeColor: Theme.of(context).colorScheme.primary,
          ),

          // Seção de Aparência
          _buildSectionHeader('Aparência'),
          ListTile(
            title: const Text('Tema'),
            // Mostra o tema selecionado atualmente.
            subtitle: Text(themeProvider.themeModeString),
            onTap: () => _mostrarDialogoDeTema(context, themeProvider),
            leading: const Icon(Icons.palette_outlined),
          ),

          // Seção de Conta
          _buildSectionHeader('Conta'),
          ListTile(
            title: const Text('Alterar Senha'),
            leading: const Icon(Icons.lock_outline),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Excluir Conta', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets Auxiliares e Lógica
  // ---------------------------------------------------------------------------

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

  // ATUALIZAÇÃO: O diálogo agora tem um estado interno para a seleção temporária
  // e um botão "Salvar" para aplicar a mudança.
  void _mostrarDialogoDeTema(BuildContext context, ThemeProvider themeProvider) {
    // Variável para guardar a escolha do usuário ANTES de ele clicar em salvar.
    String tempThemeSelection = themeProvider.themeModeString;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder permite que o conteúdo do diálogo tenha seu próprio estado e se atualize.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Escolha um tema'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Claro'),
                    value: 'Claro',
                    groupValue: tempThemeSelection,
                    onChanged: (value) {
                      setDialogState(() {
                        tempThemeSelection = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Escuro'),
                    value: 'Escuro',
                    groupValue: tempThemeSelection,
                    onChanged: (value) {
                      setDialogState(() {
                        tempThemeSelection = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Padrão do Sistema'),
                    value: 'Sistema',
                    groupValue: tempThemeSelection,
                    onChanged: (value) {
                      setDialogState(() {
                        tempThemeSelection = value!;
                      });
                    },
                  ),
                ],
              ),
              // ATUALIZAÇÃO: Adicionamos botões de Ação.
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Só aqui, ao clicar em Salvar, chamamos a função para mudar o tema.
                    themeProvider.setTheme(tempThemeSelection);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Salvar'),
                )
              ],
            );
          },
        );
      },
    );
  }
}

