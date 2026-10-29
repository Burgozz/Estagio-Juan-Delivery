import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../perfil/models/usuario.dart';
import '../../perfil/services/usuario_service.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/cpf_validator.dart';
import '../../../core/widgets/label_obrigatorio.dart';
import '../../../core/theme/app_colors.dart';

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;
  const UsuarioFormScreen({super.key, this.usuario});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final service = UsuarioService();
  String? _emailApiError;
  String? _nomeApiError;
  String? _cpfApiError;
  String? _telefoneApiError;
  String? _senhaApiError;

  @override
  void initState() {
    super.initState();
    if (widget.usuario != null) {
      _nomeCtrl.text = widget.usuario!.nome;
      _cpfCtrl.text = formatarCpf(widget.usuario!.cpf);
      _emailCtrl.text = widget.usuario!.email;
      _senhaCtrl.text = widget.usuario!.senha;
      _telefoneCtrl.text = formatarTelefone(widget.usuario!.telefone);
    }
  }

  Future<void> _salvar() async {
    setState(() {
      _emailApiError = null;
      _nomeApiError = null;
      _cpfApiError = null;
      _telefoneApiError = null;
      _senhaApiError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    final u = Usuario(
      nome: _nomeCtrl.text.trim(),
      cpf: somenteDigitos(_cpfCtrl.text),
      email: _emailCtrl.text.trim(),
      senha: _senhaCtrl.text.trim(),
      telefone: somenteDigitos(_telefoneCtrl.text).isEmpty ? null : somenteDigitos(_telefoneCtrl.text),
      dataCadastro: widget.usuario?.dataCadastro,
    );
    try {
      if (widget.usuario == null) {
        await service.criar(u);
      } else {
        await service.atualizar(widget.usuario!.id!, u);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        final msgLower = mensagem.toLowerCase();
        // "Domínio de e-mail inválido ou inexistente" (EmailDominioValido) também
        // é erro do campo email, apesar de escrito com hífen.
        if (msgLower.contains('email') || msgLower.contains('e-mail') || msgLower.contains('domínio')) {
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
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.usuario != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'EDITAR USUÁRIO' : 'NOVO USUÁRIO'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeCtrl,
                style: const TextStyle(color: kTextPrimary),
                cursorColor: kPrimary,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ ]')),
                ],
                decoration: const InputDecoration(
                  label: LabelObrigatorio('Nome'),
                  prefixIcon: Icon(Icons.person_outline, color: kTextSecondary, size: 20),
                ),
                onChanged: (_) {
                  if (_nomeApiError != null) setState(() => _nomeApiError = null);
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o nome';
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
                style: const TextStyle(color: kTextPrimary),
                cursorColor: kPrimary,
                keyboardType: TextInputType.number,
                inputFormatters: [CpfInputFormatter()],
                decoration: const InputDecoration(
                  label: LabelObrigatorio('CPF'),
                  hintText: 'XXX.XXX.XXX-XX',
                  prefixIcon: Icon(Icons.badge_outlined, color: kTextSecondary, size: 20),
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
                controller: _emailCtrl,
                style: const TextStyle(color: kTextPrimary),
                cursorColor: kPrimary,
                decoration: const InputDecoration(
                  label: LabelObrigatorio('Email'),
                  prefixIcon: Icon(Icons.email_outlined, color: kTextSecondary, size: 20),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (_emailApiError != null) setState(() => _emailApiError = null);
                },
                validator: (v) {
                  if (v!.isEmpty) return 'Informe o email';
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!regex.hasMatch(v.trim())) return 'Email inválido (ex: nome@dominio.com)';
                  if (_emailApiError != null) return _emailApiError;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _senhaCtrl,
                style: const TextStyle(color: kTextPrimary),
                cursorColor: kPrimary,
                obscureText: true,
                decoration: const InputDecoration(
                  label: LabelObrigatorio('Senha'),
                  prefixIcon: Icon(Icons.lock_outline, color: kTextSecondary, size: 20),
                ),
                onChanged: (_) {
                  if (_senhaApiError != null) setState(() => _senhaApiError = null);
                },
                validator: (v) {
                  if (v!.isEmpty) return 'Informe a senha';
                  if (_senhaApiError != null) return _senhaApiError;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _telefoneCtrl,
                style: const TextStyle(color: kTextPrimary),
                cursorColor: kPrimary,
                keyboardType: TextInputType.number,
                inputFormatters: [TelefoneInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(XX) XXXXX-XXXX',
                  prefixIcon: Icon(Icons.phone_outlined, color: kTextSecondary, size: 20),
                ),
                onChanged: (_) {
                  if (_telefoneApiError != null) setState(() => _telefoneApiError = null);
                },
                validator: (v) {
                  final digits = somenteDigitos(v);
                  if (digits.isEmpty) return _telefoneApiError;
                  if (digits.length < 10 || digits.length > 11) {
                    return 'Telefone deve ter 10 ou 11 dígitos (com DDD)';
                  }
                  if (digits[0] == '0') return 'DDD inválido (não pode começar com 0)';
                  if (_telefoneApiError != null) return _telefoneApiError;
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: Text(isEditing ? 'ATUALIZAR' : 'CADASTRAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
