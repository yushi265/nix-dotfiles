{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        golang.go
        eamodio.gitlens
        editorconfig.editorconfig
        usernamehw.errorlens
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        vscode-icons-team.vscode-icons
        redhat.vscode-yaml
      ];

      userSettings = {
        "files.autoSave" = "afterDelay";
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;
        "files.associations".".*lintrc" = "json";
        "files.exclude" = {
          "**/*.map" = true;
          "**/node_modules" = true;
        };

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

        "diffEditor.renderSideBySide" = true;

        "emmet.showSuggestionsAsSnippets" = true;
        "emmet.triggerExpansionOnTab" = true;
        "emmet.variables"."lang" = "ja";

        "html.format.contentUnformatted" = "pre, code, textarea, title, h1, h2, h3, h4, h5, h6, p";
        "html.format.extraLiners" = "";
        "html.format.unformatted" = null;
        "html.format.wrapLineLength" = 0;

        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        "search.exclude"."**/tmp" = true;

        "window.openFoldersInNewWindow" = "on";
        "window.title" = "\${activeEditorMedium}\${separator}\${rootName}";

        "workbench.editor.labelFormat" = "short";
        "workbench.editor.tabSizing" = "shrink";
        "workbench.startupEditor" = "none";
        "workbench.iconTheme" = "vscode-icons";
        "workbench.colorTheme" = "Community Material Theme Darker High Contrast";

        "git.autofetch" = true;
        "git.suggestSmartCommit" = false;

        "[markdown]"."files.trimTrailingWhitespace" = false;

        "[go]" = {
          "editor.snippetSuggestions" = "none";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave"."source.organizeImports" = "explicit";
        };

        "go.useLanguageServer" = true;
        "gopls" = {
          "usePlaceholders" = true;
          "enhancedHover" = true;
        };
      };
    };
  };
}
