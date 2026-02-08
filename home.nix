{ pkgs, machineType, ... }:

{
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  # Git configuration
  programs.git = {
    enable = true;

    settings = {
      core = {
        pager = "delta";
      };
      interactive = {
        diffFilter = "delta --color-only";
      };
      delta = {
        navigate = true;
        light = false;
        line-numbers = true;
        syntax-theme = "Monokai Extended";
      };
      merge = {
        conflictstyle = "diff3";
      };
      diff = {
        colorMoved = "default";
      };
    };
  };

  # Configuration files
  xdg.configFile = {
    # Ghostty
    "ghostty/config".source = ./configs/ghostty-config;

    # Neovim (LazyVim)
    "nvim".source = ./configs/nvim;

    # Yazi file manager
    "yazi".source = ./configs/yazi;
  };

  # Home directory files
  home.file = {
    # Vim configuration
    ".vimrc".source = ./configs/vimrc;

    # Claude Code configuration
    ".claude/settings.json".source = ./configs/claude-settings.json;
    ".claude/rotate-language.sh" = {
      source = ./configs/rotate-language.sh;
      executable = true;
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
