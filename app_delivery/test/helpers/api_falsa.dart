import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Backend falso para testes de widget. As telas continuam usando
/// `http.get/post/...` normalmente; dentro de [executar] essas chamadas são
/// atendidas por [responder] em vez da rede, e cada requisição fica gravada
/// em [requisicoes] para conferir o que o app enviou.
class ApiFalsa {
  ApiFalsa(this.responder);

  http.Response Function(http.Request req) responder;
  final requisicoes = <http.Request>[];

  late final http.Client _client = MockClient((req) async {
    requisicoes.add(req);
    return responder(req);
  });

  Future<T> executar<T>(Future<T> Function() corpo) =>
      http.runWithClient(corpo, () => _client);

  Iterable<http.Request> doMetodo(String metodo) =>
      requisicoes.where((r) => r.method == metodo);

  Map<String, dynamic> corpoJson(http.Request req) =>
      jsonDecode(req.body) as Map<String, dynamic>;
}

/// Resposta JSON em UTF-8 (as mensagens do backend têm acentos).
http.Response respostaJson(Object corpo, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(corpo)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Tela alta o bastante para os formulários caberem sem rolagem.
void usarTelaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Campo de formulário pelo texto do label.
Finder campo(String label) => find.widgetWithText(TextFormField, label);

/// Texto exibido como erro inline DENTRO do campo indicado (e não num SnackBar).
Finder erroNoCampo(String label, String mensagem) =>
    find.descendant(of: campo(label), matching: find.text(mensagem));

/// Abre [tela] por cima de uma rota inicial, para que `Navigator.pop` funcione.
Widget appComRota(Widget tela) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tela)),
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
    );
