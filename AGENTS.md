# リポジトリガイドライン

日本語で応答する。

## 構成と編集先

nix-darwin + home-manager（システム管理）と chezmoi（dotfiles 管理）のハイブリッド構成。

- `nix/flake.nix`: input と Darwin 構成。`personal` はユーザー `shiina`、`mbp-m1` は `shina`。
- `nix/hosts/common.nix`: パッケージ、Homebrew、macOS defaults。`nix/home.nix` は最小構成。
- `chezmoi/`: dotfiles の編集元。Zsh は `dot_zshrc.tmpl`、アプリ設定は `private_dot_config/`。
- `chezmoi/private_dot_codex/AGENTS.md`: 全プロジェクトに共通する Codex の個人設定。
- `chezmoi/dot_agents/skills/`: 共有スキルの実体。Codex は展開先 `~/.agents/skills/` を直接読む。Claude 用リンクは `private_dot_claude/skills/symlink_<name>.tmpl`。

展開先のホームディレクトリやプラグインキャッシュを直接編集せず、管理元を変更する。
`~/.codex/config.toml` はアプリが更新するため管理対象外。認証情報や実行時データを追加しない。

## 作業と検証

既存の未コミット変更を保持し、依頼と無関係な変更を混ぜない。Nix は2スペース、その他は既存の形式に従う。

- 差分確認: `git diff --check` と対象ファイルの差分。
- chezmoi の展開確認: `chezmoi --source "$PWD/chezmoi" cat <展開先の絶対パス>`。テンプレートは `execute-template` で確認する。
- シェルを変更したら構文チェックを行い、ファイル操作は一時ディレクトリでも検証する。
- 構成ビルド: `darwin-rebuild build --flake "$PWD/nix#personal"`。実行できない場合は原因と未検証事項を報告する。
- ホスト分岐を変える場合は `personal` / `mbp-m1` と hostname 由来の `machineType` への影響を示す。

`chezmoi apply`（`moi apply`）、`darwin-rebuild switch`（`rebuild`）、`nix flake update` は検証とは別の操作。ユーザーが適用禁止を指定した場合は実行しない。適用が依頼されていない作業は編集と検証までに留める。

`run_onchange_*` で Go テンプレートを使うファイルには `.tmpl` を付ける。スキルの追加・更新ではリンクと参照先も確認する。外部配布スキルは更新元を維持し、無関係な一括書き換えを避ける。

## コミットとPR

コミットは目的ごとにまとめ、`feat:` / `fix:` / `chore:` 等の Conventional Commits を使う。PRにはユーザーへの影響と実行した検証を記載する。UI変更時のみスクリーンショットを添付する。シークレットや秘密鍵、マシン固有の認証情報をコミットしない。
