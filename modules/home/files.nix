{ ... }:

{
  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  xdg.configFile = {
    "mise/config.toml".text = ''
      [tools]
      node = "lts"
      bun = "latest"
    '';
    "ghostty/config".source = ../../configs/ghostty-config;
    "yazi".source = ../../configs/yazi;
    "karabiner/karabiner.json".source = ../../configs/karabiner.json;
    "zed/settings.json".source = ../../configs/zed-settings.json;
    "zellij".source = ../../configs/zellij;
  };

  home.file = {
    ".vimrc".source = ../../configs/vimrc;
    ".ssh/config".source = ../../configs/ssh-config;
    ".tmux.conf".source = ../../configs/tmux.conf;
    ".npmrc".source = ../../configs/npmrc;
  };
}
