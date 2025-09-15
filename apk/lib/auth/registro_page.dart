// lib/auth/register.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Realiza o cadastro do usuário no Supabase.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        // Adicionando o nome do usuário aos metadados.
        // Isso é útil para exibir o nome dele no app depois.
        data: {'full_name': name},
      );

      //Verifica se o widget ainda está montado.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado! Verifique seu e-mail para confirmação.'),
          backgroundColor: Colors.green,
        ),
      );
      // Volta para a tela de login após o sucesso.
      Navigator.pop(context);

    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro inesperado.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Image.asset(
                'assets/logo.png',
                height: 100,),
                // Usando o widget de logo para consistência.
                  const SizedBox(height: 40),


                  // --- Campo Nome ---
                  const Text('Nome completo', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Insira seu nome',border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.0)),
                      validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira seu nome.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // --- Campo E-mail ---
                  const Text('E-mail', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'Insira seu e-mail',border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.0)),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira seu e-mail.';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Por favor, insira um e-mail válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // --- Campo Senha ---
                  const Text('Senha', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Insira sua senha',border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0)),
                    //Validador de senha complexa.
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira uma senha.';
                      }
                      if (value.length < 8) {
                        return 'A senha deve ter no mínimo 8 caracteres.';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'A senha deve conter uma letra maiúscula.';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'A senha deve conter uma letra minúscula.';
                      }
                      if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
                        return 'A senha deve conter um caractere especial.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // --- Campo Confirme a Senha ---
                  const Text('Confirme a senha', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Repita sua senha',border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha.';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30.0),

                  // --- Botão de Cadastrar ---
                  ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[400], //Cor consistente
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : const Text('Cadastrar-se', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16.0),

                  // --- Link para Login ---
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Já possuo uma conta',
                      style: TextStyle(
                        color: Colors.grey[600],
                         //Estilo consistente
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}