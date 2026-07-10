# evaluation-service (Go)

Serviço do caminho crítico de avaliação do ToggleMaster. Ele consulta regras em Redis e nos serviços de flags/targeting, devolve a decisão ao cliente e publica o evento de analytics de forma assíncrona no OCI Queue.

## Execução local

O OCI Queue é opcional localmente. Sem `OCI_QUEUE_OCID`, o serviço continua avaliando flags normalmente e registra o evento no log com `ANALYTICS_QUEUE_DISABLED`.

Variáveis mínimas:

```env
PORT=8004
REDIS_URL=redis://localhost:6379
FLAG_SERVICE_URL=http://localhost:8002
TARGETING_SERVICE_URL=http://localhost:8003
SERVICE_API_KEY=tm_key_local_development_only
```

Execução:

```bash
go mod tidy
go run .
```

Ou use o `docker-compose.yml` da raiz, que já deixa o publicador OCI desabilitado.

## Configuração OCI/OKE

O pod do serviço precisa usar a service account `evaluation-service`, autorizada pela policy de workload identity criada pelo Terraform.

```env
OCI_QUEUE_OCID=ocid1.queue...
OCI_QUEUE_MESSAGES_ENDPOINT=https://cell-1.queue.messaging.<regiao>.oci.oraclecloud.com
OCI_AUTH_MODE=workload_identity
```

Modos alternativos de autenticação, úteis fora do OKE:

- `OCI_AUTH_MODE=instance_principal` em uma instância OCI autorizada;
- `OCI_AUTH_MODE=config_file`, com `OCI_CONFIG_FILE` e `OCI_CONFIG_PROFILE` opcionais.

Os valores de fila vêm do output Terraform `evaluation_queue`. Não é necessário fornecer chaves OCI ao pod quando workload identity estiver configurada.

`SERVICE_API_KEY` é sincronizada do OCI Vault no Secret Kubernetes `evaluation-runtime-secrets`. Ela é o mesmo valor usado por `BOOTSTRAP_API_KEY` no `auth-service`; o valor não aparece nos manifests nem nos outputs Terraform.

## Endpoints

```bash
curl http://localhost:8004/health
curl "http://localhost:8004/evaluate?user_id=user-123&flag_name=enable-new-dashboard"
```

O evento publicado mantém o contrato:

```json
{
  "user_id": "user-123",
  "flag_name": "enable-new-dashboard",
  "result": true,
  "timestamp": "2026-07-09T12:00:00Z"
}
```
