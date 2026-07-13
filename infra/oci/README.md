# OCI Terraform infrastructure

This directory defines the cloud infrastructure required to run ToggleMaster on Oracle Cloud Infrastructure. Formatting, validation and a fresh read-only plan against the configured Ashburn tenancy pass. The current preview contains **53 creates, 0 changes and 0 destroys**, and **has not been applied**.

## Challenge mapping

| Phase 2 requirement | Terraform resource |
| --- | --- |
| Kubernetes cluster and worker nodes | OKE cluster and managed node pool |
| Five image repositories | Five private OCIR repositories |
| Three independent PostgreSQL databases | Three OCI Database with PostgreSQL systems |
| Redis cache | One non-sharded OCI Cache cluster |
| Standard message queue | One OCI Queue |
| Analytics NoSQL table | One OCI NoSQL table keyed by `event_id` |
| External ingress network | Public load-balancer subnet and NSG for the later Nginx deployment |
| Segredos da aplicação | OCI Vault `DEFAULT`, chave AES-256 de software e oito segredos gerados pelo OCI |
| Secure service access | OKE Workload Identity para Queue, NoSQL e o provider CSI do Vault |

The Terraform also creates a VCN, an internet gateway, a NAT gateway, a service gateway, public API/load-balancer subnets, private worker/data subnets, route tables, and network security groups.

## Deliberate boundaries

O Terraform provisiona recursos OCI e seus metadados. Deliberadamente, ele não:

- build or push the five images;
- instala Metrics Server, Secrets Store CSI ou NGINX Ingress;
- aplica manifests Kubernetes;
- cria bancos/schemas dentro dos três PostgreSQL;
- recebe o token do OCIR ou gera o image pull Secret;
- executa comandos locais por `local-exec`.

Essas tarefas estão em `k8s/` e `scripts/`. Separar a infraestrutura do deploy mantém o plano legível, permite gravar cada etapa e evita armazenar credenciais locais no state.

## Architecture decisions

- The OKE API endpoint is public but restricted to `api_allowed_cidrs`; worker and data resources have no public IPs.
- OKE uses the Flannel overlay CNI to keep the initial student deployment small and straightforward.
- The default is an Enhanced OKE cluster because OCI workload identity and node cycling are enhanced-cluster features. A Basic cluster is possible only when `create_workload_identity_policy = false`; the applications would then need a different authentication design, such as instance principals.
- O F5 NGINX Ingress Controller OSS cria dinamicamente um Load Balancer flexível de 10 Mbps na subnet pública e usa os NSGs expostos no output `network`. Esse Load Balancer não pertence ao state do Terraform; o teardown o remove e espera sua exclusão antes do `terraform destroy`.
- O Terraform cria um Vault do tipo `DEFAULT` e uma chave `SOFTWARE`, opções dentro do Always Free, em vez de um Virtual Private Vault pago.
- O OCI Vault gera três senhas administrativas de PostgreSQL, três senhas de aplicação, uma `MASTER_KEY` e uma chave interna. O conteúdo não é informado ao Terraform, não aparece em `.tfvars` e não é exportado; somente nomes, OCIDs e regras de geração fazem parte do plano/state.
- Cada PostgreSQL recebe seu próprio segredo administrativo e versão atual. No cluster, Jobs criam usuários de aplicação restritos; os Deployments não recebem a senha administrativa.
- OCI Cache is private and TLS-only. The future application value should use the output `redis.tls_url` (`rediss://`).
- The default one-node Redis cluster is a cost-conscious development setting, not a high-availability topology. OCI recommends at least three nodes for reliability; set `redis_node_count = 3` before a production-style deployment if the budget permits.
- Queue producer and consumer access is separated with `queue-push` and `queue-pull`; analytics receives row-level NoSQL access. Uma policy separada na mesma resource autoriza somente a ServiceAccount do provider CSI, em `kube-system`, a usar segredos do Vault criado pelo stack.
- PostgreSQL, Redis, and OKE sizes are variables because service availability, quotas, and cost differ by tenancy and region.

## Prerequisites for a future plan

1. Terraform 1.6 or newer and OCI CLI installed.
2. An OCI CLI profile with permission to manage networking, OKE, OCIR, PostgreSQL, Cache, Queue, NoSQL, and IAM policies in the chosen compartment.
3. A compartment and a supported OCI region.
4. Limites suficientes para três PostgreSQL, um OCI Cache, workers OKE, Load Balancer e rede.
5. Estimativa de custo revisada. PostgreSQL, Cache, workers e Load Balancer podem consumir o crédito de US$ 300; Vault `DEFAULT`, uma chave de software e oito segredos cabem nos limites Always Free documentados pela Oracle.
6. Um backend remoto privado e versionado para o state antes do primeiro apply real.

## Local development validation (safe; no deployment)

