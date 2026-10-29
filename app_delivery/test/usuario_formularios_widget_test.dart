import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_delivery/features/perfil/models/usuario.dart';
import 'package:front_delivery/features/auth/screens/cadastro_screen.dart';
import 'package:front_delivery/features/auth/screens/login_screen.dart';
import 'package:front_delivery/features/admin/screens/usuario_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/api_falsa.dart';

/// Rótulos dos campos em cada tela.
class _Labels {
  final String nome, cpf, telefone, email, senha, botao;
  const _Labels(this.nome, this.cpf, this.telefone, this.email, this.senha, this.botao);
}

const _cadastro = _Labels('Nome completo', 'CPF', 'Telefone', 'E-mail', 'Senha', 'CADASTRAR');
const _formAdmin = _Labels('Nome *', 'CPF *', 'Telefone', 'Email *', 'Senha *', 'CADASTRAR');

Future<void> _preencher(
  WidgetTester tester,
  _Labels l, {
  String nome = 'Maria Silva',
  String cpf = '11144477735',
  String telefone = '43999998888',
  String email = 'maria@gmail.com',
  String senha = '123456',
}) async {
  await tester.enterText(campo(l.nome), nome);
  await tester.enterText(campo(l.cpf), cpf);
  await tester.enterText(campo(l.telefone), telefone);
  await tester.enterText(campo(l.email), email);
  await tester.enterText(campo(l.senha), senha);
}

Future<void> _enviar(WidgetTester tester, _Labels l) async {
  await tester.tap(find.widgetWithText(ElevatedButton, l.botao));
  await tester.pumpAndSettle();
}

