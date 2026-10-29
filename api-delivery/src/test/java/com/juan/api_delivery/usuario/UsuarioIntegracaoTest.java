package com.juan.api_delivery.usuario;

import com.fasterxml.jackson.databind.JsonNode;
import com.juan.api_delivery.shared.IntegracaoBase;
import com.juan.api_delivery.shared.validation.EmailDomainValidatorTestSupport;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.http.MediaType;

import java.net.SocketTimeoutException;
import java.time.LocalDate;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import javax.naming.CommunicationException;
import javax.naming.NameNotFoundException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.isA;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** CRUD de Usuário de ponta a ponta: HTTP → validação → serviço → banco. */
class UsuarioIntegracaoTest extends IntegracaoBase {

    private static Map<String, Object> usuario(String email, String cpf) {
        return mapa("nome", "Maria Silva", "cpf", cpf, "email", email,
            "senha", "123456", "telefone", "43999998888");
    }

    private Usuario salvarDireto(String email, boolean ativo) {
        return usuarioRepository.save(Usuario.builder()
            .nome("Direto").email(email).senha("123456").cpf("11144477735")
            .telefone("4333334444").dataCadastro(LocalDate.now())
            .perfil(PerfilUsuario.CLIENTE).ativo(ativo).build());
    }

    // ------------------------------------------------------------------ CPF
    @Nested
    class Cpf {

        @ParameterizedTest
        @ValueSource(strings = {"11144477735", "52998224725"})
        void cpfValidoPassa(String cpf) throws Exception {
            postJson("/usuarios", usuario("cpf" + cpf + "@teste.com", cpf))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.cpf").value(cpf));
        }

        @Test
        void cpfComMascaraPassaEFicaSalvoSoComDigitos() throws Exception {
            postJson("/usuarios", usuario("mascara@teste.com", "111.444.777-35"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.cpf").value("11144477735"));
            assertThat(usuarioRepository.findByEmail("mascara@teste.com").orElseThrow().getCpf())
                .isEqualTo("11144477735");
        }

        @Test
        void cpfCoringaPodeSerUsadoEmVariasContas() throws Exception {
            postJson("/usuarios", usuario("coringa1@teste.com", "00000000000")).andExpect(status().isCreated());
            postJson("/usuarios", usuario("coringa2@teste.com", "00000000000")).andExpect(status().isCreated());
            postJson("/usuarios", usuario("coringa3@juan.com", "000.000.000-00")).andExpect(status().isCreated());

            long comCoringa = usuarioRepository.findAll().stream()
                .filter(u -> "00000000000".equals(u.getCpf()) && u.getEmail().startsWith("coringa"))
                .count();
            assertThat(comCoringa).isEqualTo(3);
        }

        @ParameterizedTest
        @ValueSource(strings = {"11111111111", "11144477736", "1114447773", "111444777", "abcdefghijk"})
        void cpfInvalidoRetorna400(String cpf) throws Exception {
            postJson("/usuarios", usuario("invalido@teste.com", cpf))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("CPF inválido")));
            assertThat(usuarioRepository.findByEmail("invalido@teste.com")).isEmpty();
        }

