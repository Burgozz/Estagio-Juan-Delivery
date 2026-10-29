import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/endereco.dart';
import '../services/endereco_service.dart';
import '../../../core/session/sessao_usuario.dart';
import '../../../core/widgets/label_obrigatorio.dart';
import '../../../core/theme/app_colors.dart';

/// Lista os endereços do usuário logado (GET /usuarios/{id}/enderecos),
/// permitindo cadastrar novos e excluir existentes.
class EnderecoScreen extends StatefulWidget {
  const EnderecoScreen({super.key});

  @override
  State<EnderecoScreen> createState() => _EnderecoScreenState();
}

class _EnderecoScreenState extends State<EnderecoScreen> {
  final _service = EnderecoService();
  late Future<List<Endereco>> _enderecos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _enderecos = _service.listarPorUsuario(SessaoUsuario.id!);
    setState(() {});
  }

  Future<void> _excluir(Endereco endereco) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmar exclusão', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
        content: Text(
          'Tem certeza que deseja excluir o endereço "${endereco.rua}, ${endereco.numero}"?',
          style: const TextStyle(color: kTextPrimary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kTextSecondary),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _service.deletar(endereco.id!);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _adicionar() async {
    final criado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _EnderecoFormScreen()),
    );
    if (criado == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Meus Endereços'),
        backgroundColor: kPrimary,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        onPressed: _adicionar,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<Endereco>>(
        future: _enderecos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimary));
          }
          if (snapshot.hasError) {
            final mensagem = snapshot.error.toString().replaceFirst('Exception: ', '');
            return Center(
                child: Text(mensagem, style: const TextStyle(color: kTextPrimary), textAlign: TextAlign.center));
          }
          final enderecos = snapshot.data!;
          if (enderecos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 64, color: kPrimary),
                  SizedBox(height: 16),
                  Text('Nenhum endereço cadastrado.', style: TextStyle(color: kTextSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
            itemCount: enderecos.length,
            itemBuilder: (_, i) {
              final e = enderecos[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: kPrimary, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e.rua}, ${e.numero}',
                            style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(e.bairro, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                          Text('${e.cidade} - ${e.estado}',
                              style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                      onPressed: () => _excluir(e),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Formata o texto digitado no campo CEP para o padrão XXXXX-XXX,
/// inserindo o hífen automaticamente logo após o quinto dígito.
/// Deve ser combinado com [FilteringTextInputFormatter.digitsOnly] antes
/// dele na lista de inputFormatters, para que dígitos já sejam a única
/// entrada recebida aqui.
class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.length > 8 ? newValue.text.substring(0, 8) : newValue.text;
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      buffer.write(digitos[i]);
      if (i == 4) buffer.write('-');
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class _EnderecoFormScreen extends StatefulWidget {
  const _EnderecoFormScreen();

  @override
  State<_EnderecoFormScreen> createState() => _EnderecoFormScreenState();
}

class _EnderecoFormScreenState extends State<_EnderecoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _service = EnderecoService();
  bool _salvando = false;
  bool _buscandoCep = false;

  // Marca quais campos foram preenchidos automaticamente pela busca do
  // ViaCEP, para exibir o fundo diferenciado (kAutoFillColor) e para saber
  // quando o próprio usuário os editou manualmente (o que remove o destaque).
  bool _ruaAutoPreenchida = false;
  bool _bairroAutoPreenchido = false;
  bool _cidadeAutoPreenchida = false;
  bool _estadoAutoPreenchido = false;

  // Enquanto true, as alterações feitas nos controllers são causadas pelo
  // próprio preenchimento automático (ou pela sua limpeza), não pelo
  // usuário — usado para não derrubar as flags de auto-preenchimento acima
  // dentro dos onChanged dos campos.
  bool _preenchendoAuto = false;

  // Erros de validação retornados pelo backend (GlobalExceptionHandler),
  // exibidos embaixo do campo correspondente seguindo o mesmo padrão usado
  // para o campo email nos formulários de usuário.
  String? _ruaApiError;
  String? _numeroApiError;
  String? _bairroApiError;
  String? _cidadeApiError;
  String? _estadoApiError;
  String? _cepApiError;

  Future<void> _buscarCep(String cep) async {
    setState(() => _buscandoCep = true);
    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['erro'] != true) {
          _preenchendoAuto = true;
          setState(() {
            _ruaCtrl.text = (data['logradouro'] ?? '').toString();
            _bairroCtrl.text = (data['bairro'] ?? '').toString();
            _cidadeCtrl.text = (data['localidade'] ?? '').toString();
            _estadoCtrl.text = (data['uf'] ?? '').toString();
            _ruaAutoPreenchida = true;
            _bairroAutoPreenchido = true;
            _cidadeAutoPreenchida = true;
            _estadoAutoPreenchido = true;
          });
          _preenchendoAuto = false;
        } else {
          _limparCamposAuto();
          _mostrarErroCep('CEP não encontrado. Verifique e tente novamente.');
        }
      } else {
        _limparCamposAuto();
        _mostrarErroCep('Erro ao buscar CEP. Verifique sua internet.');
      }
    } catch (_) {
      _limparCamposAuto();
      _mostrarErroCep('Erro ao buscar CEP. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  void _limparCamposAuto() {
    _preenchendoAuto = true;
    if (mounted) {
      setState(() {
        _ruaCtrl.clear();
        _bairroCtrl.clear();
        _cidadeCtrl.clear();
        _estadoCtrl.clear();
        _ruaAutoPreenchida = false;
        _bairroAutoPreenchido = false;
        _cidadeAutoPreenchida = false;
        _estadoAutoPreenchido = false;
      });
    }
    _preenchendoAuto = false;
  }

  void _mostrarErroCep(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _ruaCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _cepCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _ruaApiError = null;
      _numeroApiError = null;
      _bairroApiError = null;
      _cidadeApiError = null;
      _estadoApiError = null;
      _cepApiError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final endereco = Endereco(
      rua: _ruaCtrl.text.trim(),
      numero: _numeroCtrl.text.trim(),
      bairro: _bairroCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim(),
      estado: _estadoCtrl.text.trim(),
      cep: _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    try {
      await _service.criar(SessaoUsuario.id!, endereco);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        final msgLower = mensagem.toLowerCase();
        if (msgLower.contains('cep')) {
          setState(() => _cepApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('bairro')) {
          setState(() => _bairroApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('cidade')) {
          setState(() => _cidadeApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('estado')) {
          setState(() => _estadoApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('número') || msgLower.contains('numero')) {
          setState(() => _numeroApiError = mensagem);
          _formKey.currentState!.validate();
        } else if (msgLower.contains('rua')) {
          setState(() => _ruaApiError = mensagem);
          _formKey.currentState!.validate();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Novo Endereço'),
        backgroundColor: kPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCampoCep(),
              const SizedBox(height: 20),
              _buildCampoRua(),
              const SizedBox(height: 20),
              _buildCampoNumero(),
              const SizedBox(height: 20),
              _buildCampoBairro(),
              const SizedBox(height: 20),
              _buildCampoCidade(),
              const SizedBox(height: 20),
              _buildCampoEstado(),
              const SizedBox(height: 32),
              _buildBotaoSalvar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoCep() {
    return TextFormField(
      controller: _cepCtrl,
      style: const TextStyle(color: kTextPrimary),
      cursorColor: kPrimary,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CepInputFormatter(),
        LengthLimitingTextInputFormatter(9),
      ],
      decoration: InputDecoration(
        label: LabelObrigatorio('CEP'),
        hintText: 'Ex: 01310-100',
        prefixIcon: const Icon(Icons.markunread_mailbox_outlined, color: kTextSecondary, size: 20),
        suffixIcon: _buscandoCep
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                ),
              )
            : null,
      ),
      onChanged: (v) {
        if (_cepApiError != null) setState(() => _cepApiError = null);
        final digitos = v.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitos.length == 8) _buscarCep(digitos);
      },
      validator: (v) {
        final digitos = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        if (digitos.isEmpty) return 'Informe o CEP';
        if (digitos.length != 8) return 'CEP deve ter 8 dígitos';
        if (_cepApiError != null) return _cepApiError;
        return null;
      },
    );
  }

  Widget _buildCampoRua() {
    return TextFormField(
      controller: _ruaCtrl,
      style: const TextStyle(color: kTextPrimary),
      cursorColor: kPrimary,
      decoration: InputDecoration(
        label: LabelObrigatorio('Rua'),
        prefixIcon: const Icon(Icons.signpost_outlined, color: kTextSecondary, size: 20),
        fillColor: _ruaAutoPreenchida ? kAutoFillColor : null,
      ),
      onChanged: (_) {
        if (_ruaApiError != null) setState(() => _ruaApiError = null);
        if (!_preenchendoAuto && _ruaAutoPreenchida) {
          setState(() => _ruaAutoPreenchida = false);
        }
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Informe a rua';
        if (_ruaApiError != null) return _ruaApiError;
        return null;
      },
    );
  }

  Widget _buildCampoNumero() {
    return TextFormField(
      controller: _numeroCtrl,
      style: const TextStyle(color: kTextPrimary),
      cursorColor: kPrimary,
      decoration: const InputDecoration(
        label: LabelObrigatorio('Número'),
        prefixIcon: Icon(Icons.pin_outlined, color: kTextSecondary, size: 20),
      ),
      onChanged: (_) {
        if (_numeroApiError != null) setState(() => _numeroApiError = null);
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Informe o número';
        if (_numeroApiError != null) return _numeroApiError;
        return null;
      },
    );
  }

  Widget _buildCampoBairro() {
    return TextFormField(
      controller: _bairroCtrl,
      style: const TextStyle(color: kTextPrimary),
      cursorColor: kPrimary,
      decoration: InputDecoration(
        label: LabelObrigatorio('Bairro'),
        prefixIcon: const Icon(Icons.holiday_village_outlined, color: kTextSecondary, size: 20),
        fillColor: _bairroAutoPreenchido ? kAutoFillColor : null,
      ),
      onChanged: (_) {
        if (_bairroApiError != null) setState(() => _bairroApiError = null);
        if (!_preenchendoAuto && _bairroAutoPreenchido) {
          setState(() => _bairroAutoPreenchido = false);
        }
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Informe o bairro';
        if (_bairroApiError != null) return _bairroApiError;
        return null;
      },
    );
  }

  Widget _buildCampoCidade() {
    return TextFormField(
      controller: _cidadeCtrl,
      style: const TextStyle(color: kTextPrimary),
      cursorColor: kPrimary,
      decoration: InputDecoration(
        label: LabelObrigatorio('Cidade'),
        prefixIcon: const Icon(Icons.location_city_outlined, color: kTextSecondary, size: 20),
        fillColor: _cidadeAutoPreenchida ? kAutoFillColor : null,
      ),
      onChanged: (_) {
        if (_cidadeApiError != null) setState(() => _cidadeApiError = null);
        if (!_preenchendoAuto && _cidadeAutoPreenchida) {
          setState(() => _cidadeAutoPreenchida = false);
        }
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Informe a cidade';
        if (_cidadeApiError != null) return _cidadeApiError;
        return null;
      },
    );
  }

  Widget _buildCampoEstado() {
    return TextFormField(
      controller: _estadoCtrl,
      style: const TextStyle(color: kTextPrimary),
      cursorColor: kPrimary,
      textCapitalization: TextCapitalization.characters,
      maxLength: 2,
      decoration: InputDecoration(
        label: LabelObrigatorio('Estado (UF)'),
        hintText: 'Ex: SP',
        prefixIcon: const Icon(Icons.map_outlined, color: kTextSecondary, size: 20),
        counterText: '',
        fillColor: _estadoAutoPreenchido ? kAutoFillColor : null,
      ),
      onChanged: (_) {
        if (_estadoApiError != null) setState(() => _estadoApiError = null);
        if (!_preenchendoAuto && _estadoAutoPreenchido) {
          setState(() => _estadoAutoPreenchido = false);
        }
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Informe o estado';
        if (_estadoApiError != null) return _estadoApiError;
        return null;
      },
    );
  }

  Widget _buildBotaoSalvar() {
    return ElevatedButton(
      onPressed: _salvando ? null : _salvar,
      child: _salvando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('SALVAR ENDEREÇO'),
    );
  }
}
