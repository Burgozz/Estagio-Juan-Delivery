import 'package:flutter_test/flutter_test.dart';

import 'package:front_delivery/features/admin/filters/produto_filtro.dart';
import 'package:front_delivery/features/admin/filters/status_filtro.dart';
import 'package:front_delivery/features/admin/filters/texto_busca.dart';
import 'package:front_delivery/features/admin/filters/usuario_filtro.dart';
import 'package:front_delivery/features/catalogo/models/produto.dart';
import 'package:front_delivery/features/perfil/models/usuario.dart';

Usuario _usuario(
  int id,
  String nome, {
  String cpf = '00000000000',
  String email = 'x@x.com',
  String? telefone,
  String? dataCadastro,
  bool ativo = true,
  String perfil = 'CLIENTE',
}) =>
    Usuario(
      id: id,
      nome: nome,
      cpf: cpf,
      email: email,
      senha: '',
      telefone: telefone,
      dataCadastro: dataCadastro,
      ativo: ativo,
      perfil: perfil,
    );

Produto _produto(
  int id,
  String nome, {
  double preco = 50,
  int estoque = 10,
  bool ativo = true,
  String tipo = 'VINHO',
  String? categoria,
  String? descricao,
  String? paisOrigem,
  String? marca,
}) =>
    Produto(
      id: id,
      nome: nome,
      preco: preco,
      estoque: estoque,
      ativo: ativo,
      tipo: tipo,
      categoria: categoria,
      descricao: descricao,
      paisOrigem: paisOrigem,
      marca: marca,
    );

List<int?> _ids(List list) => list.map((e) => e.id as int?).toList();

