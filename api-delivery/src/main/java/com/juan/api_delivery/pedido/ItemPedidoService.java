package com.juan.api_delivery.pedido;

import com.juan.api_delivery.produto.Produto;
import com.juan.api_delivery.produto.ProdutoRepository;
import java.math.BigDecimal;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

import static com.juan.api_delivery.shared.exception.MensagensErro.PEDIDO_CANCELADO_NAO_ALTERA;
import static com.juan.api_delivery.shared.exception.MensagensErro.PEDIDO_NAO_ENCONTRADO;
import static com.juan.api_delivery.shared.exception.MensagensErro.PRODUTO_INDISPONIVEL;
import static com.juan.api_delivery.shared.exception.MensagensErro.PRODUTO_NAO_ENCONTRADO;

@Service
@RequiredArgsConstructor
public class ItemPedidoService {

    private final ItemPedidoRepository repository;
    private final PedidoRepository pedidoRepository;
    private final ProdutoRepository produtoRepository;

    public List<ItemPedido> listarPorPedido(Long pedidoId) {
        return repository.findByPedidoId(pedidoId);
    }

    /**
     * Adiciona o item, baixa o estoque do produto (que fica inativo se zerar)
     * e recalcula o valor total do pedido. Qualquer erro desfaz tudo.
     */
    @Transactional
    public ItemPedido adicionar(Long pedidoId, ItemPedidoDTO dto) {
        Pedido pedido = buscarPedidoAlteravel(pedidoId);
        Produto produto = produtoRepository.findByIdParaAtualizarEstoque(dto.getProdutoId())
            .orElseThrow(() -> new IllegalArgumentException(PRODUTO_NAO_ENCONTRADO));
        if (!produto.isAtivo()) {
            throw new IllegalArgumentException(PRODUTO_INDISPONIVEL);
        }
        int disponivel = produto.getEstoque() == null ? 0 : produto.getEstoque();
        if (dto.getQuantidade() > disponivel) {
            throw new IllegalArgumentException(
                "Estoque insuficiente para " + produto.getNome() + ". Disponível: " + disponivel);
        }
        produto.baixarEstoque(dto.getQuantidade());
        ItemPedido item = repository.save(ItemPedido.builder()
            .pedido(pedido)
            .produto(produto)
            .quantidade(dto.getQuantidade())
            .precoUnit(produto.getPreco())
            .build());
        recalcularValorTotal(pedido);
        return item;
    }

    /**
     * Remove o item, devolve a quantidade ao estoque (reativando o produto se
     * voltar a ter estoque) e recalcula o valor total do pedido.
     */
    @Transactional
    public void remover(Long pedidoId, Long id) {
        Pedido pedido = buscarPedidoAlteravel(pedidoId);
        ItemPedido item = repository.findById(id)
            .filter(i -> i.getPedido() != null && pedidoId.equals(i.getPedido().getId()))
            .orElseThrow(() -> new IllegalArgumentException("Item de pedido não encontrado"));
        produtoRepository.findByIdParaAtualizarEstoque(item.getProduto().getId())
            .ifPresent(produto -> produto.devolverEstoque(item.getQuantidade()));
        repository.delete(item);
        recalcularValorTotal(pedido);
    }

    /** Pedido cancelado já devolveu o estoque; mexer nos itens dele desequilibraria a conta. */
    private Pedido buscarPedidoAlteravel(Long pedidoId) {
        Pedido pedido = pedidoRepository.findById(pedidoId)
            .orElseThrow(() -> new IllegalArgumentException(PEDIDO_NAO_ENCONTRADO));
        if (pedido.getStatus() == StatusPedido.CANCELADO) {
            throw new IllegalArgumentException(PEDIDO_CANCELADO_NAO_ALTERA);
        }
        return pedido;
    }

    /** valorTotal = soma de quantidade × precoUnit de todos os itens do pedido. */
    private void recalcularValorTotal(Pedido pedido) {
        BigDecimal total = repository.findByPedidoId(pedido.getId()).stream()
            .map(i -> i.getPrecoUnit().multiply(BigDecimal.valueOf(i.getQuantidade())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        pedido.setValorTotal(total);
        pedidoRepository.save(pedido);
    }
}
