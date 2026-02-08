# AstroNvim 操作ガイド

AstroNvim v5 の基本操作をまとめたガイドです。

## 基本概念

- **Leader キー**: `Space` （ほとんどのショートカットの起点）
- **Local Leader**: `,` （ファイルタイプ固有の操作）

## ファイル操作

| キー | 説明 |
|------|------|
| `<Leader>ff` | ファイル検索（Telescope） |
| `<Leader>fw` | 単語検索（grep） |
| `<Leader>fb` | バッファ一覧 |
| `<Leader>fh` | ヘルプ検索 |
| `<Leader>fo` | 最近開いたファイル |
| `<Leader>fn` | 新規ファイル作成 |

## ファイルエクスプローラー（Neo-tree）

| キー | 説明 |
|------|------|
| `<Leader>e` | エクスプローラーをトグル |
| `<Leader>o` | エクスプローラーにフォーカス |

### Neo-tree 内の操作

| キー | 説明 |
|------|------|
| `Enter` / `o` | ファイルを開く / フォルダを展開 |
| `a` | 新規ファイル/フォルダ作成 |
| `d` | 削除 |
| `r` | 名前変更 |
| `y` | パスをコピー |
| `x` | 切り取り |
| `p` | 貼り付け |
| `H` | 隠しファイル表示切替 |
| `q` | 閉じる |

## バッファ操作

| キー | 説明 |
|------|------|
| `<Leader>c` | 現在のバッファを閉じる |
| `<Leader>C` | 強制的にバッファを閉じる |
| `<Leader>bc` | 他のバッファをすべて閉じる |
| `]b` | 次のバッファ |
| `[b` | 前のバッファ |
| `>b` | バッファを右に移動 |
| `<b` | バッファを左に移動 |

## ウィンドウ操作

