package com.juan.api_delivery.pedido;

import com.juan.api_delivery.produto.Produto;
import com.juan.api_delivery.shared.IntegracaoBase;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.ResultActions;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Pedido de ponta a ponta: baixa e devolução de estoque, produto inativo e valor total. */
class PedidoEstoqueIntegracaoTest extends IntegracaoBase {

    private long usuarioId;

    @BeforeEach
    void usarAdminComoCliente() {
        usuarioId = usuarioRepository.findByEmailIgnoreCase("admin@juan.com").orElseThrow().getId();
    }

    // ------------------------------------------------------------ helpers
    private long criarVinho(int estoque) throws Exception {
        return id(postJson("/produtos", mapa("nome", "Malbec Reserva", "preco", 89.90, "tipo", "VINHO",
            "estoque", estoque, "categoria", "VINHO_TINTO", "paisOrigem", "Argentina", "safra", 2020,
            "teorAlcool", 13.5, "harmonizacao", "Carnes vermelhas")).andExpect(status().isCreated()));
    }

    private long criarAcessorio(int estoque) throws Exception {
        return id(postJson("/produtos", mapa("nome", "Saca-rolhas", "preco", 49.90, "tipo", "ACESSORIO",
            "estoque", estoque, "tipoAcessorio", "Saca-rolhas", "marca", "Tramontina", "material", "Inox")).andExpect(status().isCreated()));
    }

    private long criarPedido() throws Exception {
        return id(postJson("/pedidos", mapa("usuarioId", usuarioId)).andExpect(status().isCreated()));
    }

    private ResultActions adicionarItem(long pedidoId, long produtoId, int quantidade) throws Exception {
        return postJson("/pedidos/" + pedidoId + "/itens", mapa("produtoId", produtoId, "quantidade", quantidade));
    }

    private long comprar(long pedidoId, long produtoId, int quantidade) throws Exception {
        return id(adicionarItem(pedidoId, produtoId, quantidade).andExpect(status().isCreated()));
    }

    private ResultActions mudarStatus(long pedidoId, String status) throws Exception {
        return mockMvc.perform(patch("/pedidos/" + pedidoId + "/status").param("status", status));
    }

    private long id(ResultActions resultado) throws Exception {
        return corpoDe(resultado).get("id").asLong();
    }

    private Produto produto(long id) {
        return produtoRepository.findById(id).orElseThrow();
    }

    private BigDecimal valorTotal(long pedidoId) {
        return pedidoRepository.findById(pedidoId).orElseThrow().getValorTotal();
    }

    // -------------------------------------------------------------- compra
    @Nested
    class Compra {

        @Test
        void compraBaixaOEstoque() throws Exception {
            long vinho = criarVinho(10);
            comprar(criarPedido(), vinho, 3);
            assertThat(produto(vinho).getEstoque()).isEqualTo(7);
            assertThat(produto(vinho).isAtivo()).isTrue();
        }

        @Test
        void compraQueZeraOEstoqueInativaOProduto() throws Exception {
            long vinho = criarVinho(2);
            comprar(criarPedido(), vinho, 2);
            assertThat(produto(vinho).getEstoque()).isZero();
            assertThat(produto(vinho).isAtivo()).isFalse();
            mockMvc.perform(get("/produtos/" + vinho)).andExpect(status().isNotFound()); // saiu do catálogo
        }

        @Test
        void quantidadeMaiorQueOEstoqueERecusadaSemMexerEmNada() throws Exception {
            long vinho = criarVinho(2);
            long pedido = criarPedido();
            adicionarItem(pedido, vinho, 3).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value("Estoque insuficiente para Malbec Reserva. Disponível: 2"));
            assertThat(produto(vinho).getEstoque()).isEqualTo(2);
            assertThat(produto(vinho).isAtivo()).isTrue();
            assertThat(itemPedidoRepository.findByPedidoId(pedido)).isEmpty();
            assertThat(valorTotal(pedido)).isEqualByComparingTo("0");
        }

