{ pkgs, lib, machineType, ... }:

{
  nixpkgs.config.allowUnfree = true;

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

    # Zsh plugins
    zsh-powerlevel10k
    zsh-fast-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
  ] ++ (lib.optionals (machineType == "personal") [
    ssm-session-manager-plugin
  ]);
}
