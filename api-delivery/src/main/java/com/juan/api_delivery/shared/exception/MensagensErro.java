package com.juan.api_delivery.shared.exception;

/**
 * Mensagens de erro usadas em mais de um lugar. O texto é o mesmo devolvido
 * ao app (o Flutter exibe essas mensagens ao usuário), então alterar um valor
 * aqui altera a resposta da API.
 */
public final class MensagensErro {

    public static final String USUARIO_NAO_ENCONTRADO = "Usuário não encontrado";
    public static final String PRODUTO_NAO_ENCONTRADO = "Produto não encontrado";
    public static final String PEDIDO_NAO_ENCONTRADO = "Pedido não encontrado";
    public static final String EMAIL_JA_CADASTRADO = "Email já cadastrado";

    public static final String NOME_TAMANHO = "Nome deve ter entre 2 e 100 caracteres";
    public static final String ESTOQUE_NEGATIVO = "Estoque não pode ser negativo";
    public static final String SAFRA_INVALIDA = "Safra inválida";

    private MensagensErro() {
    }
}
