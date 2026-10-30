import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_delivery/features/admin/widgets/pais_autocomplete_field.dart';

const _msgInvalido = 'País inválido. Selecione um país da lista.';

String? _validarPais(String? v) {
  if (v == null || v.trim().isEmpty) return 'Informe o país de origem';
  if (!paisValido(v)) return _msgInvalido;
  return null;
}

/// Campo de país seguido de um campo "Safra", para conferir a troca de foco.
Future<({GlobalKey<FormState> form, TextEditingController pais, FocusNode safra})> _montar(
  WidgetTester tester,
) async {
  final form = GlobalKey<FormState>();
  final pais = TextEditingController();
  final safra = FocusNode();
  addTearDown(pais.dispose);
  addTearDown(safra.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: form,
            child: Column(
              children: [
                PaisAutocompleteField(controller: pais, validator: _validarPais),
                TextFormField(focusNode: safra, decoration: const InputDecoration(labelText: 'Safra')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return (form: form, pais: pais, safra: safra);
}

Finder get _campoPais => find.byType(TextFormField).first;

bool _paisComFoco(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText).first).focusNode.hasFocus;

Future<void> _digitarEConfirmar(WidgetTester tester, String texto) async {
  await tester.tap(_campoPais);
  await tester.pump();
  await tester.enterText(_campoPais, texto);
  await tester.pumpAndSettle();
  await tester.testTextInput.receiveAction(TextInputAction.next);
  await tester.pumpAndSettle();
}

void main() {
  group('sugestoesDePais', () {
    List<String> nomes(String texto) => sugestoesDePais(texto).map((p) => p['nome']!).toList();

    test('ignora maiúsculas e acentos: "alba" e "ALBA" encontram Albânia', () {
      expect(nomes('alba'), ['Albânia']);
      expect(nomes('ALBA'), ['Albânia']);
      expect(nomes('albânia'), ['Albânia']);
    });

    test('quem começa com o texto vem antes de quem só contém', () {
      // "Argentina" só contém "in" e, na ordem alfabética pura, viria antes de "Índia".
      final inn = nomes('in');
      expect(inn.take(2), ['Índia', 'Indonésia']);
      final soContem = inn.skip(2).toList();
      expect(soContem, contains('Argentina'));
      expect(soContem.any((n) => n.toLowerCase().startsWith(RegExp('[ií]n'))), isFalse);
    });

    test('dentro de cada grupo a ordem é alfabética', () {
      expect(nomes('ar').take(4), ['Arábia Saudita', 'Argélia', 'Argentina', 'Armênia']);
    });

    test('"a" começa por Afeganistão (primeiro país com A)', () {
      expect(nomes('a').first, 'Afeganistão');
    });

    test('texto sem país correspondente não tem sugestões', () {
      expect(nomes('xyz'), isEmpty);
    });
  });

  group('Enter no campo de país', () {
    testWidgets('"a" + Enter preenche o primeiro país com A, fecha a lista e vai para o próximo campo', (tester) async {
      final t = await _montar(tester);
      await _digitarEConfirmar(tester, 'a');
      expect(t.pais.text, 'Afeganistão');
      expect(find.byType(ListView), findsNothing);
      expect(_paisComFoco(tester), isFalse);
      expect(t.safra.hasFocus, isTrue);
      expect(t.form.currentState!.validate(), isTrue);
    });

    testWidgets('"alba" + Enter preenche Albânia', (tester) async {
      final t = await _montar(tester);
      await _digitarEConfirmar(tester, 'alba');
      expect(t.pais.text, 'Albânia');
      expect(find.byType(ListView), findsNothing);
      expect(t.safra.hasFocus, isTrue);
      expect(t.form.currentState!.validate(), isTrue);
    });

    testWidgets('texto sem sugestão + Enter não preenche nada e a validação de país inválido vale', (tester) async {
      final t = await _montar(tester);
      await _digitarEConfirmar(tester, 'xyz');
      expect(t.pais.text, 'xyz');
      expect(_paisComFoco(tester), isTrue);
      expect(t.safra.hasFocus, isFalse);
      expect(t.form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text(_msgInvalido), findsOneWidget);
    });

    testWidgets('campo vazio + Enter não preenche nada', (tester) async {
      final t = await _montar(tester);
      await _digitarEConfirmar(tester, '');
      expect(t.pais.text, isEmpty);
      expect(t.safra.hasFocus, isFalse);
    });

    testWidgets('clicar numa sugestão continua preenchendo o campo', (tester) async {
      final t = await _montar(tester);
      await tester.tap(_campoPais);
      await tester.pump();
      await tester.enterText(_campoPais, 'alba');
      await tester.pumpAndSettle();
      final toque = await tester.startGesture(tester.getCenter(find.text('Albânia')));
      await tester.pump(const Duration(milliseconds: 80));
      await toque.up();
      await tester.pumpAndSettle();
      expect(t.pais.text, 'Albânia');
      expect(find.byType(ListView), findsNothing);
      expect(_paisComFoco(tester), isFalse);
      expect(t.form.currentState!.validate(), isTrue);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  // Windows/macOS reproduzem o comportamento do Web: o campo perde o foco no
  // pointer-down fora dele, que era o que impedia a seleção pelo toque.
  testWidgets(
    'tocar em um país da lista preenche o campo e o formulário valida',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: PaisAutocompleteField(
                  controller: controller,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o país de origem';
                    if (!paisValido(v)) return 'País inválido. Selecione um país da lista.';
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'Arg');
      await tester.pumpAndSettle();

      // Antes da seleção, "Arg" não é um país válido.
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      // Toque real: há frames entre o pointer-down e o pointer-up. É nesse
      // intervalo que a lista era removida quando o campo perdia o foco.
      final toque = await tester.startGesture(tester.getCenter(find.text('Argentina')));
      await tester.pump(const Duration(milliseconds: 80));
      await toque.up();
      await tester.pumpAndSettle();

      expect(controller.text, 'Argentina');
      expect(find.byType(ListView), findsNothing); // lista fechou
      final campo = tester.widget<EditableText>(find.byType(EditableText));
      expect(campo.focusNode.hasFocus, isFalse); // teclado escondido
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('País inválido. Selecione um país da lista.'), findsNothing);

      // Deixa expirar o timer de toque duplo do campo (iOS).
      await tester.pump(const Duration(seconds: 1));
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.windows,
      TargetPlatform.macOS,
    }),
  );
}
