/// Guarda os dados do usuário autenticado durante a sessão do app.
///
/// Preenchida no login e consultada para decidir a navegação de acordo
/// com o perfil (ADMIN ou CLIENTE). Não há autenticação por token; o
/// controle de acesso aqui é apenas o valor de [perfil] em memória.
class SessaoUsuario {
  static int? id;
  static String? nome;
  static String? email;
  static String? perfil;

  static bool get logado => id != null && perfil != null;

  static bool get isAdmin => perfil == 'ADMIN';

  static bool get isCliente => perfil == 'CLIENTE';

  static void salvar({
    required int? id,
    required String? nome,
    required String? email,
    required String? perfil,
  }) {
    SessaoUsuario.id = id;
    SessaoUsuario.nome = nome;
    SessaoUsuario.email = email;
    SessaoUsuario.perfil = perfil;
  }

  static void limpar() {
    id = null;
    nome = null;
    email = null;
    perfil = null;
  }
}
