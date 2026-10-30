import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_delivery/app.dart';
import 'package:front_delivery/core/session/logout.dart';
import 'package:front_delivery/core/session/sessao_usuario.dart';
import 'package:front_delivery/features/admin/screens/produto_list_screen.dart';
import 'package:front_delivery/features/admin/screens/usuario_list_screen.dart';
import 'package:front_delivery/features/auth/screens/login_screen.dart';
import 'package:front_delivery/features/carrinho/controllers/carrinho_controller.dart';
import 'package:front_delivery/features/catalogo/models/produto.dart';
import 'package:front_delivery/features/perfil/screens/perfil_screen.dart';
import 'package:front_delivery/main_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/api_falsa.dart';

/// Valores que o login grava no shared_preferences.
const _prefsLogado = <String, Object>{
  'usuario_nome': 'Fulano',
  'usuario_email': 'fulano@juan.com',
  'usuario_id': 7,
  'home_tab_index': 1,
};

/// Listas vazias para as telas do admin.
ApiFalsa _api() => ApiFalsa((http.Request r) => respostaJson(const []));

void _logar(String perfil) {
  SessaoUsuario.salvar(id: 7, nome: 'Fulano', email: 'fulano@juan.com', perfil: perfil);
  CarrinhoController.instance.adicionar(Produto(id: 1, nome: 'Malbec', preco: 89.9, estoque: 3));
}

/// Abre a MainScreen do admin por cima de outra rota (como acontece depois do login).
Future<void> _abrirAdmin(WidgetTester tester, ApiFalsa api) async {
  usarTelaAlta(tester);
  await api.executar(() async {
    await tester.pumpWidget(appComRota(const MainScreen()));
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
  });
}

Future<void> _confirmarSair(WidgetTester tester, ApiFalsa api) async {
  await api.executar(() async {
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Deseja sair da conta?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Sair'));
    await tester.pumpAndSettle();
  });
}

Future<void> _esperarLogoutCompleto(WidgetTester tester) async {
  expect(find.byType(LoginScreen), findsOneWidget);
  expect(find.byType(MainScreen), findsNothing);
  // Não sobrou nenhuma rota por baixo: o botão voltar não leva de volta.
  expect(Navigator.of(tester.element(find.byType(LoginScreen))).canPop(), isFalse);

  expect(SessaoUsuario.logado, isFalse);
  expect(SessaoUsuario.nome, isNull);
  expect(CarrinhoController.instance.itens, isEmpty);

  final prefs = await SharedPreferences.getInstance();
  for (final chave in chavesSessao) {
    expect(prefs.containsKey(chave), isFalse, reason: chave);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(Map.of(_prefsLogado));
    SessaoUsuario.limpar();
    CarrinhoController.instance.limpar();
  });

  group('Logout do admin', () {
    testWidgets('o botão Sair aparece nas abas Usuários e Produtos', (tester) async {
      _logar('ADMIN');
      final api = _api();
      await _abrirAdmin(tester, api);

      // A MainScreen restaura a aba salva (home_tab_index = 1, Produtos).
      expect(find.byType(ProdutoListScreen), findsOneWidget);
      expect(find.byTooltip('Sair'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);

      await api.executar(() async {
        await tester.tap(find.text('Usuários'));
        await tester.pumpAndSettle();
      });
      expect(find.byType(UsuarioListScreen), findsOneWidget);
      expect(find.byTooltip('Sair'), findsOneWidget);
    });

    testWidgets('Cancelar mantém o admin na tela e a sessão intacta', (tester) async {
      _logar('ADMIN');
      final api = _api();
      await _abrirAdmin(tester, api);

      await tester.tap(find.byTooltip('Sair'));
      await tester.pumpAndSettle();
      expect(find.text('Deseja sair da conta?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Deseja sair da conta?'), findsNothing);
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(SessaoUsuario.isAdmin, isTrue);
      expect(CarrinhoController.instance.itens, isNotEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('usuario_nome'), 'Fulano');
    });

    testWidgets('confirmar limpa sessão, prefs e carrinho e leva ao login sem volta', (tester) async {
      _logar('ADMIN');
      final api = _api();
      await _abrirAdmin(tester, api);

      await _confirmarSair(tester, api);

      await _esperarLogoutCompleto(tester);
    });

    testWidgets('depois de sair, reabrir o app cai no login', (tester) async {
      _logar('ADMIN');
      final api = _api();
      await _abrirAdmin(tester, api);
      await _confirmarSair(tester, api);

      // "Reabre" o app do zero.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().intersection(chavesSessao.toSet()), isEmpty);
    });
  });

  group('Logout do cliente', () {
    testWidgets('Sair da conta no Perfil continua funcionando', (tester) async {
      _logar('CLIENTE');
      usarTelaAlta(tester);
      await tester.pumpWidget(appComRota(const PerfilScreen()));
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      expect(find.text('Deseja sair da conta?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Sair'));
      await tester.pumpAndSettle();

      await _esperarLogoutCompleto(tester);
    });

    testWidgets('Cancelar no Perfil mantém o cliente logado', (tester) async {
      _logar('CLIENTE');
      usarTelaAlta(tester);
      await tester.pumpWidget(appComRota(const PerfilScreen()));
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(PerfilScreen), findsOneWidget);
      expect(SessaoUsuario.isCliente, isTrue);
    });
  });
}
