import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/carrinho_controller.dart';
import 'screens/usuario_list_screen.dart';
import 'screens/produto_list_screen.dart';
import 'screens/catalogo_screen.dart';
import 'screens/inicio_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pedidos_screen.dart';
import 'screens/perfil_screen.dart';
import 'core/session/sessao_usuario.dart';

const kPrimary = Color(0xFF3C0731);
const kBackground = Color(0xFFFAFAFA);
const kSurface = Color(0xFFFFFFFF);
const kTextPrimary = Color(0xFF212121);
const kTextSecondary = Color(0xFF757575);

void main() {
  runApp(
    ChangeNotifierProvider.value(
      value: CarrinhoController.instance,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juan Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackground,
        colorScheme: const ColorScheme.light(
          primary: kPrimary,
          surface: kSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimary,
          foregroundColor: kSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: kSurface,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 2.0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: kSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          labelStyle: const TextStyle(color: kTextSecondary),
          hintStyle: TextStyle(color: kTextSecondary.withValues(alpha: 0.7)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kTextSecondary, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

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