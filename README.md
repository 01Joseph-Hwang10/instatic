# Instatic — Patched Image

A thin overlay image on top of the pinned upstream
[`ghcr.io/corebunch/instatic`](https://github.com/corebunch/instatic) release
that ships **only code-level fixes**. All site data/config lives outside the
image (Postgres + uploads volume), so redeploys replace code only and data
survives.

## License

MIT — see [LICENSE](LICENSE). The upstream Instatic copyright notice is
retained because `overlay/` contains modified copies of upstream files.

## Layout

```
Dockerfile               Base-image pin + overlay COPY (files overwrite, dirs merge)
overlay/server/**        Upstream server patches (registered in overlay/OVERLAYS.md)
overlay/src/core/**      Upstream src/core overrides (same registry)
scripts/check-overlays.sh  Overlay drift guard — must pass before any base bump
docker-compose.yml       Local dev: app (:3001) + postgres 18, uploads in a volume
```

## Patches shipped

See [`overlay/OVERLAYS.md`](overlay/OVERLAYS.md) for the full registry:

1. **AI endpoint handling** — version-aware `openAiEndpoint()`; custom
   providers with non-`/v1` version segments (e.g. `…/api/paas/v4/`) no longer
   get a bogus `/v1` inserted; used by both chat completions and `/models`
   discovery.
2. **AI conversation store** — chat messages are serialized with
   `JSON.stringify` instead of being stored as `[object Object]`.
3. **Richtext sanitizer** — keeps GFM tables in article bodies.
4. **Class-name fallback** — unknown `classIds` emit the id as a CSS class
   instead of being silently dropped during admin shell round-trips.

## Usage

```bash
docker compose up         # build the patched image and run it against postgres 18
docker compose exec app bun test overlay/...   # overlay tests (inside a container with the base repo)
```

Build and push the image alone:

```bash
docker buildx build --platform linux/amd64 -t <registry>/instatic-patched:0.0.21 .
docker push <registry>/instatic-patched:0.0.21
```

## Overlay governance

Every file under `overlay/` that overrides upstream is registered in
[`overlay/OVERLAYS.md`](overlay/OVERLAYS.md).
`scripts/check-overlays.sh` (run in CI) diffs each against the pinned base
image — an Instatic version bump forces a conscious re-check of every overlay:

```bash
scripts/check-overlays.sh [new-base-tag]
```

Long-term goal: upstream the fixes and shrink the overlay to zero.
