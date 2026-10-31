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
│   ├── .chezmoi.toml.tmpl        # sourceDir
│   ├── .chezmoidata.yaml         # ホスト別の機能フラグ
│   ├── .chezmoidata/skills.yaml  # npx skills で入れる外部スキルの宣言
│   ├── .chezmoitemplates/        # 共有テンプレート (claude-settings.json)
│   ├── .chezmoiignore            # 自動生成ファイルを追跡から除外
│   ├── dot_zshrc.tmpl            # zsh 設定一式 (プラグイン/エイリアス/関数)
│   ├── dot_zprofile              # brew shellenv
│   ├── dot_gitconfig
│   ├── dot_p10k.zsh, dot_tmux.conf, dot_vimrc, dot_npmrc.tmpl
│   ├── private_dot_aws/          # ~/.aws/config (features.aws のホストのみ展開)
│   ├── private_dot_claude/       # ~/.claude/ (CLAUDE.md / settings.json / hooks / skills)
│   ├── dot_agents/               # ~/.agents/skills/ (自作スキルの実体)
│   ├── private_dot_codex/        # ~/.codex/ (AGENTS.md / keybindings.json)
│   ├── private_dot_config/       # ~/.config/{ghostty,nvim,yazi,zellij,mise,lazygit,git,gh,...}
│   ├── private_dot_ssh/          # ~/.ssh/config
│   └── run_*                     # obsidian / mise / Codex の MCP 追記 / 外部スキル導入
├── README.md
├── CLAUDE.md                     # @AGENTS.md だけ (Claude Code 用の入口)
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

マシンごとの違いは `chezmoi/.chezmoidata.yaml` に集約している (機能ごとに入れるホスト名を並べる)。
`~/.claude/settings.json` は共有するキーだけを chezmoi が置き換える部分管理。詳細は `chezmoi/README.md` を参照。
nix 側は `nix/flake.nix` の `darwinConfigurations` に hostname と同じ名前で構成を書く (`mbp-m5` / `mbp-m1`)。2 台の違いはユーザー名だけ。

## 新マシンセットアップ

```bash
# 1. Nix インストール
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. リポジトリを clone
git clone https://github.com/yushi265/nix-dotfiles.git ~/.dotfiles

# 3. nix-darwin を適用
nix run nix-darwin -- switch --flake ~/.dotfiles/nix#<hostname>  # mbp-m5 / mbp-m1

# 4. chezmoi で dotfiles を展開
chezmoi init --source=~/.dotfiles/chezmoi
chezmoi apply
```

## 日常操作

```bash
# システム設定を変更・適用 (パッケージ追加、macOS defaults 等)
rebuild                        # = sudo darwin-rebuild switch --flake ~/.dotfiles/nix#<hostname>

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

## Codexの設定管理

- このリポジトリの作業指示は `AGENTS.md`、全プロジェクト共通の個人設定は `chezmoi/private_dot_codex/AGENTS.md` で管理する。
- 自作スキルの実体は `chezmoi/dot_agents/skills/<name>/` に置く。外部スキルは `chezmoi/.chezmoidata/skills.yaml` に宣言し、`run_onchange_after_05-skills-install.sh.tmpl` が `npx skills add -g` で入れる。hooks や MCP を伴うものは Claude Code プラグインにする。CodexとCursorは `~/.agents/skills/` を直接読み、Claude Codeは `~/.claude/skills/` のリンク経由で読む。追加・更新・削除の手順は `manage-skills` スキルにまとめている。
- `~/.codex/config.toml`、認証情報、履歴、プラグインキャッシュは管理しない。モデルや権限設定はこの変更の対象外。
- プラグインとローカルに類似スキルがある場合は、使う配布元を選ぶ。プラグイン側の削除・無効化はこのリポジトリの移行処理では行わない。

適用せずに確認するには、リポジトリのルートで以下を実行する。

```bash
git diff --check
chezmoi --source "$PWD/chezmoi" cat "$HOME/.codex/AGENTS.md"
python3 -B -m unittest discover -s tests -v
darwin-rebuild build --flake "$PWD/nix#$(hostname -s)"
```

テストは一時ディレクトリでスクリプトを検証し、実ホームにはapplyしない。
共有スキルの変更は、適用後にはClaude Codeにも反映される。

仕様の参照先: [AGENTS.mdの読み込み](https://learn.chatgpt.com/docs/agent-configuration/agents-md)、[スキルの配置と検出](https://learn.chatgpt.com/docs/build-skills)。
