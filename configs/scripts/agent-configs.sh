#!/usr/bin/env bash
# Deploys Claude/Codex agent configs and shared skills.
# Called from modules/home/activation.nix with env vars:
#   AGENT_SKILLS_SOURCE, CLAUDE_SETTINGS, CLAUDE_MD, CODEX_CONFIG, CODEX_AGENTS_MD
# DRY_RUN_CMD is inherited from home-manager activation environment.

# --- Claude ---
CLAUDE_DIR="$HOME/.claude"
$DRY_RUN_CMD mkdir -p "$CLAUDE_DIR"

for f in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md"; do
  [ -L "$f" ] && $DRY_RUN_CMD rm "$f"
done

$DRY_RUN_CMD cp "$CLAUDE_SETTINGS" "$CLAUDE_DIR/settings.json"
$DRY_RUN_CMD cp "$CLAUDE_MD" "$CLAUDE_DIR/CLAUDE.md"
$DRY_RUN_CMD chmod u+w "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md"

# --- Skills (~/.claude/skills/ が正規の場所) ---
CLAUDE_SKILLS_DIR="$CLAUDE_DIR/skills"
$DRY_RUN_CMD mkdir -p "$CLAUDE_SKILLS_DIR"
for skill_source in "$AGENT_SKILLS_SOURCE"/*/; do
  skill_name="$(basename "$skill_source")"
  $DRY_RUN_CMD rm -rf "$CLAUDE_SKILLS_DIR/$skill_name"
  $DRY_RUN_CMD cp -r "$skill_source" "$CLAUDE_SKILLS_DIR/$skill_name"
done
$DRY_RUN_CMD chmod -R u+w "$CLAUDE_SKILLS_DIR"
$DRY_RUN_CMD mkdir -p "$CLAUDE_SKILLS_DIR/learned"

# --- Codex ---
CODEX_DIR="$HOME/.codex"
$DRY_RUN_CMD mkdir -p "$CODEX_DIR"

$DRY_RUN_CMD cp "$CODEX_CONFIG" "$CODEX_DIR/config.toml"
$DRY_RUN_CMD cp "$CODEX_AGENTS_MD" "$CODEX_DIR/AGENTS.md"
$DRY_RUN_CMD chmod u+w "$CODEX_DIR/config.toml" "$CODEX_DIR/AGENTS.md"

# --- Codex Skills: Claude skills へのシンボリックリンク ---
CODEX_SKILLS_DIR="$CODEX_DIR/skills"
$DRY_RUN_CMD mkdir -p "$CODEX_SKILLS_DIR"

for codex_entry in "$CODEX_SKILLS_DIR"/*; do
  [ ! -L "$codex_entry" ] && continue
  skill_name="$(basename "$codex_entry")"
  [ "$skill_name" = ".system" ] && continue
  target="$(readlink "$codex_entry")"
  case "$target" in "$CLAUDE_SKILLS_DIR"/*) [ ! -f "$target/SKILL.md" ] && $DRY_RUN_CMD rm -f "$codex_entry" ;; esac
done

for claude_skill in "$CLAUDE_SKILLS_DIR"/*; do
  [ ! -d "$claude_skill" ] || [ ! -f "$claude_skill/SKILL.md" ] && continue
  skill_name="$(basename "$claude_skill")"
  codex_link="$CODEX_SKILLS_DIR/$skill_name"
  [ -L "$codex_link" ] && [ "$(readlink "$codex_link")" = "$claude_skill" ] && continue
  [ -e "$codex_link" ] && [ ! -L "$codex_link" ] && continue
  $DRY_RUN_CMD ln -sfn "$claude_skill" "$codex_link"
done
