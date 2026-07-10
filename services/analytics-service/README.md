# analytics-service (Python)

Worker de analytics do ToggleMaster. Ele faz long polling no OCI Queue, grava os eventos no OCI NoSQL Database e só remove a mensagem da fila depois que a escrita termina com sucesso. O endpoint `/health` existe para health checks.

## Execução local

O worker deve permanecer desligado quando não houver acesso ao OCI:

```env
PORT=8005
ANALYTICS_WORKER_ENABLED=false
```

Assim, o serviço e seu health check funcionam sem credenciais ou recursos cloud:

```bash
pip install -r requirements.txt
gunicorn --bind 0.0.0.0:8005 app:app
curl http://localhost:8005/health
```

Resposta esperada:

```json
{"provider":"disabled","status":"ok","worker_enabled":false}
```

O `docker-compose.yml` da raiz já usa esse modo.

## Configuração OCI/OKE

O pod deve usar a service account `analytics-service`, autorizada pela policy de workload identity criada pelo Terraform.

```env
ANALYTICS_WORKER_ENABLED=true
OCI_AUTH_MODE=workload_identity
OCI_REGION=<regiao-oci>
OCI_QUEUE_OCID=ocid1.queue...
OCI_QUEUE_MESSAGES_ENDPOINT=https://cell-1.queue.messaging.<regiao>.oci.oraclecloud.com
OCI_NOSQL_TABLE=ToggleMasterAnalytics
OCI_COMPARTMENT_OCID=ocid1.compartment...
```

`OCI_COMPARTMENT_OCID` é obrigatório quando `OCI_NOSQL_TABLE` contém o nome da tabela. Ele pode ser omitido quando a tabela é configurada diretamente pelo OCID.

Modos alternativos:

- `OCI_AUTH_MODE=instance_principal` em uma instância OCI autorizada;
- `OCI_AUTH_MODE=config_file`, com `OCI_CONFIG_FILE` e `OCI_CONFIG_PROFILE` opcionais.

Os valores devem vir dos outputs Terraform `evaluation_queue` e `analytics_table`. Com workload identity, não há chave OCI estática no pod.

O serviço não possui segredo próprio da aplicação. A ServiceAccount `analytics-service` recebe somente as permissões OCI de consumo da fila e acesso às linhas NoSQL por Workload Identity.

## Persistência e reentrega

O ID da mensagem OCI é usado como `event_id`, tornando uma reentrega idempotente para a chave primária da tabela. A linha possui:

- `event_id`
- `user_id`
- `flag_name`
- `result`
- `occurred_at`

Eventos inválidos ou falhas no OCI NoSQL não são reconhecidos; a mensagem fica disponível para nova tentativa conforme a política da fila.
