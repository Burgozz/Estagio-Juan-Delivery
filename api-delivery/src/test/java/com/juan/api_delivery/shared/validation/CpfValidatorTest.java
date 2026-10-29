package com.juan.api_delivery.shared.validation;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CpfValidatorTest {

    @Test
    void cpfsReaisValidosPassam() {
        assertTrue(CpfValidator.isValido("11144477735"));
        assertTrue(CpfValidator.isValido("52998224725"));
    }

    @Test
    void cpfCoringaPassa() {
        assertTrue(CpfValidator.isValido(CpfValidator.CPF_CORINGA));
        assertTrue(CpfValidator.isValido("00000000000"));
    }

    @Test
    void sequenciaRepetidaFalha() {
        assertFalse(CpfValidator.isValido("11111111111"));
        assertFalse(CpfValidator.isValido("99999999999"));
    }

    @Test
    void digitoVerificadorErradoFalha() {
        assertFalse(CpfValidator.isValido("11144477736"));
    }

    @Test
    void menosDeOnzeDigitosFalha() {
        assertFalse(CpfValidator.isValido("1114447773"));
        assertFalse(CpfValidator.isValido(""));
        assertFalse(CpfValidator.isValido(null));
    }

    @Test
    void letrasFalham() {
        assertFalse(CpfValidator.isValido("abcdefghijk"));
        assertFalse(CpfValidator.isValido("111.444.777-ab"));
    }

    @Test
    void cpfComMascaraPassa() {
        assertTrue(CpfValidator.isValido("111.444.777-35"));
        assertTrue(CpfValidator.isValido("111444777-35"));
        assertTrue(CpfValidator.isValido("000.000.000-00"));
    }

    @Test
    void letrasOuEspacosNoMeioDeUmCpfValidoFalham() {
        assertFalse(CpfValidator.isValido("111a444b777c35"));
        assertFalse(CpfValidator.isValido("CPF11144477735"));
        assertFalse(CpfValidator.isValido("111 444 777 35"));
        assertFalse(CpfValidator.isValido("111/444/777-35"));
    }
}
