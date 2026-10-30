package com.juan.api_delivery.pedido;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/pedidos/{pedidoId}/itens")
@RequiredArgsConstructor
public class ItemPedidoController {

    private final ItemPedidoService service;

    @GetMapping
    public ResponseEntity<List<ItemPedido>> listarPorPedido(@PathVariable Long pedidoId) {
        return ResponseEntity.ok(service.listarPorPedido(pedidoId));
    }

    @PostMapping
    public ResponseEntity<ItemPedido> adicionar(@PathVariable Long pedidoId, @RequestBody @Valid ItemPedidoDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.adicionar(pedidoId, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> remover(@PathVariable Long pedidoId, @PathVariable Long id) {
        service.remover(pedidoId, id);
        return ResponseEntity.noContent().build();
    }
}
