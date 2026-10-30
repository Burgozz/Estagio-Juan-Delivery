package com.juan.api_delivery.pedido;

import com.juan.api_delivery.produto.ProdutoRepository;
import com.juan.api_delivery.usuario.Usuario;
import com.juan.api_delivery.usuario.UsuarioRepository;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

import static com.juan.api_delivery.shared.exception.MensagensErro.CANCELE_ANTES_DE_EXCLUIR;
import static com.juan.api_delivery.shared.exception.MensagensErro.PEDIDO_CANCELADO_NAO_ALTERA;
import static com.juan.api_delivery.shared.exception.MensagensErro.PEDIDO_NAO_ENCONTRADO;
import static com.juan.api_delivery.shared.exception.MensagensErro.USUARIO_NAO_ENCONTRADO;

@Service
@RequiredArgsConstructor
public class PedidoService {

    private final PedidoRepository repository;
    private final UsuarioRepository usuarioRepository;
    private final ItemPedidoRepository itemPedidoRepository;
    private final ProdutoRepository produtoRepository;

    public List<Pedido> listarTodos() {
        return repository.findAll();
    }

    public List<Pedido> listarPorUsuario(Long usuarioId) {
        return repository.findByUsuarioId(usuarioId);
    }

    public Pedido buscarPorId(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException(PEDIDO_NAO_ENCONTRADO));
    }

    public Pedido criar(PedidoDTO dto) {
        Usuario usuario = usuarioRepository.findById(dto.getUsuarioId())
            .orElseThrow(() -> new IllegalArgumentException(USUARIO_NAO_ENCONTRADO));
        Pedido pedido = Pedido.builder()
            .usuario(usuario)
            .status(StatusPedido.PENDENTE)
            .dataPedido(LocalDateTime.now())
            .valorTotal(BigDecimal.ZERO)
            .build();
        return repository.save(pedido);
    }

    /**
     * Ao cancelar, devolve ao estoque a quantidade de todos os itens
     * (reativando os produtos que voltarem a ter estoque). Cancelar de novo
     * não devolve outra vez, e um pedido cancelado não volta a outro status,
     * porque o estoque dele já foi devolvido.
     */
    @Transactional
    public Pedido atualizarStatus(Long id, StatusPedido status) {
        Pedido pedido = buscarPorId(id);
        if (pedido.getStatus() == StatusPedido.CANCELADO) {
            if (status == StatusPedido.CANCELADO) {
                return pedido;
            }
            throw new IllegalArgumentException(PEDIDO_CANCELADO_NAO_ALTERA);
        }
        if (status == StatusPedido.CANCELADO) {
            for (ItemPedido item : itemPedidoRepository.findByPedidoId(id)) {
                produtoRepository.findByIdParaAtualizarEstoque(item.getProduto().getId())
                    .ifPresent(produto -> produto.devolverEstoque(item.getQuantidade()));
            }
        }
        pedido.setStatus(status);
        return repository.save(pedido);
    }

    /**
     * Exclui o pedido e seus itens. Um pedido com itens que não foi cancelado
     * ainda está com o estoque baixado, então precisa ser cancelado antes
     * (o cancelamento devolve o estoque). Aqui o estoque não é mexido.
     */
    @Transactional
    public void deletar(Long id) {
        Pedido pedido = buscarPorId(id);
        List<ItemPedido> itens = itemPedidoRepository.findByPedidoId(id);
        if (!itens.isEmpty() && pedido.getStatus() != StatusPedido.CANCELADO) {
            throw new IllegalArgumentException(CANCELE_ANTES_DE_EXCLUIR);
        }
        itemPedidoRepository.deleteAll(itens);
        repository.delete(pedido);
    }
}
