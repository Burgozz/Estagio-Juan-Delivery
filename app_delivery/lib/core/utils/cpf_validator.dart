/// CPF coringa de desenvolvimento: sempre aceito e pode ser usado por
/// várias contas. Remover esta constante (e seu uso) para desativá-lo.
const String cpfCoringa = '00000000000';

/// Valida um CPF pelos dígitos verificadores (módulo 11).
/// Aceita o valor com ou sem máscara.
bool cpfValido(String? cpf) {
  if (cpf == null) return false;
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  if (digitos == cpfCoringa) return true;
  if (digitos.length != 11) return false;
  if (digitos.split('').every((d) => d == digitos[0])) return false;

  final numeros = digitos.split('').map(int.parse).toList();

  int calcularDigito(int quantidade) {
    var soma = 0;
    for (var i = 0; i < quantidade; i++) {
      soma += numeros[i] * (quantidade + 1 - i);
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  return calcularDigito(9) == numeros[9] && calcularDigito(10) == numeros[10];
}
