package com.juan.api_delivery.shared.validation;

/** Expõe a troca da consulta DNS para testes de outros pacotes. */
public final class EmailDomainValidatorTestSupport {

    private EmailDomainValidatorTestSupport() {
    }

    public static void setConsultaDns(EmailDomainValidator.ConsultaDns consulta) {
        EmailDomainValidator.setConsultaDns(consulta);
    }
}