/// Mensagens que o backend devolve (formato do GlobalExceptionHandler) e o
/// campo embaixo do qual cada uma deve aparecer.
final _errosDaApi = <(String descricao, Map<String, Object> corpo, String Function(_Labels) campo, String msg)>[
  (
    'domínio de e-mail inexistente',
    {
      'erros': ['Domínio de e-mail inválido ou inexistente']
    },
    (l) => l.email,
    'Domínio de e-mail inválido ou inexistente'
  ),
  ('e-mail duplicado', {'erro': 'Email já cadastrado'}, (l) => l.email, 'Email já cadastrado'),
  (
    'CPF recusado',
    {
      'erros': ['CPF inválido']
    },
    (l) => l.cpf,
    'CPF inválido'
  ),
  (
    'telefone recusado',
    {
      'erros': ['Telefone inválido. Informe apenas números com DDD (10 ou 11 dígitos)']
    },
    (l) => l.telefone,
    'Telefone inválido. Informe apenas números com DDD (10 ou 11 dígitos)'
  ),
  (
    'nome recusado',
    {
      'erros': ['Nome deve ter entre 2 e 100 caracteres']
    },
    (l) => l.nome,
    'Nome deve ter entre 2 e 100 caracteres'
  ),
  (
    'senha recusada',
    {
      'erros': ['Senha deve ter no mínimo 6 caracteres']
    },
    (l) => l.senha,
    'Senha deve ter no mínimo 6 caracteres'
  ),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ===================================================================
  group('CadastroScreen', () {
    Future<ApiFalsa> abrir(WidgetTester tester, ApiFalsa api) async {
      usarTelaAlta(tester);
      await tester.pumpWidget(const MaterialApp(home: CadastroScreen()));
      return api;
    }

    testWidgets('campos vazios mostram erro inline em todos e não chamam a API', (tester) async {
      final api = ApiFalsa((_) => respostaJson({}, 201));
      await api.executar(() async {
        await abrir(tester, api);
        await _enviar(tester, _cadastro);
      });
      expect(erroNoCampo('Nome completo', 'Informe o nome'), findsOneWidget);
      expect(erroNoCampo('CPF', 'Informe o CPF'), findsOneWidget);
      expect(erroNoCampo('Telefone', 'Informe o telefone'), findsOneWidget);
      expect(erroNoCampo('E-mail', 'Informe o e-mail'), findsOneWidget);
      expect(erroNoCampo('Senha', 'Informe a senha'), findsOneWidget);
      expect(api.requisicoes, isEmpty);
    });

    testWidgets('CPF, telefone e e-mail inválidos mostram erro inline', (tester) async {
      final api = ApiFalsa((_) => respostaJson({}, 201));
      await api.executar(() async {
        await abrir(tester, api);
        await _preencher(tester, _cadastro, cpf: '11144477736', telefone: '439999', email: 'maria@semponto');
        await _enviar(tester, _cadastro);
      });
      expect(erroNoCampo('CPF', 'CPF inválido'), findsOneWidget);
      expect(erroNoCampo('Telefone', 'Telefone deve ter 10 ou 11 dígitos (com DDD)'), findsOneWidget);
      expect(erroNoCampo('E-mail', 'E-mail inválido'), findsOneWidget);
      expect(api.requisicoes, isEmpty);
    });

    testWidgets('CPF coringa é aceito no app', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 1}, 201));
      await api.executar(() async {
        await abrir(tester, api);
        await _preencher(tester, _cadastro, cpf: '00000000000');
        await _enviar(tester, _cadastro);
      });
      expect(api.doMetodo('POST'), hasLength(1));
      expect(api.corpoJson(api.requisicoes.single)['cpf'], '00000000000');
    });

    testWidgets('envia CPF e telefone ao backend só com dígitos e volta ao login', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 1}, 201));
      await api.executar(() async {
        await abrir(tester, api);
        await _preencher(tester, _cadastro, cpf: '111.444.777-35', telefone: '(43) 3333-4444');
        // Na tela o valor fica mascarado...
        expect(find.text('111.444.777-35'), findsOneWidget);
        expect(find.text('(43) 3333-4444'), findsOneWidget);
        await _enviar(tester, _cadastro);
      });
      // ...mas no JSON vai só com dígitos.
      final corpo = api.corpoJson(api.doMetodo('POST').single);
      expect(corpo['cpf'], '11144477735');
      expect(corpo['telefone'], '4333334444');
      expect(corpo['email'], 'maria@gmail.com');
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('senha com menos de 6 caracteres é barrada no app', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 1}, 201));
      await api.executar(() async {
        await abrir(tester, api);
        await _preencher(tester, _cadastro, senha: '12345');
        await _enviar(tester, _cadastro);
      });
      expect(api.requisicoes, isEmpty, reason: 'não deveria chamar a API');
      expect(find.descendant(of: campo('Senha'), matching: find.textContaining('6')), findsOneWidget);
    });

    testWidgets('nome com 1 letra é barrado no app', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 1}, 201));
      await api.executar(() async {
        await abrir(tester, api);
        await _preencher(tester, _cadastro, nome: 'M');
        await _enviar(tester, _cadastro);
      });
      expect(api.requisicoes, isEmpty, reason: 'não deveria chamar a API');
    });

    for (final (descricao, corpo, campoDe, msg) in _errosDaApi) {
      testWidgets('erro da API ($descricao) aparece inline no campo certo', (tester) async {
        final api = ApiFalsa((_) => respostaJson(corpo, 400));
        await api.executar(() async {
          await abrir(tester, api);
          await _preencher(tester, _cadastro);
          await _enviar(tester, _cadastro);
        });
        expect(erroNoCampo(campoDe(_cadastro), msg), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(CadastroScreen), findsOneWidget); // continua na tela
      });
    }
  });

  // ===================================================================
  group('UsuarioFormScreen (admin)', () {
    Future<void> abrir(WidgetTester tester, {Usuario? usuario}) async {
      usarTelaAlta(tester);
      await tester.pumpWidget(appComRota(UsuarioFormScreen(usuario: usuario)));
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
    }

    testWidgets('campos obrigatórios vazios mostram erro inline', (tester) async {
      final api = ApiFalsa((_) => respostaJson({}, 201));
      await api.executar(() async {
        await abrir(tester);
        await _enviar(tester, _formAdmin);
      });
      expect(erroNoCampo('Nome *', 'Informe o nome'), findsOneWidget);
      expect(erroNoCampo('CPF *', 'Informe o CPF'), findsOneWidget);
      expect(erroNoCampo('Email *', 'Informe o email'), findsOneWidget);
      expect(erroNoCampo('Senha *', 'Informe a senha'), findsOneWidget);
      expect(api.requisicoes, isEmpty);
    });

    testWidgets('CPF, telefone e e-mail inválidos mostram erro inline', (tester) async {
      final api = ApiFalsa((_) => respostaJson({}, 201));
      await api.executar(() async {
        await abrir(tester);
        await _preencher(tester, _formAdmin, cpf: '11111111111', telefone: '0433333444', email: 'sem-arroba');
        await _enviar(tester, _formAdmin);
      });
      expect(erroNoCampo('CPF *', 'CPF inválido'), findsOneWidget);
      expect(erroNoCampo('Telefone', 'DDD inválido (não pode começar com 0)'), findsOneWidget);
      expect(erroNoCampo('Email *', 'Email inválido (ex: nome@dominio.com)'), findsOneWidget);
      expect(api.requisicoes, isEmpty);
    });

    testWidgets('criação envia CPF e telefone só com dígitos', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 9}, 201));
      await api.executar(() async {
        await abrir(tester);
        await _preencher(tester, _formAdmin, cpf: '529.982.247-25', telefone: '(43) 99999-8888');
        await _enviar(tester, _formAdmin);
      });
      final corpo = api.corpoJson(api.doMetodo('POST').single);
      expect(corpo['cpf'], '52998224725');
      expect(corpo['telefone'], '43999998888');
      expect(find.byType(UsuarioFormScreen), findsNothing); // voltou para a lista
    });

    testWidgets('edição mostra CPF/telefone mascarados e envia só dígitos', (tester) async {
      final api = ApiFalsa((_) => respostaJson({'id': 7}, 200));
      final existente = Usuario(
          id: 7,
          nome: 'José Antônio',
          cpf: '11144477735',
          email: 'jose@juan.com',
          senha: '123456',
          telefone: '4333334444',
          dataCadastro: '2026-10-01');
      await api.executar(() async {
        await abrir(tester, usuario: existente);
        expect(find.text('111.444.777-35'), findsOneWidget);
        expect(find.text('(43) 3333-4444'), findsOneWidget);
        await tester.tap(find.widgetWithText(ElevatedButton, 'ATUALIZAR'));
        await tester.pumpAndSettle();
      });
      final put = api.doMetodo('PUT').single;
      expect(put.url.path, '/usuarios/7');
      final corpo = api.corpoJson(put);
      expect(corpo['cpf'], '11144477735');
      expect(corpo['telefone'], '4333334444');
    });

    // BUG ENCONTRADO (no caso "domínio de e-mail inexistente"): usuario_form_screen.dart
    // só procura "email" na mensagem; o texto do backend é "Domínio de e-mail ...",
    // com hífen, então o erro vai para um SnackBar em vez de ficar embaixo do campo.
    for (final (descricao, corpo, campoDe, msg) in _errosDaApi) {
      testWidgets('erro da API ($descricao) aparece inline no campo certo', (tester) async {
        final api = ApiFalsa((_) => respostaJson(corpo, 400));
        await api.executar(() async {
          await abrir(tester);
          await _preencher(tester, _formAdmin);
          await _enviar(tester, _formAdmin);
        });
        expect(erroNoCampo(campoDe(_formAdmin), msg), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      });
    }
  });
}
