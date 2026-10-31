#!/bin/bash
# ダウンロードフォルダの中で Claude Code を使わせない (UserPromptSubmit フック)。
# Web ページが黙って置いた AGENTS.md / CLAUDE.md を読み込ませないための守り。
# macOS のファイルシステムは大文字小文字を区別しないので、照合でも区別しない。
cwd="$(jq -r '.cwd // empty' 2>/dev/null)"
cwd="${cwd:-$PWD}"

shopt -s nocasematch
case "$cwd" in
  */Downloads | */Downloads/*)
    echo "ダウンロードフォルダでは使えません。作業するプロジェクトのフォルダで起動し直してください。" >&2
    exit 2
    ;;
esac
exit 0
