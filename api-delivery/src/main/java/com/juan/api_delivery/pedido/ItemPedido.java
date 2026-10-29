package com.juan.api_delivery.pedido;

import com.juan.api_delivery.produto.Produto;
import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Entity
@Table(name = "itens_pedido")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ItemPedido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Min(value = 1, message = "Quantidade mínima é 1")
    private int quantidade;

    @NotNull
    @DecimalMin(value = "0.0", message = "Preço unitário não pode ser negativo")
    private BigDecimal precoUnit;

    // Ignorado na serialização para evitar recursão infinita ao serializar
    // Pedido -> itens -> pedido -> ... (GET /pedidos retorna a entidade
    // Pedido diretamente, incluindo a lista de itens).
    @ManyToOne
    @JoinColumn(name = "pedido_id")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    @JsonIgnore
    private Pedido pedido;

    @ManyToOne
    @JoinColumn(name = "produto_id")
    private Produto produto;
}