        // BUG ENCONTRADO: CpfValidator.somenteDigitos remove QUALQUER caractere que
        // não seja dígito (não só a máscara), então letras no meio de um CPF válido
        // são descartadas e o cadastro é aceito.
        @ParameterizedTest
        @ValueSource(strings = {"111a444b777c35", "CPF11144477735"})
        void cpfComLetrasMisturadasRetorna400(String cpf) throws Exception {
            postJson("/usuarios", usuario("letras@teste.com", cpf))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("CPF inválido")));
        }
    }

    // --------------------------------------------------------------- E-mail
    @Nested
    class Email {

        /** Consulta DNS real (sem simulação). Sem internet o e-mail também é aceito. */
        @Test
        void dominioRealPassa() throws Exception {
            EmailDomainValidatorTestSupport.setConsultaDns(null);
            postJson("/usuarios", usuario("alguem.teste.juan@gmail.com", "11144477735"))
                .andExpect(status().isCreated());
        }

        @Test
        void dominioInexistenteRetorna400ComMensagemDeEmail() throws Exception {
            EmailDomainValidatorTestSupport.setConsultaDns((d, t) -> {
                throw new NameNotFoundException("NXDOMAIN");
            });
            postJson("/usuarios", usuario("maria@dominioquenaoexiste123456.com", "11144477735"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem(containsString("e-mail"))));
            assertThat(usuarioRepository.findByEmail("maria@dominioquenaoexiste123456.com")).isEmpty();
        }

        @ParameterizedTest
        @ValueSource(strings = {"dev@juan.com", "dev@teste.com", "DEV2@TESTE.COM"})
        void dominiosLiberadosSemprepassamSemConsultarDns(String email) throws Exception {
            AtomicInteger consultas = new AtomicInteger();
            EmailDomainValidatorTestSupport.setConsultaDns((d, t) -> {
                consultas.incrementAndGet();
                return false; // se consultasse, reprovaria
            });
            postJson("/usuarios", usuario(email, "11144477735")).andExpect(status().isCreated());
            assertThat(consultas.get()).isZero();
        }

        @Test
        void falhaDeRedeNoDnsAceitaOEmail() throws Exception {
            EmailDomainValidatorTestSupport.setConsultaDns((d, t) -> {
                throw new javax.naming.ServiceUnavailableException("sem rede");
            });
            postJson("/usuarios", usuario("rede@empresa-x.com.br", "11144477735"))
                .andExpect(status().isCreated());
        }

        @Test
        void timeoutNoDnsAceitaOEmail() throws Exception {
            EmailDomainValidatorTestSupport.setConsultaDns((d, t) -> {
                CommunicationException e = new CommunicationException("DNS error");
                e.setRootCause(new SocketTimeoutException("timeout"));
                throw e;
            });
            postJson("/usuarios", usuario("timeout@empresa-y.com.br", "11144477735"))
                .andExpect(status().isCreated());
        }

        @Test
        void emailDuplicadoContinuaBloqueado() throws Exception {
            postJson("/usuarios", usuario("dup@teste.com", "11144477735")).andExpect(status().isCreated());
            postJson("/usuarios", usuario("dup@teste.com", "52998224725"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value("Email já cadastrado"));
            assertThat(usuarioRepository.findAll().stream()
                .filter(u -> "dup@teste.com".equals(u.getEmail())).count()).isEqualTo(1);
        }

        // BUG ENCONTRADO: a verificação de e-mail duplicado (findByEmail) diferencia
        // maiúsculas de minúsculas, então "Dup@Teste.com" vira uma segunda conta
        // para a mesma caixa de e-mail.
        @Test
        void emailDuplicadoComMaiusculasDiferentesTambemEBloqueado() throws Exception {
            postJson("/usuarios", usuario("caixa@teste.com", "11144477735")).andExpect(status().isCreated());
            postJson("/usuarios", usuario("Caixa@Teste.com", "52998224725"))
                .andExpect(status().isBadRequest());
        }

        @Test
        void emailDuplicadoNaEdicaoTambemEBloqueado() throws Exception {
            postJson("/usuarios", usuario("primeiro@teste.com", "11144477735")).andExpect(status().isCreated());
            JsonNode segundo = corpoDe(postJson("/usuarios", usuario("segundo@teste.com", "52998224725")));
            putJson("/usuarios/" + segundo.get("id").asLong(), usuario("primeiro@teste.com", "52998224725"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").value("Email já cadastrado"));
        }

        // BUG ENCONTRADO: UsuarioDTO.email não tem @NotBlank, então é possível
        // criar usuário sem e-mail (e ele nunca conseguirá fazer login).
        @Test
        void emailAusenteRetorna400() throws Exception {
            Map<String, Object> corpo = usuario(null, "11144477735");
            postJson("/usuarios", corpo)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros").isArray());
        }

        @Test
        void loginNaoConsultaDns() throws Exception {
            salvarDireto("login@empresa-z.com.br", true);
            AtomicInteger consultas = new AtomicInteger();
            EmailDomainValidatorTestSupport.setConsultaDns((d, t) -> {
                consultas.incrementAndGet();
                throw new NameNotFoundException("NXDOMAIN");
            });
            postJson("/auth/login", Map.of("email", "login@empresa-z.com.br", "senha", "123456"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("login@empresa-z.com.br"));
            assertThat(consultas.get()).isZero();
        }
    }

    // ------------------------------------------------------- Demais campos
    @Nested
    class DemaisCampos {

        @ParameterizedTest
        @ValueSource(strings = {"4333334444", "43999998888"})
        void telefoneCom10Ou11DigitosPassa(String telefone) throws Exception {
            Map<String, Object> corpo = usuario("tel" + telefone + "@teste.com", "11144477735");
            corpo.put("telefone", telefone);
            postJson("/usuarios", corpo)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.telefone").value(telefone));
        }

        /**
         * Comportamento documentado (não é bug): o backend NÃO remove a máscara
         * do telefone (diferente do CPF) e rejeita o valor formatado. O app
         * Flutter envia só dígitos, então isso não aparece pelo app.
         */
        @ParameterizedTest
        @ValueSource(strings = {"(43) 99999-8888", "(43) 3333-4444", "43 99999-8888"})
        void telefoneComMascaraERejeitadoPeloBackend(String telefone) throws Exception {
            Map<String, Object> corpo = usuario("mascaratel@teste.com", "11144477735");
            corpo.put("telefone", telefone);
            postJson("/usuarios", corpo)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem(containsString("Telefone inválido"))));
        }

        @ParameterizedTest
        @ValueSource(strings = {"433333444", "439999988887", "0433333444"})
        void telefoneComQuantidadeOuDddInvalidoRetorna400(String telefone) throws Exception {
            Map<String, Object> corpo = usuario("telinv@teste.com", "11144477735");
            corpo.put("telefone", telefone);
            postJson("/usuarios", corpo).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem(containsString("Telefone inválido"))));
        }

        @ParameterizedTest
        @ValueSource(ints = {2, 100})
        void nomeNoLimitePassa(int tamanho) throws Exception {
            Map<String, Object> corpo = usuario("nome" + tamanho + "@teste.com", "11144477735");
            corpo.put("nome", "a".repeat(tamanho));
            postJson("/usuarios", corpo).andExpect(status().isCreated());
        }

        // BUG ENCONTRADO: UsuarioDTO.nome não tem @Size(min = 2, max = 100). A regra
        // só existe na entidade Usuario, então o erro sai como {"erro": "<texto técnico
        // do Hibernate Validator>"} em vez de {"erros": ["Nome deve ter entre 2 e 100
        // caracteres"]}.
        @ParameterizedTest
        @ValueSource(ints = {1, 101})
        void nomeForaDoLimiteRetorna400NoFormatoErros(int tamanho) throws Exception {
            Map<String, Object> corpo = usuario("nomeinv@teste.com", "11144477735");
            corpo.put("nome", "a".repeat(tamanho));
            postJson("/usuarios", corpo)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("Nome deve ter entre 2 e 100 caracteres")));
        }

        @Test
        void senhaCom6CaracteresPassa() throws Exception {
            Map<String, Object> corpo = usuario("senha6@teste.com", "11144477735");
            corpo.put("senha", "abc123");
            postJson("/usuarios", corpo).andExpect(status().isCreated());
        }

        // BUG ENCONTRADO: UsuarioDTO.senha não tem @Size(min = 6). Mesmo problema do
        // nome: a regra só existe na entidade e o erro chega fora do padrão.
        @Test
        void senhaComMenosDe6Retorna400NoFormatoErros() throws Exception {
            Map<String, Object> corpo = usuario("senha5@teste.com", "11144477735");
            corpo.put("senha", "12345");
            postJson("/usuarios", corpo)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("Senha deve ter no mínimo 6 caracteres")));
        }

        // BUG ENCONTRADO: na edição a validação da entidade só roda no commit, e o
        // erro vira {"erro": "Could not commit JPA transaction"} (ou similar),
        // sem dizer qual campo está errado.
        @Test
        void edicaoComSenhaCurtaRetorna400NoFormatoErros() throws Exception {
            JsonNode criado = corpoDe(postJson("/usuarios", usuario("edita@teste.com", "11144477735")));
            Map<String, Object> corpo = usuario("edita@teste.com", "11144477735");
            corpo.put("senha", "123");
            putJson("/usuarios/" + criado.get("id").asLong(), corpo)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasItem("Senha deve ter no mínimo 6 caracteres")));
        }
    }

    // --------------------------------------------------------------- Regras
    @Nested
    class Regras {

        @Test
        void cadastroDefinePerfilClienteAtivoEDataDeHoje() throws Exception {
            Map<String, Object> corpo = usuario("novo@teste.com", "11144477735");
            corpo.put("perfil", "ADMIN");          // tentativa de virar admin
            corpo.put("ativo", false);             // e de nascer inativo
            corpo.put("dataCadastro", "2000-01-01");
            postJson("/usuarios", corpo)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.perfil").value("CLIENTE"))
                .andExpect(jsonPath("$.ativo").value(true))
                .andExpect(jsonPath("$.dataCadastro").value(LocalDate.now().toString()));

            Usuario salvo = usuarioRepository.findByEmail("novo@teste.com").orElseThrow();
            assertThat(salvo.getPerfil()).isEqualTo(PerfilUsuario.CLIENTE);
            assertThat(salvo.isAtivo()).isTrue();
            assertThat(salvo.getDataCadastro()).isEqualTo(LocalDate.now());
        }

        @Test
        void deletarFazSoftDelete() throws Exception {
            JsonNode criado = corpoDe(postJson("/usuarios", usuario("apagar@teste.com", "11144477735")));
            long id = criado.get("id").asLong();

            mockMvc.perform(delete("/usuarios/" + id)).andExpect(status().isNoContent());

            Usuario noBanco = usuarioRepository.findById(id).orElseThrow(); // a linha continua lá
            assertThat(noBanco.isAtivo()).isFalse();
        }

        @Test
        void getUsuariosRetornaSoAtivosEAdminRetornaTodos() throws Exception {
            salvarDireto("ativo@teste.com", true);
            salvarDireto("inativo@teste.com", false);

            JsonNode publicos = corpoDe(mockMvc.perform(get("/usuarios")).andExpect(status().isOk()));
            assertThat(publicos.findValuesAsText("email"))
                .contains("ativo@teste.com").doesNotContain("inativo@teste.com");
            publicos.forEach(u -> assertThat(u.get("ativo").asBoolean()).isTrue());

            JsonNode admin = corpoDe(mockMvc.perform(get("/usuarios/admin")).andExpect(status().isOk()));
            assertThat(admin.findValuesAsText("email"))
                .contains("ativo@teste.com", "inativo@teste.com", "admin@juan.com");
        }

        @Test
        void edicaoAtualizaDadosSemMudarPerfilNemDataDeCadastro() throws Exception {
            JsonNode criado = corpoDe(postJson("/usuarios", usuario("antes@teste.com", "11144477735")));
            long id = criado.get("id").asLong();
            Map<String, Object> corpo = mapa("nome", "Maria Souza", "cpf", "529.982.247-25",
                "email", "depois@teste.com", "senha", "novaSenha", "telefone", "4333334444",
                "dataCadastro", "2000-01-01");
            putJson("/usuarios/" + id, corpo)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Maria Souza"))
                .andExpect(jsonPath("$.cpf").value("52998224725"))
                .andExpect(jsonPath("$.email").value("depois@teste.com"))
                .andExpect(jsonPath("$.perfil").value("CLIENTE"))
                .andExpect(jsonPath("$.dataCadastro").value(LocalDate.now().toString()));
            postJson("/auth/login", Map.of("email", "depois@teste.com", "senha", "novaSenha"))
                .andExpect(status().isOk());
        }

        @Test
        void recadastroComEmailDeContaInativaReativaAMesmaConta() throws Exception {
            Usuario inativo = salvarDireto("volta@teste.com", false);
            postJson("/usuarios", usuario("volta@teste.com", "52998224725"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(inativo.getId()))
                .andExpect(jsonPath("$.ativo").value(true))
                .andExpect(jsonPath("$.perfil").value("CLIENTE"));
            assertThat(usuarioRepository.findAll().stream()
                .filter(u -> "volta@teste.com".equals(u.getEmail())).count()).isEqualTo(1);
        }

        @Test
        void usuarioInativoNaoConsegueFazerLogin() throws Exception {
            salvarDireto("bloqueado@teste.com", false);
            postJson("/auth/login", Map.of("email", "bloqueado@teste.com", "senha", "123456"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.erro").value("E-mail ou senha inválidos"));
        }

        @Test
        void usuarioExcluidoPelaApiNaoConsegueFazerLogin() throws Exception {
            JsonNode criado = corpoDe(postJson("/usuarios", usuario("excluido@teste.com", "11144477735")));
            postJson("/auth/login", Map.of("email", "excluido@teste.com", "senha", "123456"))
                .andExpect(status().isOk());
            mockMvc.perform(delete("/usuarios/" + criado.get("id").asLong()));
            postJson("/auth/login", Map.of("email", "excluido@teste.com", "senha", "123456"))
                .andExpect(status().isUnauthorized());
        }

        @Test
        void adminPadraoContinuaFazendoLogin() throws Exception {
            postJson("/auth/login", Map.of("email", "admin@juan.com", "senha", "admin"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.perfil").value("ADMIN"))
                .andExpect(jsonPath("$.senha").doesNotExist());
        }

        @Test
        void senhaErradaRetorna401() throws Exception {
            postJson("/auth/login", Map.of("email", "admin@juan.com", "senha", "errada"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.erro").value("E-mail ou senha inválidos"));
        }

        @Test
        void errosDeValidacaoVemNoFormatoErrosComTodasAsMensagens() throws Exception {
            Map<String, Object> corpo = mapa("nome", "Maria 123", "cpf", "11144477736",
                "email", "maria@teste.com", "senha", "123456", "telefone", "123");
            postJson("/usuarios", corpo)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros", hasSize(3)))
                .andExpect(jsonPath("$.erros", hasItem("CPF inválido")))
                .andExpect(jsonPath("$.erros", hasItem("Nome deve conter apenas letras")))
                .andExpect(jsonPath("$.erros", hasItem(containsString("Telefone inválido"))))
                .andExpect(jsonPath("$.erro").doesNotExist());
        }

        @Test
        void errosDeRegraVemNoFormatoErro() throws Exception {
            mockMvc.perform(get("/usuarios/999999"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro", isA(String.class)))
                .andExpect(jsonPath("$.erro").value("Usuário não encontrado"));
        }

        @Test
        void jsonMalformadoRetorna400NoFormatoErro() throws Exception {
            mockMvc.perform(post("/usuarios").contentType(MediaType.APPLICATION_JSON).content("{nome:"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erro").exists());
        }
    }
}
