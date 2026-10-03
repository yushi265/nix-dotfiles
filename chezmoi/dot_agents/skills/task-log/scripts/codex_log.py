"""Codex のローカル JSONL を共通のタスクログ形式へ変換する。"""

from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import os
import re
import uuid


def records(path):
    """実行中のログの書きかけ行は読み飛ばす。内容は実行しない。"""
    with path.open("rb") as stream:
        for line in stream:
            try:
                value = json.loads(line)
            except (json.JSONDecodeError, UnicodeDecodeError):
                continue
            if isinstance(value, dict):
                yield value


def timestamp(value):
    if not isinstance(value, str):
        return None
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def session_index(data_dir, project_path=None):
    sessions_dir = data_dir / "sessions"
    if not sessions_dir.is_dir():
        raise ValueError(f"Codex の sessions ディレクトリが見つかりません: {sessions_dir}")
    wanted = Path(project_path).resolve() if project_path else None
    sessions = {}
    for path in sorted(sessions_dir.rglob("*.jsonl")):
        # session_meta は先頭レコード。対象外プロジェクトの会話本文は読まない。
        first = next(records(path), {})
        if first.get("type") != "session_meta":
            continue
        meta = first.get("payload", {})
        if not isinstance(meta, dict):
            continue
        cwd = meta.get("cwd")
        if not isinstance(cwd, str) or not cwd:
            continue
        if wanted is not None and Path(cwd).resolve() != wanted:
            continue
        try:
            sid = str(uuid.UUID(meta.get("id") or meta.get("session_id") or ""))
        except (ValueError, TypeError, AttributeError):
            continue
        sessions[sid] = (meta, path)
    return sessions


def content_text(content):
    if isinstance(content, str):
        return content.strip()
    if not isinstance(content, list):
        return ""
    return "\n".join(
        item["text"] for item in content
        if isinstance(item, dict)
        and item.get("type") in ("input_text", "output_text", "text")
        and isinstance(item.get("text"), str)
    ).strip()


CONTEXT_PREFIXES = (
    "# AGENTS.md instructions", "<environment_context>", "<user_instructions>",
    "<permissions instructions>", "<skill>", "<recommended_plugins>",
)


def parse_session(path, meta, common):
    data = {"tools": Counter(), "files_modified": [], "files_modified_known": False, "git_branch": None,
            "cwd": meta["cwd"], "model": None, "end_time": None, "conversation": []}
    if isinstance(meta.get("git"), dict):
        data["git_branch"] = meta["git"].get("branch")
    event_users = []
    event_assistants = []
    start = timestamp(meta.get("timestamp"))

    def turn(role, text, time):
        return {"role": role, "timestamp": time.astimezone(common.JST).strftime("%H:%M") if time else "??",
                "text": text, "commands": [], "_time": time.timestamp() if time else 0}

    def add_user(text, time, target):
        if not text or text.startswith(CONTEXT_PREFIXES) or text.startswith(common.SKIP_PREFIXES):
            return
        target.append((turn("user", text, time),
                       {"display": text, "timestamp": int(time.timestamp() * 1000) if time else 0}))

    response_users = []
    for record in records(path):
        time = timestamp(record.get("timestamp"))
        if time:
            data["end_time"] = max(data["end_time"], time) if data["end_time"] else time
            start = min(start, time) if start else time
        payload = record.get("payload", {})
        if not isinstance(payload, dict):
            continue
        kind = record.get("type")
        if kind == "turn_context":
            if payload.get("model"):
                data["model"] = payload["model"]
        elif kind == "event_msg":
            text = payload.get("message", "")
            if not isinstance(text, str):
                continue
            if payload.get("type") == "user_message":
                add_user(text.strip(), time, event_users)
            elif payload.get("type") == "agent_message" and text.strip():
                event_assistants.append(turn("assistant", text.strip(), time))
        elif kind == "response_item":
            item_type = payload.get("type")
            if item_type == "message":
                role = payload.get("role")
                text = content_text(payload.get("content"))
                if role == "user":
                    before = len(response_users)
                    add_user(text, time, response_users)
                    if len(response_users) > before:
                        data["conversation"].append(response_users[-1][0])
                elif role == "assistant" and text and payload.get("channel") not in ("analysis", "justify"):
                    data["conversation"].append(turn("assistant", text, time))
            elif item_type in ("function_call", "custom_tool_call"):
                name = payload.get("name")
                if isinstance(name, str) and name:
                    data["tools"][name] += 1
            # reasoning、ツール引数・出力、system/developer 指示はログへ転載しない。

    # 同じ発言の event_msg / response_item を1件にまとめる。
    # 片方しか保存されていない後続ターンも残す。同文の別時刻の発言は別件。
    response_times = defaultdict(list)
    for item in data["conversation"]:
        response_times[(item["role"], item["text"])].append(item["_time"])
    for item in [item for item, _ in event_users] + event_assistants:
        times = response_times[(item["role"], item["text"])]
        match = next((i for i, time in enumerate(times)
                      if abs(time - item["_time"]) <= 1 or not time or not item["_time"]), None)
        if match is None:
            data["conversation"].append(item)
        else:
            times.pop(match)
    data["conversation"].sort(key=lambda item: item["_time"])
    entries = [{"display": item["text"], "timestamp": int(item["_time"] * 1000)}
               for item in data["conversation"] if item["role"] == "user"]
    if entries and start:
        entries[0] = {**entries[0], "timestamp": int(start.timestamp() * 1000)}
    if data["end_time"]:
        data["end_time"] = data["end_time"].astimezone(common.JST)
    # Codex の一般的なツール呼び出しから変更成功や実行コマンドは断定しない。
    return entries, data


