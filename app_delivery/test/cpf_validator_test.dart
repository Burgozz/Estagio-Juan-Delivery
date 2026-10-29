import 'package:flutter_test/flutter_test.dart';

import 'package:front_delivery/utils/cpf_validator.dart';

void main() {
  group('cpfValido', () {
    test('CPFs reais válidos passam', () {
      expect(cpfValido('11144477735'), isTrue);
      expect(cpfValido('52998224725'), isTrue);
    });

    test('CPF coringa passa', () {
      expect(cpfValido(cpfCoringa), isTrue);
      expect(cpfValido('00000000000'), isTrue);
    });

    test('sequência repetida falha', () {
      expect(cpfValido('11111111111'), isFalse);
      expect(cpfValido('99999999999'), isFalse);
    });

    test('dígito verificador errado falha', () {
      expect(cpfValido('11144477736'), isFalse);
    });

    test('menos de 11 dígitos falha', () {
      expect(cpfValido('1114447773'), isFalse);
      expect(cpfValido(''), isFalse);
      expect(cpfValido(null), isFalse);
    });

    test('CPF com máscara passa', () {
      expect(cpfValido('111.444.777-35'), isTrue);
    });
  });
}
