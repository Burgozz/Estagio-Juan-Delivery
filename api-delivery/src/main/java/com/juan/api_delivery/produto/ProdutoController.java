package com.juan.api_delivery.produto;

import java.util.List;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/produtos")
@RequiredArgsConstructor
public class ProdutoController {

    private final ProdutoService service;

    @GetMapping
    public ResponseEntity<List<ProdutoRespostaDTO>> listar(
            @RequestParam(required = false) String categoria) {
        List<Produto> produtos = (categoria == null || categoria.isBlank())
            ? service.listarAtivos()
            : service.listarPorCategoria(categoria);
        return ResponseEntity.ok(produtos.stream().map(ProdutoRespostaDTO::from).toList());
    }

    /**
     * Usado pela tela de administração: retorna todos os produtos,
     * incluindo os inativos.
     */
    @GetMapping("/admin")
    public ResponseEntity<List<ProdutoRespostaDTO>> listarTodosAdmin() {
        List<Produto> produtos = service.listarTodos();
        return ResponseEntity.ok(produtos.stream().map(ProdutoRespostaDTO::from).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProdutoRespostaDTO> buscarPorId(@PathVariable Long id) {
        Produto produto = service.buscarAtivoPorId(id);
        return ResponseEntity.ok(ProdutoRespostaDTO.from(produto));
    }

    @PostMapping
    public ResponseEntity<Produto> criar(@RequestBody @Valid ProdutoDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.criar(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Produto> atualizar(@PathVariable Long id, @RequestBody @Valid ProdutoDTO dto) {
        return ResponseEntity.ok(service.atualizar(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Long id) {
        service.deletar(id);
        return ResponseEntity.noContent().build();
    }
}
