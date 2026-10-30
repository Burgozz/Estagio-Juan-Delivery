import 'package:flutter_test/flutter_test.dart';

import 'package:front_delivery/core/utils/teor_alcool_validator.dart';

void main() {
  group('validarTeorAlcool', () {
    for (final valido in ['7', '7.0', '12.5', '13', '19.9', '20', '20.0', ' 12.5 ']) {
      test('aceita "$valido"', () => expect(validarTeorAlcool(valido), isNull));
    }

    for (final foraDaFaixa in ['0', '6.9', '6.99', '20.01', '20.1', '100', '-7']) {
      test('recusa "$foraDaFaixa" com a mensagem da faixa', () {
        expect(validarTeorAlcool(foraDaFaixa), kMsgTeorAlcoolInvalido);
      });
    }

    for (final invalido in ['abc', '12,5', '12.5.1', '%']) {
      test('recusa "$invalido" como valor inválido', () {
        expect(validarTeorAlcool(invalido), 'Valor inválido');
      });
    }

    test('campo vazio fica a cargo do formulário', () {
      expect(validarTeorAlcool(''), isNull);
      expect(validarTeorAlcool(null), isNull);
    });

    test('mensagem igual à do backend', () {
      expect(kMsgTeorAlcoolInvalido, 'Teor alcoólico deve estar entre 7% e 20%');
    });
  });
}
