# Kubernetes Base

Base independente de provedor com a estrutura exigida pela entrega. Ela renderiza sem cluster, mas contém endpoints/imagens de substituição e referencia Secrets que não existem até um ambiente fornecer os valores.

Os arquivos em `secrets/*.example.yaml` são somente documentação, usam o base64 de `REPLACE_ME` e não fazem parte de `kustomization.yaml`. Nunca aplique esses templates.

O overlay OCI fornece imagens, endpoints e segredos. Para outro provedor, crie um overlay equivalente sem alterar os contratos da base.
