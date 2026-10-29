package com.juan.api_delivery.produto;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;

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
    @Size(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres")
    private String nome;

    @NotNull
    @DecimalMin(value = "0.0", message = "Preço não pode ser negativo")
    private BigDecimal preco;

    @Size(max = 500, message = "Descrição muito longa")
    private String descricao;

    private String imagemUrl;

    @Min(value = 0, message = "Estoque não pode ser negativo")
    private Integer estoque;

    @Builder.Default
    @Column(nullable = false, columnDefinition = "boolean default true")
    private boolean ativo = true;
}
