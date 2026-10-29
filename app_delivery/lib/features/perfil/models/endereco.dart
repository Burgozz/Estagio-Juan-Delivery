class Endereco {
  final int? id;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;

  Endereco({
    this.id,
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) => Endereco(
        id: json['id'],
        rua: json['rua'] ?? '',
        numero: json['numero'] ?? '',
        bairro: json['bairro'] ?? '',
        cidade: json['cidade'] ?? '',
        estado: json['estado'] ?? '',
        cep: json['cep'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'rua': rua,
        'numero': numero,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'cep': cep,
      };
}
