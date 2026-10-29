package com.juan.api_delivery.shared.exception;

import com.juan.api_delivery.auth.CredenciaisInvalidasException;
import com.juan.api_delivery.produto.ProdutoNaoEncontradoException;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        List<String> erros = ex.getBindingResult().getFieldErrors()
            .stream()
            .map(e -> e.getDefaultMessage())
            .collect(Collectors.toList());
        return ResponseEntity.badRequest().body(Map.of("erros", erros));
    }

    @ExceptionHandler(ProdutoNaoEncontradoException.class)
    public ResponseEntity<Map<String, String>> handleProdutoNaoEncontrado(ProdutoNaoEncontradoException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("erro", ex.getMessage()));
    }

    @ExceptionHandler(CredenciaisInvalidasException.class)
    public ResponseEntity<Map<String, String>> handleCredenciaisInvalidas(CredenciaisInvalidasException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("erro", ex.getMessage()));
    }

    @ExceptionHandler({RuntimeException.class, IllegalArgumentException.class})
    public ResponseEntity<Map<String, String>> handleRuntime(RuntimeException ex) {
        return ResponseEntity.badRequest().body(Map.of("erro", ex.getMessage()));
    }
}
