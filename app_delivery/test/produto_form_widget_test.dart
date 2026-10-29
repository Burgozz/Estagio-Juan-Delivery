import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_delivery/models/produto.dart';
import 'package:front_delivery/screens/produto_form_screen.dart';

import 'helpers/api_falsa.dart';

Future<void> _abrir(WidgetTester tester, {Produto? produto}) async {
  usarTelaAlta(tester);
  await tester.pumpWidget(appComRota(ProdutoFormScreen(produto: produto)));
  await tester.tap(find.text('ABRIR'));
  await tester.pumpAndSettle();
}

Future<void> _escolherPais(WidgetTester tester, String digitado, String pais) async {
  final campoPais = campo('País de Origem da Uva *');
  await tester.tap(campoPais);
  await tester.pump();
  await tester.enterText(campoPais, digitado);
  await tester.pumpAndSettle();
  final toque = await tester.startGesture(tester.getCenter(find.text(pais)));
  await tester.pump(const Duration(milliseconds: 80));
  await toque.up();
  await tester.pumpAndSettle();
}

Future<void> _escolherCategoria(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _preencherVinho(
  WidgetTester tester, {
  String safra = '2020',
  String harmonizacao = 'Carnes vermelhas e queijos curados',
  String estoque = '10',
  bool escolherPais = true,
}) async {
  await tester.enterText(campo('Nome do Produto *'), 'Malbec Reserva');
  await _escolherCategoria(tester, 'Vinho Tinto');
  if (escolherPais) await _escolherPais(tester, 'Arg', 'Argentina');
  await tester.enterText(campo('Safra'), safra);
  await tester.enterText(campo('Teor Alcoólico (%)'), '13.5');
  await tester.enterText(campo('Harmonização *'), harmonizacao);
  await tester.enterText(campo('Preço (R\$) *'), '89.90');
  await tester.enterText(campo('Estoque (unidades) *'), estoque);
}

Future<void> _salvar(WidgetTester tester, [String botao = 'CADASTRAR']) async {
  await tester.tap(find.widgetWithText(ElevatedButton, botao));
  await tester.pumpAndSettle();
}

void main() {
  group('Vinho', () {
    testWidgets('digitar "Arg" e tocar em "Argentina" seleciona o país e o formulário valida e envia',
        (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 1}, 201));
      await api.executar(() async {
        await _abrir(tester);
        await _preencherVinho(tester, escolherPais: false);

        // Só "Arg" digitado: o formulário não passa.
        await tester.enterText(campo('País de Origem da Uva *'), 'Arg');
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _salvar(tester);
        expect(erroNoCampo('País de Origem da Uva *', 'País inválido. Selecione um país da lista.'),
            findsOneWidget);
        expect(api.requisicoes, isEmpty);

        // Seleciona pelo toque na lista.
        await _escolherPais(tester, 'Arg', 'Argentina');
        expect(find.widgetWithText(TextFormField, 'Argentina'), findsOneWidget);
        await _salvar(tester);
        await tester.pump(const Duration(seconds: 1));
      });

      final corpo = api.corpoJson(api.doMetodo('POST').single);
      expect(corpo['paisOrigem'], 'Argentina');
      expect(corpo['tipo'], 'VINHO');
      expect(corpo['categoria'], 'VINHO_TINTO');
      expect(corpo['safra'], 2020);
      expect(corpo['teorAlcool'], 13.5);
      expect(corpo['harmonizacao'], 'Carnes vermelhas e queijos curados');
      expect(find.byType(ProdutoFormScreen), findsNothing);
    });

    testWidgets('harmonização é normalizada (trim e espaços) antes de enviar', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 1}, 201));
      await api.executar(() async {
        await _abrir(tester);
        await _preencherVinho(tester, harmonizacao: '  Massas   /  risotos  ');
        await _salvar(tester);
        await tester.pump(const Duration(seconds: 1));
      });
      expect(api.corpoJson(api.doMetodo('POST').single)['harmonizacao'], 'Massas / risotos');
    });

    for (final (entrada, mensagem) in [
      ('ab', 'Harmonização deve ter entre 3 e 150 caracteres'),
      (', , .', 'Harmonização deve conter apenas letras e pontuação simples'),
      ('', 'Informe a harmonização'),
    ]) {
      testWidgets('harmonização "$entrada" é barrada no app', (tester) async {
        final api = ApiFalsa((_) => respostaJson({'id': 1}, 201));
        await api.executar(() async {
          await _abrir(tester);
          await _preencherVinho(tester, harmonizacao: entrada);
          await _salvar(tester);
          await tester.pump(const Duration(seconds: 1));
        });
        expect(erroNoCampo('Harmonização *', mensagem), findsOneWidget);
        expect(api.requisicoes, isEmpty);
      });
    }

    testWidgets('números e símbolos digitados na harmonização são ignorados', (tester) async {
      await _abrir(tester);
      await tester.enterText(campo('Harmonização *'), 'Queijos 12 meses @');
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Queijos  meses '), findsOneWidget);
    });

    // BUG ENCONTRADO: o app valida safra entre 1900 e 2026 (igual ao ProdutoDTO),
    // mas o CLAUDE.md e a entidade Vinho definem 1800–2025. Resultado: 2026 passa
    // no app e é recusada na gravação com mensagem técnica; 1800 é recusada no app.
    testWidgets('safra segue a regra do projeto (1800 a 2025)', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 1}, 201));
      await api.executar(() async {
        await _abrir(tester);
        await _preencherVinho(tester, safra: '2026');
        await _salvar(tester);
        await tester.pump(const Duration(seconds: 1));
      });
      expect(api.requisicoes, isEmpty, reason: 'safra 2026 deveria ser barrada no app');
    });

    testWidgets('estoque 0 é bloqueado na criação', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 1}, 201));
      await api.executar(() async {
        await _abrir(tester);
        await _preencherVinho(tester, estoque: '0');
        await _salvar(tester);
        await tester.pump(const Duration(seconds: 1));
      });
      expect(erroNoCampo('Estoque (unidades) *', 'Estoque inicial deve ser maior que zero'), findsOneWidget);
      expect(api.requisicoes, isEmpty);
    });

    testWidgets('estoque 0 é permitido na edição', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 3}, 200));
      final vinho = Produto(
        id: 3, nome: 'Malbec', preco: 89.9, estoque: 4, tipo: 'VINHO',
        categoria: 'VINHO_TINTO', paisOrigem: 'Argentina', safra: 2020, teorAlcool: 13.5,
        harmonizacao: 'Carnes vermelhas');
      await api.executar(() async {
        await _abrir(tester, produto: vinho);
        await tester.enterText(campo('Estoque (unidades) *'), '0');
        await _salvar(tester, 'ATUALIZAR');
      });
      final put = api.doMetodo('PUT').single;
      expect(put.url.path, '/produtos/3');
      expect(api.corpoJson(put)['estoque'], 0);
    });

    testWidgets('erro de safra vindo da API aparece embaixo do campo Safra', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'erros': ['Safra é obrigatória para vinhos']}, 400));
      await api.executar(() async {
        await _abrir(tester);
        await _preencherVinho(tester, safra: '');
        await _salvar(tester);
      });
      expect(erroNoCampo('Safra', 'Safra é obrigatória para vinhos'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6)); // deixa timers expirarem
    });
  });

  group('Acessório', () {
    testWidgets('acessório sem harmonização, safra e país funciona', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 2}, 201));
      await api.executar(() async {
        await _abrir(tester);
        await tester.tap(find.text('Acessório'));
        await tester.pumpAndSettle();
        expect(campo('Harmonização *'), findsNothing);
        expect(campo('País de Origem da Uva *'), findsNothing);

        await tester.enterText(campo('Nome do Produto *'), 'Saca-rolhas');
        await tester.enterText(campo('Tipo de Acessório *'), 'Saca-rolhas');
        await tester.enterText(campo('Marca'), 'Tramontina');
        await tester.enterText(campo('Material'), 'Inox');
        await tester.enterText(campo('Preço (R\$) *'), '49.90');
        await tester.enterText(campo('Estoque (unidades) *'), '5');
        await _salvar(tester);
      });
      final corpo = api.corpoJson(api.doMetodo('POST').single);
      expect(corpo['tipo'], 'ACESSORIO');
      expect(corpo['harmonizacao'], isNull);
      expect(corpo['safra'], isNull);
      expect(corpo['teorAlcool'], isNull);
      expect(corpo['paisOrigem'], isNull);
      expect(corpo['marca'], 'Tramontina');
    });
  });
}
