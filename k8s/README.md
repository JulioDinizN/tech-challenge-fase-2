# Kubernetes

Manifests da entrega Kubernetes do ToggleMaster.

## Recursos implementados

- namespace `togglemaster`;
- ServiceAccounts por workload, incluindo os nomes exatos exigidos pelas policies: `evaluation-service` e `analytics-service`;
- cinco Deployments e cinco Services `ClusterIP`;
- ConfigMap de endpoints e configuração não secreta;
- templates de Secret com valores base64 fictícios, excluídos do Kustomize;
- probes, requests/limits e security contexts;
- Ingress para `/validate`, `/flags`, `/rules` e `/evaluate`;
- HPAs `autoscaling/v2` para avaliação e analytics;
- overlay OCI com imagens OCIR, outputs Terraform, OCI Vault CSI e três Jobs de schema.

## Organização

`base/` é independente de provedor e renderiza sem cluster. Ele mantém imagens e endpoints de substituição e referencia Secrets que somente o ambiente fornece. Os arquivos `base/secrets/*.example.yaml` usam valores fictícios, ficam fora do `kustomization.yaml` e nunca devem ser aplicados.

`overlays/oci/` fornece imagens, endpoints, integração OCI Vault CSI e os Jobs de inicialização necessários ao OKE. Os SQLs em `overlays/oci/database/` espelham os schemas dos microsserviços; qualquer mudança de schema deve ser sincronizada e validada nos dois locais.

## Renderização segura

Sem acesso ao cluster:

```bash
kubectl kustomize k8s/base >/tmp/togglemaster-base.yaml
kubectl kustomize k8s/overlays/oci >/tmp/togglemaster-oci-template.yaml
```

O segundo comando preserva tokens `__OCI_*__`. Depois do `terraform apply`, o script abaixo substitui apenas outputs não secretos e grava um arquivo ignorado pelo Git:

```bash
IMAGE_TAG=<git-sha> ./scripts/render-oci-manifests.py
```

Os valores do Vault não entram no YAML. Eles são buscados em runtime pelo provider CSI e sincronizados nos Secrets esperados pelos Deployments.

## Add-ons

`scripts/install-oke-addons.sh` instala versões fixadas do Secrets Store CSI Driver, provider OCI Vault, Metrics Server e F5 NGINX Ingress Controller OSS. O script também passa ao Service `LoadBalancer` a subnet e os NSGs criados pelo Terraform.

Não execute os scripts de instalação/deploy sem infraestrutura aplicada, kubeconfig correto e autorização explícita.
