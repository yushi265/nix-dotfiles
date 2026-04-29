# nix-darwin dotfiles

nix-darwin + home-manager による macOS 設定の宣言的管理。

## セットアップ

```bash
# 1. Nix をインストール（Determinate Systems 推奨）
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. リポジトリをクローン
git clone https://github.com/yushi265/nix-dotfiles.git ~/.dotfiles

# 3. 初回適用
nix run nix-darwin -- switch --flake ~/.dotfiles#personal

# 4. 以降の更新（rebuild エイリアスが使える）
rebuild
```

## 構造

```
~/.dotfiles/
  flake.nix
  home.nix               # home-manager エントリーポイント
  hosts/common.nix       # nix-darwin エントリーポイント
  modules/
    darwin/
      packages.nix       # CLI ツール・エディタ
      zsh.nix            # Zsh・プラグイン・FZF
      homebrew.nix       # GUI アプリ (casks)
      system.nix         # macOS defaults
    home/
      git.nix            # Git + delta
      secrets.nix        # agenix secrets（AWS config など）
      files.nix          # dotfiles 配置
      vscode.nix         # VS Code
      activation.nix     # nvim / Claude / Codex セットアップ
  configs/
    zsh/
      aliases.zsh        # エイリアス
      functions.zsh      # repo() / gd() / rgf()
    scripts/
      agent-configs.sh   # Claude/Codex 設定デプロイ
    nvim/                # Neovim (LazyVim)
    ghostty-config       # Ghostty
    p10k.zsh             # Powerlevel10k
    ...
```

## よく使うカスタマイズ

| やりたいこと | ファイル |
|---|---|
| パッケージ追加 | `modules/darwin/packages.nix` |
| エイリアス追加 | `configs/zsh/aliases.zsh` |
| シェル関数追加 | `configs/zsh/functions.zsh` |
| GUI アプリ追加 | `modules/darwin/homebrew.nix` |
| dotfile 追加 | `modules/home/files.nix` |

編集後は `rebuild` で適用。

## マルチマシン対応

`flake.nix` がホスト名から `machineType` を自動判定:

- ホスト名に "MacBook-Pro" が含まれる → `personal`
- その他 → `work`

personal 専用設定（AWS config の secret、coleta エイリアス等）は `lib.mkIf (machineType == "personal")` で条件分岐。

## 参考

- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [Nixpkgs Search](https://search.nixos.org/packages)