| キー | 説明 |
|------|------|
| `<C-h>` | 左のウィンドウへ移動 |
| `<C-j>` | 下のウィンドウへ移動 |
| `<C-k>` | 上のウィンドウへ移動 |
| `<C-l>` | 右のウィンドウへ移動 |
| `<Leader>\` | 垂直分割 |
| `<Leader>-` | 水平分割 |
| `<C-Up>` | ウィンドウの高さを増やす |
| `<C-Down>` | ウィンドウの高さを減らす |
| `<C-Left>` | ウィンドウの幅を減らす |
| `<C-Right>` | ウィンドウの幅を増やす |

## LSP（言語サーバー）

| キー | 説明 |
|------|------|
| `K` | ホバードキュメント表示 |
| `gd` | 定義へジャンプ |
| `gD` | 宣言へジャンプ |
| `gr` | 参照一覧 |
| `gI` | 実装へジャンプ |
| `gy` | 型定義へジャンプ |
| `<Leader>la` | コードアクション |
| `<Leader>lf` | フォーマット |
| `<Leader>lr` | リネーム |
| `<Leader>ld` | 行の診断を表示 |
| `<Leader>lD` | 診断一覧（Telescope） |
| `]d` | 次の診断へ |
| `[d` | 前の診断へ |

## Git 操作

| キー | 説明 |
|------|------|
| `<Leader>gb` | ブランチ一覧 |
| `<Leader>gc` | コミット一覧 |
| `<Leader>gt` | ステータス |
| `<Leader>gj` | 次のhunkへ |
| `<Leader>gk` | 前のhunkへ |
| `<Leader>gs` | hunkをステージ |
| `<Leader>gu` | hunkをアンステージ |
| `<Leader>gp` | hunkをプレビュー |
| `<Leader>gl` | blame を表示 |
| `<Leader>gd` | diff を表示 |

## ターミナル

| キー | 説明 |
|------|------|
| `<Leader>tf` | フローティングターミナル |
| `<Leader>th` | 水平ターミナル |
| `<Leader>tv` | 垂直ターミナル |
| `<C-\>` | ターミナルをトグル |
| `<Esc><Esc>` | ターミナルモードを抜ける |

## コメント

| キー | 説明 |
|------|------|
| `gc` | 選択範囲をコメントトグル（Visual） |
| `gcc` | 行コメントトグル |
| `gbc` | ブロックコメントトグル |

## 検索・置換

| キー | 説明 |
|------|------|
| `<Leader>s` | シンボル検索 |
| `<Leader>/` | 現在のバッファ内検索 |
| `*` | カーソル下の単語を検索 |
| `n` / `N` | 次/前の検索結果 |

## セッション管理

| キー | 説明 |
|------|------|
| `<Leader>Sl` | 最後のセッションを読み込み |
| `<Leader>Ss` | セッションを保存 |
| `<Leader>Sf` | セッションを検索 |
| `<Leader>Sd` | セッションを削除 |

## UI トグル

| キー | 説明 |
|------|------|
| `<Leader>ub` | 背景色（dark/light）トグル |
| `<Leader>uc` | 自動補完トグル |
| `<Leader>uC` | カラーコード表示トグル |
| `<Leader>ud` | 診断表示トグル |
| `<Leader>ug` | サインカラムトグル |
| `<Leader>ui` | インデントガイドトグル |
| `<Leader>ul` | ステータスラインコンポーネント |
| `<Leader>un` | 行番号トグル |
| `<Leader>up` | ペーストモードトグル |
| `<Leader>us` | スペルチェックトグル |
| `<Leader>uS` | 構文ハイライトトグル |
| `<Leader>ut` | タブライントグル |
| `<Leader>uw` | 折り返しトグル |

## パッケージ管理（Lazy.nvim）

| キー | 説明 |
|------|------|
| `<Leader>pi` | プラグインインストール |
| `<Leader>ps` | プラグイン同期 |
| `<Leader>pS` | プラグインステータス |
| `<Leader>pu` | プラグイン更新 |
| `<Leader>pU` | Lazy.nvim 更新 |

### コマンドラインから

```vim
:Lazy              " Lazy.nvim 管理画面を開く
:Lazy sync         " プラグインを同期
:Lazy update       " プラグインを更新
:Mason             " LSP/ツール管理画面
```

## Mason（LSP/ツール管理）

| キー | 説明 |
|------|------|
| `<Leader>pm` | Mason を開く |

### Mason 内の操作

| キー | 説明 |
|------|------|
| `i` | パッケージをインストール |
| `X` | パッケージをアンインストール |
| `u` | パッケージを更新 |
| `U` | 全パッケージを更新 |

## よく使うコマンド

```vim
:AstroUpdate       " AstroNvim を更新
:AstroReload       " 設定をリロード
:checkhealth       " ヘルスチェック
:TSInstall <lang>  " Treesitter パーサーをインストール
:LspInfo           " LSP の状態を確認
```

## Telescope 内の操作

| キー | 説明 |
|------|------|
| `<C-j>` / `<C-k>` | 上下移動 |
| `<C-n>` / `<C-p>` | 履歴の上下 |
| `<C-c>` / `<Esc>` | 閉じる |
| `<CR>` | 選択を開く |
| `<C-x>` | 水平分割で開く |
| `<C-v>` | 垂直分割で開く |
| `<C-t>` | 新しいタブで開く |
| `<Tab>` | 複数選択トグル |

## 補完（nvim-cmp）

| キー | 説明 |
|------|------|
| `<C-Space>` | 補完を開始 |
| `<C-n>` / `<C-j>` | 次の候補 |
| `<C-p>` / `<C-k>` | 前の候補 |
| `<CR>` | 選択を確定 |
| `<C-e>` | 補完をキャンセル |
| `<Tab>` | スニペット展開/次のプレースホルダ |
| `<S-Tab>` | 前のプレースホルダ |

## カスタマイズ

設定ファイルの場所: `~/.config/nvim/lua/`

| ファイル | 説明 |
|----------|------|
| `plugins/astrocore.lua` | コア設定（オプション、キーマップ） |
| `plugins/astroui.lua` | UI 設定（カラースキーム） |
| `plugins/catppuccin.lua` | Catppuccin テーマ設定 |
| `community.lua` | コミュニティプラグイン |
| `polish.lua` | 最終設定（起動後に実行される） |

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
```

### LSP が動作しない場合

```vim
:LspInfo         " 状態確認
:Mason           " 必要なLSPをインストール
```

## 参考リンク

- [AstroNvim 公式ドキュメント](https://docs.astronvim.com/)
- [AstroNvim GitHub](https://github.com/AstroNvim/AstroNvim)
- [AstroNvim Community](https://github.com/AstroNvim/astrocommunity)
