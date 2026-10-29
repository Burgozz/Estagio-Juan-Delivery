package com.juan.api_delivery.pedido;

import com.juan.api_delivery.produto.Produto;
import com.juan.api_delivery.produto.ProdutoRepository;
import java.util.List;

import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ItemPedidoService {

    private final ItemPedidoRepository repository;
    private final PedidoRepository pedidoRepository;
    private final ProdutoRepository produtoRepository;

    public List<ItemPedido> listarPorPedido(Long pedidoId) {
        return repository.findByPedidoId(pedidoId);
    }

    public ItemPedido adicionar(Long pedidoId, ItemPedidoDTO dto) {
        Pedido pedido = pedidoRepository.findById(pedidoId)
            .orElseThrow(() -> new IllegalArgumentException("Pedido não encontrado"));
        Produto produto = produtoRepository.findById(dto.getProdutoId())
            .orElseThrow(() -> new IllegalArgumentException("Produto não encontrado"));
        ItemPedido item = ItemPedido.builder()
            .pedido(pedido)
            .produto(produto)
            .quantidade(dto.getQuantidade())
            .precoUnit(produto.getPreco())
            .build();
        return repository.save(item);
    }

    public void remover(Long id) {
        ItemPedido item = repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Item de pedido não encontrado"));
        repository.delete(item);
    }
}
