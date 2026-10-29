package com.juan.api_delivery.usuario;

import com.juan.api_delivery.shared.validation.EmailDomainValidatorTestSupport;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import javax.naming.NameNotFoundException;

import static org.hamcrest.Matchers.hasItem;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(UsuarioController.class)
class UsuarioControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UsuarioService service;

    private static String corpo(String email, String cpf) {
        return """
            {"nome": "Maria Silva", "cpf": "%s", "email": "%s",
             "senha": "123456", "telefone": "11987654321"}
            """.formatted(cpf, email);
    }

    @Test
    void cpfInvalidoRetorna400ComMensagem() throws Exception {
        mockMvc.perform(post("/usuarios")
                .contentType(MediaType.APPLICATION_JSON)
                .content(corpo("maria@teste.com", "11144477736")))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.erros", hasItem("CPF inválido")));
    }

    @Test
    void dominioDeEmailInexistenteRetorna400ComMensagem() throws Exception {
        EmailDomainValidatorTestSupport.setConsultaDns((dominio, tipo) -> {
            throw new NameNotFoundException("NXDOMAIN");
        });
        try {
            mockMvc.perform(post("/usuarios")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(corpo("maria@dominioquenaoexiste123456.com", "11144477735")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("Domínio de e-mail inválido ou inexistente")));
        } finally {
            EmailDomainValidatorTestSupport.setConsultaDns(null);
        }
    }

    @Test
    void doisCadastrosComCpfCoringaFuncionam() throws Exception {
        when(service.criar(any(UsuarioDTO.class))).thenReturn(new Usuario());

        mockMvc.perform(post("/usuarios")
                .contentType(MediaType.APPLICATION_JSON)
                .content(corpo("um@teste.com", "00000000000")))
            .andExpect(status().isCreated());
        mockMvc.perform(post("/usuarios")
                .contentType(MediaType.APPLICATION_JSON)
                .content(corpo("dois@teste.com", "00000000000")))
            .andExpect(status().isCreated());

        verify(service, times(2)).criar(any(UsuarioDTO.class));
    }
}
