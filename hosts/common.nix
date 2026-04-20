{ pkgs, lib, machineType, username, configName, ... }:

{
  # Nix settings
  # Using Determinate Systems installer, so let it manage Nix
  nix.enable = false;

  # Allow unfree packages (VSCode, etc.)
  nixpkgs.config.allowUnfree = true;

  # macOS system packages
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim
    vscode
    zed-editor

    # GUI Applications
    _1password-gui

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
    gh
    lazygit
    zellij
    mise
    pnpm
    claude-code-bin
    chezmoi

    # Zsh plugins
    zsh-powerlevel10k
    zsh-fast-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
  ] ++ (lib.optionals (machineType == "personal") [
    # AWS tools (personal machines only)
    # awscli2 は home.nix の programs.awscli で管理
    # aws-sam-cli  # FIXME: ビルドでテストが失敗するため一旦コメントアウト
    ssm-session-manager-plugin
  ]);

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
      # Homebrew PATH (for cask-installed tools like codex)
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Options
      setopt AUTO_CD

      # Load Powerlevel10k theme
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

      # Load p10k configuration
      [[ ! -f ~/.dotfiles/configs/p10k.zsh ]] || source ~/.dotfiles/configs/p10k.zsh

      # Load plugins
      source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
      if [[ -d "$HOME/.docker/completions" ]]; then
        fpath=($HOME/.docker/completions $fpath)
      fi

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

      # mise initialization
      eval "$(${pkgs.mise}/bin/mise activate zsh)"

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
      alias ssh="TERM=xterm-256color ssh"
      alias gs="git status"
      alias gw="git worktree"
      alias gwl="git worktree list"
      alias gl="git log"
      alias glo="git log --oneline"
      alias zj="zellij"
      alias zja="zellij attach"
      alias zjl="zellij list-sessions"
      alias zjd="zellij delete-session"
      alias zjs="zellij -s"
      alias vim="nvim"
      alias vi="nvim"
      alias cat="${pkgs.bat}/bin/bat"
      alias moi="chezmoi"

      # Custom functions
      # repo: ghq repository/worktree selector with fzf
      repo() {
          local selected current_git_common ghq_root
          current_git_common=$(git rev-parse --git-common-dir 2>/dev/null | xargs -I{} realpath {} 2>/dev/null)
          ghq_root=$(ghq root)

          selected=$(ghq list --full-path 2>/dev/null | \
              while read -r repo_path; do
                  local git_common is_first wt_path wt_name rel_path
                  git_common=$(realpath "$repo_path/.git" 2>/dev/null)
                  rel_path=$(echo "$repo_path" | sed "s|^$ghq_root/||")
                  is_first=true
                  while IFS= read -r line; do
                      case "$line" in
                          worktree\ *)
                              wt_path=$(echo "$line" | sed 's/^worktree //')
                              wt_name=$(basename "$wt_path")
                              if $is_first; then
                                  printf '%s\t0\t%s\t\033[32m%s\033[0m\n' "$git_common" "$wt_path" "$rel_path"
                                  is_first=false
                              else
                                  printf '%s\t1\t%s\t\033[33m↳ %s\033[0m\n' "$git_common" "$wt_path" "$wt_name"
                              fi
                              ;;
                      esac
                  done < <(git -C "$repo_path" worktree list --porcelain 2>/dev/null)
              done | \
              awk -F'\t' -v cur="$current_git_common" '{
                  if ($1 == cur) print "0\t" $0
                  else print "1\t" $0
              }' | \
              sort -t$'\t' -k1,1 -k2,2 -k3,3n -k5 | \
              cut -f4- | \
              ${pkgs.fzf}/bin/fzf --ansi --height 40% --reverse --delimiter=$'\t' --with-nth=2 --preview 'ls -la {1}' --query "$1" | \
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

      # Nix darwin-rebuild switch
      rebuild() {
        sudo darwin-rebuild switch --flake ~/.dotfiles#${configName} "$@"
      }
    '' + (if machineType == "personal" then ''
      # Personal machine specific configuration
      alias coleta-next="/Users/${username}/documents/coleta/coleta-next"
      alias coleta="/Users/${username}/documents/coleta/coleta/coleta-server"
      alias awsp='export AWS_PROFILE="coleta/tf"'
      alias awsd='export AWS_PROFILE="coleta-dev/tf"'
    '' else "");
  };

  # Homebrew integration for GUI apps
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "none";
      autoUpdate = true;
      upgrade = false;
    };

    # GUI applications (macOS-specific tools only)
    # Most GUI apps are now managed via nixpkgs in environment.systemPackages
    casks = [
      "alt-tab"
      "aqua-voice"
      "codex"
      "docker-desktop"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "obsidian"
      "raycast"
      "cmux"
      "scroll-reverser"
      "slack"
      "tailscale-app"
    ];
  };

  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Primary user for system settings
  system.primaryUser = username;

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

  # Activation scripts are now managed by home-manager (see home.nix)

  # Used for backwards compatibility
  system.configurationRevision = null;
}
