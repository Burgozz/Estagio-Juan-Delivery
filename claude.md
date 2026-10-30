# Juan Delivery — Contexto do Projeto

## Visão Geral
Marketplace mobile de vinhos e acessórios de vinho, modelo iFood.
Vendedores cadastram produtos na plataforma, usuários compram pelo app.
Escopo do estágio: apenas a experiência do usuário/cliente.

## Stack
- **Backend:** Java 21, Spring Boot 3.4.5, Maven
- **Frontend:** Flutter 3.5 (Dart)
- **Banco:** PostgreSQL 18, porta 5432, banco: api_delivery (configurado em `api-delivery/src/main/resources/application.properties`)
  - ⚠️ A senha do banco está em texto puro no `application.properties`, que é versionado no git.
- **IDE:** VS Code + IntelliJ IDEA Ultimate
- **Versionamento:** GitHub

## Estrutura de Pastas
```
api-delivery/                      backend (Spring Boot)
  src/main/java/com/juan/api_delivery/
    ApiDeliveryApplication.java
    auth/        AuthController, LoginDTO, LoginRespostaDTO, CredenciaisInvalidasException
    usuario/     Usuario, PerfilUsuario, UsuarioController, UsuarioService, UsuarioRepository, UsuarioDTO
    endereco/    Endereco, EnderecoController, EnderecoService, EnderecoRepository, EnderecoDTO, EnderecoRespostaDTO
    produto/     Produto, Vinho, Acessorio, TipoProduto, CategoriaProduto, ProdutoController, ProdutoService,
                 ProdutoRepository, VinhoRepository, AcessorioRepository, ProdutoDTO, ProdutoRespostaDTO,
                 ProdutoNaoEncontradoException
    pedido/      Pedido, ItemPedido, StatusPedido, PedidoController, ItemPedidoController, PedidoService,
                 ItemPedidoService, PedidoRepository, ItemPedidoRepository, PedidoDTO, ItemPedidoDTO
    shared/
      config/      CorsConfig, DataInitializer
      exception/   GlobalExceptionHandler, MensagensErro
      validation/  CpfValidator, @CpfValido, EmailDomainValidator, @EmailDominioValido (+ validators)
  src/test/java/com/juan/api_delivery/   mesma estrutura de pacotes do main
                                         (shared/IntegracaoBase = base dos testes de integração, H2)

app_delivery/                      frontend (Flutter), pacote Dart `front_delivery`
  lib/
    main.dart        só o main() (registra o CarrinhoController no provider)
    app.dart         MyApp (MaterialApp, tema, tela inicial)
    main_screen.dart MainScreen (BottomNavigationBar por perfil)
    core/
      config/    api_config.dart (host/porta da API)
      theme/     app_colors.dart (todas as cores compartilhadas), app_theme.dart (ThemeData), auth_theme.dart
      session/   sessao_usuario.dart
      network/   api_erro.dart (parseErro)
      utils/     cpf_validator, harmonizacao_validator, input_formatters, paises
      widgets/   label_obrigatorio
    features/
      auth/      screens/ (login, cadastro), services/ (auth_service)
      inicio/    screens/ (inicio_screen, com carrossel)
      catalogo/  models/ (produto), services/ (produto_service), screens/ (catalogo, produto_detalhe)
      carrinho/  controllers/ (carrinho_controller), screens/ (carrinho), widgets/ (carrinho_appbar_action)
      pedidos/   models/ (pedido, item_pedido), services/ (pedido_service),
                 screens/ (pedidos, detalhes_pedido, confirmacao_pedido, pedido_concluido)
      perfil/    models/ (usuario, endereco), services/ (usuario_service, endereco_service),
                 screens/ (perfil, meus_dados, endereco, alterar_senha)
      admin/     filters/, screens/ (listas e formulários de usuário e produto), widgets/ (busca, filtros, chips...)
  test/            mesma estrutura de lib/ (core/, features/admin/) + helpers/api_falsa.dart
```
Regra: código usado por uma feature só fica dentro dela; o que é usado por várias vai para `core/`.
Models e services ficam na feature "dona" (ex.: `produto` em `catalogo/`) e as outras importam de lá.

## Identidade Visual
- Cor primária: `#3C0731` (vinho escuro)
- Fundo: `#FAFAFA`
- Cards: branco com sombra suave
- Cantos arredondados: 12-16px
- Botões principais: fundo `#3C0731`, texto branco
- Erros inline: vermelho `#FF6B6B`
- SnackBar de erro: vermelho `Colors.red.shade700`, 5 segundos

## Arquitetura Backend
- Padrão 3 camadas: Controller → Service → Repository
- Herança SINGLE_TABLE na tabela `produtos` com discriminador `tipo_produto`
- Soft delete: nunca usar DELETE físico em `Usuario` e `Produto`, setar `ativo = false`
- Produtos com estoque zero são desativados automaticamente (`ativo = false`). A regra fica em
  `Produto.atualizarAtivoConformeEstoque()` (usada também por `baixarEstoque`/`devolverEstoque`); não duplicar
- Baixa/devolução de estoque busca o produto com `ProdutoRepository.findByIdParaAtualizarEstoque` (lock pessimista)
- `DataInitializer` cria admin padrão ao subir o backend
- Pacotes por funcionalidade (`usuario/`, `produto/`...): controller, service, repository, entidade e DTOs juntos
- Injeção de dependência por construtor: campos `private final` + `@RequiredArgsConstructor`
- Mensagens de erro repetidas ficam em `shared/exception/MensagensErro`

