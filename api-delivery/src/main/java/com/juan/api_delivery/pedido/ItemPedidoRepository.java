package com.juan.api_delivery.pedido;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ItemPedidoRepository extends JpaRepository<ItemPedido, Long> {
    List<ItemPedido> findByPedidoId(Long pedidoId);

    boolean existsByProdutoId(Long produtoId);
}
