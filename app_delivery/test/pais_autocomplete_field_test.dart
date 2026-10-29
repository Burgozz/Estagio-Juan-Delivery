import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_delivery/widgets/pais_autocomplete_field.dart';

void main() {
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
