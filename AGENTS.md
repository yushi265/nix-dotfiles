# リポジトリガイドライン

日本語で応答する。

## 構成と編集先

nix-darwin + home-manager（システム管理）と chezmoi（dotfiles 管理）のハイブリッド構成。

- `nix/flake.nix`: input と Darwin 構成。`personal` はユーザー `shiina`、`mbp-m1` は `shina`。
- `nix/hosts/common.nix`: パッケージ、Homebrew、macOS defaults。`nix/home.nix` は最小構成。
- `chezmoi/`: dotfiles の編集元。Zsh は `dot_zshrc.tmpl`、アプリ設定は `private_dot_config/`。
- `chezmoi/README.md`: ホスト一覧、機能フラグ、マシンごとの違いの管理手順。
- `chezmoi/private_dot_codex/AGENTS.md`: 全プロジェクトに共通する Codex の個人設定。
- `chezmoi/dot_agents/skills/`: 共有スキルの実体（詳細は「スキル」を参照）。
- `README.md`: セットアップ、日常操作（`rebuild` / `moi apply`）、ロールバックの手順。
- `CLAUDE.md`: `@AGENTS.md` の1行だけ。Claude Code にこのファイルを読ませるための入口なので、内容はここに書く。

展開先のホームディレクトリやプラグインキャッシュを直接編集せず、管理元を変更する。

追跡しないものは `chezmoi/.chezmoiignore` に理由付きで書く。大別すると、認証情報を含むもの（`.config/gh/hosts.yml` など）と、ツール側が上書きするもの（herdr の実行時データ、`.config/zed/settings.json`、`.codex/config.toml` など）。`private_dot_config/nvim/.chezmoiignore` は `lazy-lock.json` を除外している。認証情報や実行時データを追加しない。

## マシンごとの違い

`MacBook-Pro`（ユーザー `shiina`）と `mbp-m1`（ユーザー `shina`）の2台で同じソースを共有する。詳細と手順は `chezmoi/README.md` を参照する。

- ホスト別の違いは `chezmoi/.chezmoidata.yaml` の `features` に書き、テンプレートでは `{{ if has .chezmoi.hostname .features.<機能> }}` で分岐する。
- ホームのパスはベタ書きせず `{{ .chezmoi.homeDir }}` を使い、ファイル名を `.tmpl` にする。
- アプリが書き換えるファイルは丸ごと管理しない。`~/.claude/settings.json` は部分管理で、共有設定は `chezmoi/.chezmoitemplates/claude-settings.json` を編集する。`~/.codex/config.toml` は管理対象外で、不足分だけスクリプトで追記する。
- ホームの現状を丸ごと `chezmoi add` やコピーで取り込まない。`chezmoi diff` を見てキー・行単位で入れる。
- nix 側は hostname 由来の `machineType`（2台とも `personal`）で分岐する。chezmoi のテンプレートでは `machineType` を使わない。
- ホスト分岐を変える場合は2台両方への影響を示し、`chezmoi/README.md` の表も更新する。

## スキル

- 実体は `chezmoi/dot_agents/skills/<name>/`（展開先 `~/.agents/skills/`）に置く。Codex は展開先を直接読む。
- Claude Code が読むのは `~/.claude/skills/`。そこへは `private_dot_claude/skills/symlink_<name>.tmpl`（中身は `{{ .chezmoi.homeDir }}/.agents/skills/<name>`）で symlink を張る。`.claude/skills/` 直下に実体を置かない。
- skills CLI（`~/.agents/.skill-lock.json`）で入れた外部スキルも、実体を `dot_agents/skills/` にコピーして追跡する。skills CLI で更新したら差分を取り込み直す。更新元を維持し、無関係な一括書き換えを避ける。
- `dot_agents/skills/herdr/SKILL.md` は herdr バイナリ同梱版の写しで、自動追従しない。herdr を更新したら `herdr --skill > chezmoi/dot_agents/skills/herdr/SKILL.md` で再生成する。
- `~/.claude/agent/skills/` は同内容の重複コピーで管理外。
- 追加・更新ではリンクと参照先も確認する。

## 作業と検証

既存の未コミット変更を保持し、依頼と無関係な変更を混ぜない。Nix は2スペース、その他は既存の形式に従う。

- 差分確認: `git diff --check` と対象ファイルの差分。
- chezmoi の展開確認: `chezmoi --source "$PWD/chezmoi" cat <展開先の絶対パス>`。テンプレートは `execute-template` で確認する。
- シェルを変更したら構文チェックを行い、ファイル操作は一時ディレクトリでも検証する。
- 構成ビルド: `darwin-rebuild build --flake "$PWD/nix#personal"`。実行できない場合は原因と未検証事項を報告する。

`chezmoi apply`（`moi apply`）、`darwin-rebuild switch`（`rebuild`）、`nix flake update` は検証とは別の操作。ユーザーが適用禁止を指定した場合は実行しない。適用が依頼されていない作業は編集と検証までに留める。

`run_onchange_*` で `{{ include ... | sha256sum }}` などの Go テンプレートを使うファイルには `.tmpl` を付ける。付けないとテンプレート展開されず、ハッシュ行がただのコメントになって再実行が効かなくなる。

## コミットとPR

コミットは目的ごとにまとめ、`feat:` / `fix:` / `chore:` 等の Conventional Commits を使う。コミットメッセージの末尾には、実際に作業したエージェントの `Co-Authored-By:` 行を署名として付ける。PRにはユーザーへの影響と実行した検証を記載する。UI変更時のみスクリーンショットを添付する。シークレットや秘密鍵、マシン固有の認証情報をコミットしない。
