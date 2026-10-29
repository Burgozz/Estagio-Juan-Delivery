import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main_screen.dart';
import '../services/auth_service.dart';
import '../../../core/theme/auth_theme.dart';
import '../../../core/session/sessao_usuario.dart';
import 'cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _senhaFocus = FocusNode();
  final _service = AuthService();
  bool _carregando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      final dados = await _service.login(_emailCtrl.text.trim(), _senhaCtrl.text.trim());
      // Guarda os dados básicos do usuário logado para uso em telas como a
      // InicioScreen (saudação personalizada).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario_nome', (dados['nome'] ?? '').toString());
      await prefs.setString('usuario_email', (dados['email'] ?? '').toString());
      final id = dados['id'];
      if (id != null) {
        await prefs.setInt('usuario_id', int.tryParse(id.toString()) ?? 0);
      }
      // Guarda o perfil retornado pela API na sessão global, usada pela
      // MainScreen para decidir quais telas o usuário pode acessar.
      SessaoUsuario.salvar(
        id: id == null ? null : int.tryParse(id.toString()),
        nome: (dados['nome'] ?? '').toString(),
        email: (dados['email'] ?? '').toString(),
        perfil: dados['perfil']?.toString(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAuthBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.wine_bar, size: 64, color: kAuthTitle),
                  const SizedBox(height: 12),
                  const Text(
                    'JUAN DELIVERY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kAuthTitle,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: kAuthFieldText),
                    cursorColor: kAuthFieldBorderFocused,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _senhaFocus.requestFocus(),
                    decoration: authInputDecoration(
                      label: 'E-mail',
                      icon: Icons.email_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o e-mail';
                      }
                      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!regex.hasMatch(v.trim())) {
                        return 'E-mail inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _senhaCtrl,
                    focusNode: _senhaFocus,
                    style: const TextStyle(color: kAuthFieldText),
                    cursorColor: kAuthFieldBorderFocused,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _entrar(),
                    decoration: authInputDecoration(
                      label: 'Senha',
                      icon: Icons.lock_outline,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe a senha' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: authButtonStyle,
                      onPressed: _carregando ? null : _entrar,
                      child: _carregando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('ENTRAR'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuthLinkButton(
                    texto: 'Não tem conta? ',
                    trechoDestaque: 'Cadastre-se',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CadastroScreen()),
                      );
                    },
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
