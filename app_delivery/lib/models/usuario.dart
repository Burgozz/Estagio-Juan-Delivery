class Usuario {
  final int? id;
  final String nome;
  final String cpf;
  final String email;
  final String senha;
  final String? telefone;
  final dynamic dataCadastro;
  final bool ativo;
  final String? perfil;

  Usuario({
    this.id,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.senha,
    this.telefone,
    this.dataCadastro,
    this.ativo = true,
    this.perfil,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'],
        nome: json['nome'],
        cpf: json['cpf'] ?? '',
        email: json['email'],
        senha: json['senha'],
        telefone: json['telefone'],
        dataCadastro: json['dataCadastro'],
        ativo: json['ativo'] ?? true,
        perfil: json['perfil']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'cpf': cpf,
        'email': email,
        'senha': senha,
        if (telefone != null) 'telefone': telefone,
        if (dataCadastro != null) 'dataCadastro': dataCadastro,
      };
}
