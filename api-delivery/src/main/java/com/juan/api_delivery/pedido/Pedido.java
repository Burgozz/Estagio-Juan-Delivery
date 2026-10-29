package com.juan.api_delivery.pedido;

import com.juan.api_delivery.usuario.Usuario;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "pedidos")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Pedido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull
    @ManyToOne
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @NotNull
    @Enumerated(EnumType.STRING)
    private StatusPedido status;

    private LocalDateTime dataPedido;

    @DecimalMin(value = "0.0", message = "Valor total não pode ser negativo")
    private BigDecimal valorTotal;

    @OneToMany(mappedBy = "pedido")
    @Builder.Default
    private List<ItemPedido> itens = new ArrayList<>();
}
