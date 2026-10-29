package com.juan.api_delivery.shared.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import static com.juan.api_delivery.shared.exception.MensagensErro.SAFRA_INVALIDA;

/**
 * Safra entre {@link SafraValidaValidator#SAFRA_MINIMA} (1800) e o ano atual.
 * O limite superior é calculado na hora da validação ({@code Year.now()}),
 * por isso não dá para usar {@code @Max}, que só aceita constantes.
 * Valores nulos são considerados válidos aqui (a obrigatoriedade para vinho é
 * validada à parte).
 */
@Documented
@Constraint(validatedBy = SafraValidaValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface SafraValida {
    String message() default SAFRA_INVALIDA;

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
