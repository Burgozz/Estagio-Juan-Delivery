package com.juan.api_delivery.shared.config;

import com.juan.api_delivery.usuario.PerfilUsuario;
import com.juan.api_delivery.usuario.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Sobe a aplicação com o banco VAZIO (sem o admin-teste.sql), como acontece
 * na primeira execução em uma máquina nova.
 */
// BUG ENCONTRADO: DataInitializer.java:34 cria o admin com senha "admin"
// (5 caracteres), mas Usuario.senha tem @Size(min = 6). Com o banco vazio o
// save lança ConstraintViolationException e a aplicação NÃO sobe.
@SpringBootTest(properties = {
    "spring.sql.init.mode=never",
    "spring.datasource.url=jdbc:h2:mem:banco_vazio;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1"
})
@ActiveProfiles("test")
class DataInitializerTest {

    @Autowired
    private UsuarioRepository repository;

    @Test
    void aplicacaoSobeComBancoVazioECriaOAdmin() {
        var admin = repository.findByEmail("admin@juan.com").orElseThrow();
        assertThat(admin.getPerfil()).isEqualTo(PerfilUsuario.ADMIN);
        assertThat(admin.getSenha()).isEqualTo("admin");
    }
}
