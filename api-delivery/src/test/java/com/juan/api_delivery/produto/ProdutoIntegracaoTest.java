package com.juan.api_delivery.produto;

import com.fasterxml.jackson.databind.JsonNode;
import com.juan.api_delivery.pedido.ItemPedido;
import com.juan.api_delivery.pedido.Pedido;
import com.juan.api_delivery.pedido.StatusPedido;
import com.juan.api_delivery.shared.IntegracaoBase;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** CRUD de Produto de ponta a ponta: HTTP → validação → serviço → banco. */
class ProdutoIntegracaoTest extends IntegracaoBase {

    private static Map<String, Object> vinho() {
        return mapa("nome", "Malbec Reserva", "preco", 89.90, "tipo", "VINHO", "estoque", 10,
            "categoria", "VINHO_TINTO", "paisOrigem", "Argentina", "safra", 2020,
            "teorAlcool", 13.5, "harmonizacao", "Carnes vermelhas e queijos curados");
    }

    private static Map<String, Object> acessorio() {
        return mapa("nome", "Saca-rolhas", "preco", 49.90, "tipo", "ACESSORIO", "estoque", 5,
            "tipoAcessorio", "Saca-rolhas", "marca", "Tramontina", "material", "Inox");
    }

    private long criar(Map<String, Object> corpo) throws Exception {
        return corpoDe(postJson("/produtos", corpo).andExpect(status().isCreated())).get("id").asLong();
    }

    private Produto doBanco(long id) {
        return produtoRepository.findById(id).orElseThrow();
    }

    // --------------------------------------------------------- Tipo / subtipo
    @Nested
    class CriacaoPorTipo {

        @Test
        void criarVinhoPersisteSubtipoVinho() throws Exception {
            long id = criar(vinho());
            assertThat(doBanco(id)).isInstanceOf(Vinho.class);
            mockMvc.perform(get("/produtos/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tipo").value("VINHO"))
                .andExpect(jsonPath("$.safra").value(2020))
                .andExpect(jsonPath("$.tipoAcessorio").doesNotExist());
        }

        @Test
        void criarAcessorioPersisteSubtipoAcessorio() throws Exception {
            long id = criar(acessorio());
            assertThat(doBanco(id)).isInstanceOf(Acessorio.class);
            mockMvc.perform(get("/produtos/" + id))
                .andExpect(jsonPath("$.tipo").value("ACESSORIO"))
                .andExpect(jsonPath("$.marca").value("Tramontina"))
                .andExpect(jsonPath("$.safra").doesNotExist());
        }

