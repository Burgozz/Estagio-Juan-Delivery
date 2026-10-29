import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/cpf_validator.dart';
import '../../../core/session/sessao_usuario.dart';
import '../../../core/widgets/label_obrigatorio.dart';
import '../../../core/theme/app_colors.dart';

/// Exibe os dados do usuário logado (buscados via GET /usuarios/{id}, já
/// que a sessão guarda apenas nome/e-mail) e permite editá-los.
class MeusDadosScreen extends StatefulWidget {
  const MeusDadosScreen({super.key});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  final _service = UsuarioService();
  Usuario? _usuario;
  bool _carregando = true;
  String? _erro;
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final usuario = await _service.buscarPorId(SessaoUsuario.id!);
      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  Future<void> _aoSalvar(Usuario atualizado) async {
    setState(() {
      _usuario = atualizado;
      _editando = false;
    });

    SessaoUsuario.salvar(
      id: SessaoUsuario.id,
      nome: atualizado.nome,
      email: atualizado.email,
      perfil: SessaoUsuario.perfil,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario_nome', atualizado.nome);
    await prefs.setString('usuario_email', atualizado.email);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados atualizados com sucesso'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Meus Dados'),
        backgroundColor: kPrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_erro!, style: const TextStyle(color: kTextPrimary), textAlign: TextAlign.center),
        ),
      );
    }
    final usuario = _usuario!;
    if (_editando) {
      return _MeusDadosForm(
        usuario: usuario,
        onCancelar: () => setState(() => _editando = false),
        onSalvo: _aoSalvar,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _DadoCard(icone: Icons.person_outline, label: 'Nome', valor: usuario.nome),
        _DadoCard(icone: Icons.email_outlined, label: 'E-mail', valor: usuario.email),
        _DadoCard(icone: Icons.badge_outlined, label: 'CPF', valor: formatarCpf(usuario.cpf)),
        _DadoCard(
          icone: Icons.phone_outlined,
          label: 'Telefone',
          valor: (usuario.telefone == null || usuario.telefone!.isEmpty) ? 'Não informado' : formatarTelefone(usuario.telefone),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => setState(() => _editando = true),
          child: const Text('EDITAR DADOS'),
        ),
      ],
    );
  }
}

class _DadoCard extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;

  const _DadoCard({required this.icone, required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icone, color: kPrimary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulário de edição dos dados básicos, reaproveitando as mesmas
/// validações de [UsuarioFormScreen]. A senha não é exibida nem alterada
/// aqui (ver AlterarSenhaScreen); o valor já cadastrado é reenviado
/// intacto porque o backend exige o campo em PUT /usuarios/{id}.
class _MeusDadosForm extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onCancelar;
  final ValueChanged<Usuario> onSalvo;

  const _MeusDadosForm({required this.usuario, required this.onCancelar, required this.onSalvo});

  @override
  State<_MeusDadosForm> createState() => _MeusDadosFormState();
}

class _MeusDadosFormState extends State<_MeusDadosForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeCtrl = TextEditingController(text: widget.usuario.nome);
  late final _cpfCtrl = TextEditingController(text: formatarCpf(widget.usuario.cpf));
  late final _emailCtrl = TextEditingController(text: widget.usuario.email);
  late final _telefoneCtrl = TextEditingController(text: formatarTelefone(widget.usuario.telefone));
  final _service = UsuarioService();
  bool _salvando = false;
  String? _emailApiError;
  String? _nomeApiError;
  String? _cpfApiError;
  String? _telefoneApiError;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _emailApiError = null;
      _nomeApiError = null;
      _cpfApiError = null;
      _telefoneApiError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final atualizado = Usuario(
      id: widget.usuario.id,
      nome: _nomeCtrl.text.trim(),
      cpf: somenteDigitos(_cpfCtrl.text),
      email: _emailCtrl.text.trim(),
      senha: widget.usuario.senha,
      telefone: somenteDigitos(_telefoneCtrl.text).isEmpty ? null : somenteDigitos(_telefoneCtrl.text),
      dataCadastro: widget.usuario.dataCadastro,
    );
    try {
      await _service.atualizar(widget.usuario.id!, atualizado);
      widget.onSalvo(atualizado);
    } catch (e) {
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        final msgLower = mensagem.toLowerCase();
        if (msgLower.contains('email')) {
          setState(() => _emailApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('cpf')) {
          setState(() => _cpfApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('telefone')) {
          setState(() => _telefoneApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('nome')) {
          setState(() => _nomeApiError = mensagem);
          _formKey.currentState!.validate();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCampoNome(),
            const SizedBox(height: 20),
            _buildCampoCpf(),
            const SizedBox(height: 20),
            _buildCampoEmail(),
            const SizedBox(height: 20),
            _buildCampoTelefone(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('SALVAR'),
            ),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: kTextSecondary),
              onPressed: _salvando ? null : widget.onCancelar,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoNome() {
    return TextFormField(
      controller: _nomeCtrl,
      style: const TextStyle(color: kTextPrimary),
      cursorColor: kPrimary,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ ]'))],
      decoration: const InputDecoration(
        label: LabelObrigatorio('Nome'),
        prefixIcon: Icon(Icons.person_outline, color: kTextSecondary, size: 20),
      ),
      onChanged: (_) {
        if (_nomeApiError != null) setState(() => _nomeApiError = null);
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Informe o nome';
        if (!RegExp(r'^[a-zA-ZÀ-ÿ ]+$').hasMatch(v)) return 'Nome deve conter apenas letras';
        if (_nomeApiError != null) return _nomeApiError;
        return null;
      },
    );
  }

  Widget _buildCampoCpf() {
    return TextFormField(
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
    );
  }

  Widget _buildCampoEmail() {
    return TextFormField(
      controller: _emailCtrl,
      style: const TextStyle(color: kTextPrimary),
      cursorColor: kPrimary,
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) {
        if (_emailApiError != null) setState(() => _emailApiError = null);
      },
      decoration: const InputDecoration(
        label: LabelObrigatorio('Email'),
        prefixIcon: Icon(Icons.email_outlined, color: kTextSecondary, size: 20),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Informe o email';
        final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!regex.hasMatch(v.trim())) return 'Email inválido (ex: nome@dominio.com)';
        if (_emailApiError != null) return _emailApiError;
        return null;
      },
    );
  }

  Widget _buildCampoTelefone() {
    return TextFormField(
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
        if (digits.length < 10 || digits.length > 11) return 'Telefone deve ter 10 ou 11 dígitos (com DDD)';
        if (digits[0] == '0') return 'DDD inválido (não pode começar com 0)';
        if (_telefoneApiError != null) return _telefoneApiError;
        return null;
      },
    );
  }
}
