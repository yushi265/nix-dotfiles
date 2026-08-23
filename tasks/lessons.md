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
