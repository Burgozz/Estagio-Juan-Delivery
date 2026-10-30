import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front_delivery/core/utils/harmonizacao_validator.dart';

/// Simula a digitação de [entrada], caractere a caractere, no fim do campo.
String _digitar(String entrada) {
  var atual = TextEditingValue.empty;
  for (final c in entrada.split('')) {
    final novo = atual.text + c;
    atual = harmonizacaoInputFormatter.formatEditUpdate(
      atual,
      TextEditingValue(text: novo, selection: TextSelection.collapsed(offset: novo.length)),
    );
  }
  return atual.text;
}

void main() {
  group('validarHarmonizacao', () {
    for (final valido in [
      'Carnes vermelhas e queijos curados',
      'Frutos do mar, peixes grelhados.',
      'Massas / risotos',
      'Sobremesas agridoces',
      'Peixes à moda, pão-de-ló',
    ]) {
      test('aceita "$valido"', () => expect(validarHarmonizacao(valido), isNull));
    }

    for (final invalido in ['Queijos 12 meses', 'carne@grelhada', ', , .', '- -']) {
      test('rejeita "$invalido"', () {
        expect(validarHarmonizacao(invalido), kMsgHarmonizacaoInvalida);
      });
    }

    test('rejeita "ab" (menos de 3 caracteres)', () {
      expect(validarHarmonizacao('ab'), isNotNull);
    });

    test('é opcional: vazia ou nula é aceita', () {
      expect(validarHarmonizacao(''), isNull);
      expect(validarHarmonizacao('   '), isNull);
      expect(validarHarmonizacao(null), isNull);
    });

    test('limite de 150 caracteres após o trim', () {
      expect(validarHarmonizacao('  ${'a' * 150}  '), isNull);
      expect(validarHarmonizacao('a' * 151), isNotNull);
    });
  });

  group('harmonizacaoParaEnvio', () {
    test('vazia vira null e preenchida é normalizada', () {
      expect(harmonizacaoParaEnvio(''), isNull);
      expect(harmonizacaoParaEnvio('   '), isNull);
      expect(harmonizacaoParaEnvio(null), isNull);
      expect(harmonizacaoParaEnvio('  Massas   /  risotos '), 'Massas / risotos');
    });
  });

  group('normalizarHarmonizacao', () {
    test('aplica trim e colapsa espaços repetidos', () {
      expect(normalizarHarmonizacao('  Carnes    vermelhas \t e  queijos  '), 'Carnes vermelhas e queijos');
    });
  });

  group('harmonizacaoInputFormatter', () {
    test('ignora números e símbolos durante a digitação', () {
      expect(_digitar('Queijos 12 meses'), 'Queijos  meses');
      expect(_digitar('carne@grelhada#!'), 'carnegrelhada');
    });

    test('mantém letras acentuadas e pontuação simples', () {
      expect(_digitar('Pão, peixe. Massa-fresca / risoto'), 'Pão, peixe. Massa-fresca / risoto');
    });
  });
}
