import 'package:flutter/material.dart';
import '../filters/status_filtro.dart';
import '../filters/usuario_filtro.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../widgets/barra_busca_filtros.dart';
import '../widgets/filtro_chip.dart';
import '../widgets/painel_filtros.dart';
import '../widgets/resultados_header.dart';
import '../widgets/status_chips.dart';
import 'usuario_form_screen.dart';

const kPrimary = Color(0xFF3C0731);
const kBackground = Color(0xFFFAFAFA);
const kTextPrimary = Color(0xFF212121);
const kTextSecondary = Color(0xFF757575);

class UsuarioListScreen extends StatefulWidget {
  const UsuarioListScreen({super.key});

  @override
  State<UsuarioListScreen> createState() => _UsuarioListScreenState();
}

class _UsuarioListScreenState extends State<UsuarioListScreen> {
  final service = UsuarioService();
  final _buscaCtrl = TextEditingController();
  List<Usuario>? _usuarios;
  bool _carregando = true;
  Object? _erro;

  // Fica no State (e não no carregamento), então sobrevive aos recarregamentos
  // feitos depois de editar ou excluir.
  UsuarioFiltro _filtro = const UsuarioFiltro();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await service.listarTodosAdmin();
      if (!mounted) return;
      setState(() {
        _usuarios = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e;
        _carregando = false;
      });
    }
  }

  void _limparFiltros() {
    _buscaCtrl.clear();
    setState(() => _filtro = const UsuarioFiltro());
  }

  Future<void> _abrirFiltros() async {
    final escolhido = await abrirPainelFiltros<UsuarioFiltro>(
      context: context,
      rascunho: _filtro,
      limpar: (f) => f.limparAvancados(),
      construir: (f, atualizar) => [
        SecaoFiltro(
          titulo: 'Perfil',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in PerfilFiltro.values)
              FiltroChip(
                label: p.label,
                selecionado: f.perfil == p,
                onTap: () => atualizar(f.copyWith(perfil: p)),
              ),
          ]),
        ),
        SecaoFiltro(
          titulo: 'Data de cadastro',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in PeriodoCadastro.values)
              FiltroChip(
                label: p.label,
                selecionado: f.periodo == p,
                onTap: () => atualizar(f.copyWith(periodo: p)),
              ),
          ]),
        ),
        SecaoFiltro(
          titulo: 'Ordenar por',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final o in OrdenacaoUsuario.values)
              FiltroChip(
                label: o.label,
                selecionado: f.ordenacao == o,
                onTap: () => atualizar(f.copyWith(ordenacao: o)),
              ),
          ]),
        ),
      ],
    );
    if (escolhido == null || !mounted) return;
    // Busca e status vêm do estado atual (o debounce pode ter disparado com
    // o painel aberto); do painel só interessam os filtros avançados.
    setState(() => _filtro = escolhido.copyWith(busca: _filtro.busca, status: _filtro.status));
  }

  Future<void> _deletar(int id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Confirmar exclusão',
          style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Tem certeza que deseja excluir o usuário "$nome"?',
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
    if (confirmar == true) {
      await service.deletar(id);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JUAN DELIVERY')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UsuarioFormScreen()),
          );
          _carregar();
        },
      ),
      body: Column(
        children: [
          BarraBuscaFiltros(
            controller: _buscaCtrl,
            hint: 'Nome, e-mail, CPF ou telefone',
            filtrosAtivos: _filtro.avancadosAtivos,
            onBusca: (t) => setState(() => _filtro = _filtro.copyWith(busca: t)),
            onFiltros: _abrirFiltros,
          ),
          StatusChips(
            selecionado: _filtro.status,
            onChanged: (st) => setState(() => _filtro = _filtro.copyWith(status: st)),
          ),
          Expanded(child: _buildConteudo()),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimary),
      );
    }
    if (_erro != null) {
      return Center(
        child: Text('Erro: $_erro', style: const TextStyle(color: kTextPrimary)),
      );
    }
    final usuarios = _usuarios ?? const <Usuario>[];
    if (usuarios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: kPrimary),
            SizedBox(height: 16),
            Text(
              'Nenhum usuário cadastrado.',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    final filtrados = _filtro.aplicar(usuarios);
    return Column(
      children: [
        ResultadosHeader(
          total: filtrados.length,
          filtrosAtivos: _filtro.temFiltroAtivo,
          onLimpar: _limparFiltros,
        ),
        Expanded(
          child: filtrados.isEmpty
              ? SemResultados(onLimpar: _limparFiltros)
              : _buildLista(filtrados),
        ),
      ],
    );
  }

  Widget _buildLista(List<Usuario> filtrados) {
    const padding = EdgeInsets.fromLTRB(20, 4, 20, 88);
    // Com status "Ativos" ou "Inativos" a lista já é de um tipo só.
    if (_filtro.status != StatusFiltro.todos) {
      return ListView(
        padding: padding,
        children: filtrados.map((u) => _buildUsuarioCard(u, inativo: !u.ativo)).toList(),
      );
    }
    final ativos = filtrados.where((u) => u.ativo);
    final inativos = filtrados.where((u) => !u.ativo);
    return ListView(
      padding: padding,
      children: [
        ...ativos.map((u) => _buildUsuarioCard(u, inativo: false)),
        if (inativos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              'Inativos',
              style: TextStyle(
                  color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          ...inativos.map((u) => _buildUsuarioCard(u, inativo: true)),
        ],
      ],
    );
  }

  Widget _buildUsuarioCard(Usuario u, {required bool inativo}) {
    final card = Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: kPrimary.withOpacity(0.1),
            child: Icon(
              inativo ? Icons.warning_amber_rounded : Icons.person_outline,
              color: kPrimary,
              size: 22,
            ),
          ),
          title: Text(
            u.nome,
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              u.email,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          trailing: inativo
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: kPrimary, size: 20),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UsuarioFormScreen(usuario: u),
                          ),
                        );
                        _carregar();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade300, size: 20),
                      onPressed: () => _deletar(u.id!, u.nome),
                    ),
                  ],
                ),
        ),
      ),
    );

    if (!inativo) return card;

    return Stack(
      children: [
        Opacity(opacity: 0.5, child: card),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Inativo',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}