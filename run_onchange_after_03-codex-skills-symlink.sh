#!/bin/bash
# private_dot_claude/agent/skills/ の変更時に再実行される
# {{ include "private_dot_claude/agent" | sha256sum }}
set -euo pipefail

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.codex/skills"

mkdir -p "$CLAUDE_SKILLS_DIR" "$CODEX_SKILLS_DIR"

# 古い codex symlink のうち、claude skills に存在しないものを削除
for codex_entry in "$CODEX_SKILLS_DIR"/*; do
  [ ! -L "$codex_entry" ] && continue
  skill_name="$(basename "$codex_entry")"
  [ "$skill_name" = ".system" ] && continue
  target="$(readlink "$codex_entry")"
  case "$target" in
    "$CLAUDE_SKILLS_DIR"/*)
      [ ! -f "$target/SKILL.md" ] && rm -f "$codex_entry"
      ;;
  esac
done

# 各 claude skill に対して codex 側の symlink を作成
for claude_skill in "$CLAUDE_SKILLS_DIR"/*; do
  [ ! -d "$claude_skill" ] || [ ! -f "$claude_skill/SKILL.md" ] && continue
  skill_name="$(basename "$claude_skill")"
  codex_link="$CODEX_SKILLS_DIR/$skill_name"
  [ -L "$codex_link" ] && [ "$(readlink "$codex_link")" = "$claude_skill" ] && continue
  [ -e "$codex_link" ] && [ ! -L "$codex_link" ] && continue
  ln -sfn "$claude_skill" "$codex_link"
done
