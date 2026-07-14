# Fixes And Decisions

Document changes required to make the imported microservices build, run, and integrate correctly. Keep Terraform and general infrastructure adjustments in the relevant `infra/` documentation instead of this file.

Use this format:

```text
Date:
Requirement:
Problem:
Decision:
Fix:
Verification:
```

## 2026-06-13 - Local Docker Compose Execution

Requirement: Analysis and containerization.

Problem: The imported services did not build or run cleanly in containers.

Root causes:

- `auth-service` had an invalid `go.mod` entry for `github.com/jackc/pgx/v4/stdlib`.
- `auth-service` imported the PostgreSQL driver as a normal import instead of a blank driver-registration import.
- `auth-service` and `evaluation-service` had unused or missing Go imports that failed Docker builds.
- The Go services had incomplete or missing `go.sum` checksum entries.
- `flag-service` and `targeting-service` pinned `psycopg2-binary==2.9.5`, which failed against PostgreSQL 16 SCRAM authentication.
- Flask 2.2.2 was not protected from incompatible Werkzeug 3 installs.
- `analytics-service` exited at import time without cloud queue/NoSQL environment variables, which prevented the required local 9-container Compose demo from staying up.
- `evaluation-service` needed a stable local API key before it could call the protected flag and targeting services.

Fix:

- Added Dockerfiles for all five services.
- Added service `.dockerignore` files.
- Added a root `docker-compose.yml` with five app containers and four dependency containers.
- Added a shared local PostgreSQL init script for `flag-service` and `targeting-service`.
- Fixed the Go module/import issues and generated missing `go.sum` files.
- Added optional `BOOTSTRAP_API_KEY` support to `auth-service` for local Compose and smoke tests.
- Added `ANALYTICS_WORKER_ENABLED=false` support so `analytics-service` can run its health endpoint locally without requiring cloud queue credentials.
- Upgraded `psycopg2-binary` to `2.9.9` for PostgreSQL 16 compatibility.
- Pinned `Werkzeug<3` for the Flask 2.2.2 services.

Verification:

- `docker compose build` completes for all five service images.
- `docker compose up -d --force-recreate` starts nine containers.
- `docker compose ps` shows the five app containers plus `auth-db`, `app-db`, `redis`, and `dynamodb-local`.
- Health checks pass for all five application services.
- A local smoke test validates the bootstrapped API key, creates a flag, creates a targeting rule, and evaluates the flag successfully through `evaluation-service`.

## 2026-07-09 - OCI Queue And NoSQL Application Integration

Requirement: Prepare the analytics event flow for the OCI infrastructure without deploying it and without breaking local development.

Problem: Terraform provisioned OCI Queue and OCI NoSQL resources, but `evaluation-service` and `analytics-service` still used the AWS SQS, DynamoDB, and credential APIs. OCI resources cannot be consumed by changing AWS endpoint variables because the request models, authentication, queue addressing, and NoSQL row formats are different.

Root causes:

- `evaluation-service` was coupled directly to the AWS SQS client.
- `analytics-service` expected the AWS SQS message dictionary and DynamoDB typed-attribute format.
- OCI Queue requires both the queue OCID and its queue-specific messages endpoint.
- OKE workloads need resource-principal authentication instead of static cloud credentials in the pods.
- The Terraform NoSQL schema uses `occurred_at`, while the former DynamoDB item used `timestamp`.
- The latest OCI Go SDK releases require a newer Go toolchain than the service's Go 1.21 baseline.

Decision:

- Use the native OCI SDKs and OKE workload identity for the future cloud runtime.
- Keep the analytics event JSON contract unchanged between producer and consumer.
- Use the OCI Queue message ID as the NoSQL `event_id`, making a redelivery overwrite the same primary-key row instead of creating a duplicate.
- Acknowledge a Queue message only after the NoSQL update succeeds; invalid events and OCI failures remain available for retry and eventual dead-letter handling.
- Preserve a cloud-independent local mode: evaluation logs events when no Queue OCID is configured, and the analytics worker remains disabled by `ANALYTICS_WORKER_ENABLED=false`.

