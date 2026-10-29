package com.juan.api_delivery.produto;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.hasItem;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProdutoController.class)
class ProdutoControllerTest {

    private static final String MSG_HARMONIZACAO = "Harmonização deve conter apenas letras e pontuação simples";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ProdutoService service;

    private static String vinho(String harmonizacao) {
        return """
            {"nome": "Malbec Reserva", "preco": 89.90, "tipo": "VINHO", "estoque": 10,
             "categoria": "VINHO_TINTO", "paisOrigem": "Argentina", "safra": 2020,
             "teorAlcool": 13.5, "harmonizacao": "%s"}
            """.formatted(harmonizacao);
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "Carnes vermelhas e queijos curados",
        "Frutos do mar, peixes grelhados.",
        "Massas / risotos",
        "Sobremesas agridoces"
    })
    void harmonizacaoValidaPassa(String harmonizacao) throws Exception {
        when(service.criar(any(ProdutoDTO.class))).thenReturn(new Acessorio());

        mockMvc.perform(post("/produtos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(vinho(harmonizacao)))
            .andExpect(status().isCreated());
    }

    @ParameterizedTest
    @ValueSource(strings = {"Queijos 12 meses", "carne@grelhada"})
    void harmonizacaoComNumerosOuSimbolosRetorna400(String harmonizacao) throws Exception {
        mockMvc.perform(post("/produtos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(vinho(harmonizacao)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.erros", hasItem(MSG_HARMONIZACAO)));
        verify(service, never()).criar(any());
    }

    @Test
    void harmonizacaoCurtaDemaisRetorna400() throws Exception {
        mockMvc.perform(post("/produtos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(vinho("ab")))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.erros", hasItem("Harmonização deve ter entre 3 e 150 caracteres")));
        verify(service, never()).criar(any());
    }

    @Test
    void acessorioSemHarmonizacaoContinuaFuncionando() throws Exception {
        when(service.criar(any(ProdutoDTO.class))).thenReturn(new Acessorio());

        mockMvc.perform(post("/produtos")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"nome": "Saca-rolhas", "preco": 49.90, "tipo": "ACESSORIO", "estoque": 5,
                     "tipoAcessorio": "Saca-rolhas", "marca": "Tramontina", "material": "Inox"}
                    """))
            .andExpect(status().isCreated());
        verify(service).criar(any(ProdutoDTO.class));
    }
}
