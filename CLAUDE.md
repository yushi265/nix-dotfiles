# CLAUDE.md

Guidance for Claude Code when working with this nix-darwin + home-manager dotfiles repo.

## 主要コマンド

```bash
rebuild                          # sudo darwin-rebuild switch --flake ~/.dotfiles#personal
darwin-rebuild build --flake .#personal  # ビルドのみ（適用しない）
darwin-rebuild --rollback        # 前の世代にロールバック
```

## ディレクトリ構造

```
~/.dotfiles/
  flake.nix              # Flake entry point・mkDarwinSystem ヘルパー
  home.nix               # home-manager オーケストレーター（imports のみ）
  hosts/
    common.nix           # nix-darwin オーケストレーター（imports のみ）
  modules/
    darwin/
      packages.nix       # environment.systemPackages
      zsh.nix            # programs.zsh（plugin 読み込み・FZF・tools）
      homebrew.nix       # homebrew casks
      system.nix         # macOS defaults + users
    home/
      git.nix            # programs.git + delta
      aws.nix            # programs.awscli（personal only）
      files.nix          # xdg.configFile + home.file + sessionPath
      vscode.nix         # programs.vscode
      activation.nix     # home.activation（nvim/claude/codex/mise）
  configs/
    zsh/
      aliases.zsh        # エイリアス定義
      functions.zsh      # repo() / gd() / rgf()
    scripts/
      agent-configs.sh   # Claude/Codex 設定デプロイスクリプト
    p10k.zsh             # Powerlevel10k 設定
    ghostty-config       # Ghostty 設定
    nvim/                # Neovim (LazyVim)
    yazi/                # Yazi ファイルマネージャ
    agent/skills/        # 共有スキル（Claude/Codex 両方で使用）
    claude-settings.json / claude-claude-md.md
    codex-config.toml / codex-agents-md.md
```

## 設定変更のガイド

| やりたいこと | 編集するファイル |
|---|---|
| パッケージ追加 | `modules/darwin/packages.nix` |
| エイリアス追加 | `configs/zsh/aliases.zsh` |
| シェル関数追加 | `configs/zsh/functions.zsh` |
| Zsh plugin / FZF / tools | `modules/darwin/zsh.nix` |
| macOS 設定 (Dock 等) | `modules/darwin/system.nix` |
| Homebrew cask 追加 | `modules/darwin/homebrew.nix` |
| dotfile 追加 | `modules/home/files.nix` |
| Git 設定 | `modules/home/git.nix` |

## アーキテクチャ

- **nix-darwin** (`hosts/common.nix`): システムレベル — パッケージ、Zsh、Homebrew、macOS 設定
- **home-manager** (`home.nix`): ユーザーレベル — dotfiles、Git、VSCode、activation scripts
- `.zshrc` は存在しない。Nix が `/etc/zshrc` を生成する
- `machineType` は `flake.nix` でホスト名から自動判定（"MacBook-Pro" → `personal`、その他 → `work`）

## マシンタイプ別設定

`machineType` は `specialArgs`/`extraSpecialArgs` 経由で全モジュールに渡される。
personal 専用設定の例（`modules/darwin/zsh.nix` 末尾、`modules/home/aws.nix`）:

```nix
lib.mkIf (machineType == "personal") { ... }
```

## トラブルシューティング

```bash
# 詳細トレース
darwin-rebuild switch --flake ~/.dotfiles#personal --show-trace

# GC（30日以上前の世代を削除）
nix-collect-garbage --delete-older-than 30d
```

## 注意事項

- `configs/zsh/*.zsh` と `configs/scripts/*.sh` は純粋なシェルファイル（Nix エスケープ不要）
- `home.activation.agentConfigs` は Nix store パスを env var で渡してから `agent-configs.sh` を実行
- Claude `settings.json` の `language` フィールドは動的に変更される
