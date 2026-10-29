import '../../perfil/models/usuario.dart';
import 'status_filtro.dart';
import 'texto_busca.dart';

enum PerfilFiltro {
  todos('Todos'),
  admin('Admin'),
  cliente('Cliente');

  final String label;
  const PerfilFiltro(this.label);
}

enum PeriodoCadastro {
  todos('Todos'),
  ultimos7Dias('Últimos 7 dias'),
  ultimos30Dias('Últimos 30 dias'),
  esteAno('Este ano');

  final String label;
  const PeriodoCadastro(this.label);
}

enum OrdenacaoUsuario {
  maisRecentes('Mais recentes'),
  maisAntigos('Mais antigos'),
  nomeAZ('Nome A-Z'),
  nomeZA('Nome Z-A');

  final String label;
  const OrdenacaoUsuario(this.label);
}

/// Estado imutável dos filtros da tela de Usuários do admin. Toda a
/// filtragem é local, sobre a lista já carregada de /usuarios/admin.
class UsuarioFiltro {
  final String busca;
  final StatusFiltro status;
  final PerfilFiltro perfil;
  final PeriodoCadastro periodo;
  final OrdenacaoUsuario ordenacao;

  const UsuarioFiltro({
    this.busca = '',
    this.status = StatusFiltro.todos,
    this.perfil = PerfilFiltro.todos,
    this.periodo = PeriodoCadastro.todos,
    this.ordenacao = OrdenacaoUsuario.maisRecentes,
  });

  UsuarioFiltro copyWith({
    String? busca,
    StatusFiltro? status,
    PerfilFiltro? perfil,
    PeriodoCadastro? periodo,
    OrdenacaoUsuario? ordenacao,
  }) =>
      UsuarioFiltro(
        busca: busca ?? this.busca,
        status: status ?? this.status,
        perfil: perfil ?? this.perfil,
        periodo: periodo ?? this.periodo,
        ordenacao: ordenacao ?? this.ordenacao,
      );

  /// Mantém busca e status, zerando apenas o que fica no painel "Filtros".
  UsuarioFiltro limparAvancados() => UsuarioFiltro(busca: busca, status: status);

  /// Quantidade de opções do painel diferentes do padrão (badge do botão).
  int get avancadosAtivos => [
        perfil != PerfilFiltro.todos,
        periodo != PeriodoCadastro.todos,
        ordenacao != OrdenacaoUsuario.maisRecentes,
      ].where((a) => a).length;

  bool get temFiltroAtivo => busca.trim().isNotEmpty || status != StatusFiltro.todos || avancadosAtivos > 0;

  List<Usuario> aplicar(List<Usuario> usuarios, {DateTime? agora}) {
    final hoje = _soData(agora ?? DateTime.now());
    final resultado = usuarios
        .where((u) => status.aceita(u.ativo) && _aceitaBusca(u) && _aceitaPerfil(u) && _aceitaPeriodo(u, hoje))
        .toList();
    resultado.sort(_comparar);
    return resultado;
  }

  bool _aceitaBusca(Usuario u) {
    final termo = busca.trim();
    if (termo.isEmpty) return true;
    if (pareceNumeroMascarado(termo)) {
      final digitos = apenasDigitos(termo);
      return apenasDigitos(u.cpf).contains(digitos) || apenasDigitos(u.telefone).contains(digitos);
    }
    final t = normalizar(termo);
    return normalizar(u.nome).contains(t) || normalizar(u.email).contains(t);
  }

  bool _aceitaPerfil(Usuario u) => switch (perfil) {
        PerfilFiltro.todos => true,
        PerfilFiltro.admin => u.perfil == 'ADMIN',
        // Sem perfil informado, o padrão do backend é CLIENTE.
        PerfilFiltro.cliente => (u.perfil ?? 'CLIENTE') == 'CLIENTE',
      };

  bool _aceitaPeriodo(Usuario u, DateTime hoje) {
    if (periodo == PeriodoCadastro.todos) return true;
    final data = dataCadastroDe(u);
    if (data == null) return false;
    return switch (periodo) {
      PeriodoCadastro.todos => true,
      PeriodoCadastro.ultimos7Dias => !data.isBefore(hoje.subtract(const Duration(days: 7))),
      PeriodoCadastro.ultimos30Dias => !data.isBefore(hoje.subtract(const Duration(days: 30))),
      PeriodoCadastro.esteAno => data.year == hoje.year,
    };
  }

  int _comparar(Usuario a, Usuario b) => switch (ordenacao) {
        OrdenacaoUsuario.maisRecentes => (b.id ?? 0).compareTo(a.id ?? 0),
        OrdenacaoUsuario.maisAntigos => (a.id ?? 0).compareTo(b.id ?? 0),
        OrdenacaoUsuario.nomeAZ => normalizar(a.nome).compareTo(normalizar(b.nome)),
        OrdenacaoUsuario.nomeZA => normalizar(b.nome).compareTo(normalizar(a.nome)),
      };

  /// `dataCadastro` chega como "2025-03-10" ou como lista [2025, 3, 10],
  /// dependendo da serialização do LocalDate no backend.
  static DateTime? dataCadastroDe(Usuario u) {
    final v = u.dataCadastro;
    if (v is String) {
      final d = DateTime.tryParse(v);
      return d == null ? null : _soData(d);
    }
    if (v is List && v.length >= 3) {
      return DateTime(v[0] as int, v[1] as int, v[2] as int);
    }
    return null;
  }

  static DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);
}
