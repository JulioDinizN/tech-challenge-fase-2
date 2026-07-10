# Scripts

Automação reproduzível da validação e da janela de demonstração. Scripts que alteram OCI/Kubernetes existem para execução futura; nenhum foi executado durante o desenvolvimento.

| Script | Finalidade | Altera cloud |
| --- | --- | --- |
| `validate-delivery.sh` | Terraform validate, render Kustomize e testes locais | Não |
| `check-cloud-prerequisites.sh` | Confere CLIs antes da janela cloud | Não |
| `render-oci-manifests.py` | Substitui outputs não secretos no overlay | Não |
| `build-push-images.sh` | Build `linux/amd64` e push das cinco imagens | Sim, OCIR |
| `install-oke-addons.sh` | CSI, provider OCI, Metrics Server e NGINX | Sim, OKE/LB |
| `deploy-oke.sh` | Pull Secret, manifests, Jobs e espera dos rollouts | Sim, OKE |
| `smoke-oke.sh` | Fluxo auth/flag/rule/evaluate via Ingress | Sim, dados da aplicação |
| `load-test-oke.sh` | Carga para HPA e Queue | Sim, tráfego/dados |
| `capture-evidence.sh` | Coleta estado Kubernetes sem ler Secrets | Somente leitura |
| `destroy-oci.sh` | Remove workloads/LB, add-ons e executa destroy | Sim, destrutivo |

## Credenciais efêmeras

Primeiro execute `./scripts/check-cloud-prerequisites.sh`. O deploy requer Helm; `hey` é opcional porque o teste de carga possui fallback Python sem dependências.

Antes de build/deploy, exporte no shell — nunca em `.env`, histórico compartilhado ou Git:

```bash
export IMAGE_TAG="$(git rev-parse --short=12 HEAD)"
export OCIR_USERNAME='<namespace>/<usuario>'
read -rs OCIR_AUTH_TOKEN && export OCIR_AUTH_TOKEN
```

O token cria `ocir-pull-secret` diretamente no cluster porque o kubelet precisa dele antes de iniciar os contêineres. As chaves da aplicação e senhas de banco vêm do OCI Vault.

## Ordem autorizada

```bash
./scripts/build-push-images.sh
./scripts/deploy-oke.sh
./scripts/smoke-oke.sh
./scripts/load-test-oke.sh
./scripts/capture-evidence.sh
```

Use `docs/video-runbook.md` durante a gravação. Para encerrar custos, execute o teardown somente após confirmar a evidência:

```bash
CONFIRM_DESTROY=togglemaster ./scripts/destroy-oci.sh
```

O teardown remove primeiro Ingress/NGINX e espera o Load Balancer dinâmico desaparecer antes de `terraform destroy`, evitando que um recurso criado pelo controller fique órfão.
