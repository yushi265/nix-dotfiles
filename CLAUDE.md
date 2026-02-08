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

## Zsh設定の管理

### `programs.zsh`による宣言的管理

**重要**: `.zshrc`ファイルは存在しません。全てのZsh設定は`hosts/common.nix`の`programs.zsh`セクションで宣言的に管理されています。

```nix
programs.zsh = {
  enable = true;
  promptInit = ''
    # p10k instant prompt
  '';
  interactiveShellInit = ''
    # プラグイン、エイリアス、関数など全ての設定
  '';
};
```

### 設定内容（hosts/common.nix:48-262）

- **プラグイン**: p10k, fast-syntax-highlighting, autosuggestions, completions
- **エイリアス**: ls→lsd, cat→bat, vim→nvim, git shortcuts等
- **関数**: `repo()`, `gd()`, `rgf()` - FZF統合の便利関数
- **FZF**: キーバインド、プレビュー、fd/bat統合
- **Zoxide**: スマートcd (`z`コマンド)

### マシンタイプ別設定

`machineType`変数で条件分岐（254-261行目）:

```nix
'' + (if machineType == "personal" then ''
  export PATH="$HOME/.bun/bin:$PATH"
  alias coleta-next="/Users/shina/documents/coleta/coleta-next"
  # ... personal専用のエイリアス
'' else "");
```

### 設定変更の流れ

1. `hosts/common.nix`の`programs.zsh.interactiveShellInit`を編集
2. `sudo darwin-rebuild switch --flake ~/.dotfiles`で適用
3. Nixが自動的に`/etc/zshrc`を生成・更新

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
