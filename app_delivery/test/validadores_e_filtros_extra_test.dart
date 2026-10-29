// Casos que ainda não estavam cobertos em cpf_validator_test,
// input_formatters_test, harmonizacao_validator_test e filtros_admin_test.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front_delivery/filters/produto_filtro.dart';
import 'package:front_delivery/filters/status_filtro.dart';
import 'package:front_delivery/filters/texto_busca.dart';
import 'package:front_delivery/filters/usuario_filtro.dart';
import 'package:front_delivery/models/produto.dart';
import 'package:front_delivery/models/usuario.dart';
import 'package:front_delivery/utils/cpf_validator.dart';
import 'package:front_delivery/utils/input_formatters.dart';
import 'package:front_delivery/widgets/pais_autocomplete_field.dart';

List<int?> _ids(List list) => list.map((e) => e.id as int?).toList();

TextEditingValue _apagarUltimo(TextInputFormatter f, String texto) {
  final antigo = TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  final novoTexto = texto.substring(0, texto.length - 1);
  return f.formatEditUpdate(
      antigo, TextEditingValue(text: novoTexto, selection: TextSelection.collapsed(offset: novoTexto.length)));
}

void main() {
  group('cpfValido (mesmos casos do backend)', () {
    test('letras falham', () {
      expect(cpfValido('abcdefghijk'), isFalse);
      expect(cpfValido('111.444.777-ab'), isFalse);
    });

    test('segundo CPF válido também passa com máscara', () {
      expect(cpfValido('529.982.247-25'), isTrue);
      expect(cpfValido('000.000.000-00'), isTrue); // coringa com máscara
    });

    test('mais de 11 dígitos falha', () {
      expect(cpfValido('111444777350'), isFalse);
    });
  });

  group('TelefoneInputFormatter', () {
    final f = TelefoneInputFormatter();

    test('backspace no 11º dígito volta do formato celular para fixo', () {
      final v = _apagarUltimo(f, '(43) 99999-8888');
      expect(v.text, '(43) 9999-9888');
    });

    test('valor final enviado é só dígitos nos dois formatos', () {
      expect(somenteDigitos('(43) 99999-8888'), '43999998888');
      expect(somenteDigitos('(43) 3333-4444'), '4333334444');
    });
  });

  group('CpfInputFormatter', () {
    final f = CpfInputFormatter();

    test('backspace no último dígito', () {
      expect(_apagarUltimo(f, '111.444.777-35').text, '111.444.777-3');
    });

    test('colar com letras e espaços mantém só os dígitos', () {
      final v = f.formatEditUpdate(TextEditingValue.empty,
          const TextEditingValue(text: 'cpf: 111 444 777 35', selection: TextSelection.collapsed(offset: 19)));
      expect(v.text, '111.444.777-35');
    });
  });

  group('paisValido', () {
    test('aceita nome exato, sem acento, com maiúsculas ou espaços nas pontas', () {
      expect(paisValido('Argentina'), isTrue);
      expect(paisValido('ARGENTINA'), isTrue);
      expect(paisValido('Franca'), isTrue); // França sem cedilha
      expect(paisValido('  Chile  '), isTrue);
    });

    test('recusa parcial, vazio e inexistente', () {
      expect(paisValido('Arg'), isFalse);
      expect(paisValido(''), isFalse);
      expect(paisValido('   '), isFalse);
      expect(paisValido('Nárnia'), isFalse);
    });
  });

  // -------------------------------------------------------------------
  group('UsuarioFiltro (casos extras)', () {
    Usuario u(int id, String nome,
            {String cpf = '00000000000', String email = 'x@x.com', String? telefone,
             Object? data, bool ativo = true, String? perfil = 'CLIENTE'}) =>
        Usuario(id: id, nome: nome, cpf: cpf, email: email, senha: '', telefone: telefone,
            dataCadastro: data, ativo: ativo, perfil: perfil);

    final agora = DateTime(2026, 10, 22);
    final usuarios = [
      u(1, 'Conceição Araújo', cpf: '11144477735', email: 'conceicao@juan.com',
          telefone: '4333334444', data: '2026-10-15'), // exatamente 7 dias atrás
      u(2, 'Paulo', cpf: '52998224725', email: 'paulo@gmail.com', telefone: '43999998888',
          data: '2026-10-14'), // 8 dias atrás
      u(3, 'Admin', email: 'admin@juan.com', perfil: 'ADMIN', data: '2026-01-01'),
      u(4, 'Sem Perfil', email: 'semperfil@juan.com', perfil: null, data: null),
      u(5, 'Inês Inativa', email: 'ines@juan.com', ativo: false, data: '2025-12-31'),
    ];

    test('busca sem acento, por e-mail, por telefone com e sem máscara e por CPF parcial', () {
      expect(_ids(const UsuarioFiltro(busca: 'conceicao araujo').aplicar(usuarios)), [1]);
      expect(_ids(const UsuarioFiltro(busca: 'INES').aplicar(usuarios)), [5]);
      expect(_ids(const UsuarioFiltro(busca: 'gmail.com').aplicar(usuarios)), [2]);
      expect(_ids(const UsuarioFiltro(busca: '43999998888').aplicar(usuarios)), [2]);
      expect(_ids(const UsuarioFiltro(busca: '(43) 3333-4444').aplicar(usuarios)), [1]);
      expect(_ids(const UsuarioFiltro(busca: '529.982').aplicar(usuarios)), [2]);
      expect(_ids(const UsuarioFiltro(busca: '   ').aplicar(usuarios)), hasLength(5));
    });

    test('status Todos / Ativos / Inativos', () {
      expect(_ids(const UsuarioFiltro().aplicar(usuarios)), [5, 4, 3, 2, 1]);
      expect(_ids(const UsuarioFiltro(status: StatusFiltro.ativos).aplicar(usuarios)), [4, 3, 2, 1]);
      expect(_ids(const UsuarioFiltro(status: StatusFiltro.inativos).aplicar(usuarios)), [5]);
    });

    test('perfil: Admin, e Cliente inclui quem veio sem perfil', () {
      expect(_ids(const UsuarioFiltro(perfil: PerfilFiltro.admin).aplicar(usuarios)), [3]);
      expect(_ids(const UsuarioFiltro(perfil: PerfilFiltro.cliente).aplicar(usuarios)), [5, 4, 2, 1]);
    });

    test('data de cadastro: limites de 7 dias, este ano e sem data', () {
      List<int?> por(PeriodoCadastro p) =>
          _ids(UsuarioFiltro(periodo: p).aplicar(usuarios, agora: agora));
      expect(por(PeriodoCadastro.ultimos7Dias), [1]); // 15/10 entra, 14/10 não
      expect(por(PeriodoCadastro.ultimos30Dias), [2, 1]);
      expect(por(PeriodoCadastro.esteAno), [3, 2, 1]); // 31/12/2025 fica de fora
      expect(por(PeriodoCadastro.todos), contains(4)); // sem data só some quando há período
    });

    test('ordenação por nome ignora acento', () {
      final r = const UsuarioFiltro(ordenacao: OrdenacaoUsuario.nomeAZ).aplicar(usuarios);
      expect(r.map((e) => e.nome).toList(),
          ['Admin', 'Conceição Araújo', 'Inês Inativa', 'Paulo', 'Sem Perfil']);
    });

    test('painel conta perfil + período + ordenação e limpar mantém busca/status', () {
      const f = UsuarioFiltro(
          busca: 'a', status: StatusFiltro.inativos, perfil: PerfilFiltro.cliente,
          periodo: PeriodoCadastro.esteAno, ordenacao: OrdenacaoUsuario.nomeZA);
      expect(f.avancadosAtivos, 3);
      expect(f.temFiltroAtivo, isTrue);
      final l = f.limparAvancados();
      expect((l.busca, l.status, l.avancadosAtivos), ('a', StatusFiltro.inativos, 0));
    });
  });

  // -------------------------------------------------------------------
  group('ProdutoFiltro (casos extras)', () {
    Produto p(int id, String nome,
            {double preco = 50, int estoque = 10, bool ativo = true, String tipo = 'VINHO',
             String? categoria, String? pais}) =>
        Produto(id: id, nome: nome, preco: preco, estoque: estoque, ativo: ativo, tipo: tipo,
            categoria: categoria, paisOrigem: pais);

    final produtos = [
      p(1, 'Tinto Chileno', preco: 35.5, estoque: 0, ativo: false, categoria: 'VINHO_TINTO', pais: 'Chile'),
      p(2, 'Branco Argentino', preco: 60, estoque: 1, categoria: 'VINHO_BRANCO', pais: 'Argentina'),
      p(3, 'Rosé Francês', preco: 99.99, estoque: 5, categoria: 'VINHO_ROSE', pais: 'França'),
      p(4, 'Espumante', preco: 120.2, estoque: 6, categoria: 'VINHO_ESPUMANTE', pais: 'Brasil'),
      p(5, 'Decanter', preco: 80, estoque: 7, tipo: 'ACESSORIO'),
    ];

    test('busca por país sem acento', () {
      expect(_ids(const ProdutoFiltro(busca: 'franca').aplicar(produtos)), [3]);
      expect(_ids(const ProdutoFiltro(busca: 'ARGENTINA').aplicar(produtos)), [2]);
    });

    test('tipo Vinhos / Acessórios', () {
      expect(_ids(const ProdutoFiltro(tipo: TipoFiltro.vinhos).aplicar(produtos)), [4, 3, 2, 1]);
      expect(_ids(const ProdutoFiltro(tipo: TipoFiltro.acessorios).aplicar(produtos)), [5]);
    });

    test('categoria múltipla (3 categorias) com tipo Vinhos', () {
      const f = ProdutoFiltro(
          tipo: TipoFiltro.vinhos, categorias: {'VINHO_TINTO', 'VINHO_ROSE', 'VINHO_ESPUMANTE'});
      expect(_ids(f.aplicar(produtos)), [4, 3, 1]);
      expect(f.avancadosAtivos, 2);
    });

    test('com tipo Acessórios a categoria deixa de valer e não conta no badge', () {
      const f = ProdutoFiltro(tipo: TipoFiltro.acessorios, categorias: {'VINHO_TINTO'});
      expect(f.categoriaVisivel, isFalse);
      expect(_ids(f.aplicar(produtos)), [5]);
      expect(f.avancadosAtivos, 1);
    });

    test('faixas de estoque nos limites 0 / 1 / 5 / 6', () {
      List<int?> por(EstoqueFiltro e) => _ids(ProdutoFiltro(estoque: e).aplicar(produtos));
      expect(por(EstoqueFiltro.semEstoque), [1]);
      expect(por(EstoqueFiltro.baixo), [3, 2]);
      expect(por(EstoqueFiltro.disponivel), [5, 4]);
      expect(EstoqueFiltro.semEstoque.aceita(-1), isTrue);
    });

    test('faixa de preço arredonda para reais inteiros e é inclusiva', () {
      final faixa = faixaDePreco(produtos);
      expect((faixa.min, faixa.max), (35.0, 121.0));
      expect(faixaDePreco(const []), (min: 0.0, max: 0.0));
      expect(_ids(const ProdutoFiltro().comPreco(60, 99.99).aplicar(produtos)), [5, 3, 2]);
      expect(const ProdutoFiltro().comPreco(null, null).temFaixaPreco, isFalse);
    });

    test('status Todos / Ativos / Inativos', () {
      expect(_ids(const ProdutoFiltro(status: StatusFiltro.inativos).aplicar(produtos)), [1]);
      expect(_ids(const ProdutoFiltro(status: StatusFiltro.ativos).aplicar(produtos)), [5, 4, 3, 2]);
      expect(const ProdutoFiltro().aplicar(produtos), hasLength(5));
    });

    test('ordenação por nome ignora acento e "menor estoque" desempata por id', () {
      final porNome = const ProdutoFiltro(ordenacao: OrdenacaoProduto.nomeAZ).aplicar(produtos);
      expect(porNome.map((e) => e.nome).first, 'Branco Argentino');
      expect(normalizar(porNome[3].nome), 'rose frances');
      final empate = [p(1, 'A', estoque: 2), p(2, 'B', estoque: 2)];
      expect(_ids(const ProdutoFiltro(ordenacao: OrdenacaoProduto.menorEstoque).aplicar(empate)), [2, 1]);
    });

    test('limpar mantém busca e status e zera o resto', () {
      final f = const ProdutoFiltro(
              busca: 'x', status: StatusFiltro.ativos, tipo: TipoFiltro.vinhos,
              estoque: EstoqueFiltro.baixo, ordenacao: OrdenacaoProduto.maiorPreco)
          .comPreco(10, 20);
      expect(f.avancadosAtivos, 4);
      final l = f.limparAvancados();
      expect((l.busca, l.status, l.avancadosAtivos, l.temFaixaPreco), ('x', StatusFiltro.ativos, 0, false));
    });
  });
}
