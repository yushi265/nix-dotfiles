"""外部スキルの導入スクリプトを一時ディレクトリで検証する（applyは実行しない）。"""
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO / 'chezmoi'
INSTALL = SOURCE / 'run_onchange_after_05-skills-install.sh.tmpl'


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


if __name__ == '__main__':
    unittest.main()
