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
│   ├── private_dot_claude/       # ~/.claude/ (CLAUDE.md / settings.json / rules / skills)
│   ├── dot_agents/               # ~/.agents/skills/ (共有スキルの実体)
│   ├── private_dot_codex/        # ~/.codex/ (AGENTS.md / keybindings.json)
│   ├── private_dot_config/       # ~/.config/{ghostty,nvim,yazi,zellij,mise,lazygit,git,gh,...}
│   ├── private_dot_ssh/          # ~/.ssh/config
│   └── run_*                     # obsidian / mise / 旧Codexスキルリンクの移行
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

## Codexの設定管理

- このリポジトリの作業指示は `AGENTS.md`、全プロジェクト共通の個人設定は `chezmoi/private_dot_codex/AGENTS.md` で管理する。
- スキルの実体は `chezmoi/dot_agents/skills/<name>/` に置く。Codexは展開先の `~/.agents/skills/` を直接読み、Claude Codeは `~/.claude/skills/` のリンク経由で読む。
- `run_onchange_after_03-codex-skills-symlink.sh.tmpl` は旧構成からの移行用。将来のapply時に、管理対象かつ同じ実体へ到達する `~/.codex/skills/` → `~/.claude/skills/` の旧リンクだけを削除する。実体、独自リンク、管理外スキル、`.system` は保持する。廃止した `fable5` の実体と旧リンク・ルールは `.chezmoiremove` で削除する。
- `~/.codex/config.toml`、認証情報、履歴、プラグインキャッシュは管理しない。モデルや権限設定はこの変更の対象外。
- プラグインとローカルに類似スキルがある場合は、使う配布元を選ぶ。プラグイン側の削除・無効化はこのリポジトリの移行処理では行わない。

適用せずに確認するには、リポジトリのルートで以下を実行する。

```bash
git diff --check
chezmoi --source "$PWD/chezmoi" cat "$HOME/.codex/AGENTS.md"
python3 -B -m unittest discover -s tests -p 'test_codex_skills_migration.py' -v
darwin-rebuild build --flake "$PWD/nix#personal"
```

移行テストは一時ディレクトリでスクリプトと削除指定を検証し、実ホームにはapplyしない。
共有スキルの変更は、適用後にはClaude Codeにも反映される。

仕様の参照先: [AGENTS.mdの読み込み](https://learn.chatgpt.com/docs/agent-configuration/agents-md)、[スキルの配置と検出](https://learn.chatgpt.com/docs/build-skills)。
