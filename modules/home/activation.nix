{ pkgs, lib, ... }:

{
  home.activation.miseInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.mise}/bin/mise install --quiet
  '';

  home.activation.obsidianHeadless = lib.hm.dag.entryAfter [ "miseInstall" ] ''
    export PNPM_HOME="$HOME/.local/share/pnpm"
    run mkdir -p "$PNPM_HOME"
    run ${pkgs.pnpm}/bin/pnpm install -g obsidian-headless 2>/dev/null || true
  '';

  home.activation.nvimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    NVIM_DIR="$HOME/.config/nvim"
    NVIM_SOURCE="${../../configs/nvim}"

    if [ -L "$NVIM_DIR" ] || [ ! -d "$NVIM_DIR" ]; then
      $DRY_RUN_CMD rm -rf "$NVIM_DIR"
      $DRY_RUN_CMD cp -r "$NVIM_SOURCE" "$NVIM_DIR"
      $DRY_RUN_CMD chmod -R u+w "$NVIM_DIR"
    fi
  '';

  home.activation.agentConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    AGENT_SKILLS_SOURCE="${../../configs/agent/skills}"

    # --- Claude ---
    CLAUDE_DIR="$HOME/.claude"
    $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR"

    for f in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md"; do
      [ -L "$f" ] && $DRY_RUN_CMD rm "$f"
    done

    $DRY_RUN_CMD cp "${../../configs/claude-settings.json}" "$CLAUDE_DIR/settings.json"
    $DRY_RUN_CMD cp "${../../configs/claude-claude-md.md}" "$CLAUDE_DIR/CLAUDE.md"
    $DRY_RUN_CMD chmod u+w "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md"

    # --- Skills (共有、~/.claude/skills/ が正規の場所) ---
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

    $DRY_RUN_CMD cp "${../../configs/codex-config.toml}" "$CODEX_DIR/config.toml"
    $DRY_RUN_CMD cp "${../../configs/codex-agents-md.md}" "$CODEX_DIR/AGENTS.md"
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
  '';
}