        @Test
        void produtoInativoERecusado() throws Exception {
            long vinho = criarVinho(1);
            comprar(criarPedido(), vinho, 1); // zera e inativa
            long outroPedido = criarPedido();
            adicionarItem(outroPedido, vinho, 1).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value("Produto indisponível"));
            assertThat(itemPedidoRepository.findByPedidoId(outroPedido)).isEmpty();
        }

        @Test
        void valorTotalComDoisItens() throws Exception {
            long vinho = criarVinho(10);
            long acessorio = criarAcessorio(10);
            long pedido = criarPedido();
            comprar(pedido, vinho, 2);      // 2 × 89,90 = 179,80
            long item = comprar(pedido, acessorio, 3); // 3 × 49,90 = 149,70
            assertThat(valorTotal(pedido)).isEqualByComparingTo("329.50");
            mockMvc.perform(get("/pedidos/" + pedido)).andExpect(jsonPath("$.valorTotal").value(329.5));

            mockMvc.perform(delete("/pedidos/" + pedido + "/itens/" + item)).andExpect(status().isNoContent());
            assertThat(valorTotal(pedido)).isEqualByComparingTo("179.80");
        }
    }

    // ---------------------------------------------------------- devolução
    @Nested
    class Devolucao {

        @Test
        void removerItemDevolveOEstoqueEReativaOProduto() throws Exception {
            long vinho = criarVinho(2);
            long pedido = criarPedido();
            long item = comprar(pedido, vinho, 2);
            assertThat(produto(vinho).isAtivo()).isFalse();

            mockMvc.perform(delete("/pedidos/" + pedido + "/itens/" + item)).andExpect(status().isNoContent());
            assertThat(produto(vinho).getEstoque()).isEqualTo(2);
            assertThat(produto(vinho).isAtivo()).isTrue();
            assertThat(valorTotal(pedido)).isEqualByComparingTo("0");
        }

        @Test
        void removerItemPorOutroPedidoERecusado() throws Exception {
            long vinho = criarVinho(5);
            long pedido = criarPedido();
            long item = comprar(pedido, vinho, 2);
            long outroPedido = criarPedido();

            mockMvc.perform(delete("/pedidos/" + outroPedido + "/itens/" + item))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value("Item de pedido não encontrado"));
            assertThat(itemPedidoRepository.findById(item)).isPresent();
            assertThat(produto(vinho).getEstoque()).isEqualTo(3);
        }

        @Test
        void cancelarPedidoDevolveOEstoqueUmaUnicaVez() throws Exception {
            long vinho = criarVinho(5);
            long acessorio = criarAcessorio(4);
            long pedido = criarPedido();
            comprar(pedido, vinho, 2);
            comprar(pedido, acessorio, 4); // zera e inativa o acessório

            mudarStatus(pedido, "CANCELADO").andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELADO"));
            assertThat(produto(vinho).getEstoque()).isEqualTo(5);
            assertThat(produto(acessorio).getEstoque()).isEqualTo(4);
            assertThat(produto(acessorio).isAtivo()).isTrue();

            mudarStatus(pedido, "CANCELADO").andExpect(status().isOk()); // de novo: não devolve outra vez
            assertThat(produto(vinho).getEstoque()).isEqualTo(5);
            assertThat(produto(acessorio).getEstoque()).isEqualTo(4);
        }

        @Test
        void outrasMudancasDeStatusNaoMexemNoEstoque() throws Exception {
            long vinho = criarVinho(5);
            long pedido = criarPedido();
            comprar(pedido, vinho, 2);
            mudarStatus(pedido, "CONFIRMADO").andExpect(status().isOk());
            mudarStatus(pedido, "ENTREGUE").andExpect(status().isOk());
            assertThat(produto(vinho).getEstoque()).isEqualTo(3);
        }

        @Test
        void excluirPedidoComItensNaoCanceladoERecusado() throws Exception {
            long vinho = criarVinho(5);
            long pedido = criarPedido();
            comprar(pedido, vinho, 2);
            mockMvc.perform(delete("/pedidos/" + pedido)).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value("Cancele o pedido antes de excluí-lo"));
            assertThat(pedidoRepository.findById(pedido)).isPresent();
            assertThat(itemPedidoRepository.findByPedidoId(pedido)).hasSize(1);
            assertThat(produto(vinho).getEstoque()).isEqualTo(3);
        }

        @Test
        void excluirPedidoCanceladoApagaItensSemDevolverEstoqueDeNovo() throws Exception {
            long vinho = criarVinho(5);
            long pedido = criarPedido();
            comprar(pedido, vinho, 2);
            mudarStatus(pedido, "CANCELADO").andExpect(status().isOk());
            assertThat(produto(vinho).getEstoque()).isEqualTo(5);

            mockMvc.perform(delete("/pedidos/" + pedido)).andExpect(status().isNoContent());
            assertThat(pedidoRepository.findById(pedido)).isEmpty();
            assertThat(itemPedidoRepository.findByPedidoId(pedido)).isEmpty();
            assertThat(produto(vinho).getEstoque()).isEqualTo(5);
        }

        @Test
        void excluirPedidoSemItensFunciona() throws Exception {
            long pedido = criarPedido();
            mockMvc.perform(delete("/pedidos/" + pedido)).andExpect(status().isNoContent());
            assertThat(pedidoRepository.findById(pedido)).isEmpty();
        }

        @Test
        void pedidoCanceladoNaoMudaDeStatusNemDeItens() throws Exception {
            long vinho = criarVinho(5);
            long pedido = criarPedido();
            long item = comprar(pedido, vinho, 2);
            mudarStatus(pedido, "CANCELADO").andExpect(status().isOk());

            String erro = "Pedido cancelado não pode ser alterado";
            mudarStatus(pedido, "PENDENTE").andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value(erro));
            adicionarItem(pedido, vinho, 1).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value(erro));
            mockMvc.perform(delete("/pedidos/" + pedido + "/itens/" + item)).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value(erro));
            assertThat(produto(vinho).getEstoque()).isEqualTo(5); // nada devolvido em dobro
        }
    }
}
