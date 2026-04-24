{ pkgs, lib, machineType, configName, ... }:

{
  programs.zsh = {
    enable = true;

    promptInit = ''
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';

    interactiveShellInit = ''
      # Homebrew PATH
      eval "$(/opt/homebrew/bin/brew shellenv)"

      setopt AUTO_CD

      # Powerlevel10k
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ ! -f ~/.dotfiles/configs/p10k.zsh ]] || source ~/.dotfiles/configs/p10k.zsh

      # Plugins
      source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)

      # FZF
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
      export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      # Tools
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
      eval "$(${pkgs.mise}/bin/mise activate zsh)"

      # Load local env if exists
      [[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

      # Aliases & functions
      source ${../../configs/zsh/aliases.zsh}
      source ${../../configs/zsh/functions.zsh}

      # Nix rebuild shortcut
      rebuild() {
        sudo darwin-rebuild switch --flake ~/.dotfiles#${configName} "$@"
      }
    '' + lib.optionalString (machineType == "personal") ''
      source ${../../configs/zsh/aliases.personal.zsh}
    '';
  };
}
