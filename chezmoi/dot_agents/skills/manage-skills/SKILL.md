---
name: manage-skills
description: ユーザースコープのエージェントスキル（Claude Code / Codex / Cursor 共用）の追加・更新・削除・棚卸しを依頼されたときに使う。~/.dotfiles の管理ルール（自作=chezmoi、外部=npx skills、付属物あり=Claude Code プラグイン）に沿って変更する。プロジェクト内スキルの作成には使わない。
metadata:
  version: "0.1.0"
---

# ユーザースコープのスキル管理

管理元は `~/.dotfiles`。作業前にそのリポジトリの `AGENTS.md` を読み、未コミット変更を保持する。ホームの展開先（`~/.agents/skills`、`~/.claude/skills`）を直接編集・コピーせず、管理元を変更する。

## 置き場所の判断

対象ごとに次の順で1つに決める。同じスキルを複数の経路から入れない（Claude Code で二重に出る）。

1. **自作、または上流に手を入れて保守する** → ① chezmoi
2. **外部配布で、SKILL.md と references / scripts / assets だけ** → ② npx skills
3. **hooks、MCP サーバー、subagent、slash command、settings のどれかを伴う** → ③ Claude Code プラグイン

③ の配布元がスキルだけを Codex にも入れたい場合は、② にも宣言して `agents` から `claude-code` を外す（例: `cloudflare/skills`）。

| | ① chezmoi | ② npx skills | ③ プラグイン |
|---|---|---|---|
| 宣言 | `chezmoi/dot_agents/skills/<name>/` + `chezmoi/private_dot_claude/skills/symlink_<name>.tmpl` | `chezmoi/.chezmoidata/skills.yaml` | `chezmoi/.chezmoitemplates/claude-settings.json` の `enabledPlugins` / `extraKnownMarketplaces` |
| 反映 | `chezmoi apply` | `chezmoi apply` → `run_onchange_after_05-skills-install.sh.tmpl` | `chezmoi apply` 後に Claude Code が導入 |
| 対象 | 全エージェント | `defaultAgents` か `agents` で指定 | Claude Code のみ |

## 追加

**①**: `dot_agents/skills/<name>/SKILL.md` を作り、`symlink_<name>.tmpl` に `{{ .chezmoi.homeDir }}/.agents/skills/<name>` の1行だけ書く。外部スキルは原則として上流のまま ② で入れる。手元で改変した版を ① に置くのは、ユーザーが明示した場合だけにする。その場合は LICENSE を残し、`skills.yaml` の該当ソースに理由をコメントで書く。

**②**:
1. `npx -y skills add <owner/repo> --list` でスキル名を確かめる。
2. `skills.yaml` の `external` に追記する。同じソースがあれば `skills` に足し、名前順を保つ。全エージェント向けなら `agents` は書かない。
3. 同名のスキルが ① やプラグインに無いことを確かめる。

**③**:
1. 配布元の `.claude-plugin/marketplace.json` で、マーケットプレイス名とプラグイン名を確かめる。
2. `extraKnownMarketplaces` に `{"source": {"source": "github", "repo": "<owner/repo>"}, "autoUpdate": true}` を、`enabledPlugins` に `"<plugin>@<marketplace>": true` を、どちらもキー名順で足す。
3. 同名のスキルが ①② から Claude に入っていたら外す。プラグインに MCP が入っている場合は、`claude mcp list` で手動登録したものと重複していないか確かめる。

## 更新

- **①**: 管理元を編集する。`herdr` は `herdr --skill > chezmoi/dot_agents/skills/herdr/SKILL.md` で作り直す。
- **②**: `npx -y skills update -g -y` で入っているものを最新にする。上流は固定せず、宣言の変更も不要。`skills.yaml` を変えたときは、次の `chezmoi apply` で宣言分が入り直る。
- **③**: `autoUpdate: true` なら Claude Code が自動で更新する。急ぐときは `claude plugin marketplace update <marketplace>`。

## 削除

- **①**: スキルのディレクトリと `symlink_<name>.tmpl` を消し、既に展開した分は `chezmoi/.chezmoiremove` に `.agents/skills/<name>` と `.claude/skills/<name>` を足す。
- **②**: `skills.yaml` から外す。インストールスクリプトは削除まではしないため、`npx -y skills remove -g -s <name> -y` も実行する。
- **③**: `enabledPlugins` から外す。キャッシュまで消すときは `claude plugin uninstall <plugin>@<marketplace>` を使う。

## 棚卸し

- 宣言: `chezmoi/dot_agents/skills/`、`skills.yaml`、`claude-settings.json`
- 実際の状態: `npx -y skills list -g`、`ls -l ~/.claude/skills ~/.agents/skills ~/.codex/skills`
- 宣言に無い実ディレクトリや、`~/.claude/skills` 直下に置かれた実体（symlink でないもの）は報告する。勝手に消さない。`~/.claude/skills/learned` と `synced`、`~/.codex/skills/.system` は対象外。

## 検証

リポジトリのルートで実行する。

```bash
git diff --check
chezmoi --source "$PWD/chezmoi" execute-template --file chezmoi/run_onchange_after_05-skills-install.sh.tmpl | bash -n
chezmoi --source "$PWD/chezmoi" execute-template --file chezmoi/.chezmoitemplates/claude-settings.json | jq . >/dev/null
python3 -B -m unittest discover -s tests -v
```

②を足したときは、`HOME="$(mktemp -d)"` で描画済みのインストールスクリプトを実行し、配置まで確かめてもよい。

`chezmoi apply`、`npx skills add/update/remove -g`、`claude plugin ...` はホームを書き換える。ユーザーが適用まで依頼した場合だけ実行し、それ以外は編集と検証までに留める。
