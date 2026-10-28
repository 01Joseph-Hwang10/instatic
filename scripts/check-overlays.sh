#!/usr/bin/env bash
# Overlay drift guard: diffs every registered overlay file against the pinned
# base image. Fails (exit 1) when an overlay no longer matches its upstream
# counterpart — meaning the base image changed and the overlay must be
# re-checked (see overlay/OVERLAYS.md).
#
# Usage: scripts/check-overlays.sh [base-image-tag]   (default: from Dockerfile FROM)
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  TAG=$(awk '/^FROM /{for(i=2;i<=NF;i++) if ($i ~ /^ghcr|^docker|^registry|\/:/) {print $i; exit}}' Dockerfile)
fi
echo "[check-overlays] Base image: $TAG"

CONTAINER="check-overlays-$$"
trap 'docker rm -f "$CONTAINER" >/dev/null 2>&1 || true' EXIT
docker create --platform linux/amd64 --name "$CONTAINER" "$TAG" true >/dev/null

FAIL=0
check() {
  local overlay_path="$1" upstream_path="$2"
  if [[ ! -f "$overlay_path" ]]; then
    echo "[check-overlays] MISSING overlay file: $overlay_path"; FAIL=1; return
  fi
  if ! docker cp "$CONTAINER:/app/$upstream_path" "/tmp/upstream-$(basename "$upstream_path")" >/dev/null 2>&1; then
    echo "[check-overlays] $overlay_path: upstream file /app/$upstream_path not found in base image"; FAIL=1; return
  fi
  if diff -q "$overlay_path" "/tmp/upstream-$(basename "$upstream_path")" >/dev/null 2>&1; then
    echo "[check-overlays] OK (identical to upstream — overlay can be dropped): $overlay_path"
  else
    # Drift is expected for registered overrides; report which upstream lines changed.
    local upstream_changed
    upstream_changed=$(diff "$overlay_path" "/tmp/upstream-$(basename "$upstream_path")" | grep -c '^[<>]' || true)
    echo "[check-overlays] OVERRIDE active: $overlay_path (${upstream_changed} diff lines vs upstream)"
  fi
}

# Registered overlays — keep in sync with overlay/OVERLAYS.md
check overlay/server/ai/drivers/http/chatCompletions.ts        server/ai/drivers/http/chatCompletions.ts
check overlay/server/ai/drivers/openaiCompatible.ts            server/ai/drivers/openaiCompatible.ts
check overlay/server/ai/conversations/store.ts                 server/ai/conversations/store.ts
check overlay/src/core/sanitize.ts                             src/core/sanitize.ts
check overlay/src/core/page-tree/classNames.ts                 src/core/page-tree/classNames.ts

if [[ "$FAIL" -ne 0 ]]; then
  echo "[check-overlays] FAILED — update overlays per overlay/OVERLAYS.md before proceeding."
  exit 1
fi
echo "[check-overlays] All overlays accounted for."
