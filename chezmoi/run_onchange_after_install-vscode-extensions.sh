#!/bin/bash
set -euo pipefail

command -v code >/dev/null 2>&1 || exit 0

extensions=(
  golang.go
  eamodio.gitlens
  editorconfig.editorconfig
  usernamehw.errorlens
  esbenp.prettier-vscode
  dbaeumer.vscode-eslint
  vscode-icons-team.vscode-icons
  redhat.vscode-yaml
)

for ext in "${extensions[@]}"; do
  code --install-extension "$ext" --force
done
