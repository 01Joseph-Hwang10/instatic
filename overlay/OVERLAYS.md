# Overlay Registry

Every file under `overlay/` that overrides an upstream Instatic file is listed
here with its reason and upstream status. `scripts/check-overlays.sh` diffs
each entry against the pinned base image and **fails CI on drift** — an
Instatic version bump forces a conscious re-check of every overlay.

| Overlay file | Upstream file (base `ghcr.io/corebunch/instatic:0.0.21`) | Change | Upstream PR |
| --- | --- | --- | --- |
| `overlay/server/ai/drivers/http/chatCompletions.ts` | `server/ai/drivers/http/chatCompletions.ts` | Version-aware `openAiEndpoint()`: Custom Provider base URLs carrying a non-`/v1` version segment (e.g. `https://api.z.ai/api/paas/v4/`) no longer get a bogus `/v1` inserted before `/chat/completions`. Full-endpoint URLs are used verbatim. Upstream `normalizeOpenAiBaseUrl` kept as-is for compatibility. | TODO: file PR |
| `overlay/server/ai/drivers/openaiCompatible.ts` | `server/ai/drivers/openaiCompatible.ts` | Model discovery (`/models`) uses the same `openAiEndpoint()` helper, so `/v4`-style base URLs list models correctly. | TODO: file PR (same PR as above) |
| `overlay/server/ai/conversations/store.ts` | `server/ai/conversations/store.ts` | Chat messages were stored as the literal string `[object Object]` (Bun binds a plain JS array to a text parameter via `String()`), so resumed sessions rendered empty. Serialize `content_json` explicitly with `JSON.stringify`. Upstream fixed the same bug at HEAD after v0.0.21. | TODO: backport/ref PR |
| `overlay/server/ai/drivers/http/chatCompletions.patches.test.ts` | — (new file) | Tests for `openAiEndpoint()` incl. upstream-compatibility cases. | — |

## Also overridden (same mechanism — `COPY overlay/src /app/src`)

| File | Upstream file | Change | Upstream PR |
| --- | --- | --- | --- |
| `overlay/src/core/sanitize.ts` | `src/core/sanitize.ts` | Richtext sanitizer keeps GFM tables in article bodies. | TODO: file PR |
| `overlay/src/core/page-tree/classNames.ts` | `src/core/page-tree/classNames.ts` | Unknown `classIds` fall back to emitting the id as a CSS class (prevents silent drop of seeded classes during admin shell round-trips). | TODO: file PR |

## Upgrade procedure (Instatic base image bump)

1. Update the `FROM` pin in `Dockerfile`.
2. Run `scripts/check-overlays.sh <new-tag>` — it reports per-file drift.
3. For each drifted file: re-read the upstream version, re-apply the change
   described above (or drop the overlay if upstreamed/fixed), update this
   table, and run the tests (`overlay/**/*patches.test.ts` against the new
   base repo).
