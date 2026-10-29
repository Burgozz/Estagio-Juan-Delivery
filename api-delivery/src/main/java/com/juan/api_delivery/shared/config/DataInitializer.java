package com.juan.api_delivery.shared.config;

import com.juan.api_delivery.usuario.PerfilUsuario;
import com.juan.api_delivery.usuario.Usuario;
import com.juan.api_delivery.usuario.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

/**
 * Garante, ao subir o backend, a existência de um usuário administrador
 * padrão (admin@juan.com) para uso do painel de gerenciamento.
 */
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private static final String EMAIL_ADMIN = "admin@juan.com";

    private final UsuarioRepository repository;

    @Override
    public void run(String... args) {
        if (repository.findByEmail(EMAIL_ADMIN).isPresent()) {
            return;
        }
        Usuario admin = Usuario.builder()
            .nome("Admin")
            .email(EMAIL_ADMIN)
            .senha("admin")
            .cpf("00000000000")
            .telefone("00000000000")
            .perfil(PerfilUsuario.ADMIN)
            .ativo(true)
            .dataCadastro(LocalDate.now())
            .build();
        repository.save(admin);
    }
}
