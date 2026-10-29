import 'package:flutter/material.dart';

/// Vermelho padrão do asterisco em telas de fundo claro.
const kAsteriscoObrigatorio = Color(0xFFD32F2F);

/// Vermelho mais claro, para contraste em telas de fundo vinho escuro
/// (login/cadastro).
const kAsteriscoObrigatorioClaro = Color(0xFFFF6B6B);

/// Label de campo obrigatório: o texto herda o estilo do label do campo
/// (cor normal, de foco e de erro, e animação de flutuar) e só o " *"
/// fica sempre vermelho.
///
/// Uso: `InputDecoration(label: LabelObrigatorio('Nome'))`.
/// É `const` para poder ser usado dentro de `const InputDecoration`.
class LabelObrigatorio extends StatelessWidget {
  final String texto;
  final Color corAsterisco;

  const LabelObrigatorio(
    this.texto, {
    super.key,
    this.corAsterisco = kAsteriscoObrigatorio,
  });

  @override
  Widget build(BuildContext context) {
    // O TextSpan raiz não define estilo, então herda o DefaultTextStyle
    // que o InputDecorator aplica ao label (inclusive cor de foco/erro).
    return Text.rich(
      TextSpan(
        text: texto,
        children: [
          TextSpan(text: ' *', style: TextStyle(color: corAsterisco)),
        ],
      ),
    );
  }
}