These commands do not create cloud resources:

```bash
cd infra/oci
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

The provider is pinned in `versions.tf`, and `.terraform.lock.hcl` is committed for reproducibility.

## Prepare inputs later

Copy the example without committing the resulting file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Confirm current OKE versions and images instead of trusting the example placeholders:

```bash
oci ce cluster-options get \
  --cluster-option-id all \
  --compartment-id <compartment-ocid> \
  --profile <profile>

oci ce node-pool-options get \
  --node-pool-option-id all \
  --compartment-id <compartment-ocid> \
  --node-pool-k8s-version <kubernetes-version> \
  --profile <profile>
```

Set `node_image_id` to an OKE image that matches both the selected Kubernetes version and node shape. Terraform preconditions reject unsupported versions, shapes, and image IDs during planning.

## Preview the infrastructure without deploying

After replacing every value in the ignored `terraform.tfvars`, generate and inspect a saved plan:

```bash
terraform plan \
  -input=false \
  -out=togglemaster.tfplan

terraform show togglemaster.tfplan
```

Planning reads OCI metadata to validate current regions, availability domains, Kubernetes versions, node images, and shapes, but it does not create resources. Both `terraform.tfvars` and `*.tfplan` are ignored by Git.

O plano cria o Vault e todos os segredos; não existe mais OCID fictício de segredo em `terraform.tfvars`. Ainda assim, nunca aplique um plano antigo: gere um novo plano depois de qualquer alteração, revise a quantidade de recursos e confira preços/quotas no Console OCI.

## Remote state before the first apply

Real state can contain sensitive infrastructure metadata. Create a versioned, private OCI Object Storage bucket outside this stack, then:

```bash
cp backend.tf.example backend.tf
terraform init -migrate-state
```

Edit `backend.tf` first. Do not place OCI keys or tokens in it; use the OCI profile or environment authentication. The native OCI backend provides state locking.

## Future deployment workflow (not executed now)

Depois dos pré-requisitos, revisão dos inputs e backend remoto, gere novamente o plano em vez de aplicar qualquer preview de desenvolvimento:

```bash
terraform plan -out=togglemaster.tfplan
terraform show togglemaster.tfplan
terraform apply togglemaster.tfplan
```

Applying can create billable resources. A human must review the saved plan and OCI pricing before the final command.

Depois do apply autorizado:

1. execute `terraform output -raw kubeconfig_command` e rode o comando exibido;
2. defina `IMAGE_TAG`, `OCIR_USERNAME` e `OCIR_AUTH_TOKEN` somente no shell;
3. use `scripts/build-push-images.sh` e `scripts/deploy-oke.sh`;
4. execute `scripts/smoke-oke.sh` e `scripts/load-test-oke.sh` e registre no vídeo o Ingress, os HPAs e a persistência;
5. execute `scripts/destroy-oci.sh` ao finalizar.

O output `vault` contém somente o OCID do Vault e os nomes dos segredos; `deployment_context`, `network`, `postgresql_systems`, `redis`, `evaluation_queue`, `analytics_table` e `ocir_repositories` alimentam a renderização. Terraform não altera o kubeconfig nem lê o conteúdo dos segredos.

## State e ciclo de vida dos segredos

Mesmo sem valores secretos, trate o state como confidencial porque ele registra OCIDs, endpoints privados e topologia. O backend nativo OCI deve usar bucket privado, versionamento e locking.

Na destruição, Vault, chaves e segredos entram nas janelas de exclusão programada exigidas pelo OCI. Eles ficam inacessíveis, mas podem continuar aparecendo como `PENDING_DELETION`; os componentes pagos devem ser conferidos separadamente no Cost Analysis.

## Referências oficiais

- [OCI Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm): limites gratuitos de Vault, chaves de software e segredos.
- [Terraform `oci_vault_secret`](https://docs.oracle.com/en-us/iaas/tools/terraform-provider-oci/latest/docs/r/vault_secret.html): geração automática e outputs de metadados.
- [Terraform `oci_psql_db_system`](https://docs.oracle.com/en-us/iaas/tools/terraform-provider-oci/latest/docs/r/psql_db_system.html): senha por Vault Secret e versão.
- [OCI Secrets Store CSI Driver Provider](https://github.com/oracle/oci-secrets-store-csi-driver-provider/blob/main/GettingStarted.md): Workload Identity, sincronização de Secrets e rotação.
- [Anotações do OCI Load Balancer](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingloadbalancer_topic-Summaryofannotations.htm): subnet, NSGs e shape flexível.
- [Pull de imagens privadas do OCIR no OKE](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengpullingimagesfromocir.htm): token e `imagePullSecrets`.
- [Instalação do F5 NGINX Ingress Controller OSS](https://docs.nginx.com/nginx-ingress-controller/install/helm/open-source/): chart OCI usado pelo script.
