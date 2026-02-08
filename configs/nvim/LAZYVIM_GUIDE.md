# LazyVim 操作ガイド

LazyVim の基本操作をまとめたガイドです。

## 基本概念

- **Leader キー**: `Space` （ほとんどのショートカットの起点）
- **Local Leader**: `\` （ファイルタイプ固有の操作）

## ファイル操作

| キー | 説明 |
|------|------|
| `<Leader><Leader>` | ファイル検索（ルートディレクトリ） |
| `<Leader>ff` | ファイル検索（ルートディレクトリ） |
| `<Leader>fF` | ファイル検索（カレントディレクトリ） |
| `<Leader>fr` | 最近開いたファイル |
| `<Leader>fR` | 最近開いたファイル（cwd） |
| `<Leader>fn` | 新規ファイル |
| `<Leader>fg` | Git ファイル検索 |

## 検索（Telescope / fzf）

| キー | 説明 |
|------|------|
| `<Leader>/` | Grep（ルートディレクトリ） |
| `<Leader>sg` | Grep（ルートディレクトリ） |
| `<Leader>sG` | Grep（カレントディレクトリ） |
| `<Leader>sw` | カーソル下の単語を検索 |
| `<Leader>sb` | バッファ内検索 |
| `<Leader>ss` | シンボル検索 |
| `<Leader>sS` | ワークスペースシンボル検索 |
| `<Leader>sh` | ヘルプ検索 |
| `<Leader>sk` | キーマップ検索 |
| `<Leader>sc` | コマンド履歴 |
| `<Leader>sC` | コマンド検索 |
| `<Leader>sd` | 診断（現在のバッファ） |
| `<Leader>sD` | 診断（全バッファ） |
| `<Leader>sm` | マーク検索 |
| `<Leader>sR` | Resume（前回の検索を再開） |

## ファイルエクスプローラー（Neo-tree）

| キー | 説明 |
|------|------|
| `<Leader>e` | エクスプローラーをトグル（ルート） |
| `<Leader>E` | エクスプローラーをトグル（cwd） |
| `<Leader>fe` | エクスプローラーをトグル（ルート） |
| `<Leader>fE` | エクスプローラーをトグル（cwd） |
| `<Leader>ge` | Git エクスプローラー |
| `<Leader>be` | バッファエクスプローラー |

### Neo-tree 内の操作

| キー | 説明 |
|------|------|
| `Enter` / `o` | ファイルを開く / フォルダを展開 |
| `a` | 新規ファイル/フォルダ作成 |
| `d` | 削除 |
| `r` | 名前変更 |
| `y` | パスをコピー |
| `Y` | 相対パスをコピー |
| `x` | 切り取り |
| `p` | 貼り付け |
| `c` | コピー |
| `m` | 移動 |
| `H` | 隠しファイル表示切替 |
| `s` | 垂直分割で開く |
| `S` | 水平分割で開く |
| `/` | フィルター |
| `q` | 閉じる |

## バッファ操作

| キー | 説明 |
|------|------|
| `<Leader>bb` | 他のバッファに切り替え |
| `<Leader>bd` | バッファを削除 |
| `<Leader>bD` | バッファを強制削除 |
| `<Leader>bo` | 他のバッファをすべて削除 |
| `<Leader>bp` | ピン留めトグル |
| `<Leader>bP` | ピン留め以外を削除 |
| `<S-h>` / `[b` | 前のバッファ |
| `<S-l>` / `]b` | 次のバッファ |
| `<Leader>`1-9 | バッファ1-9に移動 |

## ウィンドウ操作

| キー | 説明 |
|------|------|
| `<C-h>` | 左のウィンドウへ移動 |
| `<C-j>` | 下のウィンドウへ移動 |
| `<C-k>` | 上のウィンドウへ移動 |
| `<C-l>` | 右のウィンドウへ移動 |
| `<Leader>w-` | 水平分割 |
| `<Leader>w\|` | 垂直分割 |
| `<Leader>-` | 水平分割 |
| `<Leader>\|` | 垂直分割 |
| `<Leader>wd` | ウィンドウを閉じる |
| `<Leader>wm` | ウィンドウを最大化 |
| `<C-Up>` | ウィンドウの高さを増やす |
| `<C-Down>` | ウィンドウの高さを減らす |
| `<C-Left>` | ウィンドウの幅を減らす |
| `<C-Right>` | ウィンドウの幅を増やす |

## タブ操作

| キー | 説明 |
|------|------|
| `<Leader><Tab>l` | 最後のタブ |
| `<Leader><Tab>o` | 他のタブを閉じる |
| `<Leader><Tab>f` | 最初のタブ |
| `<Leader><Tab><Tab>` | 新しいタブ |
| `<Leader><Tab>]` | 次のタブ |
| `<Leader><Tab>[` | 前のタブ |
| `<Leader><Tab>d` | タブを閉じる |

## LSP（言語サーバー）

| キー | 説明 |
|------|------|
| `K` | ホバードキュメント表示 |
| `gd` | 定義へジャンプ |
| `gD` | 宣言へジャンプ |
| `gr` | 参照一覧 |
| `gI` | 実装へジャンプ |
| `gy` | 型定義へジャンプ |
| `gK` | シグネチャヘルプ |
| `<Leader>ca` | コードアクション |
| `<Leader>cA` | ソースアクション |
| `<Leader>cf` | フォーマット |
| `<Leader>cr` | リネーム |
| `<Leader>cR` | 参照を検索（Telescope） |
| `<Leader>cd` | 行の診断を表示 |
| `<Leader>cl` | LSP 情報 |
| `]d` | 次の診断へ |
| `[d` | 前の診断へ |
| `]e` | 次のエラーへ |
| `[e` | 前のエラーへ |
| `]w` | 次の警告へ |
| `[w` | 前の警告へ |

## Git 操作

### Lazygit

| キー | 説明 |
|------|------|
| `<Leader>gg` | Lazygit を開く |
| `<Leader>gG` | Lazygit（cwd） |
| `<Leader>gf` | 現在のファイルのコミット履歴 |

### Git ピッカー（fzf-lua）

| キー | 説明 |
|------|------|
| `<Leader>gb` | Git ブランチ一覧 |
| `<Leader>gc` | Git コミット履歴 |
| `<Leader>gC` | Git コミット履歴（バッファ） |
| `<Leader>gt` | Git ステータス |
| `<Leader>gB` | ブラウザで開く |

### Hunk 操作（AstroVim 風）

| キー | 説明 |
|------|------|
| `<Leader>gs` | Hunk をステージ |
| `<Leader>gr` | Hunk をリセット |
| `<Leader>gS` | バッファをステージ |
| `<Leader>gR` | バッファをリセット |
| `<Leader>gu` | ステージを取り消し |
| `<Leader>gp` | Hunk をプレビュー |
| `<Leader>gj` | 次の Hunk へ |
| `<Leader>gk` | 前の Hunk へ |
| `]h` | 次の Hunk へ |
| `[h` | 前の Hunk へ |

### Blame / Diff

| キー | 説明 |
|------|------|
| `<Leader>gl` | Blame 行 |
| `<Leader>gL` | Blame バッファ |
| `<Leader>gd` | Diff |
| `<Leader>gD` | Diff（~） |

## ターミナル

| キー | 説明 |
|------|------|
| `<Leader>ft` | ターミナル（ルート） |
| `<Leader>fT` | ターミナル（cwd） |
| `<C-/>` | ターミナルをトグル |
| `<C-_>` | ターミナルをトグル（代替） |
| `<Esc><Esc>` | ターミナルモードを抜ける |

## コメント

| キー | 説明 |
|------|------|
| `gc` | 選択範囲をコメントトグル（Visual） |
| `gcc` | 行コメントトグル |
| `gco` | 下に行を追加してコメント |
| `gcO` | 上に行を追加してコメント |

## コード操作

| キー | 説明 |
|------|------|
| `<Leader>cf` | フォーマット |
| `<Leader>cd` | 行診断 |
| `<Leader>cc` | quickfix でコンパイル |
| `<Leader>cs` | シンボル検索 |
| `<Leader>cS` | ワークスペースシンボル |

## UI トグル

| キー | 説明 |
|------|------|
| `<Leader>ub` | 背景色（dark/light）トグル |
| `<Leader>uc` | 補完トグル |
| `<Leader>uC` | カラーコード表示トグル |
| `<Leader>ud` | 診断トグル |
| `<Leader>uf` | 自動フォーマットトグル |
| `<Leader>uF` | 自動フォーマットトグル（バッファ） |
| `<Leader>ug` | インデントガイドトグル |
| `<Leader>uh` | インレイヒントトグル |
| `<Leader>ui` | Treesitter ハイライトトグル |
| `<Leader>ul` | 行番号トグル |
| `<Leader>uL` | 相対行番号トグル |
| `<Leader>us` | スペルチェックトグル |
| `<Leader>uT` | Treesitter コンテキストトグル |
| `<Leader>uw` | 折り返しトグル |

## 通知

| キー | 説明 |
|------|------|
| `<Leader>un` | 通知を消す |
| `<Leader>sna` | 全通知履歴 |

## パッケージ管理（Lazy.nvim）

| キー | 説明 |
|------|------|
| `<Leader>l` | Lazy.nvim を開く |

### コマンドラインから

```vim
:Lazy              " Lazy.nvim 管理画面を開く
:Lazy sync         " プラグインを同期
:Lazy update       " プラグインを更新
:Lazy health       " ヘルスチェック
:Mason             " LSP/ツール管理画面
```

## Telescope 内の操作

| キー | 説明 |
|------|------|
| `<C-j>` / `<C-n>` | 下に移動 |
| `<C-k>` / `<C-p>` | 上に移動 |
| `<C-c>` / `<Esc>` | 閉じる |
| `<CR>` | 選択を開く |
| `<C-x>` | 水平分割で開く |
| `<C-v>` | 垂直分割で開く |
| `<C-t>` | 新しいタブで開く |
| `<C-d>` | プレビューを下にスクロール |
| `<C-u>` | プレビューを上にスクロール |
| `<Tab>` | 複数選択トグル + 下へ |
| `<S-Tab>` | 複数選択トグル + 上へ |
| `<C-q>` | quickfix に送る |

## 補完（nvim-cmp）

| キー | 説明 |
|------|------|
| `<C-Space>` | 補完を開始 |
| `<C-n>` | 次の候補 |
| `<C-p>` | 前の候補 |
| `<C-b>` | ドキュメントを上にスクロール |
| `<C-f>` | ドキュメントを下にスクロール |
| `<CR>` | 選択を確定 |
| `<C-e>` | 補完をキャンセル |
| `<Tab>` | 次の候補 / スニペット展開 |
| `<S-Tab>` | 前の候補 |

## Flash（高速移動）

| キー | 説明 |
|------|------|
| `s` | Flash ジャンプ |
| `S` | Flash Treesitter |
| `r` | Remote Flash（Operator pending） |
| `R` | Treesitter 検索 |

## Trouble（診断一覧）

| キー | 説明 |
|------|------|
| `<Leader>xx` | 診断（Trouble） |
| `<Leader>xX` | バッファ診断（Trouble） |
| `<Leader>xL` | ロケーションリスト |
| `<Leader>xQ` | Quickfix リスト |
| `[q` | 前の trouble/quickfix |
| `]q` | 次の trouble/quickfix |

## Todo Comments

| キー | 説明 |
|------|------|
| `<Leader>xt` | Todo（Trouble） |
| `<Leader>xT` | Todo/Fix/Fixme（Trouble） |
| `<Leader>st` | Todo 検索 |
| `<Leader>sT` | Todo/Fix/Fixme 検索 |
| `]t` | 次の Todo コメント |
| `[t` | 前の Todo コメント |

## その他の便利なキー

| キー | 説明 |
|------|------|
| `<Leader>K` | カーソル下の単語を man で検索 |
| `<Leader>L` | LazyVim の変更履歴 |
| `<Leader>qq` | 終了 |
| `<Leader>fn` | 新規ファイル |
| `<Leader>xl` | ロケーションリスト |
| `<Leader>xq` | Quickfix リスト |
| `j` / `k` | 表示行で移動（折り返し対応） |
| `<A-j>` | 行を下に移動 |
| `<A-k>` | 行を上に移動 |
| `<` / `>` | インデント（Visual） |

## カスタマイズ

設定ファイルの場所: `~/.config/nvim/lua/`

| ファイル | 説明 |
|----------|------|
| `config/options.lua` | Vim オプション |
| `config/keymaps.lua` | キーマップ |
| `config/autocmds.lua` | 自動コマンド |
| `config/lazy.lua` | Lazy.nvim 設定 |
| `plugins/*.lua` | プラグイン設定 |

## Extras（追加機能）

LazyVim には追加でインストールできる「extras」があります。

```vim
:LazyExtras        " 利用可能な extras を表示
```

主な extras:
- `lang.typescript` - TypeScript サポート
- `lang.python` - Python サポート
- `lang.rust` - Rust サポート
- `lang.go` - Go サポート
- `editor.mini-files` - 代替ファイラー
- `ui.mini-animate` - アニメーション

## トラブルシューティング

### プラグインが動かない場合

```bash
# nvim のデータをクリアして再起動
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
nvim
```

### ヘルスチェック

```vim
:checkhealth
:LazyHealth
```

### LSP が動作しない場合

```vim
:LspInfo         " 状態確認
:Mason           " 必要なLSPをインストール
```

## 参考リンク

- [LazyVim 公式ドキュメント](https://www.lazyvim.org/)
- [LazyVim GitHub](https://github.com/LazyVim/LazyVim)
- [LazyVim キーマップ一覧](https://www.lazyvim.org/keymaps)
