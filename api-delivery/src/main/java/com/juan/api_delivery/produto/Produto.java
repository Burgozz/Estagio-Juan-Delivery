package com.juan.api_delivery.produto;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorColumn;
import jakarta.persistence.DiscriminatorType;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;

import static com.juan.api_delivery.shared.exception.MensagensErro.ESTOQUE_NEGATIVO;
import static com.juan.api_delivery.shared.exception.MensagensErro.NOME_TAMANHO;

/**
 * Classe base do catálogo. Não é instanciável diretamente: todo produto
 * persistido é um {@link Vinho} ou um {@link Acessorio}, discriminados pela
 * coluna "tipo_produto" (estratégia de herança SINGLE_TABLE, mesma tabela
 * "produtos" de antes).
 */
@Entity
@Table(name = "produtos")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "tipo_produto", discriminatorType = DiscriminatorType.STRING, length = 20)
@Data
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public abstract class Produto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(min = 2, max = 100, message = NOME_TAMANHO)
    private String nome;

    @NotNull
    @DecimalMin(value = "0.0", message = "Preço não pode ser negativo")
    private BigDecimal preco;

    @Size(max = 500, message = "Descrição muito longa")
    private String descricao;

    private String imagemUrl;

    @Min(value = 0, message = ESTOQUE_NEGATIVO)
    private Integer estoque;

    @Builder.Default
    @Column(nullable = false, columnDefinition = "boolean default true")
    private boolean ativo = true;

    /**
     * Mantém "ativo" coerente com o estoque: estoque 0 desativa o produto e
     * estoque maior que 0 reativa. Usado no cadastro/edição pelo admin e em
     * toda baixa ou devolução de estoque feita pelos pedidos.
     */
    public void atualizarAtivoConformeEstoque() {
        if (estoque != null && estoque == 0) {
            ativo = false;
        } else if (estoque != null && estoque > 0) {
            ativo = true;
        }
    }

    /** Retira [quantidade] do estoque (já validada pelo chamador) e aplica a regra de ativo. */
    public void baixarEstoque(int quantidade) {
        estoque = (estoque == null ? 0 : estoque) - quantidade;
        atualizarAtivoConformeEstoque();
    }

    /** Devolve [quantidade] ao estoque e aplica a regra de ativo (reativa se voltou a ter estoque). */
    public void devolverEstoque(int quantidade) {
        estoque = (estoque == null ? 0 : estoque) + quantidade;
        atualizarAtivoConformeEstoque();
    }
}
