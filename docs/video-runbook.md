# Roteiro de provisionamento, vídeo e entrega

Este roteiro separa preparação, gravação e encerramento. Os comandos de mutação só podem ser usados depois da autorização explícita para criar recursos OCI.

## 1. Antes de criar recursos

1. Garanta que o Git esteja limpo e use uma tag de imagem imutável:

   ```bash
   git status --short
   export IMAGE_TAG="$(git rev-parse --short=12 HEAD)"
   ```

   Em seguida, confira as ferramentas. Nesta máquina, Helm deve ser instalado antes da janela cloud; `hey` é opcional:

   ```bash
   ./scripts/check-cloud-prerequisites.sh
   # macOS, se necessário: brew install helm
   ```

2. Execute a validação local:

   ```bash
   ./scripts/validate-delivery.sh
   docker compose up -d --build --wait
   docker compose ps
   ```

3. Confira `terraform.tfvars`, quotas e preços dos itens pagos: três PostgreSQL, OCI Cache, workers OKE e Load Balancer.
4. Configure o backend remoto privado descrito em `infra/oci/README.md`.
5. Gere um plano novo; nunca reutilize `togglemaster.tfplan` antigo:

   ```bash
   terraform -chdir=infra/oci init
   terraform -chdir=infra/oci plan -input=false -out=togglemaster.tfplan
   terraform -chdir=infra/oci show togglemaster.tfplan
   ```

6. Revise se o plano contém apenas criações esperadas e nenhum destroy. O plano deve incluir Vault `DEFAULT`, uma chave de software e oito segredos gerados; nenhum valor de senha deve aparecer.

## 2. Provisionamento autorizado antes da gravação

Aplicar a infraestrutura pode consumir créditos. Faça isto fora da gravação, pois OKE e bancos podem demorar:

```bash
terraform -chdir=infra/oci apply togglemaster.tfplan
terraform -chdir=infra/oci output -raw kubeconfig_command
```

Execute manualmente o comando de kubeconfig mostrado no segundo comando e confirme o contexto:

```bash
kubectl config current-context
kubectl cluster-info
```

Carregue o token do OCIR sem exibi-lo ou salvá-lo:

```bash
export OCIR_USERNAME='<namespace>/<usuario>'
read -rs OCIR_AUTH_TOKEN && export OCIR_AUTH_TOKEN
```

Publique e implante:

```bash
./scripts/build-push-images.sh
./scripts/deploy-oke.sh
./scripts/smoke-oke.sh
```

O deploy instala versões fixadas dos add-ons, cria o Pull Secret no cluster, renderiza apenas outputs não secretos, executa os três Jobs de banco e espera os cinco rollouts.

## 3. Ensaio obrigatório

Antes de gravar, confirme:

```bash
kubectl -n togglemaster get pods,services,ingress,hpa,jobs
./scripts/smoke-oke.sh
./scripts/load-test-oke.sh
```

Em outro terminal, observe:

```bash
kubectl -n togglemaster get hpa,pods -w
```

No Console OCI, deixe abertas as telas de Queue e NoSQL. Confirme que eventos chegam à tabela e que as métricas do analytics respondem à carga. Se o HPA de analytics não subir com a primeira configuração, aumente duração/concurrency e valide antes de gravar; não afirme escalabilidade que não foi observada.

## 4. Roteiro do vídeo (máximo 20 minutos)

| Tempo | Demonstração |
| --- | --- |
| 00:00-01:00 | Identificação, objetivo e repositório |
| 01:00-03:30 | Diagrama: entrada HTTP temporária, OKE, cinco serviços, três PostgreSQL, Redis, Queue, NoSQL, Vault/CSI e Workload Identity |
| 03:30-05:30 | `docker compose ps`: cinco aplicações + quatro dependências; executar o smoke local |
| 05:30-07:30 | Terraform: módulos/resources, plano revisado e outputs sem mostrar OCIDs completos |
| 07:30-09:30 | OKE/OCIR: cinco Deployments/pods prontos, Services ClusterIP, Jobs concluídos, Secrets apenas por nome |
| 09:30-11:30 | Ingress: endereço do Load Balancer e `scripts/smoke-oke.sh` retornando avaliação `true` |
| 11:30-14:00 | Metrics Server e HPA de evaluation durante carga; mostrar aumento de réplicas |
| 14:00-16:30 | Queue recebendo eventos, HPA de analytics e consumo; mostrar linhas persistidas no OCI NoSQL |
| 16:30-18:30 | Papel de cada armazenamento e decisões: async, idempotência, Secrets, usuários restritos, compatibilidade local |
| 18:30-19:30 | Desafios/correções em `docs/fixes.md`, evidências e links da entrega |
| 19:30-20:00 | Encerramento e informação de que o teardown será executado após a gravação |

Não mostre `terraform.tfvars`, state, kubeconfig, conteúdo de Secrets, token OCIR ou terminal com variáveis sensíveis.

## 5. Evidências e PDF

Após a gravação:

```bash
./scripts/capture-evidence.sh
```

Revise `evidence/runtime/` antes de copiar qualquer trecho sanitizado para `evidence/`. Depois:

1. envie o vídeo e obtenha uma URL pública/compartilhável;
2. substitua `PENDENTE` em `docs/delivery-report.md` e `docs/report.html`;
3. adicione somente evidências sem OCIDs privados ou segredos;
4. gere e abra o PDF:

   ```bash
   npm install
   npm run report:install
   npm run report:pdf
   FINAL_DELIVERY=1 ./scripts/validate-delivery.sh
   ```

O arquivo final é `dist/delivery-report.pdf`. O diretório `dist/` é ignorado pelo Git; envie o PDF diretamente ao professor junto com os links requeridos.

## 6. Encerramento de custos

Somente depois de confirmar vídeo e evidências:

```bash
CONFIRM_DESTROY=togglemaster ./scripts/destroy-oci.sh
```

O script exclui workloads e NGINX, aguarda o Load Balancer criado pelo Kubernetes desaparecer, remove add-ons e chama `terraform destroy`. Ao final, confira Cost Analysis e as listas de PostgreSQL, Cache, OKE, Compute e Load Balancers. Vault, chaves e segredos ficam em exclusão programada pelo OCI, mas dentro dos limites Always Free.
