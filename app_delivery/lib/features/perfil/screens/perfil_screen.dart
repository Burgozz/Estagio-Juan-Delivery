import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/session/sessao_usuario.dart';
import '../../auth/screens/login_screen.dart';
import 'meus_dados_screen.dart';
import 'endereco_screen.dart';
import 'alterar_senha_screen.dart';

const kPrimary = Color(0xFF3C0731);
const kGradienteFim = Color(0xFF5C1151);
const kBackground = Color(0xFFFAFAFA);
const kTextPrimary = Color(0xFF212121);
const kTextSecondary = Color(0xFF757575);
const kCreme = Color(0xFFF5E6C8);
const kPerigo = Color(0xFFD32F2F);

/// Tela de Perfil, terceira aba da BottomNavigationBar para usuários com
/// perfil CLIENTE. Reúne dados da conta, endereços, configurações e logout.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _sairDaConta(BuildContext context) async {
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
    if (confirmar != true) return;

    SessaoUsuario.limpar();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_nome');
    await prefs.remove('usuario_email');
    await prefs.remove('usuario_id');
    await prefs.remove('home_tab_index');

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _sobreOApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wine_bar, color: kPrimary),
            SizedBox(width: 10),
            Text('Juan Delivery', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Versão 1.0.0\n\n'
          'Seu marketplace de vinhos: descubra, compre e receba os melhores '
          'rótulos e acessórios com praticidade.',
          style: TextStyle(color: kTextPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kPrimary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = SessaoUsuario.nome ?? '';
    final email = SessaoUsuario.email ?? '';
    final inicial = nome.trim().isNotEmpty ? nome.trim()[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: kBackground,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(nome, email, inicial),
          const SizedBox(height: 20),
          _PerfilSectionTitle('Minha Conta'),
          _PerfilSection(
            children: [
              _PerfilItem(
                icon: Icons.person,
                titulo: 'Meus Dados',
                subtitulo: 'Nome, e-mail, CPF e telefone',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MeusDadosScreen()),
                ),
              ),
              _PerfilItem(
                icon: Icons.location_on,
                titulo: 'Meus Endereços',
                subtitulo: 'Endereços cadastrados',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EnderecoScreen()),
                ),
                ultimo: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _PerfilSectionTitle('Configurações'),
          _PerfilSection(
            children: [
              _PerfilItem(
                icon: Icons.lock,
                titulo: 'Alterar Senha',
                subtitulo: 'Redefina sua senha de acesso',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlterarSenhaScreen()),
                ),
              ),
              _PerfilItem(
                icon: Icons.notifications,
                titulo: 'Notificações',
                subtitulo: 'Preferências de notificação',
                onTap: () {},
              ),
              _PerfilItem(
                icon: Icons.info,
                titulo: 'Sobre o App',
                subtitulo: 'Juan Delivery v1.0.0',
                onTap: () => _sobreOApp(context),
                ultimo: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _PerfilSectionTitle('Sair'),
          _PerfilSection(
            children: [
              _PerfilItem(
                icon: Icons.logout,
                titulo: 'Sair da conta',
                cor: kPerigo,
                onTap: () => _sairDaConta(context),
                ultimo: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(String nome, String email, String inicial) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kGradienteFim],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: kCreme,
              shape: BoxShape.circle,
            ),
            child: Text(
              inicial,
              style: const TextStyle(
                color: kPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome.isEmpty ? 'Usuário' : nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: kCreme, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfilSectionTitle extends StatelessWidget {
  final String texto;
  const _PerfilSectionTitle(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: kTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PerfilSection extends StatelessWidget {
  final List<Widget> children;
  const _PerfilSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _PerfilItem extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String? subtitulo;
  final Color cor;
  final bool ultimo;
  final VoidCallback onTap;

  const _PerfilItem({
    required this.icon,
    required this.titulo,
    this.subtitulo,
    this.cor = kPrimary,
    this.ultimo = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: cor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(color: cor == kPerigo ? kPerigo : kTextPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      if (subtitulo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitulo!,
                          style: const TextStyle(color: kTextSecondary, fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: kTextSecondary, size: 20),
              ],
            ),
          ),
        ),
        if (!ultimo) const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.black12),
      ],
    );
  }
}
