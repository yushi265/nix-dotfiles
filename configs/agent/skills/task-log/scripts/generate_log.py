#!/usr/bin/env python3
"""
generate_log.py - Claude Code タスク実行履歴ログ生成スクリプト v2

セッション単位のファイルを生成。詳細な会話フロー・実行コマンド・モデル情報を含む。
~/.claude/history.jsonl と ~/.claude/projects/<encoded>/<session>.jsonl を使用。
"""

import json
import os
import sys
import argparse
import re
from datetime import datetime, timezone, timedelta
from collections import defaultdict

CLAUDE_DIR = os.path.expanduser("~/.claude")
HISTORY_FILE = os.path.join(CLAUDE_DIR, "history.jsonl")
PROJECTS_DIR = os.path.join(CLAUDE_DIR, "projects")
TASK_LOGS_DIR = os.path.join(CLAUDE_DIR, "task-logs")
JST = timezone(timedelta(hours=9))

SKIP_PREFIXES = ("/clear", "/usage", "/help", "/compact", "<local-command", "<system-reminder")


def encode_project_path(path):
    """プロジェクトパスをエンコードされたディレクトリ名に変換する。"""
    return path.replace("/", "-").replace(".", "-")


def get_project_name(project_path):
    """プロジェクトパスからプロジェクト名を取得する。"""
    return os.path.basename(project_path.rstrip("/")) or "unknown-project"


def parse_iso_timestamp(ts_raw):
    """タイムスタンプをJSTのdatetimeに変換する。intはms、strはISO 8601。"""
    if isinstance(ts_raw, (int, float)):
        return datetime.fromtimestamp(ts_raw / 1000, tz=JST)
    elif isinstance(ts_raw, str):
        try:
            dt_utc = datetime.fromisoformat(ts_raw.rstrip("Z")).replace(tzinfo=timezone.utc)
            return dt_utc.astimezone(JST)
        except ValueError:
            pass
    return None


