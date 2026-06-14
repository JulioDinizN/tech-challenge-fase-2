# Diagrams

Store draw.io source files and exported images for the delivery report here.

`overall-architecture.drawio` is the source of truth. Do not hand-edit `overall-architecture.svg` or `overall-architecture.png`; regenerate them from the draw.io source.

Expected files:

- `overall-architecture.drawio` - editable draw.io source of truth.
- `overall-architecture.svg` - generated vector export with embedded diagram XML.
- `overall-architecture.png` - generated report-ready image export with embedded diagram XML.
- `request-flow.drawio`, if needed
- `request-flow.png`, if needed

Regenerate exports from the repository root with:

```bash
npm run diagrams:export
```

The export script uses the draw.io desktop CLI, defaults to `/Applications/draw.io.app/Contents/MacOS/draw.io` on macOS, and can be overridden with `DRAWIO_BIN`.

The PDF generator reads local image exports from this folder through `docs/report.html`. `npm run report:pdf` runs `npm run diagrams:export` first.