void main() {
  group('texto_busca', () {
    test('normalizar remove acentos e maiúsculas', () {
      expect(normalizar('  JOÃO Conceição Rosé '), 'joao conceicao rose');
    });

    test('formatarReais usa padrão brasileiro', () {
      expect(formatarReais(1234.5), 'R\$ 1.234,50');
      expect(formatarReais(9.9), 'R\$ 9,90');
    });
  });

  group('UsuarioFiltro', () {
    final usuarios = [
      _usuario(1, 'José Antônio',
          cpf: '11144477735', email: 'jose@juan.com', telefone: '11987654321',
          dataCadastro: '2026-10-20'),
      _usuario(2, 'Maria Silva',
          cpf: '52998224725', email: 'maria@juan.com', dataCadastro: '2026-01-05'),
      _usuario(3, 'Ana Admin',
          cpf: '00000000000', email: 'admin@juan.com', perfil: 'ADMIN',
          dataCadastro: '2025-06-01'),
      _usuario(4, 'Bruno Inativo',
          cpf: '12345678909', email: 'bruno@juan.com', ativo: false,
          dataCadastro: '2026-10-21'),
    ];
    final agora = DateTime(2026, 10, 22);

    test('busca por CPF sem máscara', () {
      final r = const UsuarioFiltro(busca: '11144477735').aplicar(usuarios);
      expect(_ids(r), [1]);
    });

    test('busca por CPF com máscara acha o mesmo usuário', () {
      final r = const UsuarioFiltro(busca: '111.444.777-35').aplicar(usuarios);
      expect(_ids(r), [1]);
    });

    test('busca por telefone com máscara', () {
      final r = const UsuarioFiltro(busca: '(11) 98765-4321').aplicar(usuarios);
      expect(_ids(r), [1]);
    });

    test('busca sem acento e sem maiúscula acha nome acentuado', () {
      expect(_ids(const UsuarioFiltro(busca: 'jose antonio').aplicar(usuarios)), [1]);
      expect(_ids(const UsuarioFiltro(busca: 'ANTONIO').aplicar(usuarios)), [1]);
    });

    test('busca por e-mail', () {
      expect(_ids(const UsuarioFiltro(busca: 'maria@').aplicar(usuarios)), [2]);
    });

    test('status combinado com filtro de perfil', () {
      const f = UsuarioFiltro(status: StatusFiltro.ativos, perfil: PerfilFiltro.cliente);
      expect(_ids(f.aplicar(usuarios)), [2, 1]);
      const g = UsuarioFiltro(status: StatusFiltro.inativos, perfil: PerfilFiltro.admin);
      expect(f.aplicar(usuarios), isNotEmpty);
      expect(g.aplicar(usuarios), isEmpty);
    });

    test('status + período + busca se combinam', () {
      const f = UsuarioFiltro(
        busca: 'juan.com',
        status: StatusFiltro.ativos,
        periodo: PeriodoCadastro.ultimos7Dias,
      );
      expect(_ids(f.aplicar(usuarios, agora: agora)), [1]);
    });

    test('períodos de cadastro', () {
      List<int?> por(PeriodoCadastro p) =>
          _ids(UsuarioFiltro(periodo: p).aplicar(usuarios, agora: agora));
      expect(por(PeriodoCadastro.ultimos7Dias), [4, 1]);
      expect(por(PeriodoCadastro.ultimos30Dias), [4, 1]);
      expect(por(PeriodoCadastro.esteAno), [4, 2, 1]);
    });

    test('dataCadastro em formato de lista também é aceita', () {
      final u = Usuario(nome: 'L', cpf: '', email: '', senha: '', dataCadastro: [2026, 10, 1]);
      expect(UsuarioFiltro.dataCadastroDe(u), DateTime(2026, 10, 1));
    });

    test('ordenações', () {
      List<int?> por(OrdenacaoUsuario o) => _ids(UsuarioFiltro(ordenacao: o).aplicar(usuarios));
      expect(por(OrdenacaoUsuario.maisRecentes), [4, 3, 2, 1]);
      expect(por(OrdenacaoUsuario.maisAntigos), [1, 2, 3, 4]);
      expect(por(OrdenacaoUsuario.nomeAZ), [3, 4, 1, 2]);
      expect(por(OrdenacaoUsuario.nomeZA), [2, 1, 4, 3]);
    });

    test('contagem de filtros avançados e limpar', () {
      const f = UsuarioFiltro(
        busca: 'x',
        status: StatusFiltro.ativos,
        perfil: PerfilFiltro.admin,
        ordenacao: OrdenacaoUsuario.nomeAZ,
      );
      expect(f.avancadosAtivos, 2);
      final limpo = f.limparAvancados();
      expect(limpo.avancadosAtivos, 0);
      expect(limpo.busca, 'x');
      expect(limpo.status, StatusFiltro.ativos);
      expect(const UsuarioFiltro().temFiltroAtivo, isFalse);
    });
  });

  group('ProdutoFiltro', () {
    final produtos = [
      _produto(1, 'Vinho Tinto Português',
          preco: 89.9, estoque: 12, categoria: 'VINHO_TINTO', paisOrigem: 'Portugal'),
      _produto(2, 'Rosé Provence',
          preco: 120, estoque: 3, categoria: 'VINHO_ROSE', paisOrigem: 'França',
          descricao: 'Leve e frutado'),
      _produto(3, 'Saca-rolhas',
          preco: 35, estoque: 0, ativo: false, tipo: 'ACESSORIO', marca: 'Tramontina'),
      _produto(4, 'Espumante Brut',
          preco: 60, estoque: 5, categoria: 'VINHO_ESPUMANTE', paisOrigem: 'Brasil'),
      _produto(5, 'Taça de Cristal',
          preco: 45, estoque: 20, tipo: 'ACESSORIO', marca: 'Bohemia'),
    ];

    test('busca sem acento em nome, país, descrição e marca', () {
      expect(_ids(const ProdutoFiltro(busca: 'portugues').aplicar(produtos)), [1]);
      expect(_ids(const ProdutoFiltro(busca: 'franca').aplicar(produtos)), [2]);
      expect(_ids(const ProdutoFiltro(busca: 'FRUTADO').aplicar(produtos)), [2]);
      expect(_ids(const ProdutoFiltro(busca: 'tramontina').aplicar(produtos)), [3]);
      expect(_ids(const ProdutoFiltro(busca: 'rose').aplicar(produtos)), [2]);
    });

    test('status combinado com tipo', () {
      const f = ProdutoFiltro(status: StatusFiltro.ativos, tipo: TipoFiltro.acessorios);
      expect(_ids(f.aplicar(produtos)), [5]);
      const g = ProdutoFiltro(status: StatusFiltro.inativos, tipo: TipoFiltro.acessorios);
      expect(_ids(g.aplicar(produtos)), [3]);
    });

    test('categoria filtra vinhos e é ignorada quando o tipo é Acessórios', () {
      const f = ProdutoFiltro(categorias: {'VINHO_TINTO', 'VINHO_ROSE'});
      expect(_ids(f.aplicar(produtos)), [2, 1]);
      final g = f.copyWith(tipo: TipoFiltro.acessorios);
      expect(_ids(g.aplicar(produtos)), [5, 3]);
      expect(g.avancadosAtivos, 1);
    });

    test('faixas de estoque', () {
      List<int?> por(EstoqueFiltro e) => _ids(ProdutoFiltro(estoque: e).aplicar(produtos));
      expect(por(EstoqueFiltro.semEstoque), [3]);
      expect(por(EstoqueFiltro.baixo), [4, 2]);
      expect(por(EstoqueFiltro.disponivel), [5, 1]);
    });

    test('faixa de preço calculada dos produtos carregados', () {
      final faixa = faixaDePreco(produtos);
      expect(faixa.min, 35);
      expect(faixa.max, 120);
    });

    test('faixa de preço filtra com limites inclusivos', () {
      final f = const ProdutoFiltro().comPreco(45, 89.9);
      expect(_ids(f.aplicar(produtos)), [5, 4, 1]);
      expect(_ids(const ProdutoFiltro().comPreco(100, null).aplicar(produtos)), [2]);
      expect(_ids(const ProdutoFiltro().comPreco(null, 40).aplicar(produtos)), [3]);
      expect(f.avancadosAtivos, 1);
    });

    test('copyWith preserva a faixa de preço', () {
      final f = const ProdutoFiltro().comPreco(50, 100).copyWith(busca: 'a');
      expect(f.precoMin, 50);
      expect(f.precoMax, 100);
    });

    test('combinação: status + busca + preço + estoque', () {
      final f = const ProdutoFiltro(
        busca: 'o',
        status: StatusFiltro.ativos,
        estoque: EstoqueFiltro.disponivel,
      ).comPreco(40, 100);
      expect(_ids(f.aplicar(produtos)), [5, 1]);
    });

    test('ordenações', () {
      List<int?> por(OrdenacaoProduto o) => _ids(ProdutoFiltro(ordenacao: o).aplicar(produtos));
      expect(por(OrdenacaoProduto.maisRecentes), [5, 4, 3, 2, 1]);
      expect(por(OrdenacaoProduto.menorPreco), [3, 5, 4, 1, 2]);
      expect(por(OrdenacaoProduto.maiorPreco), [2, 1, 4, 5, 3]);
      expect(por(OrdenacaoProduto.nomeAZ), [4, 2, 3, 5, 1]);
      expect(por(OrdenacaoProduto.menorEstoque), [3, 2, 4, 1, 5]);
    });
  });
}
