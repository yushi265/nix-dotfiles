# check-nix-config

Nix（home-manager）で管理している全設定ファイルの変更をチェックし、差分を表示するスキル。
darwin-rebuild実行前に使用することで、設定ファイルの変更を検出し、上書きされる前に確認できる。

## Usage

```
/check-nix-config
```

または

```
Nixの設定チェックして
設定ファイルの差分チェックして
```

## What This Skill Does

1. **管理ファイル一覧取得**: home-managerで管理している全ファイルをリストアップ
2. **シンボリックリンクチェック**: 各ファイルがシンボリックリンクか実ファイルか確認
3. **差分表示**: 実ファイルに変更されている場合、Nix管理版との差分を表示
4. **推奨アクション提示**: 変更を永続化すべきかどうかを提案

## Implementation

### Step 1: 管理対象ファイルの確認

home.nixで管理しているファイル:

**xdg.configFile (XDG準拠の設定)**
- `~/.config/ghostty/config`
- `~/.config/nvim/` (ディレクトリ全体)
- `~/.config/yazi/` (ディレクトリ全体)

**home.file (ホームディレクトリ直下)**
- `~/.vimrc`
- `~/.claude/settings.json`
- `~/.claude/rotate-language.sh`

**programs.vscode (VSCode)**
- `~/Library/Application Support/Code/User/settings.json`
- `~/.vscode/extensions/.extensions-immutable.json`

### Step 2: 各ファイルの状態確認

全てのファイルに対して以下をチェック:

```bash
# シンボリックリンクか確認
for file in "${MANAGED_FILES[@]}"; do
  if [ -L "$file" ]; then
    echo "✅ $file (シンボリックリンク)"
  elif [ -e "$file" ]; then
    echo "⚠️  $file (実ファイル - 変更あり)"
  else
    echo "❌ $file (存在しない)"
  fi
done
```

### Step 3: 差分がある場合の詳細表示

実ファイルに変更されている項目について:

1. バックアップファイルが存在するか確認
2. 差分を表示 (diff コマンド)
3. どのアプリケーション/ツールの設定かを明示

### Step 4: サマリーと推奨アクション

```
=== Nix管理ファイルの状態 ===

✅ 変更なし (5ファイル)
⚠️  変更あり (2ファイル)

変更されたファイル:
1. ~/Library/Application Support/Code/User/settings.json (VSCode)
   - editor.fontSize: 12 → 14
   - editor.tabSize: 2 → 4

2. ~/.vimrc (Vim)
   - 新規行追加: set number

推奨アクション:
これらの変更を保持したい場合は、対応する設定ファイルを更新してください:
- VSCode: ~/.dotfiles/home.nix の programs.vscode.profiles.default.userSettings
- Vim: ~/.dotfiles/configs/vimrc
```

## Managed Files List

以下のファイル/ディレクトリが管理対象:

| ファイルパス | 管理場所 | 用途 |
|-------------|---------|------|
| `~/.config/ghostty/config` | `configs/ghostty-config` | Ghostty ターミナル設定 |
| `~/.config/nvim/` | `configs/nvim/` | Neovim (LazyVim) 設定 |
| `~/.config/yazi/` | `configs/yazi/` | Yazi ファイルマネージャ設定 |
| `~/.vimrc` | `configs/vimrc` | Vim 設定 |
| `~/.claude/settings.json` | `configs/claude-settings.json` | Claude Code 設定 |
| `~/.claude/rotate-language.sh` | `configs/rotate-language.sh` | 言語ローテーションスクリプト |
| `~/Library/Application Support/Code/User/settings.json` | `home.nix` | VSCode 設定 |

## Check Logic

