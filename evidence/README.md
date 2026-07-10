# Evidências

Armazene aqui somente saídas e imagens revisadas usadas no vídeo/relatório.

`scripts/capture-evidence.sh` escreve primeiro em `evidence/runtime/`, que é ignorado pelo Git. Revise, recorte e oculte dados privados antes de copiar uma evidência para este diretório.

Nunca versionar:

- conteúdo de Secrets, token OCIR, senha, chave OCI ou kubeconfig;
- `terraform.tfvars`, state ou plano salvo;
- OCIDs completos de tenancy/compartment quando não forem necessários;
- screenshots do Console com email, saldo, conta ou dados privados;
- logs que contenham header `Authorization`.

Evidências esperadas: nove contêineres locais, cinco pods prontos, Ingress/LB acessível, HPAs escalando, Jobs concluídos, evento consumido da Queue e linha persistida no NoSQL.
