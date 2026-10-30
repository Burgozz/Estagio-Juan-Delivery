package com.juan.api_delivery.produto;

import java.util.List;
import java.util.Optional;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ProdutoRepository extends JpaRepository<Produto, Long> {
    List<Produto> findByAtivoTrue();

    Optional<Produto> findByIdAndAtivoTrue(Long id);

    /**
     * Busca o produto travando a linha até o fim da transação (SELECT ... FOR
     * UPDATE). Usado ao baixar ou devolver estoque, para dois pedidos ao mesmo
     * tempo não venderem a mesma unidade.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT p FROM Produto p WHERE p.id = :id")
    Optional<Produto> findByIdParaAtualizarEstoque(@Param("id") Long id);

    /**
     * "categoria" é um campo específico de {@link Vinho}, então a filtragem
     * é feita sobre esse subtipo (única fonte da coluna na herança
     * SINGLE_TABLE). O retorno continua em termos de {@link Produto}.
     */
    @Query("SELECT v FROM Vinho v WHERE v.ativo = true AND v.categoria = :categoria")
    List<Produto> findByAtivoTrueECategoria(@Param("categoria") CategoriaProduto categoria);

    /**
     * Filtra produtos ativos por categoria recebendo a categoria como texto
     * (ex.: valor vindo de um @RequestParam). Valores que não correspondem a
     * nenhuma {@link CategoriaProduto} conhecida simplesmente não retornam
     * resultados, em vez de lançar exceção.
     */
    default List<Produto> findByAtivoTrueAndCategoria(String categoria) {
        if (categoria == null || categoria.isBlank()) {
            return findByAtivoTrue();
        }
        try {
            CategoriaProduto categoriaEnum = CategoriaProduto.valueOf(categoria.trim().toUpperCase());
            return findByAtivoTrueECategoria(categoriaEnum);
        } catch (IllegalArgumentException e) {
            return List.of();
        }
    }
}
