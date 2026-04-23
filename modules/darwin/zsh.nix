{ pkgs, lib, machineType, username, configName, ... }:

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

      # Syntax highlighting styles
      ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets cursor root)
      typeset -A ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=red,bold'
      ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=blue,bold'
      ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=green,bold'
      ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=magenta,bold'
      ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=yellow,bold'
      ZSH_HIGHLIGHT_STYLES[bracket-level-5]='fg=cyan,bold'
      ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='standout'
      ZSH_HIGHLIGHT_STYLES[cursor]='bg=blue'
      ZSH_HIGHLIGHT_STYLES[root]='bg=red'

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
    '' + (if machineType == "personal" then ''
      alias coleta-next="/Users/${username}/documents/coleta/coleta-next"
      alias coleta="/Users/${username}/documents/coleta/coleta/coleta-server"
      alias awsp='export AWS_PROFILE="coleta/tf"'
      alias awsd='export AWS_PROFILE="coleta-dev/tf"'
    '' else "");
  };
}
