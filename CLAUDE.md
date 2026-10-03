# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Overview

nix-darwin + home-manager (システム管理) と chezmoi (dotfiles 管理) の**ハイブリッド構成**。

- **nix-darwin** (`nix/hosts/common.nix`): パッケージ / Homebrew / Zsh / macOS defaults
- **home-manager** (`nix/home.nix`): stateVersion / sessionPath のみ (最小構成)
- **chezmoi** (`chezmoi/`): dotfiles 一式 (git / nvim / ghostty / aws / claude 等)

## 主要なコマンド

```bash
# システム設定を適用 (personal マシン)
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#personal
# または zsh 関数で
rebuild

# ビルドのみ (適用しない)
darwin-rebuild build --flake ~/.dotfiles/nix#personal

# dotfiles を適用
moi apply       # = chezmoi apply
moi diff        # = chezmoi diff

# ロールバック
darwin-rebuild --rollback
```

## ディレクトリ構造

```
~/.dotfiles/
  nix/
    flake.nix              # Flake エントリポイント
    flake.lock             # 依存関係のロック
    hosts/common.nix       # システム設定 + Zsh + パッケージ
    home.nix               # home-manager (最小)
  chezmoi/
    .chezmoi.toml.tmpl     # sourceDir (+ nix 互換の machineType)
    .chezmoidata.yaml      # ホスト別の機能フラグ / nix 構成名
    .chezmoitemplates/     # 共有テンプレート (claude-settings.json)
    dot_agents/            # ~/.agents/skills (エージェント横断のスキル実体)
    dot_gitconfig          # ~/.gitconfig
    dot_p10k.zsh           # ~/.p10k.zsh
    dot_tmux.conf, dot_vimrc, dot_npmrc.tmpl
    private_dot_aws/       # ~/.aws/config (features.aws のホストのみ展開)
    private_dot_claude/    # ~/.claude/{CLAUDE.md,settings.json,rules,skills(symlink)}
    private_dot_codex/     # ~/.codex/{AGENTS.md,keybindings.json}
    private_dot_config/    # ~/.config/{ghostty,nvim,yazi,zellij,mise,lazygit,git,gh,herdr,
                           #            karabiner,ccstatusline}
    private_dot_ssh/       # ~/.ssh/config
    run_*                  # obsidian / mise install / codex skills
  README.md
  CLAUDE.md
  AGENTS.md
```

### マシンごとの違いの管理

マシンは `MacBook-Pro` (user: shiina) と `mbp-m1` (user: shina) の2台。
ユーザー名もホームのパスも違うので、次の3つのルールで吸収する。

1. **ホスト別の違いは `chezmoi/.chezmoidata.yaml` に集約する。**
   `features.<機能>` に「入れるホスト名」を並べ、テンプレートでは
   `{{ if has .chezmoi.hostname .features.aws }}` で分岐する。
   マシンや機能を足すときはこの表に書く。ファイル単位で要る/要らんを
   分けたいときは `.chezmoiignore` (テンプレート) で同じ条件を使う。
2. **ホームのパスをベタ書きしない。** `/Users/<name>/...` は
   `{{ .chezmoi.homeDir }}/...` にしてファイルを `.tmpl` にする。
3. **アプリが書き換えるファイルは丸ごと管理しない。**
   `~/.claude/settings.json` は `private_dot_claude/modify_private_settings.json.tmpl`
   が、`.chezmoitemplates/claude-settings.json` にあるトップレベルキー
   (env / permissions / hooks / statusLine / enabledPlugins /
   extraKnownMarketplaces / pluginConfigs) だけを置き換える。それ以外
   (language / model / modelSettings / effortLevel / autoMode など) は
   各マシンの値を残す。共有設定を変えるときはテンプレート側を編集する。

**ホームの現状を丸ごと `chezmoi add` / コピーで取り込まないこと。**
別マシンのパスやそのマシン専用の hook が混ざる (2026-10 に実際に起きた)。
取り込むときは `chezmoi diff` を見てキー・行単位で入れる。

`nix/flake.nix` は別系統で、ホスト名から `machineType`
(`MacBook-Pro` / `mbp-m1` → `personal`、それ以外 → `work`) を導出している。
chezmoi 側のテンプレートはもう `machineType` を使っていない。

