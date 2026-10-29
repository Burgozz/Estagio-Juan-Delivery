// Utilitários de texto usados pelos filtros locais das telas do admin.

const _acentos = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

/// Minúsculas e sem acentos, para comparações tolerantes ("Rosé" == "rose").
String normalizar(String? texto) {
  if (texto == null || texto.isEmpty) return '';
  final buffer = StringBuffer();
  for (final ch in texto.toLowerCase().trim().split('')) {
    buffer.write(_acentos[ch] ?? ch);
  }
  return buffer.toString();
}

/// Mantém apenas os dígitos ("111.444.777-35" → "11144477735").
String apenasDigitos(String? texto) => (texto ?? '').replaceAll(RegExp(r'\D'), '');

/// Verdadeiro quando o termo é só número com caracteres de máscara
/// (pontos, traços, parênteses, barras e espaços), como CPF ou telefone.
bool pareceNumeroMascarado(String termo) =>
    RegExp(r'^[\d\s.\-()/]+$').hasMatch(termo) && apenasDigitos(termo).isNotEmpty;

/// Formata um valor em reais no padrão brasileiro: 1234.5 → "R$ 1.234,50".
String formatarReais(double valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return 'R\$ $inteiro,${partes[1]}';
}
