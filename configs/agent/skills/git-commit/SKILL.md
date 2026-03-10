---
name: git-commit
description: >
  This skill should be used when the user asks to
  "コミットして", "commitして", "変更をコミット",
  "pushして", "PRを作って", "プルリクを作って",
  "git commit", "コミットしてpushして".
  Git commit workflow with branch protection,
  granular commits, and optional push/PR creation.
version: 0.1.0
---

# Git Commit Workflow Skill

## 概要

このスキルはGitコミットワークフローを自動化する。保護ブランチでの作業検知、適切なコミット粒度での分割、オプションでpush・PR作成まで一気通貫で実行する。

## 動的コンテキスト収集

まず以下のコマンドを実行してリポジトリの現在状態を把握する:

```
!`git status`
!`git diff HEAD`
!`git branch --show-current`
!`git log --oneline -10`
```

## ステップ1: 引数解析

`$ARGUMENTS` を確認して以下のフラグを特定する:

| フラグ | 動作 |
|--------|------|
| (なし) | コミットのみ |
| `--push` | コミット + リモートへpush |
| `--pr` | コミット + push + PR作成 |

`--pr` は `--push` を暗黙的に含む。

## ステップ2: ブランチ保護チェック

現在のブランチが `main`, `master`, `develop`, `development` のいずれかの場合、**そのまま進めてはいけない**。

`AskUserQuestion` ツールを使ってユーザーに確認する:
- 選択肢1: 新規ブランチを作成してから作業する（推奨）
- 選択肢2: このまま保護ブランチに直接コミットする

保護ブランチ以外の場合はステップ4（変更分析）へスキップ。

## ステップ3: 新規ブランチ作成（必要な場合）

### 3-1. ブランチ名の提案

`git diff HEAD` と `git status` の内容から変更の目的を読み取り、以下の規約に従ったブランチ名を提案する:

- `feat/<短い説明>` — 新機能追加
- `fix/<短い説明>` — バグ修正
- `docs/<短い説明>` — ドキュメント変更
- `chore/<短い説明>` — 設定・依存関係等
- `refactor/<短い説明>` — リファクタリング
- `style/<短い説明>` — スタイル・フォーマット変更

例: `feat/add-monospace-font`, `fix/login-error`, `docs/update-readme`

### 3-2. ベースブランチの確認

```bash
gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
```

でデフォルトブランチを取得し、`AskUserQuestion` でユーザーに確認する:
- ベースブランチ（デフォルトブランチ推奨）
- ブランチ名（提案名を表示し、変更も可能）

### 3-3. ブランチ作成

```bash
git checkout -b <branch-name>
```

## ステップ4: 変更分析とコミット粒度の判定

`git status` と `git diff HEAD` の結果を分析して、変更を論理的なグループに分割する。

### 分割の基準

**1コミットにまとめる場合:**
- 同一機能・目的に関連するファイル群
- 密接に関連するバグ修正とテスト
- 同一コンポーネントのスタイルと実装

**別コミットに分割する場合:**
- 異なる機能・目的の変更（例: CSS変更とロジック変更が独立している）
- リファクタリングと機能追加が混在
- 無関係な複数のバグ修正
- 設定ファイルと機能実装の変更

### コミットグループの定義

各コミットについて以下を明確にする:
1. **対象ファイル一覧**: `git add` するファイルを特定
2. **コミットタイプ**: Conventional Commits のプレフィックス（`feat`, `fix`, `docs`, `style`, `refactor`, `chore` 等）
3. **コミットメッセージ**: 変更内容を簡潔に説明（50文字以内を目安、日本語も可）

## ステップ5: コミット実行

各コミットグループに対して順番に実行する:

### 5-1. ファイルのステージング

```bash
git add <file1> <file2> ...
```

ワイルドカードや `-A` は使わず、対象ファイルを明示的に指定する。

### 5-2. コミットメッセージの構成

```
<type>: <subject>

[body - 必要な場合のみ]

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

### 5-3. コミット実行（HEREDOCを使用）

```bash
git commit -m "$(cat <<'EOF'
<type>: <subject>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

複数コミットがある場合は各グループで繰り返す。

## ステップ6: Push（`--push` または `--pr` 指定時）

```bash
git push -u origin <branch-name>
```

## ステップ7: PR作成（`--pr` 指定時）

`gh pr create` でPRを作成する:

```bash
gh pr create --title "<PRタイトル（70文字以内）>" --body "$(cat <<'EOF'
## Summary
- <変更点1>
- <変更点2>

## Test plan
- [ ] <テスト項目1>
- [ ] <テスト項目2>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

PRタイトルは全コミットの変更内容を要約したものにする。

## 完了後の確認

実行後は以下を確認してユーザーに結果を報告する:

```bash
git log --oneline -5
```

コミット数、ブランチ名、push/PR作成の有無を簡潔に報告する。
