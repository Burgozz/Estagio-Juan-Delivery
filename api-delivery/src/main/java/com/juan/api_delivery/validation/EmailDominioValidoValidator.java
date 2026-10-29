package com.juan.api_delivery.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.util.regex.Pattern;

public class EmailDominioValidoValidator implements ConstraintValidator<EmailDominioValido, String> {

    /** Formato mínimo para consultar o DNS: local@dominio.tld, sem espaços. */
    private static final Pattern FORMATO_EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null || !FORMATO_EMAIL.matcher(value).matches()) {
            return true;
        }
        return EmailDomainValidator.isDominioValido(value);
    }
}
