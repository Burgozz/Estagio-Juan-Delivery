import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF3C0731);
const _kTextPrimary = Color(0xFF212121);

/// Chip de seleção na identidade do app: selecionado com fundo vinho e
/// texto branco; não selecionado com fundo branco e borda cinza.
class FiltroChip extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  const FiltroChip({
    super.key,
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selecionado,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selecionado ? Colors.white : _kTextPrimary,
        fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      side: BorderSide(color: selecionado ? _kPrimary : Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}
