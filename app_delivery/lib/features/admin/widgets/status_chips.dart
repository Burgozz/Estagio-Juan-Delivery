import 'package:flutter/material.dart';

import '../filters/status_filtro.dart';
import 'filtro_chip.dart';

/// Linha de chips Todos | Ativos | Inativos, abaixo da barra de busca.
class StatusChips extends StatelessWidget {
  final StatusFiltro selecionado;
  final ValueChanged<StatusFiltro> onChanged;

  const StatusChips({super.key, required this.selecionado, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Wrap(
        spacing: 8,
        children: [
          for (final s in StatusFiltro.values)
            FiltroChip(
              label: s.label,
              selecionado: s == selecionado,
              onTap: () => onChanged(s),
            ),
        ],
      ),
    );
  }
}
