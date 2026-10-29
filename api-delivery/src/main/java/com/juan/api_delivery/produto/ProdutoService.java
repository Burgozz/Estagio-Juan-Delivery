package com.juan.api_delivery.produto;

import com.juan.api_delivery.pedido.ItemPedidoRepository;
import java.util.List;

import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ProdutoService {

    private final ProdutoRepository repository;
    private final ItemPedidoRepository itemPedidoRepository;

    public List<Produto> listarAtivos() {
        return repository.findByAtivoTrue();
    }

    /**
     * Usado pela tela de administração: retorna todos os produtos,
     * incluindo os inativos (desativados por estoque zerado).
     */
    public List<Produto> listarTodos() {
        return repository.findAll();
    }

    public List<Produto> listarPorCategoria(String categoria) {
        return repository.findByAtivoTrueAndCategoria(categoria);
    }

    public Produto buscarPorId(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new RuntimeException("Produto não encontrado"));
    }

    /**
     * Usado pelo catálogo público: um produto inativo é tratado como
     * inexistente (404), nunca é retornado.
     */
    public Produto buscarAtivoPorId(Long id) {
        return repository.findByIdAndAtivoTrue(id)
            .orElseThrow(() -> new ProdutoNaoEncontradoException(id));
    }

    public Produto criar(ProdutoDTO dto) {
        if (dto.getEstoque() == null || dto.getEstoque() <= 0) {
            throw new IllegalArgumentException("Estoque inicial deve ser maior que zero para criar um produto");
        }
        validarCamposPorTipo(dto);
        Produto produto = construirNovoProduto(dto);
        atualizarAtivoConformeEstoque(produto);
        return repository.save(produto);
    }

    public Produto atualizar(Long id, ProdutoDTO dto) {
        Produto produto = buscarPorId(id);
        validarCamposPorTipo(dto);
        produto.setNome(dto.getNome());
        produto.setPreco(dto.getPreco());
        produto.setDescricao(dto.getDescricao());
        produto.setEstoque(dto.getEstoque());
        if (produto instanceof Vinho vinho) {
            vinho.setCategoria(dto.getCategoria());
            vinho.setPaisOrigem(dto.getPaisOrigem());
            vinho.setSafra(dto.getSafra() != null ? dto.getSafra() : 0);
            vinho.setTeorAlcool(dto.getTeorAlcool());
            vinho.setHarmonizacao(dto.getHarmonizacao());
        } else if (produto instanceof Acessorio acessorio) {
            acessorio.setTipoAcessorio(dto.getTipoAcessorio());
            acessorio.setMarca(dto.getMarca());
            acessorio.setMaterial(dto.getMaterial());
        }
        atualizarAtivoConformeEstoque(produto);
        return repository.save(produto);
    }

    /**
     * Desativa automaticamente o produto quando o estoque zera e o
     * reativa automaticamente quando volta a ter estoque, mantendo o
     * campo "ativo" sempre coerente com o estoque atual.
     */
    private void atualizarAtivoConformeEstoque(Produto produto) {
        Integer estoque = produto.getEstoque();
        if (estoque != null && estoque == 0) {
            produto.setAtivo(false);
        } else if (estoque != null && estoque > 0 && !produto.isAtivo()) {
            produto.setAtivo(true);
        }
    }

    /**
     * Constrói o subtipo concreto ({@link Vinho} ou {@link Acessorio})
     * correspondente ao {@link TipoProduto} informado no DTO. A discriminação
     * de subtipo agora é feita pela hierarquia de classes (SINGLE_TABLE),
     * não mais por um campo "tipo" na própria entidade.
     */
    private Produto construirNovoProduto(ProdutoDTO dto) {
        if (dto.getTipo() == TipoProduto.VINHO) {
            return Vinho.builder()
                .nome(dto.getNome())
                .preco(dto.getPreco())
                .descricao(dto.getDescricao())
                .estoque(dto.getEstoque())
                .categoria(dto.getCategoria())
                .paisOrigem(dto.getPaisOrigem())
                .safra(dto.getSafra() != null ? dto.getSafra() : 0)
                .teorAlcool(dto.getTeorAlcool())
                .harmonizacao(dto.getHarmonizacao())
                .build();
        }
        return Acessorio.builder()
            .nome(dto.getNome())
            .preco(dto.getPreco())
            .descricao(dto.getDescricao())
            .estoque(dto.getEstoque())
            .tipoAcessorio(dto.getTipoAcessorio())
            .marca(dto.getMarca())
            .material(dto.getMaterial())
            .build();
    }

    /**
     * Exclusão definitiva. Produto que já aparece em algum pedido não pode
     * ser apagado (o histórico de pedidos depende dele); nesse caso o admin
     * deve zerar o estoque, o que o deixa inativo.
     */
    public void deletar(Long id) {
        Produto produto = buscarPorId(id);
        if (itemPedidoRepository.existsByProdutoId(produto.getId())) {
            throw new IllegalArgumentException(
                "Este produto já possui pedidos e não pode ser excluído. Para removê-lo do catálogo, zere o estoque.");
        }
        repository.deleteById(produto.getId());
    }

    private void validarCamposPorTipo(ProdutoDTO dto) {
        if (dto.getTipo() == TipoProduto.VINHO && dto.getCategoria() == null) {
            throw new IllegalArgumentException("Categoria é obrigatória para produtos do tipo Vinho");
        }
        if (dto.getTipo() == TipoProduto.ACESSORIO && dto.getTipoAcessorio() == null) {
            throw new IllegalArgumentException("Tipo do acessório é obrigatório para produtos do tipo Acessorio");
        }
    }
}
