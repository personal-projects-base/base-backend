# Regras de desenvolvimento do projeto

Estas regras são obrigatórias para qualquer alteração realizada neste projeto ou em um serviço derivado deste template.

## Requisitos antes da implementação

Não inicie a implementação antes de levantar e compreender integralmente os requisitos relevantes para a tarefa.

Antes de alterar código ou configuração:

1. leia o handoff e os documentos complementares relacionados ao contexto da mudança;
2. inspecione a implementação atual e identifique os fluxos afetados;
3. confirme objetivo, escopo, comportamento esperado, restrições, dependências e critérios de conclusão;
4. identifique impactos sobre contratos existentes, banco de dados, multitenancy, integrações e código gerado;
5. esclareça com o humano qualquer decisão ausente que possa mudar materialmente a implementação.

Para tarefas pequenas e objetivas, os requisitos já fornecidos podem ser suficientes. Não crie cerimônia desnecessária, mas também não preencha lacunas relevantes com suposições silenciosas.

## Arquitetura Gonthera CLI

Antes de analisar ou alterar configuração, código gerado, entidades, endpoints, relacionamentos, autorização, mensageria ou SQL do Gonthera, consulte a [documentação oficial do Gonthera CLI para Java](https://labs.smartverse.com.br/docs/ia/gonthera/JAVA.md).

Respeite a arquitetura e o contrato vigentes descritos nessa documentação. Em especial:

- use `.gonthera/` como fonte da configuração do gerador;
- valide a configuração com `gonthera-cli:validate`;
- gere código com `gonthera-cli:generate-sources`;
- trate pacotes terminados em `_gen` como saída descartável;
- nunca implemente customizações permanentes dentro de `_gen`;
- mantenha customizações e regras do serviço nos pacotes manuais;
- preserve o fluxo `Controller -> Service -> Repository`;
- mantenha transações no Service, não no Controller;
- quando a documentação divergir do comportamento observado, não invente um contrato: investigue e comunique a divergência antes de continuar.

A documentação oficial é a fonte de verdade. Não mantenha cópias locais do manual do Gonthera CLI.

## Testes unitários

Não crie nem gere testes unitários durante o desenvolvimento, a menos que o humano solicite isso explicitamente.

Essa restrição não impede:

- executar testes já existentes;
- compilar o projeto;
- validar a configuração do Gonthera CLI;
- executar verificações estáticas ou manuais compatíveis com a tarefa;
- informar ao humano quais testes seriam recomendáveis.

Não remova, desabilite ou altere testes existentes apenas para contornar uma falha. Se uma mudança exigir alteração de testes existentes para manter o contrato atual, informe o humano antes de fazê-la.
