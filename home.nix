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
    ".claude/settings.json" = {
      source = ./configs/claude-settings.json;
      force = true;  # Allow overwriting since language field changes dynamically
    };
    ".claude/rotate-language.sh" = {
      source = ./configs/rotate-language.sh;
      executable = true;
    };
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

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
