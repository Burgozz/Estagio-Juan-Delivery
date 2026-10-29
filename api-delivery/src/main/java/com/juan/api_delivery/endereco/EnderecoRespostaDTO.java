package com.juan.api_delivery.endereco;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO de resposta para consulta de endereços. Não expõe a referência de
 * volta para o usuário dono do endereço.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class EnderecoRespostaDTO {
    private Long id;
    private String rua;
    private String numero;
    private String bairro;
    private String cidade;
    private String estado;
    private String cep;

    public static EnderecoRespostaDTO from(Endereco endereco) {
        return new EnderecoRespostaDTO(
            endereco.getId(),
            endereco.getRua(),
            endereco.getNumero(),
            endereco.getBairro(),
            endereco.getCidade(),
            endereco.getEstado(),
            endereco.getCep()
        );
    }
}
