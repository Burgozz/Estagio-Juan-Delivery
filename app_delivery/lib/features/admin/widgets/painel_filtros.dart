import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF3C0731);
const _kTextPrimary = Color(0xFF212121);
const _kTextSecondary = Color(0xFF757575);

/// Abre o painel "Filtros" em um bottom sheet. [rascunho] é o estado inicial;
/// [construir] monta as seções a partir do rascunho atual e de um `atualizar`
/// que troca o rascunho. Retorna o filtro escolhido em "Aplicar"/"Limpar",
/// ou `null` se o painel for fechado sem aplicar.
Future<T?> abrirPainelFiltros<T>({
  required BuildContext context,
  required T rascunho,
  required T Function(T atual) limpar,
  required List<Widget> Function(T atual, void Function(T novo) atualizar) construir,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      var atual = rascunho;
      return StatefulBuilder(
        builder: (ctx, setSheet) => ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                        color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: construir(atual, (novo) => setSheet(() => atual = novo)),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, limpar(atual)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(color: _kPrimary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Limpar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, atual),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Seção do painel: título + conteúdo (geralmente um Wrap de chips).
class SecaoFiltro extends StatelessWidget {
  final String titulo;
  final Widget child;
  final Widget? trailing;

  const SecaoFiltro({super.key, required this.titulo, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                titulo,
                style: const TextStyle(
                    color: _kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Texto auxiliar discreto usado dentro das seções.
class DicaFiltro extends StatelessWidget {
  final String texto;
  const DicaFiltro(this.texto, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(texto, style: const TextStyle(color: _kTextSecondary, fontSize: 12));
}