def load_history(project_path=None):
    """history.jsonl を読み込み、プロジェクト別・セッション別にグループ化する。"""
    if not os.path.exists(HISTORY_FILE):
        return {}

    sessions = defaultdict(lambda: defaultdict(list))

    with open(HISTORY_FILE, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            proj = obj.get("project", "")
            sid = obj.get("sessionId", "")
            if not proj or not sid:
                continue

            if project_path and proj != project_path:
                continue

            sessions[proj][sid].append(obj)

    return sessions


def get_session_first_message(entries):
    """セッションエントリのリストから最初の有効なユーザーメッセージを取得する。"""
    for entry in sorted(entries, key=lambda e: e.get("timestamp", 0)):
        display = entry.get("display", "").strip()
        if not display:
            continue

        skip = False
        for prefix in SKIP_PREFIXES:
            if display.lower().startswith(prefix.lower()):
                skip = True
                break
        if skip:
            continue

        pasted_match = re.match(r'^\[Pasted text[^\]]*\]\s*(.*)', display, re.DOTALL)
        if pasted_match:
            remaining = pasted_match.group(1).strip()
            if remaining:
                display = remaining
            else:
                pasted = entry.get("pastedContents", {})
                if pasted:
                    first_content = next(iter(pasted.values()), {})
                    content_text = first_content.get("content", "").strip()
                    if content_text:
                        display = content_text[:80]
                        break
                continue

        return display

    return "(内容不明)"


def get_session_start_time(entries):
    """セッションエントリの最小タイムスタンプを返す（JST）。history.jsonl のmsタイムスタンプ用。"""
    timestamps = [e.get("timestamp", 0) for e in entries if e.get("timestamp")]
    if not timestamps:
        return None
    ts_ms = min(timestamps)
    return datetime.fromtimestamp(ts_ms / 1000, tz=JST)


def parse_session_jsonl(session_file):
    """セッション JSONL ファイルをパースしてリッチデータを返す。

    Returns:
        dict: {
            "tools": {tool_name: count},
            "files_modified": [path, ...],
            "git_branch": str,
            "cwd": str,
            "model": str,
            "end_time": datetime (JST),
            "conversation": [{"role", "timestamp", "text", "commands"}, ...],
        }
    """
    result = {
        "tools": defaultdict(int),
        "files_modified": set(),
        "git_branch": None,
        "cwd": None,
        "model": None,
        "end_time": None,
        "conversation": [],
    }

    if not os.path.exists(session_file):
        return result

    try:
        all_entries = []
        with open(session_file, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                all_entries.append(obj)

        all_jst_times = []

        for obj in all_entries:
            ts_raw = obj.get("timestamp")
            ts_jst = parse_iso_timestamp(ts_raw) if ts_raw else None
            if ts_jst:
                all_jst_times.append(ts_jst)

            if obj.get("gitBranch") and not result["git_branch"]:
                result["git_branch"] = obj["gitBranch"]
            if obj.get("cwd") and not result["cwd"]:
                result["cwd"] = obj["cwd"]

            entry_type = obj.get("type")

            # ユーザーメッセージ（文字列コンテンツのみ＝実際の入力）
            if entry_type == "user":
                if obj.get("isMeta"):
                    continue
                msg = obj.get("message", {})
                content = msg.get("content")
                if isinstance(content, str) and content.strip():
                    text = content.strip()
                    # コマンド系・タグ系をスキップ
                    skip = False
                    for prefix in SKIP_PREFIXES:
                        if text.lower().startswith(prefix.lower()):
                            skip = True
                            break
                    # <command-name> 形式をスキップ
                    if not skip and re.match(r'^<[a-zA-Z][\w-]*>', text):
                        skip = True
                    if not skip:
                        ts_str = ts_jst.strftime("%H:%M") if ts_jst else "??"
                        result["conversation"].append({
                            "role": "user",
                            "timestamp": ts_str,
                            "text": text,
                            "commands": [],
                        })

            # アシスタントメッセージ
            elif entry_type == "assistant":
                msg = obj.get("message", {})
                if not result["model"] and msg.get("model"):
                    result["model"] = msg["model"]

                content = msg.get("content", [])
                if not isinstance(content, list):
                    continue

                text_parts = []
                commands_in_turn = []

                for item in content:
                    if not isinstance(item, dict):
                        continue

                    item_type = item.get("type")

                    if item_type == "text":
                        t = item.get("text", "").strip()
                        if t:
                            # 200文字で切り詰め
                            text_parts.append(t[:200] + ("…" if len(t) > 200 else ""))

                    elif item_type == "tool_use":
                        tool_name = item.get("name", "")
                        if tool_name:
                            result["tools"][tool_name] += 1

                        if tool_name in ("Write", "Edit"):
                            inp = item.get("input", {})
                            fpath = inp.get("file_path", "")
                            if fpath:
                                result["files_modified"].add(fpath)

                        if tool_name == "Bash":
                            inp = item.get("input", {})
                            desc = inp.get("description", "").strip()
                            cmd = inp.get("command", "").strip()
                            display = desc if desc else (cmd[:80] + ("…" if len(cmd) > 80 else ""))
                            if display:
                                commands_in_turn.append(display)

                combined_text = "\n\n".join(text_parts) if text_parts else ("(ツール実行)" if commands_in_turn else "")
                if combined_text or commands_in_turn:
                    ts_str = ts_jst.strftime("%H:%M") if ts_jst else "??"
                    result["conversation"].append({
                        "role": "assistant",
                        "timestamp": ts_str,
                        "text": combined_text,
                        "commands": commands_in_turn,
                    })

        if all_jst_times:
            result["end_time"] = max(all_jst_times)

    except Exception:
        pass

    result["files_modified"] = list(result["files_modified"])
    return result


def make_relative_path(file_path, cwd, project_path):
    """ファイルパスをプロジェクトルートからの相対パスに変換する。~/.claude/ 配下は除外。"""
    claude_dir_expanded = os.path.expanduser("~/.claude")
    if file_path.startswith(claude_dir_expanded):
        return None

    for base in [project_path, cwd]:
        if base and file_path.startswith(base + "/"):
            return file_path[len(base) + 1:]

    return file_path


def build_session_file(session_id, entries, session_data, project_path):
    """セッション単位のマークダウンファイル内容を生成する。

    Returns:
        (date_str, filename, content) または (None, None, None)
    """
    start_time = get_session_start_time(entries)
    if start_time is None:
        return None, None, None

    date_str = start_time.strftime("%Y-%m-%d")
    time_str = start_time.strftime("%H:%M")
    file_time_str = start_time.strftime("%H-%M")

    # タイトル（最初のユーザーメッセージ全文、改行除去）
    task_title = get_session_first_message(entries)
    task_title = task_title.replace("\n", " ").replace("\r", "")

    short_id = session_id[:8]

    # 終了時刻・所要時間
    end_time = session_data.get("end_time")
    if end_time and start_time:
        duration_secs = int((end_time - start_time).total_seconds())
        duration_mins = duration_secs // 60
        duration_str = f"{duration_mins}分" if duration_mins > 0 else "1分未満"
        time_range = f"{time_str} → {end_time.strftime('%H:%M')} ({duration_str})"
    else:
        time_range = time_str

    branch = session_data.get("git_branch") or "不明"
    model = session_data.get("model") or "不明"

    # ツール使用テーブル
    tools = session_data.get("tools", {})
    if tools:
        tools_rows = ""
        for name, count in sorted(tools.items(), key=lambda x: x[1], reverse=True):
            tools_rows += f"| {name} | {count} |\n"
        tools_section = "| ツール | 回数 |\n|--------|------|\n" + tools_rows.rstrip()
    else:
        tools_section = "(データなし)"

    # 変更ファイル
    cwd = session_data.get("cwd") or project_path
    files = session_data.get("files_modified", [])
    rel_files = []
    for fpath in files:
        rel = make_relative_path(fpath, cwd, project_path)
        if rel:
            rel_files.append(rel)
    rel_files = sorted(set(rel_files))
    files_section = "\n".join(f"- `{f}`" for f in rel_files) if rel_files else "なし"

    # 会話フロー
    conversation = session_data.get("conversation", [])
    conv_lines = []
    for turn in conversation:
        role = turn["role"]
        ts = turn["timestamp"]
        text = turn["text"]
        cmds = turn["commands"]

        if role == "user":
            conv_lines.append(f"### ユーザー ({ts})")
            conv_lines.append("")
            conv_lines.append(text)
        else:
            conv_lines.append("### アシスタント")
            conv_lines.append("")
            if text and text != "(ツール実行)":
                conv_lines.append(text)
            if cmds:
                conv_lines.append("")
                conv_lines.append("**実行コマンド:**")
                for cmd in cmds:
                    conv_lines.append(f"- `{cmd}`")
        conv_lines.append("")

    conv_section = "\n".join(conv_lines).strip() if conv_lines else "(データなし)"

    lines = [
        f"# {task_title}",
        "",
        "| 項目 | 値 |",
        "|------|-----|",
        f"| **日時** | {time_range} |",
        f"| **セッション** | `{session_id}` |",
        f"| **ブランチ** | {branch} |",
        f"| **モデル** | {model} |",
        "",
        "## ツール使用",
        "",
        tools_section,
        "",
        "## 会話フロー",
        "",
        conv_section,
        "",
        "## 変更ファイル",
        "",
        files_section,
    ]

    content = "\n".join(lines) + "\n"
    filename = f"{file_time_str}_{short_id}.md"

    return date_str, filename, content


def write_session_file(log_dir, date_str, filename, content):
    """YYYY-MM-DD/HH-MM_<short_id>.md にファイルを書き込む。"""
    date_dir = os.path.join(log_dir, date_str)
    os.makedirs(date_dir, exist_ok=True)
    filepath = os.path.join(date_dir, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    return filepath


def load_logged_sessions(log_dir):
    """記録済みセッションIDのセットを返す。"""
    logged_file = os.path.join(log_dir, ".logged-sessions")
    if not os.path.exists(logged_file):
        return set()
    with open(logged_file, encoding="utf-8") as f:
        return set(line.strip() for line in f if line.strip())


def save_logged_sessions(log_dir, new_session_ids):
    """新しいセッションIDを .logged-sessions に追記する。"""
    logged_file = os.path.join(log_dir, ".logged-sessions")
    with open(logged_file, "a", encoding="utf-8") as f:
        for sid in new_session_ids:
            f.write(sid + "\n")


def show_sessions(log_dir, project_name, show_arg):
    """--show の閲覧ロジック。"""
    if not os.path.exists(log_dir):
        return {"status": "show", "project": project_name, "content": "(ログディレクトリがありません)"}

    # セッションID (8文字以上の16進)
    if show_arg and re.match(r'^[0-9a-f]{8,}', show_arg.lower()):
        short_id = show_arg[:8].lower()
        for date_dir in sorted(os.listdir(log_dir)):
            date_path = os.path.join(log_dir, date_dir)
            if not os.path.isdir(date_path):
                continue
            for fname in sorted(os.listdir(date_path)):
                if short_id in fname.lower() and fname.endswith(".md"):
                    with open(os.path.join(date_path, fname), encoding="utf-8") as f:
                        content = f.read()
                    return {"status": "show", "project": project_name, "content": content}
        return {"status": "show", "project": project_name,
                "content": f"(セッション {show_arg} が見つかりません)"}

    # YYYY-MM-DD 形式
    if show_arg and re.match(r'^\d{4}-\d{2}-\d{2}$', show_arg):
        date_path = os.path.join(log_dir, show_arg)
        if not os.path.exists(date_path):
            return {"status": "show", "project": project_name,
                    "content": f"({show_arg} のログがありません)"}
        files = sorted(f for f in os.listdir(date_path) if f.endswith(".md"))
        if not files:
            return {"status": "show", "project": project_name,
                    "content": f"({show_arg} のログがありません)"}
        lines = [f"# {project_name} — {show_arg} のセッション一覧\n"]
        for fname in files:
            name_part = fname.replace(".md", "")
            parts = name_part.split("_", 1)
            time_part = parts[0].replace("-", ":") if parts else "??"
            sid_part = parts[1] if len(parts) > 1 else ""
            title = "(タイトル不明)"
            with open(os.path.join(date_path, fname), encoding="utf-8") as f:
                for line in f:
                    if line.startswith("# "):
                        title = line[2:].strip()
                        break
            lines.append(f"- **{time_part}** `{sid_part}` — {title}")
        return {"status": "show", "project": project_name, "content": "\n".join(lines)}

    # 引数なし → 直近7日間、YYYY-MM → その月
    all_date_dirs = []
    for d in sorted(os.listdir(log_dir)):
        dpath = os.path.join(log_dir, d)
        if os.path.isdir(dpath) and re.match(r'^\d{4}-\d{2}-\d{2}$', d):
            all_date_dirs.append(d)

    if show_arg and re.match(r'^\d{4}-\d{2}$', show_arg):
        target_dates = [d for d in all_date_dirs if d.startswith(show_arg)]
        label = show_arg
    else:
        cutoff_str = (datetime.now(tz=JST) - timedelta(days=7)).strftime("%Y-%m-%d")
        target_dates = [d for d in all_date_dirs if d >= cutoff_str]
        label = "直近7日間"

    if not target_dates:
        return {"status": "show", "project": project_name,
                "content": f"({label} のログがありません)"}

    lines = [f"# {project_name} セッション一覧 ({label})\n"]
    for date_str in target_dates:
        date_path = os.path.join(log_dir, date_str)
        files = sorted(f for f in os.listdir(date_path) if f.endswith(".md"))
        if not files:
            continue
        lines.append(f"\n## {date_str}")
        for fname in files:
            name_part = fname.replace(".md", "")
            parts = name_part.split("_", 1)
            time_part = parts[0].replace("-", ":") if parts else "??"
            sid_part = parts[1] if len(parts) > 1 else ""
            title = "(タイトル不明)"
            with open(os.path.join(date_path, fname), encoding="utf-8") as f:
                for line in f:
                    if line.startswith("# "):
                        title = line[2:].strip()
                        break
            lines.append(f"- **{time_part}** `{sid_part}` — {title}")

    return {"status": "show", "project": project_name, "content": "\n".join(lines)}


def process_project(project_path, dry_run=False, show=False, show_arg=None, auto=False):
    """1プロジェクトのログ処理を実行する。"""
    project_name = get_project_name(project_path)
    encoded = encode_project_path(project_path)
    project_sessions_dir = os.path.join(PROJECTS_DIR, encoded)
    log_dir = os.path.join(TASK_LOGS_DIR, project_name)

    if show:
        return show_sessions(log_dir, project_name, show_arg)

    all_sessions = load_history(project_path)
    project_sessions = all_sessions.get(project_path, {})

    if not project_sessions:
        if auto:
            return None
        return {"status": "success", "project": project_name,
                "new_entries": 0, "skipped": 0, "log_files": [], "entries_preview": []}

    if not dry_run:
        os.makedirs(log_dir, exist_ok=True)

    logged_sessions = load_logged_sessions(log_dir)
    new_session_ids = [sid for sid in project_sessions if sid not in logged_sessions]

    if not new_session_ids:
        if auto:
            return None
        return {"status": "success", "project": project_name,
                "new_entries": 0, "skipped": 0, "log_files": [], "entries_preview": []}

    # タイムスタンプ順にソート
    sessions_with_time = []
    for sid in new_session_ids:
        hist_entries = project_sessions[sid]
        start_time = get_session_start_time(hist_entries)
        sessions_with_time.append((start_time or datetime.min.replace(tzinfo=JST), sid, hist_entries))
    sessions_with_time.sort(key=lambda x: x[0])

    skipped = 0
    new_logged = []
    entries_preview = []
    written_files = []

    for start_time_obj, sid, hist_entries in sessions_with_time:
        if not hist_entries:
            skipped += 1
            new_logged.append(sid)
            continue

        session_file = os.path.join(project_sessions_dir, f"{sid}.jsonl")
        session_data = parse_session_jsonl(session_file)

        date_str, filename, content = build_session_file(sid, hist_entries, session_data, project_path)

        if date_str is None:
            skipped += 1
            new_logged.append(sid)
            continue

        if not dry_run:
            fpath = write_session_file(log_dir, date_str, filename, content)
            written_files.append(fpath.replace(os.path.expanduser("~"), "~"))

        task_desc = get_session_first_message(hist_entries)
        if len(task_desc) > 50:
            task_desc = task_desc[:49] + "…"
        time_str = start_time_obj.strftime("%H:%M") if start_time_obj != datetime.min.replace(tzinfo=JST) else "??"
        entries_preview.append(f"{time_str} - {task_desc}")
        new_logged.append(sid)

    if not dry_run and new_logged:
        save_logged_sessions(log_dir, new_logged)

    if auto:
        return None

    return {
        "status": "success" if not dry_run else "dry_run",
        "project": project_name,
        "new_entries": len(entries_preview),
        "skipped": skipped,
        "log_files": written_files,
        "entries_preview": entries_preview,
    }


def process_all_projects(dry_run=False, auto=False):
    """全プロジェクトのログ処理を実行する。"""
    all_sessions = load_history()
    results = []

    for project_path in sorted(all_sessions.keys()):
        result = process_project(project_path, dry_run=dry_run, auto=auto)
        if result and (result.get("new_entries", 0) > 0 or result.get("status") == "error"):
            results.append(result)

    if auto:
        return None

    total_new = sum(r.get("new_entries", 0) for r in results)
    all_previews = []
    for r in results:
        for p in r.get("entries_preview", []):
            all_previews.append(f"[{r['project']}] {p}")

    return {
        "status": "success" if not dry_run else "dry_run",
        "projects_processed": len(results),
        "new_entries": total_new,
        "entries_preview": all_previews,
        "details": results,
    }


def main():
    parser = argparse.ArgumentParser(description="Claude Code タスクログ生成 v2")
    parser.add_argument("--project-path", help="対象プロジェクトのパス")
    parser.add_argument("--all", action="store_true", help="全プロジェクト処理")
    parser.add_argument("--dry-run", action="store_true", help="プレビューのみ（書き込みなし）")
    parser.add_argument("--show", nargs="?", const="", metavar="DATE|SESSION-ID",
                        help="ログを表示する（YYYY-MM-DD, YYYY-MM, セッションID, または省略で直近7日）")
    parser.add_argument("--auto", action="store_true",
                        help="hook用サイレントモード（現在のpwdのプロジェクトを処理、stdout無出力）")

    args = parser.parse_args()

    # --auto モード（SessionStart hook用）
    if args.auto:
        try:
            project_path = os.getcwd()
            process_project(project_path, auto=True)
        except Exception:
            pass
        return

    # --show モード
    if args.show is not None:
        show_arg = args.show if args.show else None
        if not args.project_path:
            result = {"status": "error", "message": "--show には --project-path が必要です"}
        else:
            result = process_project(args.project_path, show=True, show_arg=show_arg)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return

    # --all モード
    if args.all:
        result = process_all_projects(dry_run=args.dry_run)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return

    # 通常モード（プロジェクト指定必須）
    if not args.project_path:
        result = {"status": "error", "message": "--project-path を指定してください"}
        print(json.dumps(result, ensure_ascii=False, indent=2))
        sys.exit(1)

    result = process_project(args.project_path, dry_run=args.dry_run)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
