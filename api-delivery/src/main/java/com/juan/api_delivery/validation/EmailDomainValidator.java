package com.juan.api_delivery.validation;

import lombok.extern.slf4j.Slf4j;

import javax.naming.NameNotFoundException;
import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.Attributes;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import java.util.Hashtable;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Valida se o domínio de um e-mail existe e está configurado para receber
 * e-mails (registro MX, ou registro A como fallback — RFC 5321).
 * Não verifica se a caixa de e-mail existe.
 */
@Slf4j
public final class EmailDomainValidator {

    /** Domínios de desenvolvimento que sempre passam, sem consulta DNS. */
    public static final Set<String> DOMINIOS_LIBERADOS = Set.of("juan.com", "teste.com");

    private static final String TIMEOUT_MS = "3000";

    /** Consulta de um tipo de registro DNS; permite simular a rede nos testes. */
    @FunctionalInterface
    public interface ConsultaDns {
        /**
         * @return true se o domínio possui ao menos um registro do tipo informado
         * @throws NameNotFoundException se o domínio não existe
         * @throws NamingException       em falha de rede, timeout ou DNS indisponível
         */
        boolean temRegistro(String dominio, String tipo) throws NamingException;
    }

    private static final ConsultaDns CONSULTA_JNDI = EmailDomainValidator::consultarViaJndi;

    private static volatile ConsultaDns consultaDns = CONSULTA_JNDI;

    private static final Map<String, Boolean> CACHE = new ConcurrentHashMap<>();

    private EmailDomainValidator() {
    }

    public static boolean isDominioValido(String email) {
        if (email == null) {
            return false;
        }
        int arroba = email.lastIndexOf('@');
        if (arroba < 0 || arroba == email.length() - 1) {
            return false;
        }
        String dominio = email.substring(arroba + 1).trim().toLowerCase(Locale.ROOT);

        if (DOMINIOS_LIBERADOS.contains(dominio)) {
            return true;
        }
        Boolean emCache = CACHE.get(dominio);
        if (emCache != null) {
            return emCache;
        }

        try {
            boolean valido = consultaDns.temRegistro(dominio, "MX")
                || consultaDns.temRegistro(dominio, "A");
            CACHE.put(dominio, valido);
            return valido;
        } catch (NameNotFoundException e) {
            CACHE.put(dominio, false);
            return false;
        } catch (NamingException | RuntimeException e) {
            // Sem rede/DNS não bloqueia o cadastro; não guarda em cache para tentar de novo depois.
            log.warn("Não foi possível validar o domínio de e-mail '{}' via DNS; e-mail aceito. Causa: {}",
                dominio, e.toString());
            return true;
        }
    }

    private static boolean consultarViaJndi(String dominio, String tipo) throws NamingException {
        Hashtable<String, String> env = new Hashtable<>();
        env.put(DirContext.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.dns.DnsContextFactory");
        env.put("com.sun.jndi.dns.timeout.initial", TIMEOUT_MS);
        env.put("com.sun.jndi.dns.timeout.retries", "1");

        DirContext ctx = new InitialDirContext(env);
        try {
            Attributes atributos = ctx.getAttributes(dominio, new String[]{tipo});
            Attribute registro = atributos.get(tipo);
            return registro != null && registro.size() > 0;
        } finally {
            ctx.close();
        }
    }

    /** Uso exclusivo em testes: substitui a consulta DNS e limpa o cache. */
    static void setConsultaDns(ConsultaDns consulta) {
        consultaDns = consulta == null ? CONSULTA_JNDI : consulta;
        CACHE.clear();
    }
}
