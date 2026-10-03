"""実履歴やホームディレクトリを変更せずに両クライアントの CLI を検証する。"""

from pathlib import Path
import json
import subprocess
import sys
import tempfile
import unittest


SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
SCRIPT = SCRIPTS / "generate_log.py"
if not SCRIPT.exists():
    SCRIPT = SCRIPTS / "executable_generate_log.py"


class TaskLogTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "project"
        self.project.mkdir()
        self.logs = self.root / "logs"
        self.data = self.root / "data"
        self.data.mkdir()
        self.sid = "01a0943d-fc57-7a72-965d-54a116fc95d6"

    def write_jsonl(self, path, rows):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("\n".join(json.dumps(row) for row in rows) + "\n", encoding="utf-8")

    def cli(self, source=None, *extra):
        command = [sys.executable, "-B", str(SCRIPT), "--data-dir", str(self.data),
                   "--log-dir", str(self.logs), "--project-path", str(self.project)]
        if source:
            command += ["--source", source]
        process = subprocess.run(command + list(extra), capture_output=True, text=True, check=True)
        return json.loads(process.stdout)

    def codex_fixture(self, cwd=None, sid=None, filename="session.jsonl"):
        rows = [
            {"type": "session_meta", "timestamp": "2026-09-12T06:00:00Z",
             "payload": {"id": sid or self.sid, "cwd": str(cwd or self.project),
                         "timestamp": "2026-09-12T06:00:00Z", "git": {"branch": "codex/example"}}},
            {"type": "turn_context", "payload": {"model": "gpt-6-astra"}},
            {"type": "response_item", "payload": {"type": "message", "role": "developer",
             "content": [{"type": "input_text", "text": "INTERNAL_INSTRUCTION"}]}},
            {"type": "response_item", "payload": {"type": "message", "role": "user",
             "content": [{"type": "input_text", "text": "# AGENTS.md instructions for /example"}]}},
            {"type": "event_msg", "timestamp": "2026-09-12T06:00:01Z",
             "payload": {"type": "user_message", "message": "日本語の依頼"}},
            {"type": "response_item", "timestamp": "2026-09-12T06:00:01Z",
             "payload": {"type": "message", "role": "user",
                         "content": [{"type": "input_text", "text": "日本語の依頼"}]}},
            {"type": "response_item", "payload": {"type": "reasoning", "text": "PRIVATE_REASONING"}},
            {"type": "response_item", "payload": {"type": "function_call", "name": "exec_command",
             "arguments": '{"cmd": "PRIVATE_TOOL_INPUT"}'}},
            {"type": "response_item", "payload": {"type": "custom_tool_call", "name": "apply_patch",
             "input": "PRIVATE_PATCH"}},
            {"type": "response_item", "payload": {"type": "function_call_output", "output": "PRIVATE_OUTPUT"}},
            {"type": "event_msg", "timestamp": "2026-09-12T06:02:00Z",
             "payload": {"type": "agent_message", "message": "実装しました"}},
            {"type": "response_item", "timestamp": "2026-09-12T06:02:00Z",
             "payload": {"type": "message", "role": "assistant", "phase": "final_answer",
                         "content": [{"type": "output_text", "text": "実装しました"}]}},
        ]
        path = self.data / "sessions" / "2026" / filename
        self.write_jsonl(path, rows)
        return path, rows

    def test_codex_dry_run_generation_deduplication_and_update(self):
        path, rows = self.codex_fixture()
        with path.open("a") as f:
            f.write('{"partial":')
        preview = self.cli("codex", "--dry-run")
        self.assertEqual(preview["new_entries"], 1)
        self.assertFalse(self.logs.exists())
        result = self.cli("codex")
        output = Path(result["log_files"][0])
        text = output.read_text()
        self.assertEqual(text.count("### ユーザー"), 1)
        self.assertEqual(text.count("実装しました"), 1)
        self.assertIn("15:00 → 15:02", text)
        self.assertIn("gpt-6-astra", text)
        self.assertIn("| exec_command | 1 |", text)
        self.assertIn("| apply_patch | 1 |", text)
        self.assertIn("未集計", text)
        for private in ["INTERNAL_INSTRUCTION", "PRIVATE_REASONING", "PRIVATE_TOOL_INPUT", "PRIVATE_PATCH", "PRIVATE_OUTPUT"]:
            self.assertNotIn(private, text)
        self.assertEqual(self.cli("codex")["new_entries"], 0)
        self.assertEqual(self.cli("codex", "--show", self.sid)["content"], text)
        rows.append({"type": "response_item", "timestamp": "2026-09-12T06:03:00Z",
                     "payload": {"type": "message", "role": "assistant", "content": "追加結果"}})
        self.write_jsonl(path, rows)
        self.assertEqual(self.cli("codex")["new_entries"], 1)
        self.assertIn("追加結果", output.read_text())
        self.assertEqual(len(list(self.logs.rglob("*.md"))), 1)

    def test_codex_project_filter_and_same_name_projects(self):
        self.codex_fixture()
        other = self.root / "other" / "project"
        other.mkdir(parents=True)
        self.codex_fixture(other, "11111111-2222-4333-8444-555555555555", "other.jsonl")
        self.assertEqual(self.cli("codex", "--dry-run")["new_entries"], 1)
        self.assertEqual(self.cli("codex", "--all")["new_entries"], 2)
        self.assertEqual(len(list(self.logs.iterdir())), 2)

    def test_codex_same_minute_sessions_do_not_overwrite(self):
        self.codex_fixture()
        other_sid = "01a0943d-aaaa-7bbb-8ccc-dddddddddddd"
        self.codex_fixture(sid=other_sid, filename="second.jsonl")
        self.assertEqual(self.cli("codex")["new_entries"], 2)
        outputs = list(self.logs.rglob("*.md"))
        self.assertEqual(len(outputs), 2)
        self.assertIn(self.sid, self.cli("codex", "--show", self.sid)["content"])
        self.assertIn(other_sid, self.cli("codex", "--show", other_sid)["content"])
        self.assertEqual(self.cli("codex")["new_entries"], 0)
        result = subprocess.run([sys.executable, "-B", str(SCRIPT), "--source", "codex",
                                 "--data-dir", str(self.data), "--log-dir", str(self.logs),
                                 "--project-path", str(self.project), "--show", self.sid[:8]],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(json.loads(result.stdout)["status"], "error")

    def test_claude_default_and_explicit_source_keep_existing_format(self):
        self.write_jsonl(self.data / "history.jsonl", [
            {"project": str(self.project), "sessionId": self.sid, "timestamp": 1789192800000,
             "display": "Claude の依頼"}])
        encoded = str(self.project).replace("/", "-").replace(".", "-")
        self.write_jsonl(self.data / "projects" / encoded / f"{self.sid}.jsonl", [
            {"type": "user", "timestamp": "2026-09-12T06:00:00Z", "message": {"content": "Claude の依頼"}},
            {"type": "assistant", "timestamp": "2026-09-12T06:01:00Z", "message": {
                "model": "claude-example", "content": [{"type": "text", "text": "Claude の結果"},
                {"type": "tool_use", "name": "Bash", "input": {"command": "git status"}}]}}])
        self.assertEqual(self.cli(None, "--dry-run")["new_entries"], 1)
        self.assertFalse(self.logs.exists())
        result = self.cli("claude")
        outputs = list(self.logs.rglob("*.md"))
        self.assertEqual(result["new_entries"], 1)
        self.assertIn("Claude の結果", outputs[0].read_text())
        self.assertIn("claude-example", outputs[0].read_text())
        self.assertIn("git status", outputs[0].read_text())
        self.assertEqual(self.cli()["new_entries"], 0)
        self.assertIn("Claude の結果", self.cli(None, "--show", self.sid)["content"])

    def test_codex_event_only_and_midnight_order(self):
        path, rows = self.codex_fixture()
        self.write_jsonl(path, [rows[0],
            {"type": "event_msg", "timestamp": "2026-09-12T14:59:00Z", "payload": {"type": "user_message", "message": "夜の依頼"}},
            {"type": "event_msg", "timestamp": "2026-09-12T15:01:00Z", "payload": {"type": "agent_message", "message": "翌日の結果"}}])
        result = self.cli("codex")
        text = Path(result["log_files"][0]).read_text()
        self.assertLess(text.index("### ユーザー"), text.index("### アシスタント"))
        self.assertIn("翌日の結果", text)

    def test_codex_mixed_message_formats_keep_later_turns(self):
        path, rows = self.codex_fixture()
        rows.extend([
            {"type": "event_msg", "timestamp": "2026-09-12T06:03:00Z",
             "payload": {"type": "user_message", "message": "日本語の依頼"}},
            {"type": "event_msg", "timestamp": "2026-09-12T06:04:00Z",
             "payload": {"type": "agent_message", "message": "続きの結果"}},
        ])
        self.write_jsonl(path, rows)
        result = self.cli("codex")
        text = Path(result["log_files"][0]).read_text()
        self.assertEqual(text.count("### ユーザー"), 2)
        self.assertEqual(text.count("### アシスタント"), 2)
        self.assertIn("続きの結果", text)

    def test_codex_other_project_corrupt_body_does_not_block(self):
        self.codex_fixture()
        other = self.root / "other"
        other.mkdir()
        path, _ = self.codex_fixture(other, "11111111-2222-4333-8444-555555555555", "other.jsonl")
        with path.open("ab") as stream:
            stream.write(b'\xff\n')
        result = self.cli("codex")
        self.assertEqual(result["new_entries"], 1)
        self.assertEqual(len(list(self.logs.rglob("*.md"))), 1)

    def test_codex_report_heading_in_user_text_is_preserved(self):
        path, rows = self.codex_fixture()
        rows.append({"type": "event_msg", "timestamp": "2026-09-12T06:03:00Z",
                     "payload": {"type": "user_message", "message": "## 変更ファイル\n\nなし"}})
        self.write_jsonl(path, rows)
        result = self.cli("codex")
        text = Path(result["log_files"][0]).read_text()
        self.assertIn("## 変更ファイル\n\nなし\n", text)
        self.assertEqual(text.count("未集計（"), 1)


if __name__ == "__main__":
    unittest.main()
