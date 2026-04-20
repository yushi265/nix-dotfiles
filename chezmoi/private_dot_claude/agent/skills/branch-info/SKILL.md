---
name: branch-info
description: >
  This skill should be used when the user asks to
  "ブランチの状況", "今のブランチ", "状態を確認",
  "git status", "ブランチ確認", "状況教えて",
  "statusを見て", "branch status", "今どうなってる".
  Shows comprehensive status of the current git branch.
version: 0.1.0
---

# Git Status スキル

## 概要

現在のブランチの状態を一発で把握する。差分・リモート同期状況・PR・マージ状態をまとめてレポートする。

## 情報収集

以下のコマンドをまとめて実行してリポジトリの現状を取得する:

```
!`git branch --show-current`
!`git status`
!`git diff --stat HEAD`
!`git diff HEAD`
!`git log --oneline -5`
!`git stash list`
!`git rev-parse --abbrev-ref @{upstream} 2>/dev/null`
!`git log @{upstream}..HEAD --oneline 2>/dev/null`
!`git log HEAD..@{upstream} --oneline 2>/dev/null`
!`gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null`
!`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null`
```

上記コマンドの出力を元に以下を判断する:
- upstream が取得できない場合は「NO_UPSTREAM」として扱う
- デフォルトブランチは `gh` コマンドの出力を優先し、失敗した場合は `git symbolic-ref` の出力から `refs/remotes/origin/` プレフィックスを除いた値を使う。どちらも取得できない場合は `main` をデフォルトとして扱う

デフォルトブランチが取得できたら追加で実行する:

```bash
git log <default-branch>..HEAD --oneline 2>/dev/null
git diff --stat <default-branch>...HEAD 2>/dev/null
git branch --merged <default-branch> 2>/dev/null
gh pr list --head <current-branch> --json number,title,state,url,mergedAt,isDraft 2>/dev/null
```

- `git branch --merged` の出力に `* <current-branch>` が含まれていれば「マージ済み」、なければ「未マージ」と判断する

## レポート出力

収集した情報を以下のフォーマットで整形してテキスト出力する（ツール呼び出し不要）:

```
## ブランチ状況レポート

### 基本情報
- ブランチ名: `<branch>`
- ベースブランチ: `<default-branch>`

### ローカルの差分
- 状態: 差分あり / クリーン
- <diff の内容を全体的に読んで、何が追加・変更・削除されたかを2〜3文でまとめて日本語説明>
- 変更ファイル:
  - `path/to/file1`（ステージ済み / 未ステージ）
  - `path/to/file2`（ステージ済み / 未ステージ）

### リモートとの同期状況
- upstream: `origin/<branch>` / 未設定
- push状態: N コミット先行 / 同期済み / N コミット遅れ / 未push

### PR状況
- PR: #123 "タイトル" (Open / Draft / Merged / Closed)
- URL: https://github.com/...
  または: PR なし

### ブランチ内の変更概要
- コミット数: N 件（`<default-branch>` との差分）
- コミット一覧:
  - `<hash>` <message>
  - ...
- 変更ファイル（ブランチ全体）:
  - `path/to/file` (+N, -N)

### マージ状況
- デフォルトブランチへ: マージ済み / 未マージ（N コミット差分）

### その他
- stash: N 件
- 直近コミット: `<hash>` <message>
```

## 表示ルール

- **main/master/develop にいる場合**: PR・マージ状況は省略する
- **upstream 未設定の場合**: リモート同期状況は「upstream 未設定（まだ push されていない）」と表示する
- **差分がない場合**: ローカルの差分セクションは「クリーン（差分なし）」のみ表示する
- **main/master/develop にいる場合**: ブランチ内の変更概要は「（デフォルトブランチのため省略）」と表示する
- **PR がない場合**: PR 状況は「PR なし」と表示する
- **stash が 0 件の場合**: stash の行は省略する
- 情報が取得できなかったコマンドは静かに無視して、取得できた情報だけ表示する

このスキルは読み取り専用のため、ファイル変更・コミット・push は一切行わない。
