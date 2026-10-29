package com.juan.api_delivery.usuario;

import com.juan.api_delivery.shared.validation.CpfValido;
import com.juan.api_delivery.shared.validation.EmailDominioValido;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import static com.juan.api_delivery.shared.exception.MensagensErro.EMAIL_OBRIGATORIO;
import static com.juan.api_delivery.shared.exception.MensagensErro.NOME_TAMANHO;
import static com.juan.api_delivery.shared.exception.MensagensErro.SENHA_TAMANHO;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UsuarioDTO {
    @NotBlank
    @Size(min = 2, max = 100, message = NOME_TAMANHO)
    @Pattern(
        regexp = "^[\\p{L} ]+$",
        message = "Nome deve conter apenas letras"
    )
    private String nome;

    @NotBlank
    @CpfValido
    private String cpf;

    @NotBlank(message = EMAIL_OBRIGATORIO)
    @Email
    @EmailDominioValido
    private String email;

    @NotBlank
    @Size(min = 6, message = SENHA_TAMANHO)
    private String senha;

    @Pattern(
        regexp = "^[1-9]\\d{9,10}$",
        message = "Telefone inválido. Informe apenas números com DDD (10 ou 11 dígitos)"
    )
    private String telefone;

    private LocalDate dataCadastro;

}