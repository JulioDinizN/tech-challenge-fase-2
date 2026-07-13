# Relatório de Entrega

Formato final de submissão: PDF.

A fonte canônica do relatório é `docs/report.html`. Gere o PDF de avaliação com:

```bash
npm install
npm run report:install
npm run report:pdf
```

Saída gerada: `dist/delivery-report.pdf`.

## Identificação

- Grupo: 191
- Participante: Julio Cesar Diniz Nogueira
- Matrícula: RM373719
- Discord: Júlio César - RM373719

## Links da entrega

- Repositório: https://github.com/JulioDinizN/tech-challenge-fase-2
- Vídeo de demonstração: PENDENTE - substituir somente depois de validar que o link abre sem autenticação do professor.

## Arquitetura

- Diagrama geral: `docs/diagrams/overall-architecture.png`
- Status: `docs/diagrams/overall-architecture.drawio` é a fonte de verdade; o PNG é a exportação gerada para o relatório.

## Resumo da solução

- ambiente local: cinco aplicações, dois PostgreSQL, Redis e DynamoDB Local;
- cloud: OKE, OCIR, três OCI Database with PostgreSQL, OCI Cache, Queue e NoSQL;
- entrada: OCI Load Balancer e F5 NGINX Ingress Controller OSS;
- segurança: OCI Vault, Secrets Store CSI, Secrets Kubernetes e Workload Identity;
- escala: Metrics Server e HPAs de CPU para evaluation e analytics;
- automação: Terraform e scripts reproduzíveis de build, deploy, smoke, carga, evidência e destroy.

## Estado antes da gravação

- código, Kubernetes, documentação e scripts: preparados e validados localmente;
- Terraform: plan read-only aprovado com 53 creates, 0 changes e 0 destroys;
- recursos OCI e imagens OCIR: ainda não criados/publicados;
- evidências cloud, vídeo e URL final: dependem da janela autorizada de demonstração;
- roteiro completo: `docs/video-runbook.md`.

O PDF final não deve ser enviado enquanto o link do vídeo estiver sem preenchimento nesta seção ou em `docs/report.html`.

## Pontuação extra opcional

- Google Cloud Skills Boost: não realizado no momento. Caso a trilha seja concluída, adicionar o link público do perfil ou badge.
