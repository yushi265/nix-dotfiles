{ pkgs, lib, machineType, ... }:

{
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  # Git configuration
  programs.git = {
    enable = true;

    ignores = [
      "*~"
      ".DS_Store"
    ];

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
      ghq = {
        root = "~/src";
      };
    };
  };

  # AWS CLI configuration (personal machines only)
  programs.awscli = lib.mkIf (machineType == "personal") {
    enable = true;
    settings = {
      "default" = {
        region = "ap-northeast-1";
        output = "json";
      };
      "profile yushi265" = {
        region = "ap-northeast-1";
        output = "json";
      };
      "profile AdministratorAccess-288632681694" = {
        sso_session = "coleta";  # typo修正: isso_session → sso_session
        sso_account_id = "288632681694";
        sso_role_name = "AdministratorAccess";
        region = "ap-northeast-1";
        output = "json";
      };
      "sso-session coleta" = {
        sso_start_url = "https://d-9567623602.awsapps.com/start";
        sso_region = "ap-northeast-1";
        sso_registration_scopes = "sso:account:access";
      };
      "profile coleta/tf" = {
        sso_account_id = "288632681694";
        sso_role_name = "PowerUserAccess";
        sso_start_url = "https://d-9567623602.awsapps.com/start";
        sso_region = "ap-northeast-1";
        sso_session = "coleta";
        region = "ap-northeast-1";
      };
      "profile coleta-dev/tf" = {
        sso_account_id = "550299169809";
        sso_role_name = "PowerUserAccess";
        sso_start_url = "https://d-9567623602.awsapps.com/start";
        sso_region = "ap-northeast-1";
        sso_session = "coleta";
        region = "ap-northeast-1";
      };
      "profile AdministratorAccess-550299169809" = {
        sso_session = "coleta";
        sso_account_id = "550299169809";
        sso_role_name = "AdministratorAccess";
        region = "ap-northeast-1";
        output = "json";
      };
      "profile ReadOnlyAccess-550299169809" = {
        sso_session = "coleta";
        sso_account_id = "550299169809";
        sso_role_name = "ReadOnlyAccess";
        region = "ap-northeast-1";
        output = "json";
      };
      "profile PowerUserAccess-550299169809" = {
        sso_session = "coleta";
        sso_account_id = "550299169809";
        sso_role_name = "PowerUserAccess";
        region = "ap-northeast-1";
        output = "json";
      };
    };
    # credentials は管理しない (secrets が Nix store に入るため)
  };

  # mise global tool configuration
  xdg.configFile."mise/config.toml".text = ''
    [tools]
    node = "lts"
    bun = "latest"
  '';

  # Configuration files
  xdg.configFile = {
    # Ghostty
    "ghostty/config".source = ./configs/ghostty-config;

    # Neovim (LazyVim) - managed by activation script for writable lazy-lock.json

    # Yazi file manager
    "yazi".source = ./configs/yazi;

    # Karabiner-Elements (keyboard customization)
    "karabiner/karabiner.json".source = ./configs/karabiner.json;

    # Zed editor
    "zed/settings.json".source = ./configs/zed-settings.json;

    # Zellij terminal multiplexer
    "zellij".source = ./configs/zellij;
  };

  # Home directory files
  home.file = {
    # Vim configuration
    ".vimrc".source = ./configs/vimrc;

    # SSH configuration (excluding private keys)
    ".ssh/config".source = ./configs/ssh-config;

    # tmux configuration
    ".tmux.conf".source = ./configs/tmux.conf;

    # npm configuration
    ".npmrc".source = ./configs/npmrc;
  };

  # VSCode configuration
  programs.vscode = {
    enable = true;

    profiles.default = {
      # Extensions (nixpkgs-available only)
      extensions = with pkgs.vscode-extensions; [
        # Language support
        golang.go
        # ms-python.python  # Python

        # Git tools
        eamodio.gitlens
        # mhutchie.git-graph
        # donjayamanne.githistory

        # Editor enhancements
        # vscodevim.vim
        editorconfig.editorconfig
        usernamehw.errorlens

        # Formatters & linters
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint

        # Themes & icons
        vscode-icons-team.vscode-icons
        # equinusocio.vsc-material-theme

        # Other
        redhat.vscode-yaml
        # ms-azuretools.vscode-docker
      ];

      userSettings = {
      # File settings
      "files.autoSave" = "afterDelay";
      "files.insertFinalNewline" = true;
      "files.trimFinalNewlines" = true;
      "files.trimTrailingWhitespace" = true;
      "files.associations" = {
        ".*lintrc" = "json";
      };
      "files.exclude" = {
        "**/*.map" = true;
        "**/node_modules" = true;
      };

      # Editor settings
      "editor.colorDecorators" = false;
      "editor.formatOnPaste" = true;
      "editor.formatOnSave" = true;
      "editor.formatOnType" = true;
      "editor.minimap.renderCharacters" = false;
      "editor.minimap.showSlider" = "always";
      "editor.multiCursorModifier" = "ctrlCmd";
      "editor.renderControlCharacters" = true;
      "editor.renderLineHighlight" = "all";
      "editor.renderWhitespace" = "all";
      "editor.snippetSuggestions" = "top";
      "editor.tabSize" = 4;
      "editor.wordWrap" = "on";
      "editor.suggestSelection" = "first";

      # Diff editor
      "diffEditor.renderSideBySide" = true;

      # Emmet
      "emmet.showSuggestionsAsSnippets" = true;
      "emmet.triggerExpansionOnTab" = true;
      "emmet.variables" = {
        "lang" = "ja";
      };

      # HTML formatting
      "html.format.contentUnformatted" = "pre, code, textarea, title, h1, h2, h3, h4, h5, h6, p";
      "html.format.extraLiners" = "";
      "html.format.unformatted" = null;
      "html.format.wrapLineLength" = 0;

      # Explorer
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;

      # Search
      "search.exclude" = {
        "**/tmp" = true;
      };

      # Window
      "window.openFoldersInNewWindow" = "on";
      "window.title" = "\${activeEditorMedium}\${separator}\${rootName}";

      # Workbench
      "workbench.editor.labelFormat" = "short";
      "workbench.editor.tabSizing" = "shrink";
      "workbench.startupEditor" = "none";
      "workbench.iconTheme" = "vscode-icons";
      "workbench.colorTheme" = "Community Material Theme Darker High Contrast";

      # Git
      "git.autofetch" = true;
      "git.suggestSmartCommit" = false;

      # Terminal
      "terminal.integrated.shell.windows" = "C:\\Program Files\\Git\\bin\\bash.exe";
      "terminal.integrated.env.osx" = {
        "FIG_NEW_SESSION" = "1";
      };

      # Language-specific settings
      "[markdown]" = {
        "files.trimTrailingWhitespace" = false;
      };
      "[vue]" = {
        "editor.defaultFormatter" = "octref.vetur";
      };
      "[go]" = {
        "editor.snippetSuggestions" = "none";
        "editor.formatOnSave" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
      };

      # Intelephense (PHP)
      "intelephense.diagnostics.undefinedClassConstants" = false;
      "intelephense.diagnostics.undefinedConstants" = false;
      "intelephense.diagnostics.undefinedFunctions" = false;
      "intelephense.diagnostics.undefinedMethods" = false;
      "intelephense.diagnostics.undefinedProperties" = false;
      "intelephense.diagnostics.undefinedTypes" = false;
      "intelephense.diagnostics.undefinedSymbols" = false;
      "intelephense.diagnostics.unexpectedTokens" = false;
      "intelephense.completion.fullyQualifyGlobalConstantsAndFunctions" = true;
      "intelephense.diagnostics.languageConstraints" = false;

      # VSIntelliCode
      "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";

      # Dart/Flutter
      "dart.openDevTools" = "flutter";

      # Go language server
      "go.useLanguageServer" = true;
      "go.alternateTools" = {
        "go-langserver" = "gopls";
      };
      "go.languageServerExperimentalFeatures" = {
        "format" = true;
        "autoComplete" = true;
      };
      "gopls" = {
        "usePlaceholders" = true;
        "enhancedHover" = true;
      };

      # Database Client
      "database-client.autoSync" = true;
      };
    };
  };

  # Activation script to install mise tools globally
  home.activation.miseInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.mise}/bin/mise install --quiet
  '';

  # Activation script to copy nvim config with writable lazy-lock.json
  home.activation.nvimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    NVIM_DIR="$HOME/.config/nvim"
    NVIM_SOURCE="${./configs/nvim}"

    # nvimディレクトリがシンボリックリンクまたは存在しない場合、実ディレクトリとしてコピー
    if [ -L "$NVIM_DIR" ] || [ ! -d "$NVIM_DIR" ]; then
      $DRY_RUN_CMD rm -rf "$NVIM_DIR"
      $DRY_RUN_CMD cp -r "$NVIM_SOURCE" "$NVIM_DIR"
      # lazy-lock.jsonを書き込み可能に
      $DRY_RUN_CMD chmod -R u+w "$NVIM_DIR"
    fi
  '';

  # Activation script for Claude/Codex agent configs and shared skills
  home.activation.agentConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    AGENT_SKILLS_SOURCE="${./configs/agent/skills}"

    # --- Claude ---
    CLAUDE_DIR="$HOME/.claude"
    $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR"

    # 既存の Nix store シンボリックリンクを除去（初回マイグレーション）
    for f in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md"; do
      [ -L "$f" ] && $DRY_RUN_CMD rm "$f"
    done

    # 設定ファイルを書き込み可能コピーとしてデプロイ
    $DRY_RUN_CMD cp "${./configs/claude-settings.json}" "$CLAUDE_DIR/settings.json"
    $DRY_RUN_CMD cp "${./configs/claude-claude-md.md}" "$CLAUDE_DIR/CLAUDE.md"
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

    $DRY_RUN_CMD cp "${./configs/codex-config.toml}" "$CODEX_DIR/config.toml"
    $DRY_RUN_CMD cp "${./configs/codex-agents-md.md}" "$CODEX_DIR/AGENTS.md"
    $DRY_RUN_CMD chmod u+w "$CODEX_DIR/config.toml" "$CODEX_DIR/AGENTS.md"

    # --- Codex Skills: Claude skills へのシンボリックリンク ---
    CODEX_SKILLS_DIR="$CODEX_DIR/skills"
    $DRY_RUN_CMD mkdir -p "$CODEX_SKILLS_DIR"

    # 古いリンクのクリーンアップ
    for codex_entry in "$CODEX_SKILLS_DIR"/*; do
      [ ! -L "$codex_entry" ] && continue
      skill_name="$(basename "$codex_entry")"
      [ "$skill_name" = ".system" ] && continue
      target="$(readlink "$codex_entry")"
      case "$target" in "$CLAUDE_SKILLS_DIR"/*) [ ! -f "$target/SKILL.md" ] && $DRY_RUN_CMD rm -f "$codex_entry" ;; esac
    done

    # 各スキルのシンボリックリンク作成
    for claude_skill in "$CLAUDE_SKILLS_DIR"/*; do
      [ ! -d "$claude_skill" ] || [ ! -f "$claude_skill/SKILL.md" ] && continue
      skill_name="$(basename "$claude_skill")"
      codex_link="$CODEX_SKILLS_DIR/$skill_name"
      [ -L "$codex_link" ] && [ "$(readlink "$codex_link")" = "$claude_skill" ] && continue
      [ -e "$codex_link" ] && [ ! -L "$codex_link" ] && continue
      $DRY_RUN_CMD ln -sfn "$claude_skill" "$codex_link"
    done
  '';

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
