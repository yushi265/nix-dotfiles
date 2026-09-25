"""旧ミラーの移行を隔離したchezmoi展開先で検証する（applyは実行しない）。"""
import subprocess
import shutil
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
TEMPLATE = REPO / 'chezmoi/run_onchange_after_03-codex-skills-symlink.sh.tmpl'


class MigrationTest(unittest.TestCase):
    def test_retired_skill_is_removed_from_chezmoi_destination(self):
        with tempfile.TemporaryDirectory(prefix='retired skill ') as directory:
            root = Path(directory)
            source = root / 'source'
            destination = root / 'home'
            source.mkdir()
            destination.mkdir()
            shutil.copyfile(REPO / 'chezmoi/.chezmoiremove', source / '.chezmoiremove')

            canonical = destination / '.agents/skills/fable5'
            canonical.mkdir(parents=True)
            (canonical / 'SKILL.md').write_text('retired')
            kept = destination / '.agents/skills/keep/SKILL.md'
            kept.parent.mkdir()
            kept.write_text('keep')
            claude = destination / '.claude/skills/fable5'
            claude.parent.mkdir(parents=True)
            claude.symlink_to(canonical)
            codex = destination / '.codex/skills/fable5'
            codex.parent.mkdir(parents=True)
            codex.symlink_to(claude)
            rule = destination / '.claude/rules/fable5-protocol.md'
            rule.parent.mkdir()
            rule.write_text('retired')

            command = [
                'chezmoi', '--source', str(source), '--destination', str(destination),
                '--persistent-state', str(root / 'chezmoistate.boltdb'),
                '--cache', str(root / 'cache'),
                'apply', '--include=remove', '--force',
            ]
            for _ in range(2):
                subprocess.run(command, check=True)
                for path in (canonical, claude, codex, rule):
                    self.assertFalse(path.exists() or path.is_symlink(), path)
                self.assertEqual(kept.read_text(), 'keep')

    def test_only_known_duplicate_links_are_removed(self):
        with tempfile.TemporaryDirectory(prefix='codex migration ') as directory:
            destination = Path(directory)
            agents = destination / '.agents/skills'
            claude = destination / '.claude/skills'
            codex = destination / '.codex/skills'
            for folder in (agents, claude, codex):
                folder.mkdir(parents=True)

            def canonical(name):
                folder = agents / name
                folder.mkdir()
                (folder / 'SKILL.md').write_text(name)
                return folder

            def mirror(name):
                link = codex / name
                link.symlink_to(claude / name)
                return link

            # 管理対象の重複ミラーだけ削除する。
            shared = canonical('git-branch')
            (claude / 'git-branch').symlink_to(shared)
            duplicate = mirror('git-branch')
            # ユーザー管理の実体、カスタムリンク、壊れたリンクを保持する。
            (codex / 'git-commit').mkdir()
            (codex / 'git-commit/user.txt').write_text('keep')
            other = destination / 'custom'
            other.mkdir()
            (other / 'SKILL.md').write_text('custom')
            canonical('branch-info')
            (claude / 'branch-info').symlink_to(other)
            customized = mirror('branch-info')
            direct = codex / 'prompt-gen'
            direct.symlink_to(canonical('prompt-gen'))
            dangling = mirror('note')
            canonical('note')
            # 管理外スキルは同じ構造でも削除しない。
            unmanaged = canonical('user-only')
            (claude / 'user-only').symlink_to(unmanaged)
            unmanaged_link = mirror('user-only')
            (codex / '.system').mkdir()
            (codex / '.system/keep').write_text('system')

            rendered = subprocess.check_output([
                'chezmoi', '--source', str(REPO / 'chezmoi'),
                '--destination', str(destination),
                'execute-template', '--file', str(TEMPLATE),
            ], text=True)
            # 実ホームを操作しないことを実行前に確認。
            self.assertIn(f'migration_root="{destination}"', rendered)
            script = destination / 'migration.sh'
            script.write_text(rendered)
            subprocess.run(['bash', '-n', str(script)], check=True)
            for _ in range(2):  # 再実行しても結果が変わらない。
                subprocess.run(['bash', str(script)], check=True)
                self.assertFalse(duplicate.is_symlink())
                self.assertEqual((shared / 'SKILL.md').read_text(), 'git-branch')
                self.assertTrue((claude / 'git-branch').is_symlink())
                for link in (customized, direct, dangling, unmanaged_link):
                    self.assertTrue(link.is_symlink())
                self.assertEqual((codex / 'git-commit/user.txt').read_text(), 'keep')
                self.assertEqual((codex / '.system/keep').read_text(), 'system')

    def test_empty_destination_stays_empty(self):
        with tempfile.TemporaryDirectory() as directory:
            rendered = subprocess.check_output([
                'chezmoi', '--source', str(REPO / 'chezmoi'),
                '--destination', directory,
                'execute-template', '--file', str(TEMPLATE),
            ], text=True)
            subprocess.run(['bash'], input=rendered, text=True, check=True)
            self.assertEqual(list(Path(directory).iterdir()), [])


if __name__ == '__main__':
    unittest.main()
