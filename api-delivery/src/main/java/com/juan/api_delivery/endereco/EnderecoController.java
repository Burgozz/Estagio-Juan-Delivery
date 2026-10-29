package com.juan.api_delivery.endereco;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
public class EnderecoController {

    private final EnderecoService service;

    @GetMapping("/usuarios/{usuarioId}/enderecos")
    public ResponseEntity<List<EnderecoRespostaDTO>> listarPorUsuario(@PathVariable Long usuarioId) {
        List<Endereco> enderecos = service.listarPorUsuario(usuarioId);
        return ResponseEntity.ok(enderecos.stream().map(EnderecoRespostaDTO::from).toList());
    }

    @PostMapping("/usuarios/{usuarioId}/enderecos")
    public ResponseEntity<EnderecoRespostaDTO> criar(@PathVariable Long usuarioId, @RequestBody @Valid EnderecoDTO dto) {
        Endereco endereco = service.criar(usuarioId, dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(EnderecoRespostaDTO.from(endereco));
    }

    @DeleteMapping("/enderecos/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Long id) {
        service.deletar(id);
        return ResponseEntity.noContent().build();
    }
}
