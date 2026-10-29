package com.juan.api_delivery.auth;

import com.juan.api_delivery.usuario.Usuario;
import com.juan.api_delivery.usuario.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UsuarioService service;

    @PostMapping("/login")
    public ResponseEntity<LoginRespostaDTO> login(@RequestBody @Valid LoginDTO dto) {
        Usuario usuario = service.login(dto.getEmail(), dto.getSenha());
        return ResponseEntity.ok(LoginRespostaDTO.from(usuario));
    }
}
