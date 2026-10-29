/// Filtro de status comum às telas de Usuários e Produtos do admin.
enum StatusFiltro {
  todos('Todos'),
  ativos('Ativos'),
  inativos('Inativos');

  final String label;
  const StatusFiltro(this.label);

  bool aceita(bool ativo) => switch (this) {
        StatusFiltro.todos => true,
        StatusFiltro.ativos => ativo,
        StatusFiltro.inativos => !ativo,
      };
}
