# Lessons

## chezmoi 管理スキルの置き場所ルール (2026-08-23)

- **ルール**: chezmoi 管理のスキルはすべて実体を `~/.agents/skills/<name>/` に置き
  (chezmoi ソースでは `chezmoi/dot_agents/skills/<name>/`)、`~/.claude/skills/<name>` は
  そこへの symlink (`private_dot_claude/skills/symlink_<name>.tmpl`、中身は
  `{{ .chezmoi.homeDir }}/.agents/skills/<name>`) にする。
- **経緯**: eli5 追加時に `private_dot_claude/skills/` 直下に実体を置いてユーザーに
  訂正された。その後、既存の手書きスキル9個もすべて同方式に統一 (2026-08-23)。
- **例外**: `grill-me` は skills CLI (`~/.agents/.skill-lock.json`) 管理、`learned` は
  空ディレクトリ。どちらも chezmoi 追跡外 (`.chezmoiignore` 参照)。
- **注意**: codex ミラー (`run_onchange_after_03`) のハッシュ glob は
  `dot_agents/skills/*/SKILL.md`。symlink 側 (`private_dot_claude`) を glob しても
  SKILL.md が無くマッチしないので、実体側を指すこと。

## マシン間の違いは「取り込み」ではなく「表とテンプレート」で扱う

- **ルール**: ホームの現状を丸ごと source にコピーしない。ホスト別の違いは
  `chezmoi/.chezmoidata.yaml` の `features`、パスは `{{ .chezmoi.homeDir }}`、
  アプリが書き換える `~/.claude/settings.json` は modify スクリプトによる部分管理
  (`.chezmoitemplates/claude-settings.json` のキーだけ置き換え) で扱う。
- **経緯**: `mbp-m1` (user: shina) のホーム設定を丸ごと取り込んだコミットが
  `MacBook-Pro` (user: shiina) 側で `/Users/shina` のパスや専用 hook として混入し、
  revert した (2026-10-03)。同日、逆向きに `/Users/shiina` を取り込みかけたのも同じ原因。
- **注意**: nix の `machineType` は2台とも `personal` で何も分岐していなかったため
  2026-10-20 に削除した。2台の違いは chezmoi の `features` で書く。

## コミットには署名を付ける

- **ルール**: コミットメッセージ末尾に `Co-Authored-By:` の署名を付ける。
- **経緯**: `git-commit` スキルの「署名は付けない」に従って署名なしでコミットし、
  ユーザーに訂正された。メモリではなくスキル本体を直すよう指示され、v0.2.1 で明記 (2026-10-03)。

## 外部スキルの手元改変は勝手に温存しない

- **ルール**: 外部スキルを npx skills などの上流管理に移すとき、写しに入っていた
  手元の改変を見つけても、独断で自作扱いにして残さない。上流の版に寄せるのが既定で、
  残すかどうかはユーザーに確認する。
- **経緯**: grill-me / grill-with-docs の Codex 向けフォールバック改変を見つけ、
  自作扱いで chezmoi に残そうとしたら「元に戻して」と訂正された (2026-10-19)。
