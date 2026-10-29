package com.juan.api_delivery.shared;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.juan.api_delivery.pedido.ItemPedidoRepository;
import com.juan.api_delivery.pedido.PedidoRepository;
import com.juan.api_delivery.produto.ProdutoRepository;
import com.juan.api_delivery.shared.validation.EmailDomainValidatorTestSupport;
import com.juan.api_delivery.usuario.UsuarioRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

/**
 * Base dos testes de integração: sobe a aplicação inteira (controller,
 * validação, serviço, entidades e repositórios) sobre um H2 em memória
 * (perfil "test"). Nenhuma camada é mockada.
 *
 * Não usa @Transactional de propósito: com rollback automático o Hibernate
 * nunca faria o flush das atualizações e a validação da entidade não rodaria.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public abstract class IntegracaoBase {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper json;

    @Autowired
    protected UsuarioRepository usuarioRepository;

    @Autowired
    protected ProdutoRepository produtoRepository;

    @Autowired
    protected PedidoRepository pedidoRepository;

    @Autowired
    protected ItemPedidoRepository itemPedidoRepository;

    @BeforeEach
    protected void prepararBase() {
        // Limpeza entre testes (apenas no H2 de teste). O admin criado pelo
        // DataInitializer é mantido. Itens e pedidos saem antes, porque
        // referenciam produtos e usuários.
        itemPedidoRepository.deleteAll();
        pedidoRepository.deleteAll();
        produtoRepository.deleteAll();
        usuarioRepository.findAll().stream()
            .filter(u -> !"admin@juan.com".equals(u.getEmail()))
            .forEach(usuarioRepository::delete);
        // Por padrão o DNS é simulado como "domínio existe", para os testes
        // não dependerem da internet. Testes específicos trocam a consulta.
        EmailDomainValidatorTestSupport.setConsultaDns((dominio, tipo) -> true);
    }

    @AfterEach
    protected void restaurarDns() {
        EmailDomainValidatorTestSupport.setConsultaDns(null);
    }

    protected ResultActions postJson(String url, Object corpo) throws Exception {
        return mockMvc.perform(post(url)
            .contentType(MediaType.APPLICATION_JSON)
            .content(json.writeValueAsString(corpo)));
    }

    protected ResultActions putJson(String url, Object corpo) throws Exception {
        return mockMvc.perform(put(url)
            .contentType(MediaType.APPLICATION_JSON)
            .content(json.writeValueAsString(corpo)));
    }

    protected JsonNode corpoDe(ResultActions resultado) throws Exception {
        return json.readTree(resultado.andReturn().getResponse().getContentAsString());
    }

    /** Mapa mutável que aceita valores null (Map.of não aceita). */
    protected static Map<String, Object> mapa(Object... chavesEValores) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; i < chavesEValores.length; i += 2) {
            m.put((String) chavesEValores[i], chavesEValores[i + 1]);
        }
        return m;
    }
}
