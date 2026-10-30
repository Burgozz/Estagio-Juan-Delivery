package com.juan.api_delivery.produto;

import com.juan.api_delivery.shared.validation.SafraValida;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import static com.juan.api_delivery.shared.exception.MensagensErro.TEOR_ALCOOL_INVALIDO;

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

    @SafraValida
    private int safra;

    @DecimalMin(value = "7.0", message = TEOR_ALCOOL_INVALIDO)
    @DecimalMax(value = "20.0", message = TEOR_ALCOOL_INVALIDO)
    private double teorAlcool;

    @NotBlank
    private String harmonizacao;
}
