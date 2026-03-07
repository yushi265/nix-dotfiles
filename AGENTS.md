# リポジトリガイドライン

## プロジェクト構成とモジュール整理
このリポジトリは `nix-darwin` と `home-manager` を使って macOS 環境を管理します。[`flake.nix`](/Users/shiina/.dotfiles/flake.nix) では input と Darwin 構成を定義し、[`hosts/common.nix`](/Users/shiina/.dotfiles/hosts/common.nix) ではシステムレベルのパッケージとシェル挙動を管理し、[`home.nix`](/Users/shiina/.dotfiles/home.nix) ではユーザーレベルの dotfiles をリンクします。アプリケーション設定は [`configs/`](/Users/shiina/.dotfiles/configs) 配下に置いてください。たとえば [`configs/nvim/`](/Users/shiina/.dotfiles/configs/nvim)、[`configs/yazi/`](/Users/shiina/.dotfiles/configs/yazi)、[`configs/ghostty-config`](/Users/shiina/.dotfiles/configs/ghostty-config)、[`configs/tmux.conf`](/Users/shiina/.dotfiles/configs/tmux.conf) です。[`home/default.nix`](/Users/shiina/.dotfiles/home/default.nix) は最小限の互換用モジュールなので、ブートストラップ動作が変わるときだけ更新してください。

## ビルド・テスト・開発コマンド
主な検証手段として build / switch コマンドを使ってください。

- `nix run nix-darwin -- switch --flake .#personal`: 新しいマシンでの初回セットアップ
- `sudo darwin-rebuild switch --flake ~/.dotfiles#personal`: ローカル変更の適用
- `darwin-rebuild build --flake ~/.dotfiles#personal`: 切り替えを行わずに構成がビルドできるか確認
- `darwin-rebuild switch --flake ~/.dotfiles#personal --show-trace`: evaluation に失敗したときにスタックトレース付きで再実行
- `nix flake update`: [`flake.lock`](/Users/shiina/.dotfiles/flake.lock) の固定 input を更新。コミット前に差分を確認すること

このリポジトリには専用の自動テストスイートはありません。`darwin-rebuild build` の成功を最低限必要なチェックとして扱ってください。

## コーディングスタイルと命名規則
各設定言語では既存のスタイルに従ってください。Nix ファイルでは 2 スペースインデントを使い、属性セットは関心ごとごとにまとめます。`configs/nvim/lua` 配下の Lua プラグインファイルは、`git.lua` や `markdown.lua` のように、設定対象の機能ごとに小さく分割したモジュールを優先してください。dotfiles の既存ファイル名は維持し、新しい設定パスは説明的かつ小文字で命名してください。

## テスト方針
すべての変更は `darwin-rebuild build --flake ~/.dotfiles#personal` で検証してください。シェルやエディタのようなリスクの高い変更では、switch 後に対象アプリケーションも実際に開いて手動確認してください。マシン固有のロジックを変える場合は、それが `personal`、`personal-old`、またはホスト名由来の `machineType` のどれに影響するかを明記してください。

## コミットとプルリクエストの方針
最近の履歴では `feat:`、`fix:`、`chore:` のような Conventional Commits プレフィックスに、短い命令形の要約を付ける形式が使われており、日本語の要約も多いです。コミットは 1 つの設定変更に集中させてください。プルリクエストではユーザーに見える影響を説明し、実行した検証コマンドを記載し、Ghostty やエディタテーマのような UI に関わる設定を変えた場合のみスクリーンショットを添付してください。

## セキュリティと設定の注意
シークレット、秘密鍵、マシン固有の認証情報はコミットしないでください。Nix ストアに入ってしまう値は Nix 管理ファイルに含めず、秘匿情報は引き続きローカルの外部ファイルで管理してください。
