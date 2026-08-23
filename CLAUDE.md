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
    .chezmoi.toml.tmpl     # machineType 自動判定 + sourceDir
    dot_agents/            # ~/.agents/skills (エージェント横断のスキル実体)
    dot_gitconfig          # ~/.gitconfig
    dot_p10k.zsh           # ~/.p10k.zsh
    dot_tmux.conf, dot_vimrc, dot_npmrc
    private_dot_aws/       # ~/.aws/config (machineType template)
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

### machineType 判定

`nix/flake.nix` と `chezmoi/.chezmoi.toml.tmpl` の両方でホスト名から自動判定:
- hostname に "MacBook-Pro" を含む or "mbp-m1" → `personal`
- それ以外 → `work`

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
- `chezmoi/private_dot_aws/config.tmpl` も machineType で分岐 (personal のみ展開)
- `private_dot_config/nvim/.chezmoiignore` で lazy-lock.json を追跡除外
- Claude settings.json の `language` フィールドは動的に変更される
- **`run_onchange_*` で `{{ include ... | sha256sum }}` を使うならファイル名を
  `.tmpl` で終わらせること。** サフィックスがないとテンプレート展開されず、
  ハッシュ行がただのコメント文字列になって再実行が一切効かなくなる
- **chezmoi 管理のスキルは実体を `dot_agents/skills/<name>/` (→ `~/.agents/skills/`) に
  置き、`~/.claude/skills/<name>` へは `private_dot_claude/skills/symlink_<name>.tmpl`
  (中身は `{{ .chezmoi.homeDir }}/.agents/skills/<name>`) で symlink を張る。**
  `.claude/skills/` 直下に実体を置かないこと。Claude Code が読むのは
  `~/.claude/skills/` (symlink 経由で実体に到達する)
- `~/.claude/agent/skills/` は同内容の重複コピーで管理外
- `dot_agents/skills/herdr/SKILL.md` は herdr バイナリ同梱版の写し。
  herdr を更新したら `herdr --skill > chezmoi/dot_agents/skills/herdr/SKILL.md`
  で再生成すること (自動追従はしない)

### 意図的に追跡しないもの

`chezmoi/.chezmoiignore` に理由付きで記載。大別すると3種類:

1. **認証情報を含む** — `.config/gh/hosts.yml` / `.config/raycast/config.json`
2. **ツール側が上書きする** — herdr の hook スクリプト (`managed by herdr` と明記)、
   `.config/zed/settings.json` や codexbar など GUI 操作で書き換わるもの
3. **別リポジトリ・外部が正** — `grill-me` (`~/.agents/.skill-lock.json` 管理)
