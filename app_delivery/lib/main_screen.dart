import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/session/sessao_usuario.dart';
import 'core/theme/app_colors.dart';
import 'features/catalogo/screens/catalogo_screen.dart';
import 'features/inicio/screens/inicio_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/pedidos/screens/pedidos_screen.dart';
import 'features/perfil/screens/perfil_screen.dart';
import 'features/admin/screens/produto_list_screen.dart';
import 'features/admin/screens/usuario_list_screen.dart';

/// Tela principal pós-login, com a BottomNavigationBar.
///
/// As abas exibidas dependem do perfil salvo em [SessaoUsuario]: CLIENTE
/// vê Início/Busca/Perfil, ADMIN vê Usuários/Produtos — nunca as duas juntas.
/// Sem sessão válida (usuário não autenticado tentando acessar a tela
/// diretamente), redireciona para a LoginScreen.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _prefsKey = 'home_tab_index';

  // Índice, dentro das abas do perfil CLIENTE, correspondente à aba de
  // Busca (Catálogo).
  static const _indiceCatalogoCliente = 1;

  // Quantidade de abas de cada perfil: CLIENTE tem Início/Busca/Pedidos/Perfil,
  // ADMIN tem Usuários/Produtos.
  int get _quantidadeAbas => SessaoUsuario.isCliente ? 4 : 2;

  int _index = 0;

  // Filtro aplicado à aba de Catálogo quando a navegação vem da
  // InicioScreen (categorias em destaque / "Ver mais").
  String? _categoriaCatalogo;
  String? _tipoCatalogo;

  @override
  void initState() {
    super.initState();
    _restoreIndex();
  }

  Future<void> _restoreIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefsKey);
    if (saved != null && saved >= 0 && saved < _quantidadeAbas && mounted) {
      setState(() => _index = saved);
    }
  }

  Future<void> _selecionarAba(int i) async {
    setState(() {
      _index = i;
      // Ao entrar na aba de Busca diretamente pela barra (não via
      // navegação filtrada da InicioScreen), sempre mostra tudo.
      if (SessaoUsuario.isCliente && i == _indiceCatalogoCliente) {
        _categoriaCatalogo = null;
        _tipoCatalogo = null;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, i);
  }

  Future<void> _abrirCatalogo({String? categoria, String? tipo}) async {
    setState(() {
      _categoriaCatalogo = categoria;
      _tipoCatalogo = tipo;
      _index = _indiceCatalogoCliente;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, _indiceCatalogoCliente);
  }

  void _voltarParaLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Proteção de navegação: sem usuário autenticado, não há perfil para
    // decidir a tab bar, então volta para o login.
    if (!SessaoUsuario.logado) {
      _voltarParaLogin();
      return const Scaffold(body: SizedBox.shrink());
    }

    final List<Widget> telas;
    final List<BottomNavigationBarItem> itens;

    if (SessaoUsuario.isAdmin) {
      // Admin: acesso direto ao gerenciamento, sem Início nem Busca.
      telas = const [
        UsuarioListScreen(),
        ProdutoListScreen(),
      ];
      itens = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Usuários',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wine_bar_outlined),
          activeIcon: Icon(Icons.wine_bar),
          label: 'Produtos',
        ),
      ];
    } else {
      // Cliente: navegação, busca no catálogo e perfil, sem acesso a
      // gerenciamento.
      telas = [
        InicioScreen(onNavegarCatalogo: _abrirCatalogo),
        CatalogoScreen(categoriaInicial: _categoriaCatalogo, tipoInicial: _tipoCatalogo),
        const PedidosScreen(),
        const PerfilScreen(),
      ];
      itens = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search),
          label: 'Busca',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Pedidos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }

    final index = _index < telas.length ? _index : 0;

    return Scaffold(
      body: telas[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimary,
        unselectedItemColor: kTextSecondary,
        backgroundColor: kSurface,
        elevation: 8,
        onTap: _selecionarAba,
        items: itens,
      ),
    );
  }
}
