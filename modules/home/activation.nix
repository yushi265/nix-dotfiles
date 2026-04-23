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
    AGENT_SKILLS_SOURCE="${../../configs/agent/skills}" \
    CLAUDE_SETTINGS="${../../configs/claude-settings.json}" \
    CLAUDE_MD="${../../configs/claude-claude-md.md}" \
    CODEX_CONFIG="${../../configs/codex-config.toml}" \
    CODEX_AGENTS_MD="${../../configs/codex-agents-md.md}" \
      bash ${../../configs/scripts/agent-configs.sh}
  '';
}