## Zsh 設定の管理

`.zshrc` ファイルは存在しない。全 Zsh 設定は `nix/hosts/common.nix` の `programs.zsh` で宣言的に管理。

```nix
programs.zsh = {
  enable = true;
  promptInit = ''# p10k instant prompt'';
  interactiveShellInit = ''
    # プラグイン、エイリアス、関数など
  '';
};
```

設定内容 (`nix/hosts/common.nix`):
- **プラグイン**: powerlevel10k, fast-syntax-highlighting, autosuggestions, completions
- **エイリアス**: ls→lsd, cat→bat, vim→nvim, moi→chezmoi, git shortcuts, zellij shortcuts
- **関数**: `repo()`, `gd()`, `rgf()` (FZF統合), `rebuild()` (darwin-rebuild wrapper)
- **FZF / zoxide / mise**: 初期化とキーバインド

設定変更の流れ:
1. `nix/hosts/common.nix` を編集
2. `rebuild` で適用 → Nix が `/etc/zshrc` を自動更新

## chezmoi dotfiles の管理

設定変更の流れ:
1. `chezmoi/` 配下のファイルを直接編集
2. `moi apply` で反映

新マシンでの初回セットアップ:
```bash
chezmoi init --source=~/.dotfiles/chezmoi
chezmoi apply
```

## 設定されているツール

### CLIツール (nixpkgs)
neovim, vim, lsd, ripgrep, fd, ghq, jq, bat, fzf, zoxide, git-open, yazi, delta,
gh, lazygit, zellij, mise, pnpm, chezmoi, claude-code-bin

### Zsh プラグイン (nixpkgs)
powerlevel10k, fast-syntax-highlighting, zsh-autosuggestions, zsh-completions

### GUI アプリ (Homebrew casks)
ghostty, alt-tab, aqua-voice, codex, docker-desktop, google-chrome,
karabiner-elements, obsidian, raycast, cmux, scroll-reverser, slack, tailscale-app

## 注意事項

- `nix/hosts/common.nix` の personal 分岐は machineType == "personal" でガード
- `chezmoi/private_dot_aws/config.tmpl` は `.chezmoidata.yaml` の `features.aws` で分岐
- `private_dot_config/nvim/.chezmoiignore` で lazy-lock.json を追跡除外
- Claude settings.json は部分管理 (上の「マシンごとの違いの管理」参照)。
  `language` などの動的なキーは chezmoi の差分に出ない
- **`run_onchange_*` で `{{ include ... | sha256sum }}` を使うならファイル名を
  `.tmpl` で終わらせること。** サフィックスがないとテンプレート展開されず、
  ハッシュ行がただのコメント文字列になって再実行が一切効かなくなる
- **chezmoi 管理のスキルは実体を `dot_agents/skills/<name>/` (→ `~/.agents/skills/`) に
  置き、`~/.claude/skills/<name>` へは `private_dot_claude/skills/symlink_<name>.tmpl`
  (中身は `{{ .chezmoi.homeDir }}/.agents/skills/<name>`) で symlink を張る。**
  `.claude/skills/` 直下に実体を置かないこと。Claude Code が読むのは
  `~/.claude/skills/` (symlink 経由で実体に到達する)
- `~/.claude/agent/skills/` は同内容の重複コピーで管理外
- **`~/.agents/.skill-lock.json` (skills CLI) 経由で入れたスキルも chezmoi で追跡する。**
  cloudflare/skills・mattpocock/skills 等から入れた実体を `dot_agents/skills/` に
  コピーして管理下に置く。skills CLI で更新したら差分を取り込み直すこと
- `dot_agents/skills/herdr/SKILL.md` は herdr バイナリ同梱版の写し。
  herdr を更新したら `herdr --skill > chezmoi/dot_agents/skills/herdr/SKILL.md`
  で再生成すること (自動追従はしない)

### 意図的に追跡しないもの

`chezmoi/.chezmoiignore` に理由付きで記載。大別すると2種類:

1. **認証情報を含む** — `.config/gh/hosts.yml` / `.config/raycast/config.json`
2. **ツール側が上書きする** — herdr の hook スクリプト (`managed by herdr` と明記)、
   `.config/zed/settings.json` や codexbar など GUI 操作で書き換わるもの
