import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_delivery/features/admin/screens/produto_form_screen.dart';
import 'package:front_delivery/features/admin/screens/produto_list_screen.dart';
import 'package:front_delivery/features/admin/screens/usuario_form_screen.dart';
import 'package:front_delivery/features/admin/screens/usuario_list_screen.dart';
import 'package:front_delivery/features/admin/widgets/filtro_chip.dart';
import 'package:http/http.dart' as http;

import '../../helpers/api_falsa.dart';

Map<String, Object?> _usuario(int id, String nome, String email, {bool ativo = true, String perfil = 'CLIENTE'}) => {
      'id': id,
      'nome': nome,
      'email': email,
      'senha': '123456',
      'cpf': '11144477735',
      'telefone': '43999998888',
      'dataCadastro': '2026-10-01',
      'ativo': ativo,
      'perfil': perfil,
    };

Map<String, Object?> _vinho(int id, String nome,
        {bool ativo = true, int estoque = 10, String categoria = 'VINHO_TINTO'}) =>
    {
      'id': id,
      'nome': nome,
      'preco': 80.0,
      'tipo': 'VINHO',
      'estoque': estoque,
      'ativo': ativo,
      'categoria': categoria,
      'paisOrigem': 'Chile',
      'safra': 2020,
      'teorAlcool': 13.0,
      'harmonizacao': 'Carnes vermelhas',
    };

Map<String, Object?> _acessorio(int id, String nome, {bool ativo = true, int estoque = 5}) => {
      'id': id,
      'nome': nome,
      'preco': 40.0,
      'tipo': 'ACESSORIO',
      'estoque': estoque,
      'ativo': ativo,
      'tipoAcessorio': 'Taça',
      'marca': 'Bohemia',
      'material': 'Cristal',
    };

/// Responde GET /usuarios/admin e /produtos/admin com as listas dadas.
ApiFalsa _api({List<Object?> usuarios = const [], List<Object?> produtos = const []}) => ApiFalsa((http.Request r) {
      if (r.url.path == '/usuarios/admin') return respostaJson(usuarios);
      if (r.url.path == '/produtos/admin') return respostaJson(produtos);
      return respostaJson({'erro': 'rota inesperada ${r.url.path}'}, 404);
    });

/// Card (Card ou Stack do inativo) que contém o texto [nome].
Finder _cardDe(String nome) => find.ancestor(of: find.text(nome), matching: find.byType(Card));

Future<void> _digitarBusca(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField).first, texto);
  await tester.pump(const Duration(milliseconds: 350)); // debounce de 300ms
  await tester.pumpAndSettle();
}

