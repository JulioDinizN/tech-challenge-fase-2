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

- `diagrams/overall-architecture.drawio` é a fonte editável de verdade;
- `diagrams/overall-architecture.png` é a única exportação versionada e usada pelo relatório;
- não edite o PNG manualmente; execute `npm run diagrams:export`;
- o script usa o CLI do draw.io Desktop, procura por padrão em `/Applications/draw.io.app/Contents/MacOS/draw.io` no macOS e aceita `DRAWIO_BIN` para outro caminho;
- o diagrama deve refletir o que foi realmente implantado e demonstrado.
