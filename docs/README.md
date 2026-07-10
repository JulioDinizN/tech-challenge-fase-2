# Documentação

Material em português para revisão e entrega:

- `report.html`: fonte canônica do PDF final;
- `delivery-report.md`: identificação e links em formato texto;
- `architecture.md`: explicação fiel ao diagrama e à implementação;
- `fixes.md`: somente mudanças necessárias nos microsserviços;
- `local-development.md`: Compose e smoke local;
- `video-runbook.md`: provisionamento autorizado, roteiro de até 20 minutos, evidências, PDF e destroy.

Saída gerada:

- `dist/delivery-report.pdf` é gerado de `docs/report.html` e ignorado pelo Git;
- execute `npm install`, `npm run report:install` e `npm run report:pdf` na raiz;
- `report:pdf` regenera os diagramas antes do PDF;
- não entregue um PDF que ainda contenha `PENDENTE`.

Diagramas:

- mantenha o `.drawio` como fonte de verdade;
- não edite PNG/SVG manualmente; execute `npm run diagrams:export`;
- o diagrama deve refletir o que foi realmente implantado e demonstrado.
