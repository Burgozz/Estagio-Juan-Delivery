import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/carrinho/controllers/carrinho_controller.dart';
import '../theme/app_colors.dart';
import 'sessao_usuario.dart';

/// Chaves do shared_preferences ligadas à sessão do usuário logado.
const chavesSessao = ['usuario_nome', 'usuario_email', 'usuario_id', 'home_tab_index'];

/// Pergunta "Deseja sair da conta?" e, se confirmado, faz o logout.
/// Usado pelo cliente (tela de Perfil) e pelo admin (AppBar das listas).
Future<void> confirmarSairDaConta(BuildContext context) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Sair da conta',
        style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
      ),
      content: const Text(
        'Deseja sair da conta?',
        style: TextStyle(color: kTextPrimary),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: kTextSecondary),
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: kPerigo),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sair', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  if (confirmar != true || !context.mounted) return;
  await sairDaConta(context);
}

/// Limpa a sessão (memória e shared_preferences) e o carrinho, e volta para
/// o login removendo todas as telas anteriores.
Future<void> sairDaConta(BuildContext context) async {
  final navigator = Navigator.of(context);
  SessaoUsuario.limpar();
  CarrinhoController.instance.limpar();
  final prefs = await SharedPreferences.getInstance();
  for (final chave in chavesSessao) {
    await prefs.remove(chave);
  }
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// Botão de sair para a AppBar (ícone de logout com tooltip "Sair").
class BotaoSair extends StatelessWidget {
  const BotaoSair({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sair',
      onPressed: () => confirmarSairDaConta(context),
    );
  }
}
