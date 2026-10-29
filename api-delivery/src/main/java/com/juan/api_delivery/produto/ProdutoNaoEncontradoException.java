package com.juan.api_delivery.produto;

/**
 * Lançada quando um produto não existe ou existe mas está inativo
 * (ativo = false), caso em que deve ser tratado como inexistente pelo
 * catálogo público.
 */
public class ProdutoNaoEncontradoException extends RuntimeException {
    public ProdutoNaoEncontradoException(Long id) {
        super("Produto não encontrado: " + id);
    }
}
