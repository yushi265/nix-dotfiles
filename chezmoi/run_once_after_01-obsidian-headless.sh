#!/bin/bash
set -euo pipefail

export PNPM_HOME="$HOME/.local/share/pnpm"
mkdir -p "$PNPM_HOME"
command -v pnpm >/dev/null 2>&1 && pnpm install -g obsidian-headless 2>/dev/null || true