Fix:

- Replaced the AWS SQS dependency in `evaluation-service` with an `AnalyticsEventPublisher` interface and an OCI Queue implementation.
- Added OKE workload identity, instance principal, and OCI config-file authentication modes.
- Pinned `github.com/oracle/oci-go-sdk/v65` to `v65.101.0`, which remains compatible with Go 1.21.
- Replaced `boto3` in `analytics-service` with the OCI Python SDK.
- Added OCI Queue long polling, OCI NoSQL row updates, post-write message acknowledgement, validation, and retry-safe failure behavior.
- Added producer and consumer unit tests.
- Removed obsolete AWS metadata environment variables from Compose and documented the OCI configuration and local fallback behavior.
- Updated the OCI infrastructure boundary documentation to show that application adaptation is complete while Kubernetes wiring and deployment remain pending.

Local compatibility:

- These changes do not require OCI to run the project locally.
- Docker Compose does not inject the placeholder OCI values from `.env.example` into either service.
- `evaluation-service` remains fully functional without `OCI_QUEUE_OCID`; only external analytics publication is skipped and logged.
- `analytics-service` continues serving `/health` with its worker disabled.
- DynamoDB Local remains in Compose only to preserve the nine-container challenge topology; the OCI-adapted worker does not use it.

Verification:

- `go test ./...` passes for `evaluation-service` using Go 1.21.
- `python -m unittest -v` passes both `analytics-service` message-processing tests inside its built image.
- `docker compose build evaluation-service analytics-service` completes successfully.
- An isolated `docker compose up -d --build --wait` starts all nine containers and reports all health checks passing.
- The local smoke flow validates the API key (`200`), creates a flag (`201`), creates a targeting rule (`201`), and evaluates it successfully (`200`, `result: true`).
- Runtime logs confirm `evaluation-service` uses `ANALYTICS_QUEUE_DISABLED` and `analytics-service` starts with its worker disabled.
- No Terraform plan/apply, OCI API call, image push, or cloud deployment was performed.

## 2026-07-09 - Configuração PostgreSQL compatível com OCI Vault

Requirement: Permitir que os três microsserviços relacionais usem os bancos gerenciados e os Secrets do Kubernetes/Vault sem quebrar o ambiente local.

Problem: `auth-service`, `flag-service` e `targeting-service` aceitavam somente `DATABASE_URL`. Para usar uma senha sincronizada do OCI Vault seria necessário montar uma URL completa com credencial dentro de um Secret, duplicando host, porta, usuário e banco e dificultando a separação entre configuração não secreta e segredo.

Root causes:

- o contrato importado concentrava configuração e senha em uma única string;
- Kubernetes não expande referências de Secret dentro do valor de outra variável;
- montar `DATABASE_URL` pelo Terraform colocaria o valor sensível no plano e no state;
- senhas com caracteres especiais exigem escaping correto quando incluídas em URL.

Decision:

- manter `DATABASE_URL` com prioridade para retrocompatibilidade local;
- quando ela não existir, aceitar `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` e `DB_SSLMODE`;
- manter host, porta, banco, usuário e SSL no ConfigMap e somente `DB_PASSWORD` no Secret;
- usar conexão TLS (`DB_SSLMODE=require`) como padrão do modo por componentes.

Fix:

- `auth-service` ganhou um construtor de DSN que valida os campos, aceita IPv6 e faz escaping seguro de usuário/senha;
- `flag-service` e `targeting-service` passaram a fornecer os parâmetros separados diretamente ao pool `psycopg2`, sem reconstruir URL com senha;
- foram adicionados testes de prioridade de `DATABASE_URL`, defaults, caracteres especiais, porta inválida e erros que não vazam senha;
- o Compose não foi alterado e continua injetando as mesmas `DATABASE_URL` com `sslmode=disable` para os PostgreSQL locais.

