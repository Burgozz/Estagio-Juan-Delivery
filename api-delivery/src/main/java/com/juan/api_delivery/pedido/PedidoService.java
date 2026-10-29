package com.juan.api_delivery.pedido;

import com.juan.api_delivery.usuario.Usuario;
import com.juan.api_delivery.usuario.UsuarioRepository;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PedidoService {

    private final PedidoRepository repository;
    private final UsuarioRepository usuarioRepository;

    public List<Pedido> listarTodos() {
        return repository.findAll();
    }

    public List<Pedido> listarPorUsuario(Long usuarioId) {
        return repository.findByUsuarioId(usuarioId);
    }

    public Pedido buscarPorId(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Pedido não encontrado"));
    }

    public Pedido criar(PedidoDTO dto) {
        Usuario usuario = usuarioRepository.findById(dto.getUsuarioId())
            .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));
        Pedido pedido = Pedido.builder()
            .usuario(usuario)
            .status(StatusPedido.PENDENTE)
            .dataPedido(LocalDateTime.now())
            .valorTotal(BigDecimal.ZERO)
            .build();
        return repository.save(pedido);
    }

    public Pedido atualizarStatus(Long id, StatusPedido status) {
        Pedido pedido = buscarPorId(id);
        pedido.setStatus(status);
        return repository.save(pedido);
    }

    public void deletar(Long id) {
        Pedido pedido = buscarPorId(id);
        repository.delete(pedido);
    }
}
