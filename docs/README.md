# Documentation

This folder contains material for the final review.

Recommended files:

- `report.html` - canonical source for the final PDF report.
- `architecture.md`
- `requirements-progress.md`
- `fixes.md`
- `demo-script.md`
- `delivery-report.md`

Generated report output:

- `dist/delivery-report.pdf` is generated from `docs/report.html`.
- The generated PDF is ignored by Git through the existing `dist/` rule.
- Run `npm install`, `npm run report:install`, and `npm run report:pdf` from the repository root.
- `npm run report:pdf` regenerates diagram exports from draw.io before creating the PDF.

Diagrams:

- Keep draw.io source files and exported report images in `docs/diagrams/`.
- Treat `docs/diagrams/overall-architecture.drawio` as the source of truth.
- Do not hand-edit exported SVG/PNG files; run `npm run diagrams:export`.
