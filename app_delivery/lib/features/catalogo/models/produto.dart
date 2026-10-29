class Produto {
  final int? id;
  final String nome;
  final double preco;
  final String? descricao;
  final String tipo;
  final int estoque;
  final bool ativo;

  // Campos específicos de Vinho (podem vir ausentes/nulos quando tipo != VINHO)
  final String? categoria;
  final String? paisOrigem;
  final int? safra;
  final double? teorAlcool;
  final String? harmonizacao;

  // Campos específicos de Acessório (podem vir ausentes/nulos quando tipo != ACESSORIO)
  final String? tipoAcessorio;
  final String? marca;
  final String? material;

  Produto({
    this.id,
    required this.nome,
    required this.preco,
    this.descricao,
    this.tipo = 'VINHO',
    required this.estoque,
    this.ativo = true,
    this.categoria,
    this.paisOrigem,
    this.safra,
    this.teorAlcool,
    this.harmonizacao,
    this.tipoAcessorio,
    this.marca,
    this.material,
  });

  bool get isVinho => tipo == 'VINHO';
  bool get isAcessorio => tipo == 'ACESSORIO';

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
        id: json['id'],
        nome: json['nome'] ?? '',
        preco: (json['preco'] as num?)?.toDouble() ?? 0.0,
        descricao: json['descricao'],
        tipo: json['tipo'] ?? 'VINHO',
        estoque: json['estoque'] ?? 0,
        ativo: json['ativo'] ?? true,
        // Campos de Vinho: ausentes/nulos quando o produto é um Acessório.
        categoria: json['categoria'],
        paisOrigem: json['paisOrigem'],
        safra: json['safra'],
        teorAlcool: (json['teorAlcool'] as num?)?.toDouble(),
        harmonizacao: json['harmonizacao'],
        // Campos de Acessório: ausentes/nulos quando o produto é um Vinho.
        tipoAcessorio: json['tipoAcessorio'],
        marca: json['marca'],
        material: json['material'],
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'preco': preco,
        'descricao': descricao,
        'tipo': tipo,
        'estoque': estoque,
        'categoria': categoria,
        'paisOrigem': paisOrigem,
        'safra': safra,
        'teorAlcool': teorAlcool,
        'harmonizacao': harmonizacao,
        'tipoAcessorio': tipoAcessorio,
        'marca': marca,
        'material': material,
      };
}
