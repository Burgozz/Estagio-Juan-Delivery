import 'package:flutter_test/flutter_test.dart';
import 'package:front_delivery/core/network/api_erro.dart';
import 'package:http/http.dart' as http;

void main() {
  group('parseErro', () {
    test('formato de validação {"erros": [...]} junta as mensagens com quebra de linha', () {
      final r = http.Response('{"erros": ["Nome obrigatório", "CPF inválido"]}', 400);
      expect(parseErro(r), 'Nome obrigatório\nCPF inválido');
    });

    test('formato {"erro": "..."} devolve a mensagem', () {
      final r = http.Response('{"erro": "Email já cadastrado"}', 400);
      expect(parseErro(r), 'Email já cadastrado');
    });

    test('corpo vazio ou fora do formato devolve "Erro <status>"', () {
      expect(parseErro(http.Response('', 500)), 'Erro 500');
      expect(parseErro(http.Response('<html>', 502)), 'Erro 502');
      expect(parseErro(http.Response('{"outro": 1}', 404)), 'Erro 404');
    });
  });
}
