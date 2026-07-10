# Kubernetes Overlays

Configurações específicas do ambiente.

- `oci/`: overlay completo para OKE/OCIR, com placeholders preenchidos por `scripts/render-oci-manifests.py`, integração OCI Vault CSI e Jobs de inicialização dos três PostgreSQL.

Os SQLs em `oci/database/` espelham os schemas dos microsserviços. Mudanças de schema precisam ser aplicadas nos dois locais e verificadas antes da implantação.
