# flux-system

Created by `flux bootstrap`. Do not hand-author `gotk-components.yaml` or `gotk-sync.yaml`.

After bootstrap this directory contains:

- `gotk-components.yaml` — Flux controllers
- `gotk-sync.yaml` — Kustomization that syncs `./clusters/lab`
- `kustomization.yaml` — lists the two files above

`clusters/lab/kustomization.yaml` includes this directory so Flux can upgrade itself from git.

See `docs/03-gitops.md`.
