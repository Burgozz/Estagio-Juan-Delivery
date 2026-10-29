package com.juan.api_delivery.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import com.juan.api_delivery.validation.CpfValido;
import com.juan.api_delivery.validation.EmailDominioValido;
import lombok.AllArgsConstructor;
import java.time.LocalDate;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UsuarioDTO {
    @NotBlank
    @Pattern(
        regexp = "^[\\p{L} ]+$",
        message = "Nome deve conter apenas letras"
    )
    private String nome;

    @NotBlank
    @CpfValido
    private String cpf;

    @Email
    @EmailDominioValido
    private String email;

    @NotBlank
    private String senha;

    @Pattern(
        regexp = "^[1-9]\\d{9,10}$",
        message = "Telefone inválido. Informe apenas números com DDD (10 ou 11 dígitos)"
    )
    private String telefone;

    private LocalDate dataCadastro;


}