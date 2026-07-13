# Arquitetura

Visão de contêiner e implantação do ToggleMaster para a entrega final na Oracle Cloud Infrastructure.

## Diagrama

- Fonte editável: `docs/diagrams/overall-architecture.drawio`
- Exportação PNG usada no relatório: `docs/diagrams/overall-architecture.png`

O arquivo `.drawio` é a fonte de verdade. O PNG deve ser regenerado com `npm run diagrams:export` e não deve ser editado manualmente.

## Entrada e execução

1. Durante a demonstração efêmera, o cliente acessa as APIs por HTTP no endereço público do OCI Load Balancer. TLS exige domínio/certificado e é a evolução indicada para produção; o diagrama não afirma HTTPS sem essa configuração.
2. O F5 NGINX Ingress Controller OSS encaminha `/validate`, `/flags`, `/rules` e `/evaluate` aos serviços no namespace `togglemaster` do OKE.
3. O OKE obtém no OCIR as imagens versionadas dos cinco microsserviços.

## Microsserviços e comunicação interna

- `auth-service`: cria e valida chaves de API.
- `flag-service`: mantém as definições das flags e consulta o `auth-service` para validar a chave recebida.
- `targeting-service`: mantém regras de segmentação e consulta o `auth-service` para validar a chave recebida.
- `evaluation-service`: atende a rota crítica `/evaluate`, consulta `flag-service` e `targeting-service`, usa o OCI Cache e publica eventos no OCI Queue.
- `analytics-service`: consome eventos do OCI Queue, grava as linhas no OCI NoSQL e confirma a mensagem somente após a persistência.

## Persistência e mensageria

- Três sistemas OCI Database with PostgreSQL independentes armazenam autenticação, flags e regras de segmentação. Três Jobs idempotentes criam cada banco, usuário de aplicação com privilégio restrito e schema antes da validação dos pods.
- OCI Cache (Redis) mantém o cache de baixa latência do fluxo de avaliação.
- OCI Queue desacopla a avaliação do processamento de analytics.
- OCI NoSQL Database armazena os eventos na tabela `ToggleMasterAnalytics`.

## Segurança e escalabilidade

- O Terraform cria um OCI Vault `DEFAULT`, uma chave AES-256 `SOFTWARE` e oito segredos com conteúdo gerado pelo próprio OCI. Esse tipo de Vault/chave e a quantidade de segredos permanecem dentro da franquia Always Free; os serviços de banco, cache, workers e Load Balancer ainda podem consumir créditos.
- O OCI Secrets Store CSI Driver Provider usa Workload Identity para ler o Vault e sincronizar somente os segredos necessários em Secrets nativos do Kubernetes. O token do OCIR é uma exceção operacional: ele é fornecido no momento do deploy para criar `ocir-pull-secret`, pois o kubelet precisa autenticar a imagem antes que o volume CSI do pod exista.
- `evaluation-service` possui somente `queue-push`; `analytics-service`, `queue-pull` e acesso às linhas NoSQL. Não há chaves OCI estáticas nos pods.
- Metrics Server fornece métricas para os HPAs de `evaluation-service` (50% de CPU) e `analytics-service` (30% de CPU), com mínimo de 1 e máximo de 5 réplicas. KEDA não foi usado porque não há scaler oficial para OCI Queue nesta entrega.
- Todos os Deployments possuem requests/limits, probes HTTP, usuário não root, filesystem somente leitura, `seccomp` e remoção de capabilities.

## Segredos e configuração

```text
Terraform -> OCI Vault (conteúdo gerado no OCI)
          -> outputs apenas com OCIDs, nomes e endpoints
          -> Kustomize/renderização sem valores secretos
OCI Vault -> provider CSI com Workload Identity
          -> Secret Kubernetes sincronizado
          -> variável de ambiente do contêiner
```

Endpoints privados, nomes de banco, região e URLs internas ficam em ConfigMap. Senhas de banco, `MASTER_KEY` e a chave interna ficam no Vault. O state do Terraform continua sensível por conter metadados da infraestrutura, embora não receba o conteúdo dos segredos gerados.

## Fluxo de analytics

1. `/evaluate` responde ao cliente sem aguardar analytics.
2. `evaluation-service` publica `user_id`, `flag_name`, `result` e `timestamp` na OCI Queue.
3. `analytics-service` faz long polling, valida o evento e grava `event_id`, `user_id`, `flag_name`, `result` e `occurred_at` no OCI NoSQL.
4. A mensagem só é confirmada depois da gravação. O ID da Queue é a chave primária, tornando a reentrega idempotente.

## Ambiente local

Docker Compose preserva a topologia exigida de cinco aplicações e quatro dependências locais. As integrações OCI permanecem desabilitadas localmente: o `evaluation-service` registra os eventos no log e o worker do `analytics-service` permanece desligado.
