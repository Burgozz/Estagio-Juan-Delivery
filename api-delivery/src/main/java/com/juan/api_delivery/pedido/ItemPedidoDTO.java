package com.juan.api_delivery.pedido;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ItemPedidoDTO {
    @NotNull(message = "Informe o produto")
    private Long produtoId;

    @NotNull(message = "Informe a quantidade")
    @Min(value = 1, message = "Quantidade deve ser maior que zero")
    private Integer quantidade;
}
