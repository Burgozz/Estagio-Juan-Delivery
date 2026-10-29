package com.juan.api_delivery.produto;

import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import static com.juan.api_delivery.shared.exception.MensagensErro.SAFRA_INVALIDA;

@Entity
@DiscriminatorValue("VINHO")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class Vinho extends Produto {

    @NotNull
    @Enumerated(EnumType.STRING)
    private CategoriaProduto categoria;

    @NotBlank
    private String paisOrigem;

    @Min(value = 1800, message = SAFRA_INVALIDA)
    @Max(value = 2025, message = SAFRA_INVALIDA)
    private int safra;

    @DecimalMin(value = "0.0", message = "Teor alcoólico não pode ser negativo")
    @DecimalMax(value = "100.0", message = "Teor alcoólico inválido")
    private double teorAlcool;

    @NotBlank
    private String harmonizacao;
}
