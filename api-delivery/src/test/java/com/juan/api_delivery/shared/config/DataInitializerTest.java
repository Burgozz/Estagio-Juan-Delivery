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
// Com o banco vazio, a aplicação precisa subir e criar o admin padrão com a
// senha "admin" (5 caracteres). O mínimo de 6 vale só para o UsuarioDTO, não
// para a entidade, justamente para permitir essa exceção.
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
        var admin = repository.findByEmailIgnoreCase("admin@juan.com").orElseThrow();
        assertThat(admin.getPerfil()).isEqualTo(PerfilUsuario.ADMIN);
        assertThat(admin.getSenha()).isEqualTo("admin");
    }
}
