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
    public static final String EMAIL_OBRIGATORIO = "Email é obrigatório";

    public static final String NOME_TAMANHO = "Nome deve ter entre 2 e 100 caracteres";
    public static final String SENHA_TAMANHO = "Senha deve ter no mínimo 6 caracteres";
    public static final String ESTOQUE_NEGATIVO = "Estoque não pode ser negativo";
    public static final String SAFRA_INVALIDA = "Safra deve estar entre 1800 e o ano atual";
    // Faixa de teor alcoólico do vinho pela Lei nº 7.678/1988.
    public static final String TEOR_ALCOOL_INVALIDO = "Teor alcoólico deve estar entre 7% e 20%";

    private MensagensErro() {
    }
}
