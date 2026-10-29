import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
      selectedColor: kPrimary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selecionado ? Colors.white : kTextPrimary,
        fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      side: BorderSide(color: selecionado ? kPrimary : Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}
