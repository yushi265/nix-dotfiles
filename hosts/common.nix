{ pkgs, machineType, ... }:

{
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };

    # Optimize store automatically
    optimise.automatic = true;

    # Auto garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 7; };
      options = "--delete-older-than 30d";
    };
  };

  # macOS system packages
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim

    # CLI tools
    lsd
    ripgrep
    fd
    ghq
    jq
    bat
    fzf
    zoxide
    git-open
    yazi
    delta

    # Zsh plugins
    zsh-powerlevel10k
    zsh-fast-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
  ];

  # Zsh configuration
  programs.zsh = {
    enable = true;

    # Prompt initialization (p10k instant prompt)
    promptInit = ''
      # Enable Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';

    interactiveShellInit = ''
      # Load Powerlevel10k theme
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

      # Load p10k configuration
      [[ ! -f ~/.dotfiles/configs/p10k.zsh ]] || source ~/.dotfiles/configs/p10k.zsh

      # Load plugins
      source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
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

      # FZF configuration
      export FZF_DEFAULT_COMMAND='${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND='${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git'
      export FZF_CTRL_T_OPTS="--preview '${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :500 {}'"

      # FZF key bindings and completion
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      # Zoxide initialization
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

      # Load local env if exists
      [[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

      # Aliases
      alias c="clear"
      alias f="yazi"
      alias dc="docker compose"
      alias ls="lsd"
      alias l="ls -l"
      alias la="ls -a"
      alias lal="ls -la"
      alias lt="ls --tree"
      alias ccusage="npx ccusage@latest"
      alias gs="git status"
      alias gw="git worktree"
      alias gwl="git worktree list"
      alias gl="git log"
      alias glo="git log --oneline"
      alias vim="nvim"
      alias vi="nvim"
      alias cat="${pkgs.bat}/bin/bat"

      # Custom functions
      # repo: git repository/worktree selector with fzf
      repo() {
          local selected current_git_common
          current_git_common=$(git rev-parse --git-common-dir 2>/dev/null | xargs -I{} realpath {} 2>/dev/null)

          selected=$(${pkgs.fd}/bin/fd --type f --type d --hidden --no-ignore \
              '^\.git$' ~/Documents --max-depth 5 2>/dev/null | \
              while read -r gitpath; do
                  dir=$(dirname "$gitpath")
                  name=$(basename "$dir")
                  if [[ -d "$gitpath" ]]; then
                      git_common=$(realpath "$gitpath" 2>/dev/null)
                      printf '%s\t0\t%s\t\033[32m%s\033[0m\n' "$git_common" "$dir" "$name"
                  else
                      git_common=$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null | xargs -I{} realpath {} 2>/dev/null)
                      printf '%s\t1\t%s\t\033[33m↳ %s\033[0m\n' "$git_common" "$dir" "$name"
                  fi
              done | \
              awk -F'\t' -v cur="$current_git_common" '{
                  if ($1 == cur) print "0\t" $0
                  else print "1\t" $0
              }' | \
              sort -t$'\t' -k1,1 -k2,2 -k3,3n -k5 | \
              cut -f4- | \
              ${pkgs.fzf}/bin/fzf --ansi --height 40% --reverse --delimiter=$'\t' --with-nth=2 --preview 'ls -la {1}' | \
              cut -f1)

          if [[ -n "$selected" ]]; then
              cd "$selected" || return 1
          fi
      }

      # gd: interactive git diff with fzf
      gd() {
          emulate -L zsh
          setopt NO_XTRACE NO_VERBOSE

          if ! git rev-parse --is-inside-work-tree &>/dev/null; then
              echo "Error: Not a git repository" >&2
              return 1
          fi

          local mode files result key selected preview_cmd reload_cmd
          mode="all"

          while getopts "suh" opt; do
              case $opt in
                  s) mode="staged" ;;
                  u) mode="unstaged" ;;
                  h)
                      echo "Usage: gd [-s|-u|-h]"
                      echo "  -s  Show staged changes only"
                      echo "  -u  Show unstaged changes only"
                      echo "  -h  Show this help"
                      echo ""
                      echo "Keys:"
                      echo "  ENTER    View diff (delta)"
                      echo "  CTRL-E   Edit file in vim"
                      echo "  CTRL-S   Toggle stage/unstage"
                      echo "  ESC      Quit"
                      return 0
                      ;;
                  *) return 1 ;;
              esac
          done

          preview_cmd='echo {1} | grep -q S && git diff --cached --color=always -- {2} | ${pkgs.delta}/bin/delta || git diff --color=always -- {2} | ${pkgs.delta}/bin/delta'
          reload_cmd='git diff --cached --name-only | while read -r f; do [ -n "$f" ] && printf "\033[32m[S]\033[0m %s\n" "$f"; done; git diff --name-only | while read -r f; do [ -n "$f" ] && printf "\033[33m[U]\033[0m %s\n" "$f"; done'

          while true; do
              case $mode in
                  staged) files=$(git diff --cached --name-only | sed 's/^/[S] /') ;;
                  unstaged) files=$(git diff --name-only | sed 's/^/[U] /') ;;
                  all)
                      files=$(
                          git diff --cached --name-only | while read -r f; do
                              [[ -n "$f" ]] && printf '\033[32m[S]\033[0m %s\n' "$f"
                          done
                          git diff --name-only | while read -r f; do
                              [[ -n "$f" ]] && printf '\033[33m[U]\033[0m %s\n' "$f"
                          done
                      )
                      ;;
              esac

              if [[ -z "$files" ]]; then
                  echo "No changes found"
                  break
              fi

              result=$(echo "$files" | ${pkgs.fzf}/bin/fzf \
                  --ansi --height 60% --reverse --delimiter=' ' --expect=ctrl-e \
                  --preview "$preview_cmd" --preview-window 'right:60%:wrap' \
                  --header 'ENTER: diff | CTRL-E: edit | CTRL-S: stage/unstage | ESC: quit' \
                  --bind "ctrl-s:execute-silent(echo {1} | grep -q S && git reset HEAD -- {2} || git add -- {2})+reload($reload_cmd)")

              [[ -z "$result" ]] && break

              key=$(echo "$result" | head -1)
              selected=$(echo "$result" | tail -1 | sed 's/^\[[SU]\] //')

              [[ -z "$selected" ]] && break

              case $key in
                  ctrl-e) ${pkgs.neovim}/bin/nvim "$selected" ;;
                  *)
                      if git diff --cached --name-only | grep -qx "$selected"; then
                          git diff --cached -- "$selected" | ${pkgs.delta}/bin/delta --paging=never | less -R
                      else
                          git diff -- "$selected" | ${pkgs.delta}/bin/delta --paging=never | less -R
                      fi
                      ;;
              esac
          done
      }

      # rgf: interactive ripgrep with fzf
      rgf() {
          local initial_query="''${*:-}"
          local result file line

          result=$(${pkgs.ripgrep}/bin/rg --color=always --line-number --no-heading . 2>/dev/null | \
              ${pkgs.fzf}/bin/fzf --ansi --disabled --query "$initial_query" \
                  --bind "change:reload:${pkgs.ripgrep}/bin/rg --color=always --line-number --no-heading {q} || true" \
                  --delimiter=: \
                  --preview '${pkgs.bat}/bin/bat --style=numbers --color=always --highlight-line {2} {1}' \
                  --preview-window 'right:60%:+{2}-5')

          if [[ -n "$result" ]]; then
              file=$(echo "$result" | cut -d: -f1)
              line=$(echo "$result" | cut -d: -f2)
              ${pkgs.neovim}/bin/nvim "+$line" "$file"
          fi
      }
    '' + (if machineType == "personal" then ''
      # Personal machine specific configuration
      export PATH="$HOME/.bun/bin:$PATH"
      alias coleta-next="/Users/shina/documents/coleta/coleta-next"
      alias coleta="/Users/shina/documents/coleta/coleta/coleta-server"
      alias awsp='export AWS_PROFILE="coleta/tf"'
      alias awsd='export AWS_PROFILE="coleta-dev/tf"'
    '' else "");
  };

  # Homebrew integration for GUI apps
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    # GUI applications
    casks = [
      "ghostty"
    ];
  };

  # Primary user for system settings
  system.primaryUser = "shina";

  # macOS system settings
  system = {
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        tilesize = 48;
      };

      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        _FXShowPosixPathInTitle = true;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
    };

    stateVersion = 5;
  };

  # User configuration files
  system.activationScripts.postActivation.text = ''
    # Configure git to use delta for diff/log (run as primary user with explicit HOME)
    sudo -u shina HOME=/Users/shina ${pkgs.git}/bin/git config --global core.pager "${pkgs.delta}/bin/delta"
    sudo -u shina HOME=/Users/shina ${pkgs.git}/bin/git config --global interactive.diffFilter "${pkgs.delta}/bin/delta --color-only"
    sudo -u shina HOME=/Users/shina ${pkgs.git}/bin/git config --global delta.navigate true
    sudo -u shina HOME=/Users/shina ${pkgs.git}/bin/git config --global delta.light false
    sudo -u shina HOME=/Users/shina ${pkgs.git}/bin/git config --global delta.line-numbers true
    sudo -u shina HOME=/Users/shina ${pkgs.git}/bin/git config --global delta.syntax-theme "Monokai Extended"
    sudo -u shina HOME=/Users/shina ${pkgs.git}/bin/git config --global merge.conflictstyle diff3
    sudo -u shina HOME=/Users/shina ${pkgs.git}/bin/git config --global diff.colorMoved default

    # Ghostty configuration
    sudo -u shina mkdir -p /Users/shina/.config/ghostty
    sudo -u shina ln -sf /Users/shina/.dotfiles/configs/ghostty-config /Users/shina/.config/ghostty/config

    # Neovim configuration
    sudo -u shina mkdir -p /Users/shina/.config
    sudo -u shina ln -sfn /Users/shina/.dotfiles/configs/nvim /Users/shina/.config/nvim

    # Yazi configuration
    sudo -u shina ln -sfn /Users/shina/.dotfiles/configs/yazi /Users/shina/.config/yazi

    # Vim configuration
    sudo -u shina ln -sf /Users/shina/.dotfiles/configs/vimrc /Users/shina/.vimrc
  '';

  # Used for backwards compatibility
  system.configurationRevision = null;
}
