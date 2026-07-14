# POSTECH Tech Challenge - Fase 2

Repositório de entrega do ToggleMaster, Grupo 76. O projeto reúne os cinco microsserviços, o ambiente local exigido com nove contêineres e a infraestrutura reproduzível para Oracle Cloud Infrastructure (OCI).

## Estado da entrega

| Etapa | Estado |
| --- | --- |
| Dockerfiles e Docker Compose local | Implementado e validado |
| Adaptação Queue/NoSQL para OCI | Implementada com fallback local |
| Terraform de rede, OKE, OCIR e dados | Aplicado em OCI com state remoto privado |
| OCI Vault e segredos gerados | Provisionados e consumidos via CSI/Workload Identity |
| Kubernetes base e overlay OCI | Implantados e validados no OKE |
| Scripts de build, deploy, smoke, carga e destroy | Implementados; fluxo cloud validado, destroy ainda não executado |
| Evidências técnicas cloud | Pods, Ingress, HPA, Queue e NoSQL validados |
| Vídeo e link final no PDF | Gravação concluída; link adicionado e PDF final gerado |

O ambiente temporário de demonstração está provisionado. Os cinco Deployments estão prontos, o Ingress responde pelo OCI Load Balancer, os HPAs escalaram sob carga e um evento do smoke foi persistido no OCI NoSQL. A gravação foi concluída; preserve o ambiente somente até confirmar o upload e o PDF final, então use o teardown ordenado e confira os custos no Console OCI.

## Estrutura

```text
.
|-- services/                 # Código e Dockerfile dos cinco microsserviços
|-- docker/                   # Inicialização dos bancos locais
|-- docker-compose.yml        # Ambiente local de nove contêineres
|-- k8s/                      # Base Kubernetes e overlay OCI/OKE
|-- infra/oci/                # Infraestrutura OCI em Terraform
|-- scripts/                  # Validação, deploy, testes e teardown
`-- docs/                     # Arquitetura, correções e relatório
```

## Fluxo de execução

1. Validar localmente com `./scripts/validate-delivery.sh` e Docker Compose.
2. Revisar custos, quotas, `terraform.tfvars` e o novo `terraform plan`.
3. Após autorização explícita, aplicar o Terraform e criar o kubeconfig do OKE.
4. Publicar as cinco imagens com tag imutável no OCIR.
5. Implantar add-ons e workloads com `scripts/deploy-oke.sh`.
6. Executar smoke test, carga, evidências e gravar o vídeo de até 20 minutos.
7. Inserir o link do vídeo em `docs/report.html`, gerar o PDF final e revisar placeholders.
8. Remover primeiro os recursos Kubernetes/LB e depois executar o `terraform destroy` pelo script documentado.

## Execução local

```bash
cp .env.example .env
docker compose up --build
```

O ambiente mantém exatamente a topologia local exigida:

- cinco contêineres de aplicação;
- dois PostgreSQL, um Redis e um DynamoDB Local.

As adaptações para Vault e OCI não quebram o desenvolvimento local: `DATABASE_URL` continua com prioridade; Queue e worker OCI permanecem opcionais no Compose. Consulte `docs/local-development.md`.

## Infraestrutura OCI

O Terraform em `infra/oci/` cobre VCN, OKE, cinco repositórios OCIR, três sistemas OCI Database with PostgreSQL, OCI Cache, Queue, NoSQL, Vault, chave AES de software, oito segredos gerados pelo OCI e policies de Workload Identity.

O overlay `k8s/overlays/oci/` transforma outputs não secretos do Terraform em ConfigMaps, referências de imagem e `SecretProviderClass`. O Secrets Store CSI sincroniza os valores do Vault em Secrets nativos do Kubernetes; nenhum valor secreto é renderizado ou versionado.

Consulte `infra/oci/README.md`, `k8s/README.md` e `scripts/README.md` para operação, evidências e teardown.

## Origem dos microsserviços

The initial service source code was imported from the public FIAP ToggleMaster repositories:

| Service | Source | Imported commit |
| --- | --- | --- |
| auth-service | https://github.com/FIAP-TCs/auth-service | `56e447f83409bf35b22ef04a9e39c2e30df9af33` |
| flag-service | https://github.com/FIAP-TCs/flag-service | `21052b1abcf209ea6848350bdd9928b80b7f86fe` |
| targeting-service | https://github.com/FIAP-TCs/targeting-service | `dd9568a583fa409b88a446685779d9e581282fd2` |
| evaluation-service | https://github.com/FIAP-TCs/evaluation-service | `5e8ade059f69650d2e8cfbefad0a83cfac25f0a9` |
| analytics-service | https://github.com/FIAP-TCs/analytics-service | `212d7e9b7e50f881c4022bc9e8d2722f08a2a3e2` |

Cada serviço foi importado em `services/` sem seu diretório `.git`, permitindo versionar a entrega completa em um único repositório. As mudanças necessárias nos microsserviços estão registradas em `docs/fixes.md`; ajustes gerais de infraestrutura ficam documentados em `infra/` e `k8s/`.
