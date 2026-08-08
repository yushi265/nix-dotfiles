# configName は rebuild() が chezmoi (~/.zshrc) へ移ったため未使用。
# flake.nix からは引き続き渡されるが ... で受け流す。
{ pkgs, lib, machineType, username, ... }:

{
  # Nix settings
  # Using Determinate Systems installer, so let it manage Nix
  nix.enable = false;

  # Allow unfree packages (ssm-session-manager-plugin 等)
  nixpkgs.config.allowUnfree = true;

  # zsh の設定を chezmoi (~/.zshrc) 側から source するため、nix store の
  # ハッシュ付きパスではなく /run/current-system/sw/share/ 配下の安定パスで
  # 参照できるようにする。デフォルトの pathsToLink は /share/zsh までしか
  # 含まないため、p10k のテーマ本体と fzf のキーバインドが出てこない。
  environment.pathsToLink = [
    "/share/zsh-powerlevel10k"
    "/share/fzf"
  ];

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
    gh
    lazygit
    zellij
    pnpm
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

    # zsh の設定は chezmoi (chezmoi/dot_zshrc.tmpl -> ~/.zshrc) で管理している。
    # nix が担当するのはパッケージの提供のみで、シェル設定は生成しない。
    # プラグイン本体は environment.systemPackages にあり、~/.zshrc からは
    # /run/current-system/sw/share/ 配下の安定パスで source している。
    #
    # promptInit は空にしておくこと。既定値のままだと nix-darwin が
    # /etc/zshrc にプロンプト初期化を出力し、~/.zshrc 側と二重に走る。
    promptInit = "";
  };

  # Homebrew integration for GUI apps
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "none";
      autoUpdate = true;
      upgrade = false;
    };

    # CLI tools that need to track upstream faster than nixpkgs
    # (nixpkgs lags mise by ~1-2 weeks; upgrade with `brew upgrade mise`)
    brews = [
      "mise"
    ];

    # GUI applications (macOS-specific tools only)
    # Most GUI apps are now managed via nixpkgs in environment.systemPackages
    casks = [
      # p10k のアイコン表示に必要 (~/.p10k.zsh の POWERLEVEL9K_MODE=nerdfont-v3)。
      # ghostty の font-family もこのフォント名を指している。
      "font-jetbrains-mono-nerd-font"

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
      "1password"
      "slack"
      "tailscale-app"
      "zed"
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
