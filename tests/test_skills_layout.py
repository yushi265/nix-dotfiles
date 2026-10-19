"""外部スキルの導入と配置移行のスクリプトを一時ディレクトリで検証する（applyは実行しない）。"""
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO / 'chezmoi'
INSTALL = SOURCE / 'run_onchange_after_05-skills-install.sh.tmpl'
MIGRATION = SOURCE / 'run_onchange_after_06-skills-layout-migration.sh.tmpl'


def render(template, destination):
    return subprocess.check_output([
        'chezmoi', '--source', str(SOURCE), '--destination', str(destination),
        'execute-template', '--file', str(template),
    ], text=True)


def skills_data():
    data = json.loads(subprocess.check_output(
        ['chezmoi', '--source', str(SOURCE), 'data', '--format', 'json'], text=True))
    return data['skills']


class DeclarationTest(unittest.TestCase):
    def test_external_skills_are_not_also_managed_by_chezmoi(self):
        local = {p.name for p in (SOURCE / 'dot_agents/skills').iterdir()}
        external = [name for entry in skills_data()['external'] for name in entry['skills']]
        self.assertEqual(len(external), len(set(external)), '同じスキルを二重に宣言している')
        self.assertEqual(set(external) & local, set())

    def test_every_local_skill_has_a_claude_link(self):
        local = {p.name for p in (SOURCE / 'dot_agents/skills').iterdir()}
        links = {p.name.removeprefix('symlink_').removesuffix('.tmpl')
                 for p in (SOURCE / 'private_dot_claude/skills').glob('symlink_*.tmpl')}
        self.assertEqual(local, links)


class InstallTest(unittest.TestCase):
    def test_commands_follow_declared_agents(self):
        with tempfile.TemporaryDirectory() as directory:
            rendered = render(INSTALL, directory)
        subprocess.run(['bash', '-n'], input=rendered, text=True, check=True)
        commands = [line for line in rendered.splitlines() if line.startswith('npx ')]
        data = skills_data()
        self.assertEqual(len(commands), len(data['external']))
        for command, entry in zip(commands, data['external']):
            self.assertIn(f'add "{entry["source"]}" -g -y', command)
            for name in entry['skills']:
                self.assertIn(f'-s "{name}"', command)
            for agent in entry.get('agents', data['defaultAgents']):
                self.assertIn(f'-a "{agent}"', command)
        cloudflare = next(c for c in commands if '"cloudflare/skills"' in c)
        self.assertNotIn('claude-code', cloudflare)

    def test_only_stale_claude_links_to_plugin_skills_are_removed(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            agents = home / '.agents/skills'
            claude = home / '.claude/skills'
            agents.mkdir(parents=True)
            claude.mkdir(parents=True)
            for name in ('cloudflare', 'wrangler', 'grilling'):
                (agents / name).mkdir()
            other = home / 'other'
            other.mkdir()
            stale = claude / 'cloudflare'
            stale.symlink_to(agents / 'cloudflare')
            custom = claude / 'wrangler'
            custom.symlink_to(other)
            real = claude / 'durable-objects'
            real.mkdir()
            shared = claude / 'grilling'
            shared.symlink_to(agents / 'grilling')

            # ネットワークに出ないよう npx を差し替える。
            bin_dir = home / 'bin'
            bin_dir.mkdir()
            (bin_dir / 'npx').write_text('#!/bin/sh\nexit 0\n')
            (bin_dir / 'npx').chmod(0o755)
            script = home / 'install.sh'
            script.write_text(render(INSTALL, home))
            env = {**os.environ, 'HOME': str(home), 'PATH': f'{bin_dir}:{os.environ["PATH"]}'}
            for _ in range(2):
                subprocess.run(['bash', str(script)], env=env, check=True)
                self.assertFalse(stale.is_symlink())
                self.assertTrue(custom.is_symlink())
                self.assertTrue(real.is_dir())
                self.assertTrue(shared.is_symlink())


class MigrationTest(unittest.TestCase):
    def test_removes_only_known_duplicates(self):
        with tempfile.TemporaryDirectory(prefix='skills migration ') as directory:
            home = Path(directory)
            agents = home / '.agents/skills'
            claude = home / '.claude/skills'
            codex = home / '.codex/skills'
            for folder in (agents, claude, codex):
                folder.mkdir(parents=True)

            def skill(folder, name, aws=False):
                path = folder / name
                path.mkdir()
                (path / 'SKILL.md').write_text(name)
                if aws:
                    (path / '.aws-skill-metadata').write_text('{"version": "v2"}')
                return path

            aws_copies = [skill(agents, 'aws-cdk', aws=True), skill(claude, 'aws-cdk', aws=True)]
            kept_local = skill(agents, 'git-commit')
            kept_claude = skill(claude, 'learned')
            aws_link = claude / 'aws-iam'
            aws_link.symlink_to(skill(home, 'aws-iam', aws=True))

            # npx skills で ~/.agents に入った外部スキルだけ Codex 側の実体を消す。
            skill(agents, 'defuddle')
            codex_duplicate = skill(codex, 'defuddle')
            codex_pending = skill(codex, 'json-canvas')
            codex_unmanaged = skill(codex, 'hatch-pet')
            skill(agents, 'hatch-pet')
            codex_system = codex / '.system'
            codex_system.mkdir()

            rendered = render(MIGRATION, home)
            # 実ホームを操作しないことを実行前に確認。
            self.assertIn(f'migration_root="{home}"', rendered)
            script = home / 'migration.sh'
            script.write_text(rendered)
            subprocess.run(['bash', '-n', str(script)], check=True)
            for _ in range(2):
                subprocess.run(['bash', str(script)], check=True)
                for path in aws_copies + [codex_duplicate]:
                    self.assertFalse(path.exists(), path)
                for path in (kept_local, kept_claude, codex_pending, codex_unmanaged, codex_system):
                    self.assertTrue(path.is_dir(), path)
                self.assertTrue(aws_link.is_symlink())

    def test_empty_destination_stays_empty(self):
        with tempfile.TemporaryDirectory() as directory:
            subprocess.run(['bash'], input=render(MIGRATION, directory), text=True, check=True)
            self.assertEqual(list(Path(directory).iterdir()), [])


if __name__ == '__main__':
    unittest.main()
