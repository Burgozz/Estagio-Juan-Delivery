# Juan Delivery

Marketplace mobile de vinhos e acessórios de vinho, no modelo iFood. Vendedores cadastram produtos e clientes compram pelo app.

O repositório tem duas partes independentes:

| Pasta | O que é | Stack |
|---|---|---|
| `api-delivery/` | Backend (API REST) | Java 21, Spring Boot 3.4.5, Maven, PostgreSQL |
| `app_delivery/` | Frontend (app) | Flutter / Dart |

As regras de negócio, os padrões de código e os endpoints estão descritos em [`claude.md`](claude.md).

## Estrutura de pastas

### Backend: organizado por funcionalidade

```
api-delivery/src/main/java/com/juan/api_delivery/
├── ApiDeliveryApplication.java
├── auth/        login (AuthController, LoginDTO, LoginRespostaDTO)
├── usuario/     Usuario, PerfilUsuario, controller, service, repository, DTO
├── endereco/    Endereco, controller, service, repository, DTOs
├── produto/     Produto, Vinho, Acessorio, TipoProduto, CategoriaProduto, controller, service, repositories, DTOs
├── pedido/      Pedido, ItemPedido, StatusPedido, controllers, services, repositories, DTOs
└── shared/
    ├── config/      CorsConfig, DataInitializer (cria o admin padrão)
    ├── exception/   GlobalExceptionHandler, MensagensErro
    └── validation/  validação de CPF e de domínio de e-mail
```

Cada pacote de funcionalidade reúne tudo daquele assunto: controller, service, repository, entidade e DTOs. Os testes em `src/test/java` seguem os mesmos pacotes.

### Frontend: feature-first

```
app_delivery/lib/
├── main.dart          ponto de entrada
├── app.dart           MaterialApp e tema
├── main_screen.dart   barra de navegação (abas por perfil: CLIENTE ou ADMIN)
├── core/              código compartilhado entre features
│   ├── config/        api_config.dart (endereço da API)
│   ├── theme/         cores (app_colors.dart) e ThemeData (app_theme.dart, auth_theme.dart)
│   ├── session/       SessaoUsuario
│   ├── network/       tratamento comum de erros da API (parseErro)
│   ├── utils/         validadores (CPF, harmonização), máscaras de input, lista de países
│   └── widgets/       widgets usados em várias features (LabelObrigatorio)
└── features/
    ├── auth/          login e cadastro
    ├── inicio/        tela inicial e carrossel
    ├── catalogo/      busca e detalhe do produto
    ├── carrinho/      CarrinhoController e tela do carrinho
    ├── pedidos/       lista, detalhe, confirmação e pedido concluído
    ├── perfil/        perfil, meus dados, endereços e alterar senha
    └── admin/         gerenciamento de usuários e produtos (listas, formulários e filtros)
```

Dentro de cada feature, quando faz sentido, há `models/`, `services/`, `screens/` e `widgets/`. Os testes em `test/` seguem a mesma estrutura.

## Como rodar

### Pré-requisitos

- Java 21 e Maven (ou o `mvnw` incluído no projeto)
- PostgreSQL rodando na porta **5432**, com um banco chamado `api_delivery`
- Flutter SDK (Dart 3.5 ou mais novo)

### Backend

1. Crie o banco:
   ```sql
   CREATE DATABASE api_delivery;
   ```
2. Confira o usuário e a senha do banco em `api-delivery/src/main/resources/application.properties`.
   > ⚠️ Hoje a senha do banco está em texto puro nesse arquivo, que é versionado no git.
3. Suba a API (as tabelas são criadas e atualizadas automaticamente, `ddl-auto=update`):
   ```bash
   cd api-delivery
   ./mvnw spring-boot:run        # Windows: mvnw.cmd spring-boot:run
   ```
   A API sobe em `http://localhost:8080`. Ao subir, o `DataInitializer` cria o admin padrão
   (`admin@juan.com` / `admin`), caso ele ainda não exista.

4. Testes:
   ```bash
   mvn test
   ```
   Os testes de integração usam um banco H2 em memória e não tocam no PostgreSQL.

### Frontend

```bash
cd app_delivery
flutter pub get
flutter run -d chrome          # ou -d windows, ou um emulador
```

O endereço da API fica em `lib/core/config/api_config.dart`:

| Onde o app roda | `host` |
|---|---|
| Navegador ou desktop no mesmo PC da API | `localhost` |
| Emulador Android | `10.0.2.2` |
| Celular na mesma rede Wi-Fi | IP do PC (veja com `ipconfig`) |

Testes e análise estática:

```bash
flutter test
flutter analyze
dart format lib test           # largura de 120 colunas, configurada no analysis_options.yaml
```

### Acessar pelo celular (versão web)

1. Descubra o IP do PC na rede Wi-Fi com `ipconfig` (por exemplo, `192.168.0.15`).
2. Em `lib/core/config/api_config.dart`, troque `host` para esse IP.
3. Com o backend rodando, suba o app web aceitando conexões de outros aparelhos:
   ```bash
   cd app_delivery
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8081
   ```
4. No celular, conectado à **mesma rede Wi-Fi**, abra `http://192.168.0.15:8081`.

Se o celular não conseguir abrir, libere as portas 8080 (API) e 8081 (app) no firewall do Windows.
