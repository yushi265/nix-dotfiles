# chezmoi ソース — マシンごとの違いの管理

このディレクトリは chezmoi のソース (`~/.dotfiles/chezmoi`) で、複数のマシンで共有する。
マシンによってユーザー名もホームのパスも入れたい設定も違うので、その違いを
ここに書いた仕組みで吸収している。

このファイル自体は `.chezmoiignore` で除外しているので、ホームには展開されない。

## 今あるホスト

| hostname | ユーザー | ホーム | nix 構成名 | 有効な機能 |
|---|---|---|---|---|
| `MacBook-Pro` | `shiina` | `/Users/shiina` | `personal` | `aws` |
| `mbp-m1` | `shina` | `/Users/shina` | `mbp-m1` | `aws` |

hostname は `chezmoi data` の `hostname` の値。ここに載っていないホストでも
apply はできるが、機能フラグで囲んだ設定は何も入らない。

## 仕組み (3 つのルール)

### 1. ホスト別の違いは `.chezmoidata.yaml` の表に書く

機能ごとに「入れるホスト名」を並べる。

```yaml
features:
  aws:
    - MacBook-Pro
    - mbp-m1
```

テンプレート (`.tmpl`) からはこう参照する。

```
{{ if has .chezmoi.hostname .features.aws -}}
...このホストにだけ入れたい内容...
{{ end -}}
```

今ある機能フラグ:

| 機能 | 中身 | 使っているファイル |
|---|---|---|
| `aws` | AWS プロファイル一式、coleta 用のエイリアス (`awsp` / `awsd` など) | `private_dot_aws/config.tmpl`、`dot_zshrc.tmpl` |

`nixConfig` は `rebuild` 関数が使う nix-darwin の構成名
(`nix/flake.nix` の `darwinConfigurations`) をホストごとに引く表。
載っていないホストは hostname をそのまま構成名として使う。

### 2. ホームのパスをベタ書きしない

`/Users/<name>/...` と書かず `{{ .chezmoi.homeDir }}/...` と書き、ファイル名を
`.tmpl` で終わらせる。ユーザー名が違うマシンでも同じソースで通る。

テンプレート化済み: `dot_npmrc.tmpl`、`dot_zshrc.tmpl`、
`.chezmoitemplates/claude-settings.json`、`private_dot_claude/skills/symlink_*.tmpl`

### 3. アプリが書き換えるファイルは丸ごと管理しない

アプリが自分で値を書き換えるファイルを丸ごと管理すると、永久に差分が出て、
別マシンの値で上書きする事故になる。扱い方は 3 通り。

| 方式 | 対象 | やり方 |
|---|---|---|
| 部分管理 | `~/.claude/settings.json` | 下の節を参照 |
| 不足分だけ追記 | `~/.codex/config.toml` (MCP サーバー) | `run_onchange_after_04-cloudflare-mcp.sh.tmpl` |
| 追跡しない | `~/.config/zed/settings.json`、`~/.config/gh/hosts.yml` など | `.chezmoiignore` に理由付きで記載 |

## `~/.claude/settings.json` の部分管理

`private_dot_claude/modify_private_settings.json.tmpl` が、今あるファイルを読んで
**共有するトップレベルキーだけ**を `.chezmoitemplates/claude-settings.json` の内容で
置き換える。それ以外のキーはそのマシンの値を残す。実行には `jq` が必要。

| 区分 | キー |
|---|---|
| 共有する (chezmoi が置き換える) | `env`、`permissions`、`hooks`、`statusLine`、`enabledPlugins`、`extraKnownMarketplaces`、`pluginConfigs` |
| マシン任せ (差分に出ない) | `language`、`model`、`modelSettings`、`effortLevel`、`autoMode`、`remoteControlAtStartup`、`agentPushNotifEnabled`、`skip*Prompt` など上に無いもの全部 |

注意:

- 共有するキーは**キーごと丸ごと**置き換える。Claude Code で「常に許可」を押して
  増えた `permissions` は差分に出て、apply すると消える。残したいものは
  `.chezmoitemplates/claude-settings.json` に足す。
- 特定のホストにだけ入れたい hook などは、そのテンプレートの中で
  ルール 1 の `{{ if has .chezmoi.hostname .features.<機能> }}` で囲む。

## よくある作業

**機能を新しいホストにも入れる**
`.chezmoidata.yaml` の該当する機能のリストに hostname を足す。

**新しい機能フラグを作る**
`.chezmoidata.yaml` の `features` に機能名とホストのリストを足し、
対象ファイルを `.tmpl` にして `{{ if has .chezmoi.hostname .features.<機能> }}` で囲む。

**ファイルごと特定のホストにだけ置く**
`.chezmoiignore` はテンプレートとして評価されるので、同じ条件で除外を書く。

```
{{ if not (has .chezmoi.hostname .features.aws) }}
.aws
{{ end }}
```

**マシンを追加する**
1. 新マシンで `chezmoi data` を実行して `hostname` を確認する
2. `.chezmoidata.yaml` の `features` の必要な機能と、`nixConfig` に足す
3. `nix/flake.nix` の `darwinConfigurations` に構成を足す
4. 上の「今あるホスト」の表を更新する

**Claude の共有設定を変える**
`.chezmoitemplates/claude-settings.json` を編集して `chezmoi apply`。
ホーム側の `settings.json` を直接編集しても、共有キーは次の apply で戻る。

## やってはいけないこと

**ホームの現状を丸ごと `chezmoi add` やコピーで取り込まない。**
そのマシンのパスや専用の hook が混ざり、別マシンで事故になる
(2026-10 に `mbp-m1` の設定が `MacBook-Pro` 側に混入して revert した)。
取り込むときは `chezmoi diff` を見て、キー・行単位で入れる。

## 別マシンで pull したあとの確認

いきなり apply せず、先に差分を見る。

```bash
chezmoi diff
```

想定外の差分 (別ユーザーのパス、知らない hook など) が出たら apply せずに原因を調べる。

## 補足: nix 側の `machineType`

`nix/flake.nix` はこの表とは別系統で、hostname から `machineType`
(`MacBook-Pro` / `mbp-m1` → `personal`、それ以外 → `work`) を導出し、
`nix/hosts/common.nix` のパッケージ分岐に使っている。
`.chezmoi.toml.tmpl` にも同じ値が残っているが、chezmoi のテンプレートは
もう `machineType` を参照していない。2 台とも `personal` になるので、
2 台の違いを書く用途には使えない。