        @Test
        void tipoAusenteRetorna400() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.remove("tipo");
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("Informe o tipo do produto (VINHO ou ACESSORIO)")));
        }

        @Test
        void vinhoSemSafraRetorna400() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.remove("safra");
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("Safra é obrigatória para vinhos")));
            assertThat(produtoRepository.count()).isZero();
        }

        @Test
        void vinhoSemTeorAlcoolRetorna400() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("teorAlcool", null);
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("Teor alcoólico é obrigatório para vinhos")));
            assertThat(produtoRepository.count()).isZero();
        }

        @Test
        void acessorioSemSafraTeorEHarmonizacaoFunciona() throws Exception {
            long id = criar(acessorio());
            assertThat(doBanco(id).isAtivo()).isTrue();
        }

        @Test
        void vinhoSemCategoriaRetorna400() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.remove("categoria");
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value("Categoria é obrigatória para produtos do tipo Vinho"));
        }
    }

    // ------------------------------------------------------ Safra / teor
    @Nested
    class Limites {

        @ParameterizedTest
        @ValueSource(ints = {1900, 2000, 2025})
        void safraDentroDoLimitePassa(int safra) throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("safra", safra);
            criar(corpo);
        }

        // BUG ENCONTRADO: o CLAUDE.md e a entidade Vinho (@Min(1800)) aceitam
        // safras a partir de 1800, mas ProdutoDTO tem @Min(1900).
        @Test
        void safra1800Passa() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("safra", 1800);
            criar(corpo);
        }

        @Test
        void safraAbaixoDoMinimoRetorna400() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("safra", 1799);
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros").isArray());
        }

        // BUG ENCONTRADO: ProdutoDTO aceita safra 2026 (@Max(2026)), mas a entidade
        // Vinho tem @Max(2025). O pedido passa no @Valid e explode na gravação, com
        // {"erro": "<texto técnico>"} em vez de {"erros": [...]}.
        @Test
        void safraAcimaDoMaximoRetorna400NoFormatoErros() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("safra", 2026);
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros").isArray());
        }

        // BUG ENCONTRADO: limites de safra divergentes entre a entidade e o DTO
        // (Vinho: 1800–2025; ProdutoDTO: 1900–2026).
        @Test
        void limitesDeSafraSaoIguaisNaEntidadeENoDto() throws Exception {
            var safraVinho = Vinho.class.getDeclaredField("safra");
            var safraDto = ProdutoDTO.class.getDeclaredField("safra");
            assertThat(safraDto.getAnnotation(Max.class).value())
                .as("@Max de safra: ProdutoDTO x Vinho")
                .isEqualTo(safraVinho.getAnnotation(Max.class).value());
            assertThat(safraDto.getAnnotation(Min.class).value())
                .as("@Min de safra: ProdutoDTO x Vinho")
                .isEqualTo(safraVinho.getAnnotation(Min.class).value());
        }

        @ParameterizedTest
        @ValueSource(doubles = {0.0, 13.5, 100.0})
        void teorAlcoolDentroDoLimitePassa(double teor) throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("teorAlcool", teor);
            criar(corpo);
        }

        // BUG ENCONTRADO: ProdutoDTO.teorAlcool não tem @DecimalMin/@DecimalMax. A
        // regra 0–100 só existe na entidade Vinho, e o erro chega fora do padrão.
        @ParameterizedTest
        @ValueSource(doubles = {-0.1, 100.1})
        void teorAlcoolForaDoLimiteRetorna400NoFormatoErros(double teor) throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("teorAlcool", teor);
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros").isArray());
            assertThat(produtoRepository.count()).isZero();
        }
    }

    // ------------------------------------------------------- Harmonização
    @Nested
    class Harmonizacao {

        @ParameterizedTest
        @ValueSource(strings = {
            "Carnes vermelhas e queijos curados",
            "Frutos do mar, peixes grelhados.",
            "Massas / risotos"
        })
        void harmonizacaoValidaEPersistida(String harmonizacao) throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("harmonizacao", harmonizacao);
            long id = criar(corpo);
            assertThat(((Vinho) doBanco(id)).getHarmonizacao()).isEqualTo(harmonizacao);
        }

        @ParameterizedTest
        @ValueSource(strings = {"Queijos 12 meses", "carne@grelhada", "ab"})
        void harmonizacaoInvalidaRetorna400(String harmonizacao) throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("harmonizacao", harmonizacao);
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem(containsString("Harmonização deve"))));
            assertThat(produtoRepository.count()).isZero();
        }

        // BUG ENCONTRADO: o @Pattern de ProdutoDTO.harmonizacao aceita texto só com
        // pontuação (", , ." tem 5 caracteres permitidos). O Flutter exige ao menos
        // 3 letras, o backend não.
        @Test
        void harmonizacaoSoComPontuacaoRetorna400() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("harmonizacao", ", , .");
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem(containsString("Harmonização deve"))));
            assertThat(produtoRepository.count()).isZero();
        }

        // BUG ENCONTRADO: ProdutoDTO não exige harmonização para vinho; quem barra é o
        // @NotBlank da entidade, com erro fora do padrão {"erros": [...]}.
        @Test
        void vinhoSemHarmonizacaoRetorna400NoFormatoErros() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.remove("harmonizacao");
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros").isArray());
        }

        @Test
        void acessorioSemHarmonizacaoFunciona() throws Exception {
            Map<String, Object> corpo = acessorio();
            corpo.put("harmonizacao", null);
            criar(corpo);
        }
    }

    // ------------------------------------------------------------ Estoque
    @Nested
    class Estoque {

        @Test
        void estoqueZeroBloqueadoNaCriacao() throws Exception {
            Map<String, Object> corpo = vinho();
            corpo.put("estoque", 0);
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value("Estoque inicial deve ser maior que zero para criar um produto"));
            assertThat(produtoRepository.count()).isZero();
        }

        @Test
        void estoqueNegativoBloqueado() throws Exception {
            Map<String, Object> corpo = acessorio();
            corpo.put("estoque", -1);
            postJson("/produtos", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("Estoque não pode ser negativo")));
        }

        @Test
        void estoqueZeroPermitidoNaEdicaoEDesativa() throws Exception {
            long id = criar(vinho());
            Map<String, Object> corpo = vinho();
            corpo.put("estoque", 0);
            putJson("/produtos/" + id, corpo).andExpect(status().isOk());
            assertThat(doBanco(id).isAtivo()).isFalse();
            assertThat(doBanco(id).getEstoque()).isZero();
        }

        @Test
        void estoqueMaiorQueZeroReativa() throws Exception {
            long id = criar(acessorio());
            Map<String, Object> corpo = acessorio();
            corpo.put("estoque", 0);
            putJson("/produtos/" + id, corpo).andExpect(status().isOk());
            assertThat(doBanco(id).isAtivo()).isFalse();

            corpo.put("estoque", 3);
            putJson("/produtos/" + id, corpo).andExpect(status().isOk());
            assertThat(doBanco(id).isAtivo()).isTrue();
            mockMvc.perform(get("/produtos/" + id)).andExpect(status().isOk());
        }
    }

    // ------------------------------------------------- Exclusão e listagens
    @Nested
    class ExclusaoEListagem {

        @Test
        void deletarProdutoSemPedidosRemoveDoBanco() throws Exception {
            long id = criar(vinho());
            mockMvc.perform(delete("/produtos/" + id)).andExpect(status().isNoContent());

            assertThat(produtoRepository.findById(id)).isEmpty();
            mockMvc.perform(get("/produtos/" + id)).andExpect(status().isNotFound());
        }

        @Test
        void deletarProdutoInativoSemPedidosRemoveDoBanco() throws Exception {
            long id = criar(acessorio());
            Map<String, Object> semEstoque = acessorio();
            semEstoque.put("estoque", 0);
            putJson("/produtos/" + id, semEstoque).andExpect(status().isOk());

            mockMvc.perform(delete("/produtos/" + id)).andExpect(status().isNoContent());
            assertThat(produtoRepository.findById(id)).isEmpty();
        }

        @Test
        void deletarProdutoComPedidosRetorna400EMantemNoBanco() throws Exception {
            long id = criar(vinho());
            Pedido pedido = pedidoRepository.save(Pedido.builder()
                .usuario(usuarioRepository.findByEmail("admin@juan.com").orElseThrow())
                .status(StatusPedido.ENTREGUE)
                .dataPedido(LocalDateTime.now())
                .valorTotal(new BigDecimal("89.90"))
                .build());
            itemPedidoRepository.save(ItemPedido.builder()
                .pedido(pedido)
                .produto(doBanco(id))
                .quantidade(1)
                .precoUnit(new BigDecimal("89.90"))
                .build());

            mockMvc.perform(delete("/produtos/" + id))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value(
                    "Este produto já possui pedidos e não pode ser excluído. Para removê-lo do catálogo, zere o estoque."));

            assertThat(produtoRepository.findById(id)).isPresent();
            assertThat(doBanco(id).isAtivo()).isTrue();
        }

        @Test
        void deletarProdutoInexistenteRetorna400() throws Exception {
            mockMvc.perform(delete("/produtos/999999"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value("Produto não encontrado"));
        }

        @Test
        void listagensPublicasRetornamSoAtivosEAdminRetornaTodos() throws Exception {
            long tintoAtivo = criar(vinho());
            Map<String, Object> branco = vinho();
            branco.put("nome", "Chardonnay");
            branco.put("categoria", "VINHO_BRANCO");
            long brancoAtivo = criar(branco);
            Map<String, Object> outroTinto = vinho();
            outroTinto.put("nome", "Tinto Excluído");
            long tintoInativo = criar(outroTinto);
            long acessorioInativo = criar(acessorio());
            Map<String, Object> tintoSemEstoque = vinho();
            tintoSemEstoque.put("nome", "Tinto Excluído");
            tintoSemEstoque.put("estoque", 0);
            putJson("/produtos/" + tintoInativo, tintoSemEstoque).andExpect(status().isOk());
            Map<String, Object> semEstoque = acessorio();
            semEstoque.put("estoque", 0);
            putJson("/produtos/" + acessorioInativo, semEstoque).andExpect(status().isOk());

            JsonNode publicos = corpoDe(mockMvc.perform(get("/produtos")).andExpect(status().isOk()));
            assertThat(publicos.findValues("id").stream().map(JsonNode::asLong))
                .containsExactlyInAnyOrder(tintoAtivo, brancoAtivo);

            JsonNode tintos = corpoDe(mockMvc.perform(get("/produtos").param("categoria", "VINHO_TINTO")));
            assertThat(tintos.findValues("id").stream().map(JsonNode::asLong))
                .containsExactly(tintoAtivo);

            JsonNode tintosMinusculo = corpoDe(mockMvc.perform(get("/produtos").param("categoria", "vinho_tinto")));
            assertThat(tintosMinusculo.findValues("id").stream().map(JsonNode::asLong))
                .containsExactly(tintoAtivo);

            JsonNode admin = corpoDe(mockMvc.perform(get("/produtos/admin")).andExpect(status().isOk()));
            assertThat(admin.findValues("id").stream().map(JsonNode::asLong))
                .containsExactlyInAnyOrder(tintoAtivo, brancoAtivo, tintoInativo, acessorioInativo);
            admin.forEach(p -> {
                long id = p.get("id").asLong();
                boolean deveriaEstarAtivo = id == tintoAtivo || id == brancoAtivo;
                assertThat(p.get("ativo").asBoolean()).as("ativo do produto %d", id).isEqualTo(deveriaEstarAtivo);
            });
        }

        @ParameterizedTest
        @ValueSource(strings = {"VINHO_AZUL", "xyz", "123"})
        void categoriaInvalidaRetornaListaVaziaSemErro(String categoria) throws Exception {
            criar(vinho());
            mockMvc.perform(get("/produtos").param("categoria", categoria))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
        }

        @Test
        void categoriaVaziaRetornaTodosOsAtivos() throws Exception {
            criar(vinho());
            criar(acessorio());
            JsonNode lista = corpoDe(mockMvc.perform(get("/produtos").param("categoria", "")));
            assertThat(lista.size()).isEqualTo(2);
        }
    }
}
