# Patched Instatic image
#
# Base = pinned upstream Instatic release. Everything under overlay/ is merged
# on top (Docker COPY semantics: files overwrite, directories merge), so the
# image ships only code-level fixes while all site data/config stays in the
# database + uploads volume and survives every redeploy.
#
# Every overridden upstream file MUST be registered in overlay/OVERLAYS.md and
# is checked against the base image by scripts/check-overlays.sh in CI.
FROM --platform=linux/amd64 ghcr.io/corebunch/instatic:0.0.21

USER root

# Code-level fixes for upstream files. `overlay/server` overwrites the upstream
# server files it patches; `overlay/src` the upstream client/core files.
COPY overlay/server /app/server
COPY overlay/src /app/src

# Self-hosted KaTeX for FHound Insights: site content references `/katex/*`
# (published pages set `script-src 'self'` CSP, so a CDN is not an option).
# Reference copy of KaTeX 0.16.8 — also mirrored in
# gs://fhound-insights-uploads-live/_instatic/assets/katex/.
COPY public/katex /app/dist/katex

USER bun
