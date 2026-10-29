import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Barra de busca em formato pill com botão "Filtros" ao lado.
///
/// [onBusca] é chamado com debounce de 300ms enquanto o usuário digita, e
/// imediatamente ao tocar no X. O [controller] fica com a tela, para que
/// "Limpar filtros" possa apagar o texto.
class BarraBuscaFiltros extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onBusca;
  final VoidCallback onFiltros;

  /// Quantidade de filtros avançados ativos; exibida como badge quando > 0.
  final int filtrosAtivos;

  const BarraBuscaFiltros({
    super.key,
    required this.controller,
    required this.hint,
    required this.onBusca,
    required this.onFiltros,
    this.filtrosAtivos = 0,
  });

  @override
  State<BarraBuscaFiltros> createState() => _BarraBuscaFiltrosState();
}

class _BarraBuscaFiltrosState extends State<BarraBuscaFiltros> {
  static const _debounce = Duration(milliseconds: 300);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_redesenhar);
  }

  @override
  void didUpdateWidget(BarraBuscaFiltros old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_redesenhar);
      widget.controller.addListener(_redesenhar);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_redesenhar);
    super.dispose();
  }

  // Mostra/esconde o X conforme o texto muda (inclusive por fora do campo).
  void _redesenhar() => setState(() {});

  void _aoDigitar(String texto) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => widget.onBusca(texto));
  }

  void _limpar() {
    _timer?.cancel();
    widget.controller.clear();
    widget.onBusca('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                onChanged: _aoDigitar,
                style: const TextStyle(color: kTextPrimary),
                cursorColor: kPrimary,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(color: kTextSecondary),
                  prefixIcon: const Icon(Icons.search, color: kTextSecondary),
                  suffixIcon: widget.controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          icon: const Icon(Icons.close, color: kTextSecondary, size: 20),
                          onPressed: _limpar,
                        ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _BotaoFiltros(ativos: widget.filtrosAtivos, onTap: widget.onFiltros),
        ],
      ),
    );
  }
}

class _BotaoFiltros extends StatelessWidget {
  final int ativos;
  final VoidCallback onTap;

  const _BotaoFiltros({required this.ativos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final destacado = ativos > 0;
    return Tooltip(
      message: 'Filtros',
      child: Material(
        color: destacado ? kPrimary : Colors.white,
        shape: CircleBorder(
          side: BorderSide(color: destacado ? kPrimary : Colors.black12),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Badge(
              isLabelVisible: destacado,
              label: Text('$ativos'),
              backgroundColor: Colors.white,
              textColor: kPrimary,
              offset: const Offset(6, -6),
              alignment: AlignmentDirectional.topEnd,
              child: Center(
                child: Icon(Icons.tune, color: destacado ? Colors.white : kPrimary, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
