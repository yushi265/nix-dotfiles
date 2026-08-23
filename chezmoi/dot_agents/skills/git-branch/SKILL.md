---
name: git-branch
description: >
  This skill should be used when the user asks to
  "ブランチを作って", "ブランチ作成", "新しいブランチ",
  "branch作って", "git branch", "ブランチを切って",
  "ブランチ切って", "create branch".
  Creates a new git branch with an appropriate name
  based on the user's description.
version: 0.1.0
---

# Git Branch 作成スキル

## 概要

このスキルは `$ARGUMENTS` の内容に適したブランチ名を自動生成し、指定またはデフォルトのベースブランチから新規ブランチを作成する。既存の差分がある場合はユーザーに引き継ぎ方を確認する。

## ステップ1: コンテキスト収集

まず以下のコマンドを実行してリポジトリの現在状態を把握する:

```
!`git branch --show-current`
!`git status`
!`git diff HEAD`
!`git stash list`
```

## ステップ2: 引数解析

`$ARGUMENTS` から以下を抽出する:

| 要素 | 説明 |
|------|------|
| 目的テキスト | ブランチの目的・説明（例: "ログイン画面のバグ修正"） |
| `--from <branch>` または `--base <branch>` | ベースブランチ指定（省略可） |

例:
- `/git-branch ログイン画面のバグ修正` → 自動でデフォルトブランチから作成
- `/git-branch 新機能追加 --from develop` → `develop` ブランチから作成

## ステップ3: ブランチ名の自動生成

目的テキストを分析して Conventional Branch Naming に従ったブランチ名を提案する:

| プレフィックス | 用途 |
|----------------|------|
| `feat/<説明>` | 新機能追加 |
| `fix/<説明>` | バグ修正 |
| `docs/<説明>` | ドキュメント変更 |
| `chore/<説明>` | 設定・依存関係等 |
| `refactor/<説明>` | リファクタリング |
| `style/<説明>` | スタイル・フォーマット変更 |

ブランチ名の規則:
- 英小文字・数字・ハイフンのみ使用（スラッシュはプレフィックス区切りのみ）
- スペースはハイフンに変換
- 簡潔かつ内容が伝わる名前にする（例: `fix/login-error`, `feat/add-search-feature`）

`AskUserQuestion` を使って提案ブランチ名をユーザーに確認する（変更可能にする）。

## ステップ4: ベースブランチの決定

### `--from`/`--base` 指定あり

引数で指定されたブランチをそのまま使用する。

### 指定なし

以下のコマンドでデフォルトブランチを自動取得する:

```bash
gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
```

## ステップ5: 既存差分の処理

`git status` に未コミットの変更がある場合は `AskUserQuestion` でユーザーに確認する:

| 選択肢 | 動作 |
|--------|------|
| 変更をそのまま新ブランチに持っていく（推奨） | `git checkout -b <branch> <base>` で変更はワーキングツリーに残ったまま新ブランチへ移動 |
| 変更を stash して新ブランチをクリーンな状態で作成 | `git stash` → `git checkout -b <branch> <base>` |
| 変更を現在のブランチにコミットしてから新ブランチを作成 | コミット実行 → `git checkout -b <branch> <base>` |

未コミットの変更がない場合はこのステップをスキップする。

## ステップ6: ブランチ作成

選択に応じて実行する:

### パターンA: 変更をそのまま引き継ぐ（推奨）

```bash
git checkout -b <branch-name> <base-branch>
```

ワーキングツリーの変更はそのまま新ブランチに引き継がれる。

### パターンB: stashして新ブランチ作成

```bash
git stash
git checkout -b <branch-name> <base-branch>
```

必要に応じて後から `git stash pop` で変更を復元する旨をユーザーに伝える。

### パターンC: 先にコミットしてから新ブランチ作成

`/git-commit` スキルの手順に従ってコミットを実行してから、以下を実行する:

```bash
git checkout -b <branch-name> <base-branch>
```

## ステップ7: 完了報告

以下の情報を簡潔にユーザーに報告する:

- 作成したブランチ名
- ベースブランチ名
- 差分の処理方法（引き継ぎ / stash / 事前コミット）
- stashした場合は `git stash pop` で復元できる旨
