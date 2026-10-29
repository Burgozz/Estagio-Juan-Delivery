package com.juan.api_delivery.pedido;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PedidoDTO {
    @NotNull(message = "Informe o usuário do pedido")
    private Long usuarioId;
}
