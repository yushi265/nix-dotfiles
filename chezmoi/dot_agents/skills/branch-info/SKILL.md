---
name: branch-info
description: Gitブランチの状態、差分、upstream、PR状況を確認する依頼に使う。一般的な作業進捗の質問だけでは使わない。
metadata:
  version: "0.2.0"
---

# ブランチ状況の確認

読み取り専用で調べる。変更・コミット・push・fetchは行わない。

まず `git status --short --branch`、`git diff --stat HEAD`、`git log --oneline -5` を実行する。内容説明に必要なファイルだけ追加で差分を読む。未追跡ファイルは `git diff` に出ないためstatusと合わせて報告する。

- upstreamがある場合は `git rev-list --left-right --count 'HEAD...@{upstream}'` で先行・遅延を調べる。ローカルの参照時点の情報であることを明示する。
- upstream未設定は「upstream未設定」とだけ述べ、未pushと断定しない。
- 比較対象はユーザー指定を優先する。なければ `git symbolic-ref --short refs/remotes/origin/HEAD`、必要に応じて `gh repo view --json defaultBranchRef` でデフォルトブランチを調べる。取得できなければ不明とする。デフォルトブランチを実際の分岐元と断定しない。
- 比較対象が分かれば `git log <ref>..HEAD --oneline` と `git diff --stat <ref>...HEAD` を確認する。
- PR状況が必要なら `gh pr list --head <branch> --state all --json number,title,state,url,mergedAt,isDraft,headRefName,headRepositoryOwner` を使い、同名の別リポジトリのPRを区別する。取得失敗を「PRなし」と扱わない。
- `git merge-base --is-ancestor HEAD <ref>` の成功はコミットが包含されていることを示す。失敗だけでPR未マージとは断定しない（squash/rebaseでは履歴が異なる）。終了コード1とコマンドエラーを区別する。

ブランチ名、変更概要、同期状況、必要ならPRと比較結果を簡潔に報告する。取得できない情報は理由付きで不明と記す。detached HEADも明示する。
