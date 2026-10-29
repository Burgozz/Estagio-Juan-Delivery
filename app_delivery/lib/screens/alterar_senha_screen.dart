import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../core/session/sessao_usuario.dart';
import '../core/widgets/label_obrigatorio.dart';

const kPrimary = Color(0xFF3C0731);
const kBackground = Color(0xFFFAFAFA);
const kTextPrimary = Color(0xFF212121);
const kTextSecondary = Color(0xFF757575);

/// Permite ao usuário logado trocar a própria senha. Como o backend não
/// tem um endpoint dedicado, os demais dados do usuário são recarregados
/// via GET /usuarios/{id} e reenviados intactos em PUT /usuarios/{id},
/// junto da nova senha.
class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key});

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _atualCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  final _service = UsuarioService();

  bool _mostrarAtual = false;
  bool _mostrarNova = false;
  bool _mostrarConfirmar = false;
  bool _salvando = false;

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final usuario = await _service.buscarPorId(SessaoUsuario.id!);
      if (usuario.senha != _atualCtrl.text) {
        setState(() => _salvando = false);
        _formKey.currentState!.validate();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Senha atual incorreta'), backgroundColor: Colors.red.shade700),
        );
        return;
      }
      final atualizado = Usuario(
        id: usuario.id,
        nome: usuario.nome,
        cpf: usuario.cpf,
        email: usuario.email,
        senha: _novaCtrl.text,
        telefone: usuario.telefone,
        dataCadastro: usuario.dataCadastro,
      );
      await _service.atualizar(usuario.id!, atualizado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Alterar Senha'),
        backgroundColor: kPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _atualCtrl,
                style: const TextStyle(color: kTextPrimary),
                cursorColor: kPrimary,
                obscureText: !_mostrarAtual,
                decoration: InputDecoration(
                  label: LabelObrigatorio('Senha atual'),
                  prefixIcon: const Icon(Icons.lock_outline, color: kTextSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_mostrarAtual ? Icons.visibility_off : Icons.visibility, color: kTextSecondary, size: 20),
                    onPressed: () => setState(() => _mostrarAtual = !_mostrarAtual),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Informe a senha atual' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _novaCtrl,
                style: const TextStyle(color: kTextPrimary),
                cursorColor: kPrimary,
                obscureText: !_mostrarNova,
                decoration: InputDecoration(
                  label: LabelObrigatorio('Nova senha'),
                  prefixIcon: const Icon(Icons.lock_outline, color: kTextSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_mostrarNova ? Icons.visibility_off : Icons.visibility, color: kTextSecondary, size: 20),
                    onPressed: () => setState(() => _mostrarNova = !_mostrarNova),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a nova senha';
                  if (v == _atualCtrl.text) return 'A nova senha não pode ser igual à atual';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmarCtrl,
                style: const TextStyle(color: kTextPrimary),
                cursorColor: kPrimary,
                obscureText: !_mostrarConfirmar,
                decoration: InputDecoration(
                  label: LabelObrigatorio('Confirmar nova senha'),
                  prefixIcon: const Icon(Icons.lock_outline, color: kTextSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_mostrarConfirmar ? Icons.visibility_off : Icons.visibility, color: kTextSecondary, size: 20),
                    onPressed: () => setState(() => _mostrarConfirmar = !_mostrarConfirmar),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirme a nova senha';
                  if (v != _novaCtrl.text) return 'As senhas não coincidem';
                  return null;
                },
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}
