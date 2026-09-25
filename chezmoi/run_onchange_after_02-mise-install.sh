#!/bin/bash
# mise/config.toml の変更時に再実行される
# {{ include "private_dot_config/mise/config.toml" | sha256sum }}
set -euo pipefail

command -v mise >/dev/null 2>&1 && mise install --quiet || true