Local compatibility:

- quem usa `.env` ou Docker Compose não precisa trocar nenhuma variável;
- `DATABASE_URL` continua sendo escolhida antes de qualquer `DB_*`;
- o novo modo só é ativado no overlay OKE, onde a senha vem do OCI Vault CSI.

Verification:

- `go test ./...` passou no `auth-service` usando a imagem Go 1.21;
- os três testes unitários de configuração passaram no `flag-service`;
- os três testes unitários de configuração passaram no `targeting-service`;
- `terraform validate` e a renderização Kustomize confirmaram o contrato dos nomes usados pelo futuro deploy;
- as cinco imagens locais foram reconstruídas e os nove contêineres ficaram saudáveis;
- o smoke auth/flag/targeting/evaluation passou com status `200` e `result: true`;
- nenhum apply, push de imagem ou alteração cloud foi executado.

## 2026-07-14 - Compatibilidade dos contêineres e Workload Identity no OKE

Requirement: Executar os cinco microsserviços no OKE com usuário não root, segredos externos e acesso à OCI sem chaves estáticas.

Problem: As imagens funcionavam no Docker Compose, mas o OKE recusava iniciar os contêineres com `runAsNonRoot` porque os Dockerfiles declaravam um usuário por nome. Depois disso, o `evaluation-service` ainda não conseguia inicializar o provider de Workload Identity do OCI Go SDK sem os parâmetros de resource principal exigidos pelo SDK.

Root causes:

- o runtime CRI-O não consegue comprovar antecipadamente que um nome de usuário da imagem corresponde a um UID diferente de zero;
- `runAsNonRoot` exige um UID numérico verificável;
- o provider OKE do OCI Go SDK usa o token da ServiceAccount, mas também espera `OCI_RESOURCE_PRINCIPAL_VERSION` e a região no ambiente do contêiner;
- o ambiente local não fornece Workload Identity e deve continuar usando os fallbacks existentes.

Decision:

- executar todos os microsserviços com o UID numérico dedicado `10001`;
- manter os security contexts, filesystem somente leitura e capabilities removidas;
- fornecer ao `evaluation-service` a versão `2.2` e a região já existente no ConfigMap, sem adicionar credenciais ao pod;
- preservar os modos `instance_principal`, `config_file` e os fallbacks locais.

Fix:

- os cinco Dockerfiles agora criam o usuário de aplicação com UID/GID `10001` e terminam com `USER 10001`;
- o Deployment do `evaluation-service` define `OCI_RESOURCE_PRINCIPAL_VERSION=2.2` e mapeia `OCI_RESOURCE_PRINCIPAL_REGION` a partir de `OCI_REGION`;
- as imagens corrigidas foram publicadas no OCIR com uma tag imutável de demonstração.

Local compatibility:

- Docker Compose continua usando as mesmas imagens, portas e variáveis;
- o UID numérico não altera o usuário efetivo nem exige privilégios adicionais;
- as variáveis de Workload Identity existem somente no manifest Kubernetes;
- sem `OCI_QUEUE_OCID`, o `evaluation-service` continua registrando o evento localmente em vez de acessar OCI.

Verification:

- o OKE aceitou as cinco imagens com `runAsNonRoot` e deixou os cinco Deployments `Ready`;
- os logs do `evaluation-service` confirmaram conexão ao OCI Cache e inicialização do publicador OCI Queue;
- o smoke externo pelo Ingress retornou `200` na validação e avaliação e `201` na primeira criação de flag e regra;
- o evento da avaliação apareceu na tabela OCI NoSQL após o consumo da Queue;
- sob carga, os HPAs de evaluation e analytics criaram quatro réplicas prontas de cada serviço;
- após a carga e a redução das réplicas, um novo smoke externo terminou com sucesso.
