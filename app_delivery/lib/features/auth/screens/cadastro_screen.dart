import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../perfil/models/usuario.dart';
import '../../perfil/services/usuario_service.dart';
import '../../../core/theme/auth_theme.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/cpf_validator.dart';
import 'login_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _service = UsuarioService();
  bool _carregando = false;
  String? _emailApiError;
  String? _nomeApiError;
  String? _cpfApiError;
  String? _telefoneApiError;
  String? _senhaApiError;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    setState(() {
      _emailApiError = null;
      _nomeApiError = null;
      _cpfApiError = null;
      _telefoneApiError = null;
      _senhaApiError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    final usuario = Usuario(
      nome: _nomeCtrl.text.trim(),
      cpf: somenteDigitos(_cpfCtrl.text),
      email: _emailCtrl.text.trim(),
      senha: _senhaCtrl.text.trim(),
      telefone: somenteDigitos(_telefoneCtrl.text),
    );
    try {
      await _service.criar(usuario);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        final msgLower = mensagem.toLowerCase();
        if (msgLower.contains('email') || msgLower.contains('e-mail')) {
          setState(() => _emailApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('cpf')) {
          setState(() => _cpfApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('telefone')) {
          setState(() => _telefoneApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('senha')) {
          setState(() => _senhaApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('nome')) {
          setState(() => _nomeApiError = mensagem);
          _formKey.currentState!.validate();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagem),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAuthBackground,
      appBar: AppBar(
        title: const Text('CADASTRO'),
        backgroundColor: kAuthBackground,
        foregroundColor: kAuthTitle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kAuthCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeCtrl,
                  style: const TextStyle(color: kAuthFieldText),
                  cursorColor: kAuthFieldBorderFocused,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ ]')),
                  ],
                  decoration: authInputDecoration(
                    label: 'Nome completo',
                    icon: Icons.person_outline,
                  ),
                  onChanged: (_) {
                    if (_nomeApiError != null) setState(() => _nomeApiError = null);
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o nome';
                    final tamanho = v.trim().length;
                    if (tamanho < 2 || tamanho > 100) return 'Nome deve ter entre 2 e 100 caracteres';
                    if (!RegExp(r'^[a-zA-ZÀ-ÿ ]+$').hasMatch(v)) {
                      return 'Nome deve conter apenas letras';
                    }
                    if (_nomeApiError != null) return _nomeApiError;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _cpfCtrl,
                  style: const TextStyle(color: kAuthFieldText),
                  cursorColor: kAuthFieldBorderFocused,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CpfInputFormatter()],
                  decoration: authInputDecoration(
                    label: 'CPF',
                    hint: 'XXX.XXX.XXX-XX',
                    icon: Icons.badge_outlined,
                  ),
                  onChanged: (_) {
                    if (_cpfApiError != null) setState(() => _cpfApiError = null);
                  },
                  validator: (v) {
                    final digits = somenteDigitos(v);
                    if (digits.isEmpty) return 'Informe o CPF';
                    if (!cpfValido(digits)) return 'CPF inválido';
                    if (_cpfApiError != null) return _cpfApiError;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _telefoneCtrl,
                  style: const TextStyle(color: kAuthFieldText),
                  cursorColor: kAuthFieldBorderFocused,
                  keyboardType: TextInputType.number,
                  inputFormatters: [TelefoneInputFormatter()],
                  decoration: authInputDecoration(
                    label: 'Telefone',
                    hint: '(XX) XXXXX-XXXX',
                    icon: Icons.phone_outlined,
                  ),
                  onChanged: (_) {
                    if (_telefoneApiError != null) setState(() => _telefoneApiError = null);
                  },
                  validator: (v) {
                    final digits = somenteDigitos(v);
                    if (digits.isEmpty) return 'Informe o telefone';
                    if (digits.length < 10 || digits.length > 11) {
                      return 'Telefone deve ter 10 ou 11 dígitos (com DDD)';
                    }
                    if (digits[0] == '0') return 'DDD inválido (não pode começar com 0)';
                    if (_telefoneApiError != null) return _telefoneApiError;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: kAuthFieldText),
                  cursorColor: kAuthFieldBorderFocused,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailApiError != null) {
                      setState(() => _emailApiError = null);
                    }
                  },
                  decoration: authInputDecoration(
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o e-mail';
                    }
                    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!regex.hasMatch(v.trim())) return 'E-mail inválido';
                    if (_emailApiError != null) return _emailApiError;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _senhaCtrl,
                  style: const TextStyle(color: kAuthFieldText),
                  cursorColor: kAuthFieldBorderFocused,
                  obscureText: true,
                  decoration: authInputDecoration(
                    label: 'Senha',
                    icon: Icons.lock_outline,
                  ),
                  onChanged: (_) {
                    if (_senhaApiError != null) setState(() => _senhaApiError = null);
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    if (v.length < 6) return 'Senha deve ter no mínimo 6 caracteres';
                    if (_senhaApiError != null) return _senhaApiError;
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: authButtonStyle,
                    onPressed: _carregando ? null : _cadastrar,
                    child: _carregando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('CADASTRAR'),
                  ),
                ),
                const SizedBox(height: 12),
                AuthLinkButton(
                  texto: 'Já tem conta? ',
                  trechoDestaque: 'Entrar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
