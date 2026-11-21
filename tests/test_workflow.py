#!/usr/bin/env python3
"""Exercise shell caches and tmux picker edge cases without live sessions."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
PICKER = ROOT / "tmux/.tmux/scripts/session-picker"


class ShellTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which("zsh"), "zsh is unavailable")
    def test_completion_cache_is_created_refreshed_and_then_reused(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / ".zshrc").symlink_to(ROOT / "zsh/.zshrc")
            insecure = home / "insecure-completions"
            insecure.mkdir()
            insecure.chmod(0o777)
            (insecure / "_dotfiles_insecure").write_text("#compdef dotfiles-insecure\n")
            # Ubuntu's global zshrc would initialize completions before ours.
            (home / ".zshenv").write_text(
                'skip_global_compinit=1\nfpath=("$HOME/insecure-completions" $fpath)\n'
            )
            env = dict(os.environ, HOME=directory, ZDOTDIR=directory, TERM="xterm-256color")

            def start():
                result = subprocess.run(
                    ["zsh", "-i", "-c", '[[ -z ${_comps[dotfiles-insecure]} ]]'],
                    cwd=directory, env=env, stdin=subprocess.DEVNULL,
                    capture_output=True, text=True, timeout=20,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stderr, "")

            start()
            dump = home / ".zcompdump"
            self.assertTrue(dump.is_file())
            stale = time.time() - 49 * 3600
            os.utime(dump, (stale, stale))
            start()
            refreshed = dump.stat().st_mtime_ns
            self.assertGreater(refreshed / 1e9, stale + 3600)
            start()
            self.assertEqual(dump.stat().st_mtime_ns, refreshed)

    @unittest.skipUnless(shutil.which("zsh") and shutil.which("fd"), "zsh/fd unavailable")
    def test_file_and_directory_widgets_exclude_generated_content(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / ".zshrc").symlink_to(ROOT / "zsh/.zshrc")
            project = home / "project"
            for name in ["src/main.py", ".config/settings.toml", "node_modules/pkg/index.js", ".venv/lib/package.py", ".git/objects/object"]:
                path = project / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.touch()
            result = subprocess.run(
                ["zsh", "-i", "-c", 'eval "$FZF_CTRL_T_COMMAND"; eval "$FZF_ALT_C_COMMAND"'],
                cwd=project, env=dict(os.environ, HOME=directory, ZDOTDIR=directory),
                capture_output=True, text=True, timeout=20,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("src/main.py", result.stdout)
            self.assertIn(".config/settings.toml", result.stdout)
            self.assertIn("src/", result.stdout)
            for excluded in ["node_modules", ".venv", ".git/"]:
                self.assertNotIn(excluded, result.stdout)


class SessionPickerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.bindir = self.home / "bin"
        self.bindir.mkdir()
        self.log = self.home / "tmux.jsonl"
        self.env = dict(os.environ, HOME=str(self.home),
                        PATH=str(self.bindir) + os.pathsep + os.environ["PATH"],
                        PICKER_TMUX_LOG=str(self.log))
        self.stub("tmux", '''
import json, os, sys
with open(os.environ["PICKER_TMUX_LOG"], "a") as log:
    log.write(json.dumps(sys.argv[1:]) + "\\n")
if sys.argv[1] == "list-sessions":
    print("$1 current [work]")
    print("$2 dev's quoted project")
if sys.argv[1] == "has-session" and os.environ.get("PICKER_NEW"):
    sys.exit(1)
''')
        self.stub("fzf", '''
import os, sys
lines = sys.stdin.read().splitlines()
selection = os.environ.get("PICKER_SELECTION", "")
if selection not in lines:
    sys.exit(1)
print(selection)
''')
        self.stub("zoxide", 'import os\nprint(os.environ.get("PICKER_PROJECT", ""))\n')
        self.stub("fd", "")

    def stub(self, name, code):
        path = self.bindir / name
        path.write_text(f"#!{sys.executable}\n" + code)
        path.chmod(0o755)

    def run_picker(self, *args):
        result = subprocess.run(["sh", str(PICKER), *args], env=self.env,
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_session_names_with_quotes_and_spaces_switch_by_id(self):
        self.env["PICKER_SELECTION"] = "$2 dev's quoted project"
        calls = self.run_picker("sessions", "$1")
        self.assertEqual(calls[-1], ["switch-client", "-t", "$2"])

    def test_current_session_is_excluded_and_cancellation_changes_nothing(self):
        self.env["PICKER_SELECTION"] = "$1 current [work]"
        calls = self.run_picker("sessions", "$1")
        self.assertEqual([call[0] for call in calls], ["list-sessions"])

    def test_project_paths_with_spaces_use_exact_session_targets(self):
        project = self.home / "project with spaces"
        project.mkdir()
        self.env.update(PICKER_PROJECT=str(project) + "/",
                        PICKER_SELECTION=str(project) + "/", PICKER_NEW="1")
        calls = self.run_picker("projects")
        create = next(call for call in calls if call[0] == "new-session")
        self.assertEqual(create[-2:], ["-c", str(project)])
        name = create[create.index("-s") + 1]
        self.assertIn(["has-session", "-t", "=" + name], calls)
        self.assertEqual(calls[-1], ["switch-client", "-t", "=" + name])


if __name__ == "__main__":
    unittest.main(verbosity=2)
