import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Vermelho padrão do asterisco em telas de fundo claro.
const kAsteriscoObrigatorio = kPerigo;

/// Vermelho mais claro, para contraste em telas de fundo vinho escuro
/// (login/cadastro).
const kAsteriscoObrigatorioClaro = kErroInline;

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
