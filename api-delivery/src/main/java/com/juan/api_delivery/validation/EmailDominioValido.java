package com.juan.api_delivery.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Valida via DNS se o domínio do e-mail existe e recebe e-mails. Valores
 * nulos, vazios ou com formato inválido são ignorados aqui; o formato fica
 * a cargo do {@code @Email}.
 */
@Documented
@Constraint(validatedBy = EmailDominioValidoValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface EmailDominioValido {
    String message() default "Domínio de e-mail inválido ou inexistente";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
