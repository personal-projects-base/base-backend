# Handoff — Base Backend Java

## O que é este projeto

Este repositório é um projeto-base reutilizável para novos backends Java. Ele não representa um domínio de negócio definitivo: a intenção é copiá-lo, renomeá-lo e continuar o desenvolvimento a partir de uma estrutura técnica já configurada.

O template entrega uma base com:

- Java 25;
- Spring Boot 3.5;
- Spring Cloud e OpenFeign;
- Spring MVC, Spring Data JPA e Hibernate;
- multitenancy por schema PostgreSQL;
- migrações com Flyway;
- autenticação através da biblioteca `authorization-backend`;
- Swagger/OpenAPI com Springdoc;
- integrações opcionais com RabbitMQ, MongoDB, e-mail e Amazon S3;
- drivers para PostgreSQL, MySQL e SQL Server;
- Lombok configurado como annotation processor.

## Estado técnico deste handoff

O projeto-base está configurado atualmente com:

| Componente | Versão/linha |
| --- | --- |
| Java | 25 |
| Spring Boot | 3.5.16 |
| Spring Framework | 6.2.x, gerenciado pelo Boot |
| Spring Cloud | 2025.0.3 |
| Hibernate | 6.6.x, gerenciado pelo Boot |
| Flyway | 11.7.x, gerenciado pelo Boot |
| Springdoc | 2.8.17 |
| Lombok | 1.18.46 |

As interfaces de multitenancy já foram adaptadas para os tipos genéricos do Hibernate 6.6. O Flyway usa os módulos `flyway-core` e `flyway-database-postgresql`. A migração inicial continua sendo executada na subida da aplicação, e as migrações de tenant continuam sendo executadas na primeira utilização de cada tenant.

A compilação das APIs foi validada com sucesso usando um alvo Java temporário compatível com o JDK disponível no ambiente de manutenção. Depois de copiar o template, o build e a execução final devem ser validados com um JDK 25 completo.

## Como iniciar um novo projeto a partir daqui

Depois de copiar o repositório, substituir pelo menos os identificadores abaixo:

1. Renomear o diretório do projeto.
2. Alterar `groupId`, `artifactId`, `name` e `description` no `pom.xml`.
3. Renomear o pacote raiz atual `com.smartverse` para o pacote do novo projeto.
4. Atualizar a classe `StarterApplication` e todas as referências ao pacote raiz.
5. Atualizar `SERVICE_NAME`, o context path e a URL documentada do Swagger.
6. Definir o nome do banco/schema do novo serviço.
7. Revisar `src/main/resources/properties.json` ou `.gonthera/properties.json`, conforme o fluxo utilizado pelo gerador.
8. Remover módulos opcionais que o novo serviço não utilizará.
9. Criar as migrations e entidades específicas do novo domínio.
10. Criar um novo handoff dentro de `docs/handoff/<nome-do-projeto>/`, sem sobrescrever este documento nem handoffs de projetos integrados.

## Variáveis de ambiente

O novo projeto deve definir, conforme os recursos utilizados:

```text
DATABASE_SCHEMA_NAME=<nome-base-dos-schemas>
DB_NAME=POSTGRES
SERVER_HOST=<host-do-banco>
DB_PORT=<porta-do-banco>
DB_USERNAME=<usuario>
DB_PASSWORD=<senha>
SECRET_JWT=<segredo-jwt>
SERVER_PORT=<porta-http>
SERVICE_NAME=<contexto-do-servico>
MONGO_USER=<usuario-mongodb>
MONGO_PASSWORD=<senha-mongodb>
AWS_ACCESS=<chave-aws>
AWS_SECRET=<segredo-aws>
PASSWORD_EMAIL=<senha-email>
```

Antes de utilizar a lista, conferir os nomes efetivamente consumidos em `EnumConfigContext` e nas configurações específicas. Segredos e senhas devem permanecer fora do Git.

## Multitenancy e migrações

O modelo atual utiliza um schema PostgreSQL por tenant. O nome é composto pela aplicação no formato:

```text
<DATABASE_SCHEMA_NAME>_<TENANT>
```

A implementação normaliza esse nome para maiúsculas ao selecionar e migrar schemas. Ao continuar o projeto, preservar essa convenção ou alterar todas as partes relacionadas em conjunto:

- `ConfigContextImpl`;
- `ConfigDataSource`;
- `MultiTenantConnectionProviderImpl`;
- `TenantSchemaInterceptor`;
- `DBMigration`;
- migrations em `src/main/resources/db/migration`.

## Validação depois da cópia

Com o JDK 25 configurado em `JAVA_HOME`, executar:

```bash
./mvnw clean compile
./mvnw test
./mvnw spring-boot:run
```

Também validar manualmente:

- conexão com o PostgreSQL;
- criação/migração do schema inicial;
- criação/migração de um tenant;
- autenticação e geração de token;
- troca de tenant entre requisições;
- Swagger em `/<SERVICE_NAME>/swagger-ui/index.html`;
- somente as integrações opcionais mantidas no novo projeto.

## Ponto de continuidade

Este handoff termina com a infraestrutura-base atualizada para Java 25 e Spring Boot 3.5. Ele fica deliberadamente aberto: o próximo trabalho começa pela identidade e pelo domínio do projeto que receber a cópia.

Ao continuar, registrar aqui ou no handoff específico do novo projeto:

- nome, pacote e propósito do serviço;
- integrações que foram mantidas ou removidas;
- decisões de banco e multitenancy;
- novas variáveis de ambiente;
- migrations criadas;
- endpoints e regras de negócio adicionados;
- pendências, riscos e último comando de validação executado.

### Próxima continuidade

- Projeto derivado: a definir.
- Objetivo de negócio: a definir.
- Integrações necessárias: a definir.
- Primeira entrega: a definir.
- Pendências conhecidas do projeto derivado: a definir.
