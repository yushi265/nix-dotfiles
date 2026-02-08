#!/bin/bash
set -euo pipefail

# Claude Code 言語ローテーションスクリプト

SETTINGS_FILE="$HOME/.claude/settings.json"
LOG_FILE="$HOME/.claude/rotate-language.log"
# LAST_RUN_FILE="$HOME/.claude/rotate-language.last"

# 今日すでに実行済みかチェック
# TODAY=$(date +%Y-%m-%d)
# if [ -f "$LAST_RUN_FILE" ]; then
#   LAST_RUN=$(cat "$LAST_RUN_FILE")
#   if [ "$LAST_RUN" = "$TODAY" ]; then
#     exit 0
#   fi
# fi

LANGUAGES=(
  "深夜テンションのなんJ実況民"
  "設定を語り出す重度の中二病"
  "語彙が全て『それな』な限界JK"
  "主君への忠誠だけで生きている江戸武士"
  "関西弁で明るくお節介な話し方"
  "丁寧語で威圧感のある帝王口調"
  "ハイテンションなお嬢様口調"
)

# settings.json の存在確認
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "$(date): settings.json not found" >>"$LOG_FILE"
  exit 1
fi

# ランダム選択
RANDOM_INDEX=$((RANDOM % ${#LANGUAGES[@]}))
LANGUAGE="${LANGUAGES[$RANDOM_INDEX]}"

if command -v jq >/dev/null 2>&1; then
  TMP_FILE=$(mktemp)
  jq --arg lang "$LANGUAGE" '
    .language = $lang
  ' "$SETTINGS_FILE" >"$TMP_FILE"

  mv "$TMP_FILE" "$SETTINGS_FILE"
else
  # jq が無い場合のフォールバック（最低限）
  if grep -q '"language"' "$SETTINGS_FILE"; then
    sed -i '' "s/\"language\": *\"[^\"]*\"/\"language\": \"$LANGUAGE\"/" "$SETTINGS_FILE"
  else
    sed -i '' "s/}$/,\n  \"language\": \"$LANGUAGE\"\n}/" "$SETTINGS_FILE"
  fi
fi

echo "$(date): Language set to '$LANGUAGE'" >>"$LOG_FILE"

# 実行日を記録
# echo "$TODAY" > "$LAST_RUN_FILE"
