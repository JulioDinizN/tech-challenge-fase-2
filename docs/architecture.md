# Arquitetura

Visão de contêiner e implantação do ToggleMaster para a entrega final na Oracle Cloud Infrastructure.

## Diagrama

- Fonte editável: `docs/diagrams/overall-architecture.drawio`
- Exportação SVG: `docs/diagrams/overall-architecture.svg`
- Exportação PNG usada no relatório: `docs/diagrams/overall-architecture.png`

O arquivo `.drawio` é a fonte de verdade. As exportações devem ser regeneradas com `npm run diagrams:export`; os arquivos PNG e SVG não devem ser editados manualmente.

## Entrada e execução

1. O cliente acessa a aplicação por HTTPS através do OCI Load Balancer.
2. O Nginx Ingress Controller encaminha as rotas HTTP aos serviços executados no namespace `togglemaster` do OKE.
3. O OKE obtém no OCIR as imagens versionadas dos cinco microsserviços.

## Microsserviços e comunicação interna

- `auth-service`: cria e valida chaves de API.
- `flag-service`: mantém as definições das flags e consulta o `auth-service` para validar a chave recebida.
- `targeting-service`: mantém regras de segmentação e consulta o `auth-service` para validar a chave recebida.
- `evaluation-service`: atende a rota crítica `/evaluate`, consulta `flag-service` e `targeting-service`, usa o OCI Cache e publica eventos no OCI Queue.
- `analytics-service`: consome eventos do OCI Queue, grava as linhas no OCI NoSQL e confirma a mensagem somente após a persistência.

## Persistência e mensageria

- Três sistemas OCI Database with PostgreSQL independentes armazenam autenticação, flags e regras de segmentação.
- OCI Cache (Redis) mantém o cache de baixa latência do fluxo de avaliação.
- OCI Queue desacopla a avaliação do processamento de analytics.
- OCI NoSQL Database armazena os eventos na tabela `ToggleMasterAnalytics`.

## Segurança e escalabilidade

- OKE Workload Identity autoriza `evaluation-service` a publicar na fila e `analytics-service` a consumir a fila e gravar no NoSQL sem chaves OCI estáticas nos pods.
- Metrics Server fornece métricas para os HPAs de `evaluation-service` e `analytics-service`, ambos baseados em CPU na implementação mínima da entrega.

## Ambiente local

Docker Compose preserva a topologia exigida de cinco aplicações e quatro dependências locais. As integrações OCI permanecem desabilitadas localmente: o `evaluation-service` registra os eventos no log e o worker do `analytics-service` permanece desligado.
