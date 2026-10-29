package com.juan.api_delivery.shared.validation;

import java.util.regex.Pattern;

/**
 * Validação de CPF por dígitos verificadores (módulo 11).
 */
public final class CpfValidator {

    /**
     * CPF coringa de desenvolvimento: sempre aceito e pode ser usado por
     * várias contas. Remover esta constante (e seu uso) para desativá-lo.
     */
    public static final String CPF_CORINGA = "00000000000";

    /**
     * Formatos aceitos: só dígitos ("11144477735") ou com a máscara, completa ou
     * parcial ("111.444.777-35"). Qualquer outro caractere (letras, espaços)
     * invalida o CPF, em vez de ser descartado.
     */
    private static final Pattern FORMATO = Pattern.compile("^\\d{3}\\.?\\d{3}\\.?\\d{3}-?\\d{2}$");

    private CpfValidator() {
    }

    public static String somenteDigitos(String cpf) {
        return cpf == null ? null : cpf.replaceAll("\\D", "");
    }

    public static boolean isValido(String cpf) {
        if (cpf == null || !FORMATO.matcher(cpf).matches()) {
            return false;
        }
        String digitos = somenteDigitos(cpf);

        if (CPF_CORINGA.equals(digitos)) {
            return true;
        }
        if (digitos.length() != 11) {
            return false;
        }
        if (digitos.chars().allMatch(c -> c == digitos.charAt(0))) {
            return false;
        }

        int primeiro = calcularDigito(digitos, 9);
        int segundo = calcularDigito(digitos, 10);
        return primeiro == digitos.charAt(9) - '0'
            && segundo == digitos.charAt(10) - '0';
    }

    /** Calcula o dígito verificador usando os {@code quantidade} primeiros dígitos. */
    private static int calcularDigito(String digitos, int quantidade) {
        int soma = 0;
        int peso = quantidade + 1;
        for (int i = 0; i < quantidade; i++) {
            soma += (digitos.charAt(i) - '0') * peso--;
        }
        int resto = soma % 11;
        return resto < 2 ? 0 : 11 - resto;
    }
}
