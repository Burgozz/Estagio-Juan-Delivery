import 'package:flutter/material.dart';

/// Paleta e estilos das telas de autenticação (Login/Cadastro). É um
/// esquema escuro próprio, deliberadamente diferente do tema claro usado
/// no restante do app (ver kBackground/kSurface em main.dart).
const kAuthBackground = Color(0xFF3C0731);
const kAuthCard = Color(0xFF1E1E1E);
const kAuthFieldFill = Color(0xFF3A3A3A);
const kAuthFieldBorder = Color(0xFF555555);
const kAuthFieldBorderFocused = Color(0xFF888888);
const kAuthFieldText = Colors.white;
const kAuthLabel = Color(0xFFAAAAAA);
const kAuthIcon = Color(0xFFAAAAAA);
const kAuthButton = Color(0xFF5C1151);
const kAuthTitle = Color(0xFFF5E6C8);
const kAuthLinkMuted = Color(0xFFBBBBBB);
const kAuthLinkHighlight = Color(0xFFF5E6C8);
const kAuthError = Color(0xFFFF6B6B);

/// Decoração padrão dos campos de texto das telas de autenticação:
/// fundo cinza médio, borda sutil (mais clara quando focada) e
/// mensagens de erro em vermelho claro para contrastar com o fundo escuro.
InputDecoration authInputDecoration({
  required String label,
  String? hint,
  required IconData icon,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: kAuthFieldFill,
    labelStyle: const TextStyle(color: kAuthLabel),
    hintStyle: const TextStyle(color: kAuthLabel),
    prefixIcon: Icon(icon, color: kAuthIcon, size: 20),
    errorStyle: const TextStyle(color: kAuthError),
    border: border(kAuthFieldBorder, 1),
    enabledBorder: border(kAuthFieldBorder, 1),
    focusedBorder: border(kAuthFieldBorderFocused, 1.5),
    errorBorder: border(kAuthError, 1),
    focusedErrorBorder: border(kAuthError, 1.5),
  );
}

/// Estilo do botão principal ("Entrar" / "Cadastrar"): fundo vinho mais
/// claro para contrastar com o card escuro, cantos arredondados e texto
/// branco em negrito.
final authButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: kAuthButton,
  foregroundColor: Colors.white,
  disabledBackgroundColor: kAuthButton.withValues(alpha: 0.6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  padding: const EdgeInsets.symmetric(vertical: 16),
  textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
);

/// Link em duas cores (ex.: "Não tem conta? Cadastre-se"), com o trecho
/// clicável em creme e o restante em cinza claro.
class AuthLinkButton extends StatelessWidget {
  final String texto;
  final String trechoDestaque;
  final VoidCallback onPressed;

  const AuthLinkButton({
    super.key,
    required this.texto,
    required this.trechoDestaque,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text.rich(
        TextSpan(
          text: texto,
          style: const TextStyle(color: kAuthLinkMuted),
          children: [
            TextSpan(
              text: trechoDestaque,
              style: const TextStyle(
                color: kAuthLinkHighlight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
