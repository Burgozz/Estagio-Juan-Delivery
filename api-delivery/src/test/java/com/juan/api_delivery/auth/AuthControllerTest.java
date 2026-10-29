package com.juan.api_delivery.auth;

import com.juan.api_delivery.shared.validation.EmailDomainValidatorTestSupport;
import com.juan.api_delivery.usuario.PerfilUsuario;
import com.juan.api_delivery.usuario.Usuario;
import com.juan.api_delivery.usuario.UsuarioService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UsuarioService service;

    @AfterEach
    void restaurarDnsReal() {
        EmailDomainValidatorTestSupport.setConsultaDns(null);
    }

    @Test
    void loginDoAdminFuncionaSemConsultarDns() throws Exception {
        AtomicInteger consultas = new AtomicInteger();
        EmailDomainValidatorTestSupport.setConsultaDns((dominio, tipo) -> {
            consultas.incrementAndGet();
            return false;
        });

        Usuario admin = Usuario.builder()
            .id(1L)
            .nome("Admin")
            .email("admin@juan.com")
            .senha("admin")
            .perfil(PerfilUsuario.ADMIN)
            .build();
        when(service.login("admin@juan.com", "admin")).thenReturn(admin);

        mockMvc.perform(post("/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\": \"admin@juan.com\", \"senha\": \"admin\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.email").value("admin@juan.com"))
            .andExpect(jsonPath("$.perfil").value("ADMIN"));

        assertEquals(0, consultas.get());
    }
}
