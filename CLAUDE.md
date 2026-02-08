# CLAUDE.md

This file provides guidance to Claude Code when working with this Nix configuration.

## Overview

これは nix-darwin で管理された macOS dotfiles リポジトリです。
chezmoi から Nix への移行が完了し、全ての設定が宣言的に管理されています。

## 主要なコマンド

```bash
# 設定の変更を適用
sudo darwin-rebuild switch --flake ~/.dotfiles

# 設定をビルドのみ（適用しない）
darwin-rebuild build --flake ~/.dotfiles

# 前の世代にロールバック
darwin-rebuild --rollback
```

## アーキテクチャ

### ディレクトリ構造

```
~/.dotfiles/
  flake.nix              # Flake entry point
  flake.lock             # 依存関係のロック
  hosts/
    common.nix           # システム設定 + Zsh + パッケージ
  configs/
    p10k.zsh             # Powerlevel10k設定
    ghostty-config       # Ghostty設定
    nvim/                # Neovim (LazyVim)
    yazi/                # Yaziファイルマネージャ
    vimrc                # Vim設定
    claude-settings.json # Claude Code設定
    rotate-language.sh   # 言語ローテーションスクリプト
```

### マシンタイプ切り替え

`flake.nix` でホスト名から `machineType` を自動判定:
- "MacBook-Pro" → `personal`
- その他 → `work`

`machineType` は全モジュールに `extraSpecialArgs` で渡され、
条件分岐に使用されます（例: personal専用のaliases）。

## 設定されているツール

### CLIツール（nixpkgs）
- neovim, vim, lsd, ripgrep, fd, ghq, jq
- bat, fzf, zoxide, git-open, yazi, delta

### Zshプラグイン（nixpkgs）
- powerlevel10k
- fast-syntax-highlighting
- zsh-autosuggestions
- zsh-completions

### GUIアプリ（Homebrew casks）
- Ghostty

## 依存関係

- **Nix**: パッケージマネージャ（Determinate Systems installer推奨）
- **nix-darwin**: macOS システム設定管理
- **Homebrew**: GUI アプリケーション管理（nix-darwin統合）

## 新しいマシンでの環境構築

```bash
# 1. Nixをインストール
sh <(curl -L https://nixos.org/nix/install)

# 2. このリポジトリをclone
git clone <repository-url> ~/.dotfiles

# 3. 設定を適用（初回はsudoが必要）
cd ~/.dotfiles
nix run nix-darwin -- switch --flake .

# 4. 以降は通常のコマンドで
sudo darwin-rebuild switch --flake ~/.dotfiles
```

## トラブルシューティング

### ビルドエラー
```bash
# 詳細なトレースを表示
darwin-rebuild switch --flake ~/.dotfiles --show-trace
```

### 前の世代にロールバック
```bash
darwin-rebuild --rollback
```

### Nixストアの最適化
```bash
# ガベージコレクション（30日以上前の世代を削除）
nix-collect-garbage --delete-older-than 30d

# ストアの最適化
nix-store --optimise
```

## 注意事項

- activationScriptは全てrootとして実行されるため、ユーザー設定は `sudo -u shina HOME=/Users/shina` で実行
- lazyvim.jsonはLazyVimが書き込み可能な状態で管理（gitignore推奨）
- Claude settings.jsonの`language`フィールドは動的に変更されます
