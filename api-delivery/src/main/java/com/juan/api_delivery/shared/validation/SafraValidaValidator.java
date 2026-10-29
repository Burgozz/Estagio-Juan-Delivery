package com.juan.api_delivery.shared.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.time.Year;

public class SafraValidaValidator implements ConstraintValidator<SafraValida, Integer> {

    public static final int SAFRA_MINIMA = 1800;

    /** Ano atual: maior safra aceita. */
    public static int safraMaxima() {
        return Year.now().getValue();
    }

    @Override
    public boolean isValid(Integer safra, ConstraintValidatorContext context) {
        if (safra == null) {
            return true;
        }
        return safra >= SAFRA_MINIMA && safra <= safraMaxima();
    }
}
