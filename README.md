# 🏗️ Nixベース macOS設定

**nix-darwin + home-manager**を使用した宣言的macOSシステム設定。システム設定からdotfilesまで全てを管理します。

## ✨ 特徴

- 🔧 **完全宣言的**: 全ての設定がNixで定義されています
- 🔄 **再現可能**: どのMacでもクローンして再構築可能
- 📦 **統合パッケージ管理**: CLIツールはnixpkgs、GUIアプリはHomebrew経由
- 🏠 **home-manager統合**: ユーザー設定とdotfilesを宣言的に管理
- 🎨 **美しいシェル**: Powerlevel10k、fzf、zoxideなどを備えたZsh
- 🌈 **開発者フレンドリー**: Neovim (LazyVim)、Git (delta)、Ghosttyを事前設定
- 🔀 **マルチマシン対応**: 個人用/会社用設定を自動検出で切り替え

## 📋 前提条件

- macOS (macOS 15.5+でテスト済み)
- 管理者権限 (初回インストール時)

## 🚀 クイックスタート

### 1. Nixのインストール

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. リポジトリをクローン

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 3. 設定を適用

```bash
# 初回セットアップ (nix-darwinをインストール)
nix run nix-darwin -- switch --flake .#personal
# または
nix run nix-darwin -- switch --flake .#personal-old

# 以降の更新
sudo darwin-rebuild switch --flake ~/.dotfiles#personal
# または
sudo darwin-rebuild switch --flake ~/.dotfiles#personal-old
```

### 4. ターミナルを再起動

新しいターミナルウィンドウを開いて、新しい設定を確認しましょう!

## 📦 含まれているもの

### CLIツール

- **シェル**: Powerlevel10kテーマ付きZsh
- **エディタ**: Neovim (LazyVim)、Vim
- **ファイル管理**: yazi、lsd、fd、ripgrep
- **Git**: deltaによる差分ビューアーで強化
- **ユーティリティ**: fzf、zoxide、bat、jq、ghq

### Zsh機能

- 🎨 Powerlevel10k instant prompt
- 🌈 シンタックスハイライト
- 💡 自動補完
- 🔍 インタラクティブなファジー検索 (fzf)
- 📂 スマートディレクトリジャンプ (zoxide)
- 🎯 カスタム関数: `repo()`, `gd()`, `rgf()`

### GUIアプリケーション

- **Ghostty**: モダンなGPUアクセラレーション対応ターミナルエミュレータ

### システム設定

- macOSデフォルト設定 (Dock、Finder、キーボードリピート速度)
- 自動Nixストア最適化
- スケジュール済みガベージコレクション

## 🗂️ ディレクトリ構造

```
~/.dotfiles/
├── flake.nix                 # メインNix flake設定
├── flake.lock                # 依存関係ロックファイル
├── hosts/
│   └── common.nix            # システム設定、パッケージ、Zsh
├── home.nix                  # home-manager ユーザー設定
├── configs/
│   ├── p10k.zsh              # Powerlevel10kテーマ
│   ├── ghostty-config        # Ghosttyターミナル設定
│   ├── nvim/                 # Neovim (LazyVim) 設定
│   ├── yazi/                 # Yaziファイルマネージャーテーマ
│   ├── vimrc                 # Vim設定
│   ├── claude-settings.json  # Claude Code設定
│   └── rotate-language.sh    # 言語ローテーションスクリプト
├── CLAUDE.md                 # Claude Codeガイダンス
├── README.md                 # このファイル
└── .gitignore
```

## ⚙️ カスタマイズ

### マシン固有設定

ホスト名に基づいてマシンタイプを自動検出します:
- ホスト名に "MacBook-Pro" が含まれる → `machineType = "personal"`
- その他のホスト名 → `machineType = "work"`

個人用固有のエイリアスとPATHは`hosts/common.nix`で条件付き適用されます。

### パッケージの追加

`hosts/common.nix`を編集:

```nix
environment.systemPackages = with pkgs; [
  # ここにパッケージを追加
  htop
  tmux
  # ...
];
```

### Zshのカスタマイズ

`hosts/common.nix`の`programs.zsh.interactiveShellInit`セクションを変更して、エイリアス、関数、シェル設定を追加します。

### Homebrew Casksの追加

`hosts/common.nix`の`homebrew.casks`リストを編集:

```nix
homebrew.casks = [
  "ghostty"
  "rectangle"  # 例: ウィンドウマネージャー
];
```

## 🔧 よくあるタスク

### パッケージの更新

```bash
# flakeの入力を更新
cd ~/.dotfiles
nix flake update

# 新しいパッケージでリビルド
sudo darwin-rebuild switch --flake .
```

### 前の世代にロールバック

```bash
sudo darwin-rebuild --rollback
```

### 古い世代のクリーンアップ

```bash
# 30日以上前の世代を削除
nix-collect-garbage --delete-older-than 30d

# Nixストアを最適化
nix-store --optimise
```

### 適用せずに変更をプレビュー

```bash
darwin-rebuild build --flake ~/.dotfiles
```

## 🐛 トラブルシューティング

### ビルドエラー

```bash
# 詳細なエラートレースを表示
darwin-rebuild switch --flake ~/.dotfiles --show-trace
```

### クリーンな状態にリセット

```bash
# 前の動作する世代にロールバック
sudo darwin-rebuild --rollback
```

### Nix daemonの問題

```bash
# nix-daemonを再起動
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

## 🏗️ アーキテクチャ

### nix-darwin vs home-manager

- **nix-darwin** (`hosts/common.nix`): システムレベルの設定
  - パッケージのインストール
  - Zsh設定
  - macOSシステム設定（Dock、Finder等）
  - Homebrewアプリケーション

- **home-manager** (`home.nix`): ユーザーレベルの設定
  - Git設定（delta統合）
  - dotfilesのシンボリックリンク管理
  - アプリケーション固有設定

### 設定ファイルの管理

home-managerが全てのdotfilesを自動的にシンボリックリンクで管理します:

```nix
# home.nix の例
xdg.configFile = {
  "ghostty/config".source = ./configs/ghostty-config;
  "nvim".source = ./configs/nvim;
};

home.file = {
  ".vimrc".source = ./configs/vimrc;
};
```

既存のファイルは `.backup` 拡張子で自動バックアップされます。

## 📚 リソース

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [Nixpkgs Search](https://search.nixos.org/packages)
- [Nix Language Basics](https://nixos.org/manual/nix/stable/language/)

## 🙏 謝辞

- [nix-darwin](https://github.com/LnL7/nix-darwin) - NixによるmacOS設定
- [home-manager](https://github.com/nix-community/home-manager) - ユーザー環境管理
- [LazyVim](https://www.lazyvim.org/) - Neovim設定
- [Catppuccin](https://github.com/catppuccin) - 優しいパステルテーマ
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zshテーマ

## 📝 ライセンス

この設定は個人使用のために現状のまま提供されています。自由にフォークしてカスタマイズしてください!

---

**注意**: これは個人用の設定です。使用前にホスト名、ユーザー名、マシン固有の設定を調整してください。
