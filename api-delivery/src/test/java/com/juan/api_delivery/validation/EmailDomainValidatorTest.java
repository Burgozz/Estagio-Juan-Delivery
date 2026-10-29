package com.juan.api_delivery.validation;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import javax.naming.CommunicationException;
import javax.naming.ServiceUnavailableException;
import java.net.SocketTimeoutException;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class EmailDomainValidatorTest {

    @BeforeEach
    @AfterEach
    void restaurarDnsReal() {
        EmailDomainValidator.setConsultaDns(null);
    }

    // --- Consultas DNS reais (exigem internet) ---

    @Test
    void dominiosReaisPassam() {
        assertTrue(EmailDomainValidator.isDominioValido("alguem@gmail.com"));
        assertTrue(EmailDomainValidator.isDominioValido("alguem@outlook.com"));
        assertTrue(EmailDomainValidator.isDominioValido("alguem@hotmail.com"));
    }

    @Test
    void dominioInventadoFalha() {
        assertFalse(EmailDomainValidator.isDominioValido("alguem@dominioquenaoexiste123456.com"));
    }

    // --- Comportamento com DNS simulado ---

    @Test
    void dominiosLiberadosPassamSemConsultarDns() {
        AtomicInteger consultas = new AtomicInteger();
        EmailDomainValidator.setConsultaDns((dominio, tipo) -> {
            consultas.incrementAndGet();
            return false;
        });

        assertTrue(EmailDomainValidator.isDominioValido("admin@juan.com"));
        assertTrue(EmailDomainValidator.isDominioValido("x@teste.com"));
        assertTrue(EmailDomainValidator.isDominioValido("X@JUAN.COM"));
        assertEquals(0, consultas.get());
    }

    @Test
    void timeoutAceitaEmail() {
        EmailDomainValidator.setConsultaDns((dominio, tipo) -> {
            CommunicationException e = new CommunicationException("DNS error");
            e.setRootCause(new SocketTimeoutException("timeout"));
            throw e;
        });
        assertTrue(EmailDomainValidator.isDominioValido("alguem@qualquer.com"));
    }

    @Test
    void dnsIndisponivelAceitaEmail() {
        EmailDomainValidator.setConsultaDns((dominio, tipo) -> {
            throw new ServiceUnavailableException("sem DNS");
        });
        assertTrue(EmailDomainValidator.isDominioValido("alguem@qualquer.com"));
    }

    @Test
    void semMxUsaRegistroAComoFallback() {
        EmailDomainValidator.setConsultaDns((dominio, tipo) -> tipo.equals("A"));
        assertTrue(EmailDomainValidator.isDominioValido("alguem@soa.com"));
    }

    @Test
    void semMxNemAFalha() {
        EmailDomainValidator.setConsultaDns((dominio, tipo) -> false);
        assertFalse(EmailDomainValidator.isDominioValido("alguem@vazio.com"));
    }

    @Test
    void resultadoFicaEmCache() {
        AtomicInteger consultas = new AtomicInteger();
        EmailDomainValidator.setConsultaDns((dominio, tipo) -> {
            consultas.incrementAndGet();
            return true;
        });

        EmailDomainValidator.isDominioValido("a@cacheado.com");
        EmailDomainValidator.isDominioValido("b@CACHEADO.com");
        assertEquals(1, consultas.get());
    }
}
