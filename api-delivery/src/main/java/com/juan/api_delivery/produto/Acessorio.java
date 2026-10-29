package com.juan.api_delivery.produto;

import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

@Entity
@DiscriminatorValue("ACESSORIO")
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class Acessorio extends Produto {

    @NotBlank
    private String tipoAcessorio;

    @NotBlank
    private String marca;

    @NotBlank
    private String material;
}