## Padrões de Erro
- `GlobalExceptionHandler` intercepta todas as exceções
- `MethodArgumentNotValidException` → `{"erros": ["msg1", "msg2"]}`
- `IllegalArgumentException` / `RuntimeException` → `{"erro": "mensagem"}`
- Sempre usar `@Valid` no `@RequestBody` nos controllers
- Flutter trata via `parseErro()` de `lib/core/network/api_erro.dart`, usado por todos os services

## Padrões Flutter
- Pacote `http` puro — nunca usar Dio ou Retrofit
- Sessão: classe estática `SessaoUsuario` com campos `id`, `nome`, `email`, `perfil`
- Persistência de sessão: `shared_preferences`
- Navegação por perfil:
  - CLIENTE: Início, Busca, Pedidos, Perfil
  - ADMIN: Usuários, Produtos
- Erros de API exibidos inline embaixo do campo via `String? _xApiError`
- Sempre usar `Form` + `GlobalKey<FormState>` + `validator` nos formulários
- Carrinho: `CarrinhoController` com `ChangeNotifier` via `provider`. A quantidade de um item nunca passa do
  estoque do produto (`adicionar`/`incrementar` retornam false no limite)
- Finalizar pedido: se a API recusar um item, o app cancela o pedido criado (PATCH status=CANCELADO), mostra a
  mensagem da API e mantém o carrinho
- Cores: sempre pelas constantes de `lib/core/theme/app_colors.dart` (`kPrimary`, `kBackground`, `kCreme`...);
  nunca redeclarar `kPrimary` numa tela. Paletas exclusivas de uma tela (status, categorias) ficam na tela
- `dart format` com largura de 120 colunas (configurado em `analysis_options.yaml`)

## Testes
- Backend: `mvn test` (integração em H2, perfil `test`). Frontend: `flutter test`
- Todos os testes devem passar. Se um teste novo documentar um bug, marque-o com o comentário
  `BUG ENCONTRADO`; ao corrigir, corrija o código, não o teste
- Validações de entrada ficam no DTO (para o erro sair como `{"erros": [...]}`); a entidade só
  repete o que também vale para dados criados direto no banco (ex.: o admin padrão, senha `admin`)

## Entidades Principais
- `Usuario`: id, nome, email, senha, telefone, cpf, dataCadastro, ativo, perfil
- `Produto` (abstract): id, nome, preco, descricao, imagemUrl, estoque, ativo
- `Vinho` extends Produto: categoria, paisOrigem, safra, teorAlcool, harmonizacao
- `Acessorio` extends Produto: tipoAcessorio, marca, material
- `Pedido`: id, usuario, status, dataPedido, valorTotal
- `ItemPedido`: id, quantidade, precoUnit, pedido, produto
- `Endereco`: id, rua, numero, bairro, cidade, estado, cep, usuario

## Enums
- `PerfilUsuario`: ADMIN, CLIENTE
- `StatusPedido`: PENDENTE, CONFIRMADO, EM_PREPARO, EM_ENTREGA, ENTREGUE, CANCELADO
- `CategoriaProduto`: VINHO_TINTO, VINHO_BRANCO, VINHO_ROSE, VINHO_ESPUMANTE, VINHO_SOBREMESA, VINHO_ORGANICO, VINHO_IMPORTADO
- `TipoProduto`: VINHO, ACESSORIO

## Endpoints Principais
- `POST /auth/login` → autenticação
- `GET/POST/PUT/DELETE /usuarios`
- `GET/POST/PUT/DELETE /produtos`
- `GET /produtos/admin` → todos incluindo inativos (só admin)
- `GET /produtos?categoria={}` → filtro por categoria
- `GET/POST/DELETE /usuarios/{id}/enderecos`
- `GET/POST/PATCH/DELETE /pedidos`
- `GET /pedidos/usuario/{usuarioId}`
- `GET/POST/DELETE /pedidos/{pedidoId}/itens`

## Regras de Negócio Importantes
- Produto com estoque 0 → `ativo = false` automaticamente
- Produto com estoque > 0 e inativo → reativar automaticamente
- Estoque > 0 obrigatório na criação, permitido 0 na edição
- Pedido (`ItemPedidoService`, `PedidoService`, todos `@Transactional`):
  - adicionar item baixa o estoque; recusa com 400 `{"erro"}` produto inativo ("Produto indisponível") e quantidade
    maior que o estoque ("Estoque insuficiente para <nome>. Disponível: <n>")
  - remover item (`DELETE /pedidos/{pedidoId}/itens/{id}`) devolve o estoque; o item precisa ser do `pedidoId` da URL
  - `valorTotal` = soma de quantidade × precoUnit dos itens, recalculado a cada item adicionado ou removido
  - mudar para CANCELADO devolve o estoque de todos os itens uma única vez; pedido cancelado não muda de status
    nem de itens ("Pedido cancelado não pode ser alterado")
- CPF: exatamente 11 dígitos numéricos
- Telefone: 10 ou 11 dígitos numéricos
- CEP: exatamente 8 dígitos numéricos
- Safra: entre 1800 e o ano atual (`@SafraValida`, calculado com `Year.now()`)
- Teor alcoólico: entre 7.0 e 20.0 (Lei nº 7.678/1988)
- Harmonização: opcional; se preenchida, só letras e pontuação simples, mínimo 3 letras (vazia é salva como null)
- Email único por usuário
- Todos os novos usuários criados via cadastro recebem perfil CLIENTE
- Admin padrão: email `admin@juan.com`, senha `admin`