def project_log_dir(log_root, project_path, common):
    # 別の場所にある同名リポジトリのログが混ざらないようにする。
    resolved = str(Path(project_path).resolve())
    key = hashlib.sha256(resolved.encode()).hexdigest()[:12]
    return log_root / f"{common.get_project_name(resolved)}-{key}"


def show_log(log_dir, project_path, show_arg, common):
    if show_arg and re.fullmatch(r"[0-9a-fA-F]{8}[0-9a-fA-F-]*", show_arg):
        matches = [p for p in sorted(log_dir.glob("*/*.md"))
                   if p.stem.split("_", 1)[-1].startswith(show_arg.lower())]
        if len(matches) > 1:
            return {"status": "error", "message": "複数のセッションに一致します。完全なセッションIDを指定してください。"}
        return {"status": "show", "project": common.get_project_name(project_path),
                "content": matches[0].read_text(encoding="utf-8") if matches else f"(セッション {show_arg} が見つかりません)"}
    return common.show_sessions(str(log_dir), common.get_project_name(project_path), show_arg)


def run(args, common):
    data_dir = Path(args.data_dir or os.environ.get("CODEX_HOME") or "~/.codex").expanduser()
    log_root = Path(args.log_dir).expanduser() if args.log_dir else data_dir / "task-logs"
    project_path = args.project_path or (os.getcwd() if args.auto else None)
    if not project_path and not args.all:
        raise ValueError("--project-path または --all を指定してください")
    if args.show is not None:
        if not project_path:
            raise ValueError("--show には --project-path が必要です")
        log_dir = project_log_dir(log_root, project_path, common)
        return show_log(log_dir, project_path, args.show or None, common)

    sessions = session_index(data_dir, None if args.all else project_path)
    result = {"status": "dry_run" if args.dry_run else "success", "source": "codex",
              "new_entries": 0, "skipped": 0, "log_files": [], "entries_preview": []}
    for sid, (meta, path) in sessions.items():
        entries, data = parse_session(path, meta, common)
        if not entries:
            result["skipped"] += 1
            continue
        date, name, content = common.build_session_file(sid, entries, data, meta["cwd"])
        if not date:
            result["skipped"] += 1
            continue
        # UUIDv7 の先頭8文字は近い時刻のセッションで共通になる。
        name = name.replace(sid[:8], sid)
        log_dir = project_log_dir(log_root, meta["cwd"], common)
        destination = log_dir / date / name
        if destination.exists() and destination.read_text(encoding="utf-8") == content:
            continue
        if not args.dry_run:
            written = common.write_session_file(str(log_dir), date, name, content)
            result["log_files"].append(written)
        result["new_entries"] += 1
        result["entries_preview"].append(f"[{common.get_project_name(meta['cwd'])}] {common.get_session_first_message(entries)[:80]}")
    return result
