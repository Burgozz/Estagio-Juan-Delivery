package com.juan.api_delivery.produto;

import java.math.BigDecimal;

import com.juan.api_delivery.shared.validation.SafraValida;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import static com.juan.api_delivery.shared.exception.MensagensErro.ESTOQUE_NEGATIVO;
import static com.juan.api_delivery.shared.exception.MensagensErro.TEOR_ALCOOL_INVALIDO;
import static com.juan.api_delivery.shared.exception.MensagensErro.TEOR_ALCOOL_NEGATIVO;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProdutoDTO {
    @NotBlank
    private String nome;
    @NotNull
    @DecimalMin("0.0")
    private BigDecimal preco;
    private String descricao;
    @NotNull(message = "Informe o tipo do produto (VINHO ou ACESSORIO)")
    private TipoProduto tipo;

    // Campos específicos de Vinho
    private CategoriaProduto categoria;
    private String paisOrigem;
    @SafraValida
    private Integer safra;
    @DecimalMin(value = "0.0", message = TEOR_ALCOOL_NEGATIVO)
    @DecimalMax(value = "100.0", message = TEOR_ALCOOL_INVALIDO)
    private Double teorAlcool;
    // @Pattern e @Size ignoram null: Acessorio continua sem enviar harmonização.
    // O lookahead exige no mínimo 3 letras (igual ao app), para recusar texto só
    // com pontuação, como ", , .".
    @Pattern(
        regexp = "^(?=(?:[^a-zA-ZÀ-ÿ]*[a-zA-ZÀ-ÿ]){3})[a-zA-ZÀ-ÿ\\s,.\\-/]+$",
        message = "Harmonização deve conter apenas letras e pontuação simples"
    )
    @Size(min = 3, max = 150, message = "Harmonização deve ter entre 3 e 150 caracteres")
    private String harmonizacao;

    // Campos específicos de Acessorio
    private String tipoAcessorio;
    private String marca;
    private String material;

    @NotNull(message = "Informe o estoque")
    @Min(value = 0, message = ESTOQUE_NEGATIVO)
    private Integer estoque;

    // safra e teorAlcool são campos wrapper aqui (compartilhados com o DTO de
    // Acessorio, que nunca os envia), mas na entidade Vinho viraram tipos
    // primitivos. Exigi-los apenas quando tipo == VINHO evita tanto o
    // NullPointerException no unboxing quanto a quebra da criação/atualização
    // de Acessorio.
    @AssertTrue(message = "Safra é obrigatória para vinhos")
    public boolean isSafraValida() {
        return tipo != TipoProduto.VINHO || safra != null;
    }

    @AssertTrue(message = "Teor alcoólico é obrigatório para vinhos")
    public boolean isTeorAlcoolValido() {
        return tipo != TipoProduto.VINHO || teorAlcool != null;
    }

    @AssertTrue(message = "Harmonização é obrigatória para vinhos")
    public boolean isHarmonizacaoValida() {
        return tipo != TipoProduto.VINHO || (harmonizacao != null && !harmonizacao.isBlank());
    }
}