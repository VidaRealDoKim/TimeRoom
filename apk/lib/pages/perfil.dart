import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Widget da Tela de Perfil
// Convertido para StatefulWidget para permitir interatividade, como o botão
// de notificação e as ações de clique.
// -----------------------------------------------------------------------------
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  // ---------------------------------------------------------------------------
  // Estado do Widget (State)
  // Variáveis que controlam os dados que podem mudar na tela.
  // ---------------------------------------------------------------------------

  // Variável para controlar o estado do Switch de notificações.
  bool _notificacoesAtivadas = true;

  // Índice da aba selecionada na barra de navegação inferior.
  int _selectedIndex = 3; // Inicia na aba "Perfil"

  // ---------------------------------------------------------------------------
  // Build (Construção da Interface)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // A ESTRUTURA PRINCIPAL (SCAFFOLD, APPBAR, BOTTOMNAVBAR) FOI REMOVIDA
    // POIS O DASHBOARD JÁ CONTROLA ISSO.
    // Retornamos apenas o conteúdo que deve aparecer na tela.
    return _buildBody();
  }

  // A AppBar não é mais necessária nesta tela.
  // PreferredSizeWidget _buildAppBar() { ... }

  // Constrói o corpo principal da tela.
  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      children: [
        const SizedBox(height: 20),
        // Seção com as informações do usuário (foto, nome, email).
        _buildUserInfo(),
        const SizedBox(height: 40),
        // Lista de opções do menu.
        _buildMenuOption(
          icon: Icons.person_outline,
          text: 'My Profile',
          onTap: () {
            // TODO: Navegar para a tela de edição de perfil.
            print('Clicou em My Profile');
          },
        ),
        _buildMenuOption(
          icon: Icons.settings_outlined,
          text: 'Settings',
          onTap: () {
            // TODO: Navegar para a tela de configurações.
            print('Clicou em Settings');
          },
        ),
        // Opção de notificação com um Switch funcional.
        _buildNotificationOption(),
        _buildMenuOption(
          icon: Icons.logout,
          text: 'Log Out',
          onTap: () {
            // TODO: Implementar a lógica de logout (ex: Supabase).
            print('Clicou em Log Out');
            // Exemplo de como navegar para a tela de login após o logout.
            // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          },
        ),
      ],
    );
  }

  // Constrói a seção de informações do usuário.
  Widget _buildUserInfo() {
    return Row(
      children: [
        // Avatar do usuário.
        const CircleAvatar(
          radius: 35,
          // Em um app real, esta imagem viria da URL do perfil do usuário.
          backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=2960&auto=format&fit=crop'),
        ),
        const SizedBox(width: 15),
        // Coluna com nome e email.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your Name', // Em um app real, viria do banco de dados.
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'yourname@gmail.com', // Em um app real, viria do banco de dados.
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        )
      ],
    );
  }

  // Constrói um item de opção padrão do menu.
  Widget _buildMenuOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black54),
      title: Text(text, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Constrói o item de notificação, que é especial por ter um Switch.
  Widget _buildNotificationOption() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notifications_outlined, color: Colors.black54),
      title: const Text('Notification', style: TextStyle(fontSize: 16)),
      // O trailing aqui é o Switch funcional.
      trailing: Switch(
        value: _notificacoesAtivadas,
        // O onChanged é chamado sempre que o usuário toca no Switch.
        onChanged: (bool value) {
          // setState() avisa o Flutter para redesenhar a tela com o novo valor.
          setState(() {
            _notificacoesAtivadas = value;
          });
        },
        activeColor: const Color(0xFF1ABC9C), // Cor verde-água
      ),
    );
  }

// A BARRA DE NAVEGAÇÃO FOI REMOVIDA DAQUI.
// O DASHBOARD JÁ TEM A SUA PRÓPRIA BARRA DE NAVEGAÇÃO.

}