```bash
# 管理対象ファイルの配列
MANAGED_FILES=(
  "$HOME/.config/ghostty/config"
  "$HOME/.config/nvim"
  "$HOME/.config/yazi"
  "$HOME/.vimrc"
  "$HOME/.claude/settings.json"
  "$HOME/.claude/rotate-language.sh"
  "$HOME/Library/Application Support/Code/User/settings.json"
)

# 対応するソースファイルの配列
SOURCE_FILES=(
  "$HOME/.dotfiles/configs/ghostty-config"
  "$HOME/.dotfiles/configs/nvim"
  "$HOME/.dotfiles/configs/yazi"
  "$HOME/.dotfiles/configs/vimrc"
  "$HOME/.dotfiles/configs/claude-settings.json"
  "$HOME/.dotfiles/configs/rotate-language.sh"
  "home.nix (programs.vscode.profiles.default.userSettings)"
)

# 各ファイルをチェック
for i in "${!MANAGED_FILES[@]}"; do
  file="${MANAGED_FILES[$i]}"
  source="${SOURCE_FILES[$i]}"

  if [ -L "$file" ]; then
    # シンボリックリンク = 変更なし
    echo "✅ $(basename "$file")"
  elif [ -e "$file" ]; then
    # 実ファイル = 変更あり
    echo "⚠️  $(basename "$file") - 変更検出"

    # バックアップファイルと差分表示
    if [ -f "$file.backup" ]; then
      echo "=== 差分 ==="
      diff "$file.backup" "$file" || true
      echo ""
      echo "ソースファイル: $source"
      echo ""
    fi
  fi
done
```

## Notes

- **darwin-rebuild実行前**に使用することを推奨
- シンボリックリンクが実ファイルに置き換わっている = アプリケーション内で直接編集された
- darwin-rebuildを実行すると、実ファイルは`.backup`に移動され、Nix管理版のシンボリックリンクに戻る
- 変更を永続化したい場合は、必ず対応する設定ファイル（`home.nix`または`configs/`内のファイル）を編集してからdarwin-rebuildを実行

## Related Commands

```bash
# darwin-rebuild実行前にチェック
/check-nix-config

# 変更があった場合、対応するファイルを編集
vim ~/.dotfiles/home.nix
vim ~/.dotfiles/configs/vimrc

# 編集後、適用
sudo darwin-rebuild switch --flake ~/.dotfiles
```

## Example Output

### すべて変更なしの場合

```
=== Nix管理ファイルの状態チェック ===

✅ ghostty/config (シンボリックリンク)
✅ nvim/ (シンボリックリンク)
✅ yazi/ (シンボリックリンク)
✅ .vimrc (シンボリックリンク)
✅ .claude/settings.json (シンボリックリンク)
✅ .claude/rotate-language.sh (シンボリックリンク)
✅ VSCode settings.json (シンボリックリンク)

すべてのファイルがNix管理下です。
そのままdarwin-rebuildを実行できます。
```

### 変更ありの場合

```
=== Nix管理ファイルの状態チェック ===

✅ ghostty/config (シンボリックリンク)
✅ nvim/ (シンボリックリンク)
✅ yazi/ (シンボリックリンク)
✅ .vimrc (シンボリックリンク)
⚠️  .claude/settings.json (実ファイル - 変更あり)
✅ .claude/rotate-language.sh (シンボリックリンク)
⚠️  VSCode settings.json (実ファイル - 変更あり)

=== 変更詳細 ===

【1】 .claude/settings.json
ソースファイル: ~/.dotfiles/configs/claude-settings.json

< "language": "ja",
> "language": "en",

【2】 VSCode settings.json
ソースファイル: ~/.dotfiles/home.nix (programs.vscode.profiles.default.userSettings)

< "editor.fontSize": 12,
> "editor.fontSize": 14,
< "editor.tabSize": 2,
> "editor.tabSize": 4,

=== 推奨アクション ===

⚠️ darwin-rebuildを実行すると、上記の変更は上書きされます。

変更を保持したい場合:
1. .claude/settings.json → ~/.dotfiles/configs/claude-settings.json を編集
2. VSCode settings → ~/.dotfiles/home.nix の programs.vscode.profiles.default.userSettings を編集
3. sudo darwin-rebuild switch --flake ~/.dotfiles で適用

変更を破棄する場合:
- そのままdarwin-rebuildを実行してください
```
