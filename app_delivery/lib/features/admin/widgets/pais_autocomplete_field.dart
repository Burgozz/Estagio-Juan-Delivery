import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/paises.dart';
import '../../../core/widgets/label_obrigatorio.dart';
import '../../../core/theme/app_colors.dart';

/// Remove acentos e normaliza para minúsculas, para permitir busca e
/// validação de país sem distinção entre maiúsculas/minúsculas e ignorando
/// acentuação.
String _normalizar(String texto) {
  const comAcento = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñ';
  const semAcento = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNn';
  var resultado = texto.toLowerCase();
  for (var i = 0; i < comAcento.length; i++) {
    resultado = resultado.replaceAll(comAcento[i].toLowerCase(), semAcento[i].toLowerCase());
  }
  return resultado;
}

/// Verifica se [texto] corresponde exatamente ao nome de algum país da
/// lista estática (ignorando maiúsculas/minúsculas e acentos).
bool paisValido(String texto) {
  final alvo = _normalizar(texto.trim());
  if (alvo.isEmpty) return false;
  return paisesDoMundo.any((p) => _normalizar(p['nome']!) == alvo);
}

/// Campo de texto para o país de origem do vinho, com autocomplete em
/// dropdown mostrando bandeira + nome de cada país.
///
/// Segue o mesmo estilo visual dos demais campos do formulário de produto
/// (mesmas cores, ícone à esquerda, mesma fonte) e valida o texto digitado
/// contra a lista estática de países em [paisesDoMundo].
class PaisAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const PaisAutocompleteField({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  State<PaisAutocompleteField> createState() => _PaisAutocompleteFieldState();
}

class _PaisAutocompleteFieldState extends State<PaisAutocompleteField> {
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final List<Map<String, String>> _paisesOrdenados = List<Map<String, String>>.from(paisesDoMundo)
    ..sort((a, b) => _normalizar(a['nome']!).compareTo(_normalizar(b['nome']!)));

  OverlayEntry? _overlayEntry;
  List<Map<String, String>> _opcoesFiltradas = [];

  @override
  void initState() {
    super.initState();
    _opcoesFiltradas = _paisesOrdenados;
    _focusNode.addListener(_aoMudarFoco);
    widget.controller.addListener(_aoMudarTexto);
  }

  void _aoMudarFoco() {
    if (_focusNode.hasFocus) {
      _atualizarOpcoes();
      _mostrarDropdown();
    } else {
      _removerDropdown();
    }
  }

  void _aoMudarTexto() {
    if (!_focusNode.hasFocus) return;
    _atualizarOpcoes();
    if (_opcoesFiltradas.isEmpty) {
      _removerDropdown();
    } else {
      _mostrarDropdown();
    }
  }

  void _atualizarOpcoes() {
    final consulta = _normalizar(widget.controller.text.trim());
    _opcoesFiltradas = consulta.isEmpty
        ? _paisesOrdenados
        : _paisesOrdenados.where((p) => _normalizar(p['nome']!).contains(consulta)).toList();
  }

  void _mostrarDropdown() {
    _removerDropdown();
    if (_opcoesFiltradas.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final largura = renderBox?.size.width ?? 300.0;
    final altura = renderBox?.size.height ?? 56.0;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: largura,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, altura + 4),
            child: Align(
              alignment: Alignment.topLeft,
              // TextFieldTapRegion faz o toque na lista contar como "dentro"
              // do campo; sem isso, no Web/desktop o campo perde o foco no
              // pointer-down e a lista é removida antes do onTap do item.
              // Precisa ficar dentro do follower para usar a posição já
              // deslocada no hit test.
              child: TextFieldTapRegion(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 5 * 48.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _opcoesFiltradas.length,
                        itemBuilder: (context, index) {
                          final pais = _opcoesFiltradas[index];
                          return InkWell(
                            onTap: () => _selecionarPais(pais),
                            child: SizedBox(
                              height: 48,
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Text(pais['bandeira']!, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      pais['nome']!,
                                      style: const TextStyle(fontSize: 16, color: kTextPrimary),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removerDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selecionarPais(Map<String, String> pais) {
    final nome = pais['nome']!;
    widget.controller.value = TextEditingValue(
      text: nome,
      selection: TextSelection.collapsed(offset: nome.length),
    );
    _removerDropdown();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _removerDropdown();
    widget.controller.removeListener(_aoMudarTexto);
    _focusNode.removeListener(_aoMudarFoco);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: const TextStyle(color: kTextPrimary),
        cursorColor: kPrimary,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]'))],
        decoration: const InputDecoration(
          label: LabelObrigatorio('País de Origem da Uva'),
          prefixIcon: Icon(Icons.flag_outlined, color: kTextSecondary, size: 20),
        ),
        validator: widget.validator,
      ),
    );
  }
}
