# Base Backend Java

Template reutilizável para criação de serviços Java com Spring Boot, PostgreSQL, Flyway, multitenancy por schema e geração de código com Gonthera CLI.

> [!IMPORTANT]
> A fonte de verdade para configurar e usar o gerador é a **[documentação oficial do Gonthera CLI para Java](https://labs.smartverse.com.br/docs/ia/gonthera/JAVA.md)**.
>
> Consulte-a antes de alterar `.gonthera/`, gerar código ou customizar classes geradas. Este repositório não mantém uma cópia local dessa documentação.

## Tecnologias principais

- Java 25;
- Spring Boot 3.5;
- Spring MVC e Spring Data JPA;
- PostgreSQL e Flyway;
- multitenancy por schema;
- Swagger/OpenAPI;
- Gonthera CLI;
- integrações opcionais com RabbitMQ, MongoDB, e-mail e Amazon S3.

## Pré-requisitos

- JDK 25;
- PostgreSQL;
- acesso ao repositório Maven configurado no `pom.xml`;
- serviços opcionais somente quando utilizados pelo projeto derivado.

## Configurando um novo projeto

Depois de clonar o template, execute o configurador uma única vez, antes de iniciar o desenvolvimento do novo serviço.

### Linux, macOS, Git Bash ou WSL

```bash
./setup-project.sh
```

### Windows PowerShell

```powershell
.\setup-project.ps1
```

Caso a política de execução do Windows bloqueie o arquivo:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-project.ps1
```

O arquivo `.sh` não é executado diretamente pelo Prompt de Comando ou PowerShell. No Windows, utilize Git Bash, WSL ou o configurador `.ps1`.

### Informações solicitadas

O configurador solicita dois valores:

1. Nome do projeto em kebab-case, como `customer-service`.
2. Pacote Java principal, como `com.gonthera.customerservice`.

Com esses valores, a configuração será aplicada da seguinte forma:

| Item | Valor resultante |
| --- | --- |
| Pasta do projeto | `customer-service` |
| Gonthera `projectName` | `customer-service` |
| Gonthera `mainPackage` | `com.gonthera.customerservice` |
| Maven `groupId` | `com.gonthera` |
| Maven `artifactId`, `name` e `description` | `customer-service` |
| Pacote da aplicação | `com.gonthera` |
| Pacotes manuais do serviço | `com.gonthera.customerservice` |

O `groupId` e o pacote da aplicação são derivados removendo o último segmento do pacote Java principal. Isso mantém a classe principal em um pacote capaz de localizar tanto o código manual quanto o código gerado.

Antes de alterar qualquer arquivo, o configurador mostra um resumo e solicita confirmação.

### Alterações realizadas

O configurador:

- atualiza `.gonthera/project.json`;
- atualiza as coordenadas do projeto no `pom.xml`;
- substitui packages e imports nos fontes manuais;
- reorganiza os diretórios de `src/main/java` e `src/test/java`;
- ignora qualquer diretório cujo pacote termine em `_gen`;
- executa `gonthera-cli:validate`;
- renomeia a pasta raiz do projeto;
- remove o `.git` herdado do template somente depois da validação.

Se a validação falhar, o configurador interrompe o processo e preserva o `.git` para permitir a inspeção das alterações. Ele também recusa a operação quando a pasta de destino já existe.

> [!WARNING]
> Ao concluir com sucesso, o configurador exclui todo o histórico e os remotes Git herdados do template. Ele não executa `git init` automaticamente.

Depois da configuração, entre na pasta renomeada e inicie um novo repositório quando desejar:

```bash
cd ../customer-service
git init
```

O código `_gen` não é renomeado pelo configurador. Ele será descartado e recriado pelo Gonthera CLI de acordo com o novo `mainPackage`.

### Documentação do projeto derivado

Cada serviço criado a partir deste template deve manter regras e documentos próprios:

- `docs/rule/PROJECT_RULES.md`: regras obrigatórias de desenvolvimento válidas para todo o projeto;
- `docs/handoff/<nome-do-projeto>/HANDOFF.md`: contexto atual do desenvolvimento, decisões tomadas, estado das entregas, validações executadas e pendências;
- `docs/skill/<nome-do-projeto>/SKILL.md`: regras estáveis e específicas que orientam como analisar, alterar, gerar e validar o projeto.

> [!IMPORTANT]
> Antes de analisar, planejar ou implementar qualquer alteração, leia integralmente `docs/rule/PROJECT_RULES.md` e o `HANDOFF.md` do serviço. Leia também os documentos complementares indicados pelo handoff que sejam relevantes para a tarefa. Nenhum desenvolvimento deve começar sem que as regras e o contexto atual tenham sido compreendidos.

O handoff do template começa vazio e deve ser renomeado e preenchido conforme o contexto real do novo serviço. Ele não deve repetir a documentação oficial do Gonthera CLI nem ser usado como manual genérico.

Todo contexto de continuidade deve ser registrado no handoff, e não espalhado em arquivos sem referência. Ao mesmo tempo, não concentre todo o histórico, arquitetura e estado do serviço em um único `HANDOFF.md`. Quando o conteúdo ficar extenso ou difícil de consultar, mantenha o `HANDOFF.md` como índice e resumo atual e distribua os detalhes em arquivos temáticos dentro da mesma pasta.

Exemplo:

```text
docs/handoff/customer-service/
├── HANDOFF.md
├── architecture.md
├── integrations.md
└── deliveries/
    └── customer-import.md
```

O arquivo principal deve indicar claramente quando cada documento complementar precisa ser consultado. Evite duplicar a mesma informação em mais de um lugar.

O skill deve conter apenas orientações específicas que mudem decisões de desenvolvimento naquele projeto. Não inclua conselhos genéricos, histórico de trabalho ou cópias de documentação externa. A documentação oficial do Gonthera CLI para Java continua sendo a fonte de verdade para o gerador.

Também não concentre todas as regras e referências em um `SKILL.md` muito grande. Mantenha nele o propósito, as regras essenciais e o direcionamento para arquivos complementares. Detalhes extensos devem ser separados por assunto em `references/` e carregados somente quando forem relevantes para a tarefa.

Exemplo:

```text
docs/skill/customer-service/
├── SKILL.md
└── references/
    ├── database.md
    ├── integrations.md
    └── security.md
```

Cada referência deve ser mencionada no `SKILL.md`, com uma orientação objetiva sobre quando deve ser lida.

## Configuração do ambiente

A aplicação lê configurações por variáveis de ambiente. Crie seu arquivo local a partir do exemplo versionado:

```bash
cp .env.example .env
```

Preencha os valores necessários e carregue o arquivo antes de iniciar a aplicação:

```bash
set -a
source .env
set +a
```

O `.env.example` documenta as configurações disponíveis e pode ser versionado. O arquivo `.env` contém os valores locais e não deve ser registrado no Git.

## Gonthera CLI

A configuração do gerador fica em `.gonthera/`. Execute os comandos sempre na raiz do projeto:

```bash
./mvnw gonthera-cli:validate
./mvnw gonthera-cli:generate-sources
```

O código gerado fica em pacotes terminados em `_gen` e pode ser apagado e recriado a cada geração. Mantenha regras de negócio e outras customizações fora desses pacotes.

Além dos fontes Java, a geração pode sobrescrever arquivos em `src/main/resources`. Revise as alterações geradas antes de incorporá-las ao projeto.

## Executando com Docker

O Docker executa a validação e a geração do Gonthera CLI antes de compilar a aplicação. O JAR produzido em `target` no estágio de build é copiado para uma imagem de execução com Java 25.

Prepare a configuração local e suba somente a aplicação:

```bash
cp .env.example .env
docker compose up --build
```

Para encerrar:

```bash
docker compose down
```

O Compose injeta o conteúdo de `.env` no container, mantendo compatibilidade com as leituras existentes via `System.getenv()`.

O serviço utiliza `network_mode: host`, portanto compartilha a rede do host e publica diretamente a porta definida por `SERVER_PORT`. Serviços disponíveis no host podem ser acessados por `localhost`. Para acessar outro servidor, altere `SERVER_HOST` no `.env`.

## Executando sem Docker

Depois de carregar as variáveis do `.env` no shell:

```bash
./mvnw spring-boot:run
```

Com os valores de exemplo, o Swagger estará disponível em:

```text
http://localhost:8081/basebackend/swagger-ui/index.html
```

## Multitenancy

O projeto utiliza um schema PostgreSQL para cada tenant. O nome efetivo segue o padrão:

```text
<DATABASE_SCHEMA_NAME>_<TENANT>
```

A implementação atual normaliza o nome para letras maiúsculas ao selecionar e migrar o schema. Qualquer alteração nessa convenção deve ser aplicada em conjunto à configuração do datasource, ao Hibernate e às migrations do Flyway.

### Resolução do tenant em endpoints anônimos

O tenant nunca deve ser escolhido diretamente por um valor enviado pelo cliente, pois isso permitiria que uma requisição tentasse selecionar o schema de outra organização.

Endpoints anônimos utilizam o tenant isolado `public` por padrão. Quando um fluxo anônimo precisar descobrir o tenant, cada serviço deve implementar sua própria regra segura: receber um identificador opaco, consultar um cadastro mantido em uma base isolada e somente então obter o tenant associado. Um UUID reduz a possibilidade de enumeração, mas não substitui autenticação, autorização ou tokens assinados quando houver acesso a dados sensíveis.

As rotas que precisam consultar a base central devem ser declaradas explicitamente em `InterceptorExclusions.requiresAdminTenant`. A resolução específica do tenant deve permanecer fora do header e ser implementada pelo serviço conforme seu domínio.

## Criando um projeto derivado

Depois de executar o configurador:

1. Atualize `SERVICE_NAME` e `DATABASE_SCHEMA_NAME` no `.env`.
2. Configure entidades, endpoints e outros recursos em `.gonthera/` conforme a documentação oficial.
3. Remova integrações e dependências que não serão utilizadas.
4. Gere os fontes e compile o projeto.

```bash
./mvnw gonthera-cli:validate
./mvnw gonthera-cli:generate-sources
./mvnw clean compile
```
