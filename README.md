# dotfiles

nix-darwin + home-manager (システム管理) と chezmoi (dotfiles 管理) のハイブリッド構成。

## ディレクトリ構造

```
~/.dotfiles/
├── nix/                          # nix-darwin + home-manager
│   ├── flake.nix                 # Flake エントリポイント
│   ├── flake.lock
│   ├── hosts/common.nix          # パッケージ / Homebrew / macOS 設定
│   └── home.nix                  # home-manager (最小構成)
├── chezmoi/                      # dotfiles (chezmoi 管理)
│   ├── .chezmoi.toml.tmpl        # machineType 自動判定 + sourceDir
│   ├── .chezmoiignore            # 自動生成ファイルを追跡から除外
│   ├── dot_zshrc.tmpl            # zsh 設定一式 (プラグイン/エイリアス/関数)
│   ├── dot_zprofile              # brew shellenv
│   ├── dot_gitconfig
│   ├── dot_p10k.zsh, dot_tmux.conf, dot_vimrc, dot_npmrc
│   ├── private_dot_aws/          # ~/.aws/config (machineType template)
│   ├── private_dot_claude/       # ~/.claude/
│   ├── private_dot_codex/        # ~/.codex/
│   ├── private_dot_config/       # ~/.config/{ghostty,nvim,yazi,zed,zellij,mise,lazygit,Code,...}
│   ├── private_dot_ssh/          # ~/.ssh/config
│   └── run_*                     # mise / VSCode 拡張 / obsidian / codex skills
├── README.md
├── CLAUDE.md
└── AGENTS.md
```

## 役割分担

| 管轄 | 担当 |
|---|---|
| **nix-darwin** (`nix/hosts/common.nix`) | CLI パッケージ / Homebrew casks+brews / macOS defaults |
| **home-manager** (`nix/home.nix`) | stateVersion のみ (最小) |
| **chezmoi** (`chezmoi/`) | dotfiles 一式 (zsh / git / nvim / ghostty / herdr / claude 等) |

Zsh 設定は `chezmoi/dot_zshrc.tmpl` に集約している。nix はプラグイン本体を
`environment.systemPackages` で提供するだけで、`~/.zshrc` から
`/run/current-system/sw/share/` 配下の安定パスを source する。

machineType は hostname から自動判定: `MacBook-Pro` / `mbp-m1` → `personal`、それ以外 → `work`

## 新マシンセットアップ

```bash
# 1. Nix インストール
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. リポジトリを clone
git clone https://github.com/yushi265/nix-dotfiles.git ~/.dotfiles

# 3. nix-darwin を適用
nix run nix-darwin -- switch --flake ~/.dotfiles/nix#personal

# 4. chezmoi で dotfiles を展開
chezmoi init --source=~/.dotfiles/chezmoi
chezmoi apply
```

## 日常操作

```bash
# システム設定を変更・適用 (パッケージ追加、macOS defaults 等)
rebuild                        # = sudo darwin-rebuild switch --flake ~/.dotfiles/nix#...

# dotfiles を変更・適用 (zsh 設定もこちら。rebuild 不要)
moi diff                       # = chezmoi diff
moi apply                      # = chezmoi apply

# flake.lock を更新
cd ~/.dotfiles/nix && nix flake update
rebuild

# mise だけ更新 (nixpkgs は追随が 1-2 週間遅れるため Homebrew 管理)
brew upgrade mise
```

## パッケージ追加

```bash
# CLI ツール: nix/hosts/common.nix の environment.systemPackages に追加
# GUI アプリ: nix/hosts/common.nix の homebrew.casks に追加
rebuild
```

## ロールバック

```bash
sudo darwin-rebuild --rollback
```
