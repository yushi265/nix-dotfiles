---
name: task-log
description: Record or browse local Claude Code or Codex session histories as Markdown task logs. Use when asked to save task history or view session logs, not to inspect application error logs.
metadata:
  version: "0.2.1"
---

# Task Log Skill

## 概要

Claude Code / Codex のタスク実行履歴を **セッション単位のマークダウンファイル** として記録する。コマンドは利用可能なシェル実行ツールで実行する。

履歴の種類はユーザーの指定を優先し、指定がなければこのスキルを実行中のクライアントに合わせて `--source claude` / `--source codex` を明示する。両方の設定ディレクトリがあるという理由で混在させない。種類を特定できない場合だけ確認する。

- Claude: `~/.claude/history.jsonl` と `~/.claude/projects/` を読み、既存の `~/.claude/task-logs/<project>/` に保存する。既存の `--auto` hook は互換性を保つ。
- Codex: `${CODEX_HOME:-~/.codex}/sessions/` のローカル JSONL を読み、同じ設定ディレクトリの `task-logs/<project>-<path-hash>/` に保存する。履歴が更新されたセッションはログも更新する。新しい hook は追加しない。

配下は `YYYY-MM-DD/HH-MM_<session-id>.md`。Claude は既存形式の先頭8文字、Codex は同時刻のセッションの衝突を避けるため完全なIDを使う。Codex の閲覧で短縮IDが複数に一致した場合は完全なIDを使う。Codex では会話・モデル・ツール使用回数を記録し、内部推論やツールの引数・出力は転載しない。ツール呼び出しだけでは成功を確定できない変更ファイルは「未集計」と示す。

現在の会話の要約保存は `note` スキルが利用可能ならそちらを使う。

## ステップ1: 引数解析

依頼と会話、ホストが展開したスキル引数があればその内容から以下を特定する:

| フラグ | 動作 |
|--------|------|
| (なし) | 対象クライアントの未記録セッションを記録（Codex は既存ログの更新も行う） |
| `--source claude` / `--source codex` | 履歴の種類を明示 |
| `--show` | 直近7日間のセッション一覧を表示 |
| `--show YYYY-MM-DD` | 指定日のセッション一覧を表示 |
| `--show YYYY-MM` | 指定月のセッション一覧を表示 |
| `--show <session-id>` | 指定セッションの詳細ファイルを表示 |
| `--dry-run` | 記録予定の確認（書き込みなし） |
| `--all` | 全プロジェクトの未記録セッションを処理 |

## ステップ2: 動的コンテキスト収集

```bash
pwd
```

## ステップ3: スクリプト実行

読んだ SKILL.md のディレクトリを基準に `scripts/generate_log.py` を解決する。以下の `<script>` はその絶対パス、`<source>` は選択した `claude` または `codex`、`<project-path>` は `pwd` などで確認した対象プロジェクト。chezmoi のソース上で検証する場合のファイル名は `scripts/executable_generate_log.py`。

別の履歴保存場所を指定された場合は `--data-dir <client-directory>`、出力先を指定された場合は `--log-dir <output-root>` を付けられる。通常は省略する。

### 通常実行（引数なし） — バックアップ手動記録

```bash
python3 "<script>" --source <source> --project-path "<project-path>"
```

### --dry-run

```bash
python3 "<script>" --source <source> --project-path "<project-path>" --dry-run
```

### --show（引数なし = 直近7日）

```bash
python3 "<script>" --source <source> --project-path "<project-path>" --show
```

### --show YYYY-MM-DD / YYYY-MM

```bash
python3 "<script>" --source <source> --project-path "<project-path>" --show "YYYY-MM-DD"
```

### --show セッションID

```bash
python3 "<script>" --source <source> --project-path "<project-path>" --show "セッションID（先頭8文字以上）"
```

### --all

```bash
python3 "<script>" --source <source> --all
```

## ステップ4: 結果の解釈と報告

スクリプトは JSON を stdout に出力する。その結果を解釈してユーザーに報告する。

### 手動記録成功時

```json
{
  "status": "success",
  "project": "digital-garden",
  "new_entries": 3,
  "skipped": 0,
  "log_files": [
    "~/.claude/task-logs/digital-garden/2026-02-22/22-43_1d8bc1af.md"
  ],
  "entries_preview": ["22:43 - リモートURL更新", "23:03 - フォント変更"]
}
```

### --show 時の出力例

```json
{
  "status": "show",
  "project": "digital-garden",
  "content": "# digital-garden セッション一覧 (直近7日間)\n## 2026-02-22\n- **22:43** `1d8bc1af` — ..."
}
```

### エラー時

```json
{
  "status": "error",
  "message": "エラーの説明"
}
```

## 報告フォーマット

### 手動記録時

- 新しく記録したセッション数（`new_entries`）
- ログファイルパス（`log_files`）
- 記録したタスク一覧（`entries_preview`）
- 自動記録については、そのクライアントで hook の有効化を確認できた場合だけ説明する

### 新しいセッションなし時

「新しく記録するセッションはありません」と報告する。確認せずに hook の自動記録を理由にしない。

### --show 時

`content` フィールドのマークダウンをそのまま表示する。

### --dry-run 時

「以下のセッションが記録される予定です（実際の書き込みは行いませんでした）」として `entries_preview` を表示する。
