package com.juan.api_delivery.auth;

/**
 * Lançada quando o login falha por e-mail não encontrado (ou inativo) ou
 * senha incorreta. A mensagem é sempre genérica para não revelar qual dos
 * dois casos ocorreu.
 */
public class CredenciaisInvalidasException extends RuntimeException {
    public CredenciaisInvalidasException() {
        super("E-mail ou senha inválidos");
    }
}
