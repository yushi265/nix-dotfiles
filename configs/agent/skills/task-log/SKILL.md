---
name: task-log
description: >
  This skill should be used when the user asks to
  "タスクログを記録して", "タスク履歴を記録", "task-log", "ログを記録して",
  "セッション履歴を書き出して", "作業履歴を記録", "task log", "ログ更新して".
  Records Claude Code task execution history as structured markdown files.
version: 0.2.0
---

# Task Log Skill

## 概要

Claude Code でのタスク実行履歴を **セッション単位のマークダウンファイル** として自動記録・蓄積するスキル。
SessionStart hook による自動記録が主役。手動呼び出しは閲覧・バックアップ用。

ファイル構成: `~/.claude/task-logs/<project>/YYYY-MM-DD/HH-MM_<session-id>.md`

## ステップ1: 引数解析

`$ARGUMENTS` を確認して以下のフラグを特定する:

| フラグ | 動作 |
|--------|------|
| (なし) | 未記録セッションを手動記録（hook が漏らした場合のバックアップ） |
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

### 通常実行（引数なし） — バックアップ手動記録

```bash
python3 ~/.claude/skills/task-log/scripts/generate_log.py \
  --project-path "$(pwd)"
```

### --dry-run

```bash
python3 ~/.claude/skills/task-log/scripts/generate_log.py \
  --project-path "$(pwd)" --dry-run
```

### --show（引数なし = 直近7日）

```bash
python3 ~/.claude/skills/task-log/scripts/generate_log.py \
  --project-path "$(pwd)" --show
```

### --show YYYY-MM-DD / YYYY-MM

```bash
python3 ~/.claude/skills/task-log/scripts/generate_log.py \
  --project-path "$(pwd)" --show "YYYY-MM-DD"
```

### --show セッションID

```bash
python3 ~/.claude/skills/task-log/scripts/generate_log.py \
  --project-path "$(pwd)" --show "セッションID（先頭8文字以上）"
```

### --all

```bash
python3 ~/.claude/skills/task-log/scripts/generate_log.py --all
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
- 「次回からは SessionStart hook が自動記録します」とコメント

### 新しいセッションなし時

「新しいセッションはありません（SessionStart hook が自動記録済みです）」とシンプルに報告する。

### --show 時

`content` フィールドのマークダウンをそのまま表示する。

### --dry-run 時

「以下のセッションが記録される予定です（実際の書き込みは行いませんでした）」として `entries_preview` を表示する。