void main() {
  // ===================================================================
  group('Usuários (admin)', () {
    Future<void> abrir(WidgetTester tester) async {
      usarTelaAlta(tester);
      await tester.pumpWidget(const MaterialApp(home: UsuarioListScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra a seção "Inativos" quando existe inativo, sem editar/excluir nele', (tester) async {
      final api = _api(usuarios: [
        _usuario(1, 'Ana Ativa', 'ana@juan.com'),
        _usuario(2, 'Bruno Inativo', 'bruno@juan.com', ativo: false),
        _usuario(3, 'Carla Ativa', 'carla@juan.com'),
      ]);
      await api.executar(() => abrir(tester));

      // "Inativos" aparece no chip de status E como título da seção.
      expect(find.text('Inativos'), findsNWidgets(2));
      expect(find.text('Inativo'), findsOneWidget); // badge

      final secao = tester.getTopLeft(find.text('Inativos').last).dy;
      expect(tester.getTopLeft(find.text('Bruno Inativo')).dy, greaterThan(secao));
      expect(tester.getTopLeft(find.text('Ana Ativa')).dy, lessThan(secao));

      expect(find.descendant(of: _cardDe('Bruno Inativo'), matching: find.byIcon(Icons.edit_outlined)), findsNothing);
      expect(find.descendant(of: _cardDe('Bruno Inativo'), matching: find.byIcon(Icons.delete_outline)), findsNothing);
      expect(find.descendant(of: _cardDe('Ana Ativa'), matching: find.byIcon(Icons.edit_outlined)), findsOneWidget);
      expect(find.descendant(of: _cardDe('Ana Ativa'), matching: find.byIcon(Icons.delete_outline)), findsOneWidget);
    });

    testWidgets('sem inativos, a seção "Inativos" não aparece', (tester) async {
      final api = _api(usuarios: [
        _usuario(1, 'Ana Ativa', 'ana@juan.com'),
        _usuario(2, 'Admin', 'admin@juan.com', perfil: 'ADMIN'),
      ]);
      await api.executar(() => abrir(tester));
      expect(find.text('Inativos'), findsOneWidget); // só o chip
      expect(find.text('Inativo'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
    });

    testWidgets('excluir pede confirmação, chama DELETE e o usuário passa para "Inativos"', (tester) async {
      var anaAtiva = true;
      final api = ApiFalsa((r) {
        if (r.method == 'DELETE' && r.url.path == '/usuarios/1') {
          anaAtiva = false;
          return http.Response('', 204);
        }
        return respostaJson([
          _usuario(1, 'Ana Ativa', 'ana@juan.com', ativo: anaAtiva),
          _usuario(2, 'Carla Ativa', 'carla@juan.com'),
        ]);
      });
      await api.executar(() async {
        await abrir(tester);
        expect(find.text('Inativos'), findsOneWidget);

        await tester.tap(find.descendant(of: _cardDe('Ana Ativa'), matching: find.byIcon(Icons.delete_outline)));
        await tester.pumpAndSettle();
        expect(find.text('Tem certeza que deseja excluir o usuário "Ana Ativa"?'), findsOneWidget);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(api.doMetodo('DELETE'), isEmpty);

        await tester.tap(find.descendant(of: _cardDe('Ana Ativa'), matching: find.byIcon(Icons.delete_outline)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();
      });
      expect(api.doMetodo('DELETE').single.url.path, '/usuarios/1');
      expect(find.text('Inativos'), findsNWidgets(2));
      expect(
          tester.getTopLeft(find.text('Ana Ativa')).dy, greaterThan(tester.getTopLeft(find.text('Inativos').last).dy));
    });

    testWidgets('botão Reativar aparece só para usuários inativos', (tester) async {
      final api = _api(usuarios: [
        _usuario(1, 'Ana Ativa', 'ana@juan.com'),
        _usuario(2, 'Bruno Inativo', 'bruno@juan.com', ativo: false),
        _usuario(3, 'Dora Inativa', 'dora@juan.com', ativo: false),
      ]);
      await api.executar(() => abrir(tester));
      final reativar = find.widgetWithText(TextButton, 'Reativar');
      expect(reativar, findsNWidgets(2));
      expect(find.byIcon(Icons.restore), findsNWidgets(2));
      // Cada botão fica na mesma faixa vertical do card do seu inativo, e nenhum no ativo.
      final yBotoes = tester.widgetList(reativar).map((w) => tester.getCenter(find.byWidget(w)).dy).toList();
      for (final nome in ['Bruno Inativo', 'Dora Inativa']) {
        final card = tester.getRect(_cardDe(nome));
        expect(yBotoes.where((y) => y > card.top && y < card.bottom), hasLength(1), reason: nome);
      }
      final cardAna = tester.getRect(_cardDe('Ana Ativa'));
      expect(yBotoes.where((y) => y > cardAna.top && y < cardAna.bottom), isEmpty);
    });

    testWidgets('reativar pede confirmação, chama o PATCH, atualiza a lista e mostra SnackBar verde', (tester) async {
      var brunoAtivo = false;
      final api = ApiFalsa((r) {
        if (r.method == 'PATCH' && r.url.path == '/usuarios/2/reativar') {
          brunoAtivo = true;
          return respostaJson(_usuario(2, 'Bruno Inativo', 'bruno@juan.com'));
        }
        return respostaJson([
          _usuario(1, 'Ana Ativa', 'ana@juan.com'),
          _usuario(2, 'Bruno Inativo', 'bruno@juan.com', ativo: brunoAtivo),
        ]);
      });
      await api.executar(() async {
        await abrir(tester);
        await tester.tap(find.widgetWithText(TextButton, 'Reativar'));
        await tester.pumpAndSettle();
        expect(find.text('Deseja reativar este usuário?'), findsOneWidget);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(api.doMetodo('PATCH'), isEmpty);

        await tester.tap(find.widgetWithText(TextButton, 'Reativar'));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Reativar')));
        await tester.pumpAndSettle();
      });
      expect(api.doMetodo('PATCH').single.url.path, '/usuarios/2/reativar');
      expect(api.doMetodo('GET').length, 2); // carregou a lista de novo
      expect(find.text('Usuário "Bruno Inativo" reativado com sucesso'), findsOneWidget);
      expect(find.text('Inativo'), findsNothing); // badge sumiu
      expect(find.widgetWithText(TextButton, 'Reativar'), findsNothing);
      expect(
          find.descendant(of: _cardDe('Bruno Inativo'), matching: find.byIcon(Icons.delete_outline)), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // deixa o SnackBar sair
    });

    testWidgets('erro ao reativar mostra a mensagem da API em SnackBar vermelho', (tester) async {
      final api = ApiFalsa((r) {
        if (r.method == 'PATCH') return respostaJson({'erro': 'Usuário já está ativo'}, 400);
        return respostaJson([_usuario(2, 'Bruno Inativo', 'bruno@juan.com', ativo: false)]);
      });
      await api.executar(() async {
        await abrir(tester);
        await tester.tap(find.widgetWithText(TextButton, 'Reativar'));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Reativar')));
        await tester.pumpAndSettle();
      });
      expect(find.text('Usuário já está ativo'), findsOneWidget);
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, Colors.red.shade700);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('painel de filtros: perfil Admin + badge de filtros ativos', (tester) async {
      final api = _api(usuarios: [
        _usuario(1, 'Ana Cliente', 'ana@juan.com'),
        _usuario(2, 'Admin', 'admin@juan.com', perfil: 'ADMIN'),
      ]);
      await api.executar(() async {
        await abrir(tester);
        await tester.tap(find.byTooltip('Filtros'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FiltroChip, 'Admin'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();
      });
      expect(find.text('Ana Cliente'), findsNothing);
      expect(find.text('admin@juan.com'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // badge do botão Filtros
      await tester.tap(find.text('Limpar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Cliente'), findsOneWidget);
    });

    testWidgets('erro da API ao carregar é exibido na tela', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'erro': 'Banco fora do ar'}, 500));
      await api.executar(() => abrir(tester));
      expect(find.textContaining('Banco fora do ar'), findsOneWidget);
    });

    testWidgets('busca e status continuam aplicados ao voltar da edição', (tester) async {
      final api = _api(usuarios: [
        _usuario(1, 'Maria Silva', 'maria@juan.com'),
        _usuario(2, 'Mariana Inativa', 'mariana@juan.com', ativo: false),
        _usuario(3, 'José Antônio', 'jose@juan.com'),
      ]);
      await api.executar(() async {
        await abrir(tester);
        await _digitarBusca(tester, 'mari');
        await tester.tap(find.widgetWithText(FiltroChip, 'Ativos'));
        await tester.pumpAndSettle();
        expect(find.text('Maria Silva'), findsOneWidget);
        expect(find.text('Mariana Inativa'), findsNothing);
        expect(find.text('José Antônio'), findsNothing);

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(UsuarioFormScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      });

      expect(api.doMetodo('GET'), hasLength(2), reason: 'recarrega a lista ao voltar');
      expect(find.widgetWithText(TextField, 'mari'), findsOneWidget);
      expect(tester.widget<FiltroChip>(find.widgetWithText(FiltroChip, 'Ativos')).selecionado, isTrue);
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.text('Mariana Inativa'), findsNothing);
      expect(find.text('José Antônio'), findsNothing);
      expect(find.text('1 resultado'), findsOneWidget);
    });
  });

  // ===================================================================
  group('Produtos (admin)', () {
    Future<void> abrir(WidgetTester tester) async {
      usarTelaAlta(tester);
      await tester.pumpWidget(const MaterialApp(home: ProdutoListScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('inativos ficam separados, abaixo da seção "Inativos", com badge', (tester) async {
      final api = _api(produtos: [
        _vinho(1, 'Malbec'),
        _vinho(2, 'Cabernet Esgotado', ativo: false, estoque: 0),
        _acessorio(3, 'Taça'),
        _acessorio(4, 'Saca-rolhas Excluído', ativo: false),
      ]);
      await api.executar(() => abrir(tester));

      expect(find.text('Inativos'), findsNWidgets(2)); // chip + seção
      expect(find.text('Inativo'), findsNWidgets(2)); // um badge por inativo

      final secao = tester.getTopLeft(find.text('Inativos').last).dy;
      for (final ativo in ['Malbec', 'Taça']) {
        expect(tester.getTopLeft(find.text(ativo)).dy, lessThan(secao), reason: ativo);
      }
      for (final inativo in ['Cabernet Esgotado', 'Saca-rolhas Excluído']) {
        expect(tester.getTopLeft(find.text(inativo)).dy, greaterThan(secao), reason: inativo);
        // badge "Inativo" está no mesmo Stack do card
        final stack = find.ancestor(of: find.text(inativo), matching: find.byType(Stack)).first;
        expect(find.descendant(of: stack, matching: find.text('Inativo')), findsOneWidget);
      }
    });

    testWidgets('lixeira abre o diálogo de exclusão definitiva; Cancelar não chama DELETE', (tester) async {
      final api = _api(produtos: [_vinho(1, 'Malbec')]);
      await api.executar(() async {
        await abrir(tester);
        await tester.tap(find.descendant(of: _cardDe('Malbec'), matching: find.byIcon(Icons.delete_outline)));
        await tester.pumpAndSettle();
        expect(find.text('Excluir produto?'), findsOneWidget);
        expect(
          find.text('O produto Malbec será removido definitivamente da plataforma. '
              'Esta ação não pode ser desfeita.'),
          findsOneWidget,
        );
        final excluir = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Excluir'));
        expect(excluir.style!.foregroundColor!.resolve({}), Colors.red.shade700);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
      });
      expect(api.doMetodo('DELETE'), isEmpty);
      expect(find.text('Malbec'), findsOneWidget);
    });

    testWidgets('excluir com sucesso some da lista, mantém filtros e mostra SnackBar verde', (tester) async {
      var excluido = false;
      final api = ApiFalsa((r) {
        if (r.method == 'DELETE') {
          excluido = true;
          return http.Response('', 204);
        }
        return respostaJson([
          if (!excluido) _vinho(1, 'Malbec'),
          _vinho(2, 'Malbec Gran Reserva'),
          _acessorio(3, 'Taça'),
        ]);
      });
      await api.executar(() async {
        await abrir(tester);
        await _digitarBusca(tester, 'malbec');
        await tester.tap(find.descendant(of: _cardDe('Malbec'), matching: find.byIcon(Icons.delete_outline)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();
      });
      expect(api.doMetodo('DELETE').single.url.path, '/produtos/1');
      expect(api.doMetodo('GET'), hasLength(2), reason: 'recarrega a lista após excluir');
      expect(find.text('Malbec'), findsNothing);
      expect(find.text('Malbec Gran Reserva'), findsOneWidget);
      expect(find.text('Taça'), findsNothing, reason: 'busca "malbec" continua aplicada');
      expect(find.widgetWithText(TextField, 'malbec'), findsOneWidget);

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect((snack.content as Text).data, 'Produto excluído');
      expect(snack.backgroundColor, Colors.green.shade700);
    });

    testWidgets('produto com pedidos: mostra a mensagem do backend em SnackBar vermelho', (tester) async {
      const msg = 'Este produto já possui pedidos e não pode ser excluído. '
          'Para removê-lo do catálogo, zere o estoque.';
      final api = ApiFalsa((r) {
        if (r.method == 'DELETE') return respostaJson({'erro': msg}, 400);
        return respostaJson([_vinho(1, 'Malbec')]);
      });
      await api.executar(() async {
        await abrir(tester);
        await tester.tap(find.descendant(of: _cardDe('Malbec'), matching: find.byIcon(Icons.delete_outline)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();
      });
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect((snack.content as Text).data, msg);
      expect(snack.backgroundColor, Colors.red.shade700);
      expect(find.text('Malbec'), findsOneWidget);
    });

    testWidgets('produto inativo também tem lixeira e pode ser excluído', (tester) async {
      var excluido = false;
      final api = ApiFalsa((r) {
        if (r.method == 'DELETE') {
          excluido = true;
          return http.Response('', 204);
        }
        return respostaJson([
          _vinho(1, 'Malbec'),
          if (!excluido) _vinho(2, 'Cabernet Esgotado', ativo: false, estoque: 0),
        ]);
      });
      await api.executar(() async {
        await abrir(tester);
        final lixeira = find.descendant(of: _cardDe('Cabernet Esgotado'), matching: find.byIcon(Icons.delete_outline));
        expect(lixeira, findsOneWidget);
        await tester.tap(lixeira);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();
      });
      expect(api.doMetodo('DELETE').single.url.path, '/produtos/2');
      expect(find.text('Cabernet Esgotado'), findsNothing);
    });

    testWidgets('sem inativos, não há seção nem badge', (tester) async {
      final api = _api(produtos: [_vinho(1, 'Malbec'), _acessorio(2, 'Taça')]);
      await api.executar(() => abrir(tester));
      expect(find.text('Inativos'), findsOneWidget);
      expect(find.text('Inativo'), findsNothing);
    });

    testWidgets('filtros continuam aplicados ao voltar da edição', (tester) async {
      final api = _api(produtos: [
        _vinho(1, 'Malbec Argentino'),
        _vinho(2, 'Malbec Esgotado', ativo: false, estoque: 0),
        _acessorio(3, 'Taça Malbec'),
        _vinho(4, 'Chardonnay', categoria: 'VINHO_BRANCO'),
      ]);
      await api.executar(() async {
        await abrir(tester);
        await _digitarBusca(tester, 'malbec');
        await tester.tap(find.widgetWithText(FiltroChip, 'Ativos'));
        await tester.pumpAndSettle();
        // painel: tipo Vinhos
        await tester.tap(find.byTooltip('Filtros'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FiltroChip, 'Vinhos'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();
        expect(find.text('Malbec Argentino'), findsOneWidget);
        expect(find.text('Taça Malbec'), findsNothing);

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(ProdutoFormScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      });

      expect(api.doMetodo('GET'), hasLength(2));
      expect(find.widgetWithText(TextField, 'malbec'), findsOneWidget);
      expect(tester.widget<FiltroChip>(find.widgetWithText(FiltroChip, 'Ativos')).selecionado, isTrue);
      expect(find.text('Malbec Argentino'), findsOneWidget);
      expect(find.text('Malbec Esgotado'), findsNothing);
      expect(find.text('Taça Malbec'), findsNothing);
      expect(find.text('Chardonnay'), findsNothing);
    });

    testWidgets('escolher "Acessórios" limpa as categorias selecionadas', (tester) async {
      final api = _api(produtos: [
        _vinho(1, 'Malbec'),
        _vinho(2, 'Chardonnay', categoria: 'VINHO_BRANCO'),
        _acessorio(3, 'Taça'),
      ]);
      bool selecionado(String label) => tester.widget<FiltroChip>(find.widgetWithText(FiltroChip, label)).selecionado;

      await api.executar(() async {
        await abrir(tester);
        await tester.tap(find.byTooltip('Filtros'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FiltroChip, 'Tinto'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FiltroChip, 'Branco'));
        await tester.pumpAndSettle();
        expect(selecionado('Tinto'), isTrue);
        expect(selecionado('Branco'), isTrue);

        await tester.tap(find.widgetWithText(FiltroChip, 'Acessórios'));
        await tester.pumpAndSettle();
        expect(find.text('Categoria'), findsNothing); // seção some

        await tester.tap(find.widgetWithText(FiltroChip, 'Vinhos'));
        await tester.pumpAndSettle();
        expect(selecionado('Tinto'), isFalse);
        expect(selecionado('Branco'), isFalse);
        expect(selecionado('Todas'), isTrue);

        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();
      });
      expect(find.text('Malbec'), findsOneWidget);
      expect(find.text('Chardonnay'), findsOneWidget);
      expect(find.text('Taça'), findsNothing);
    });
  });
}
