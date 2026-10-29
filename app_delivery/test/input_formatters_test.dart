import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front_delivery/utils/input_formatters.dart';

TextEditingValue _valor(String texto) =>
    TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));

/// Simula a digitação de [entrada], caractere a caractere, no fim do campo.
TextEditingValue _digitar(TextInputFormatter f, String entrada, {String inicial = ''}) {
  var atual = _valor(inicial);
  for (final c in entrada.split('')) {
    atual = f.formatEditUpdate(atual, _valor(atual.text + c));
  }
  return atual;
}

/// Simula um backspace com o cursor no fim do campo.
TextEditingValue _backspace(TextInputFormatter f, TextEditingValue atual) {
  final t = atual.text;
  return f.formatEditUpdate(atual, _valor(t.substring(0, t.length - 1)));
}

/// Simula colar [colado] em um campo vazio.
TextEditingValue _colar(TextInputFormatter f, String colado) =>
    f.formatEditUpdate(_valor(''), _valor(colado));

void main() {
  group('TelefoneInputFormatter', () {
    final f = TelefoneInputFormatter();

    test('formata progressivamente enquanto digita', () {
      expect(_digitar(f, '4').text, '(4');
      expect(_digitar(f, '43').text, '(43');
      expect(_digitar(f, '439').text, '(43) 9');
      expect(_digitar(f, '4399999').text, '(43) 99999');
      expect(_digitar(f, '43999998888').text, '(43) 99999-8888');
      expect(_digitar(f, '4333334444').text, '(43) 3333-4444');
    });

    test('reposiciona o hífen ao digitar o 11º dígito', () {
      final fixo = _digitar(f, '4333334444');
      expect(fixo.text, '(43) 3333-4444');
      expect(_digitar(f, '5', inicial: fixo.text).text, '(43) 33334-4445');
    });

    test('limita a 11 dígitos', () {
      expect(_digitar(f, '439999988887777').text, '(43) 99999-8888');
    });

    test('ignora letras e símbolos', () {
      expect(_digitar(f, '4a3b9#9*').text, '(43) 99');
      expect(_digitar(f, 'abc').text, '');
    });

    test('cursor fica sempre no final', () {
      final v = _digitar(f, '43999998888');
      expect(v.selection, TextSelection.collapsed(offset: v.text.length));
    });

    test('backspace apaga até esvaziar sem travar nos símbolos', () {
      var v = _digitar(f, '43999998888');
      final esperados = [
        '(43) 9999-9888',
        '(43) 9999-988',
        '(43) 9999-98',
        '(43) 99999',
        '(43) 9999',
        '(43) 999',
        '(43) 99',
        '(43) 9',
        '(43',
        '(4',
        '',
      ];
      for (final e in esperados) {
        v = _backspace(f, v);
        expect(v.text, e);
        expect(v.selection.baseOffset, v.text.length);
      }
    });

    test('backspace sobre um símbolo remove também o dígito anterior', () {
      // Hífen apagado em "(43) 1234-56": remove o "4" que vinha antes dele.
      final antes = _valor('(43) 1234-56');
      final depois = f.formatEditUpdate(
        antes,
        const TextEditingValue(text: '(43) 123456', selection: TextSelection.collapsed(offset: 9)),
      );
      expect(depois.text, '(43) 12356');
      expect(depois.selection.baseOffset, depois.text.length);

      // Parêntese de "(4" apagado com o cursor logo após ele.
      final soDdd = f.formatEditUpdate(
        _valor('(43'),
        const TextEditingValue(text: '43', selection: TextSelection.collapsed(offset: 0)),
      );
      expect(soDdd.text, '(43');
    });

    test('colar valor formatado ou só números', () {
      expect(_colar(f, '(43) 99999-8888').text, '(43) 99999-8888');
      expect(_colar(f, '43999998888').text, '(43) 99999-8888');
      expect(_colar(f, '4333334444').text, '(43) 3333-4444');
      expect(_colar(f, '+55 (43) 3333-4444').text, '(55) 43333-3444');
    });
  });

  group('CpfInputFormatter', () {
    final f = CpfInputFormatter();

    test('formata progressivamente enquanto digita', () {
      expect(_digitar(f, '111').text, '111');
      expect(_digitar(f, '1114').text, '111.4');
      expect(_digitar(f, '1114447').text, '111.444.7');
      expect(_digitar(f, '11144477735').text, '111.444.777-35');
    });

    test('limita a 11 dígitos', () {
      expect(_digitar(f, '1114447773599').text, '111.444.777-35');
    });

    test('ignora letras e símbolos', () {
      expect(_digitar(f, '1a1b1c4!').text, '111.4');
    });

    test('cursor fica sempre no final', () {
      final v = _digitar(f, '1114447');
      expect(v.selection, TextSelection.collapsed(offset: v.text.length));
    });

    test('backspace apaga até esvaziar sem travar nos símbolos', () {
      var v = _digitar(f, '11144477735');
      final esperados = [
        '111.444.777-3',
        '111.444.777',
        '111.444.77',
        '111.444.7',
        '111.444',
        '111.44',
        '111.4',
        '111',
        '11',
        '1',
        '',
      ];
      for (final e in esperados) {
        v = _backspace(f, v);
        expect(v.text, e);
        expect(v.selection.baseOffset, v.text.length);
      }
    });

    test('backspace sobre um símbolo remove também o dígito anterior', () {
      // Hífen apagado em "111.444.777-35": remove o "7" que vinha antes dele.
      final antes = _valor('111.444.777-35');
      final depois = f.formatEditUpdate(
        antes,
        const TextEditingValue(text: '111.444.77735', selection: TextSelection.collapsed(offset: 11)),
      );
      expect(depois.text, '111.444.773-5');
      expect(depois.selection.baseOffset, depois.text.length);
    });

    test('colar valor formatado ou só números', () {
      expect(_colar(f, '111.444.777-35').text, '111.444.777-35');
      expect(_colar(f, '11144477735').text, '111.444.777-35');
    });
  });

  group('helpers', () {
    test('somenteDigitos remove a máscara', () {
      expect(somenteDigitos('(43) 99999-8888'), '43999998888');
      expect(somenteDigitos('111.444.777-35'), '11144477735');
      expect(somenteDigitos(null), '');
    });

    test('formatarTelefone / formatarCpf para exibição', () {
      expect(formatarTelefone('43999998888'), '(43) 99999-8888');
      expect(formatarTelefone('4333334444'), '(43) 3333-4444');
      expect(formatarTelefone(null), '');
      expect(formatarCpf('11144477735'), '111.444.777-35');
    });
  });
}
