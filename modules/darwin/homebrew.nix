{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "none";
      autoUpdate = true;
      upgrade = false;
    };

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
}
