#!/usr/bin/env python3
"""Static regression tests for safety and portability invariants."""

import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def tracked_files():
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT, text=True, capture_output=True, check=True,
    )
    return [ROOT / name for name in result.stdout.splitlines() if name]


class AuditTests(unittest.TestCase):
    def test_no_permission_bypass(self):
        for path in tracked_files():
            if path.is_file():
                self.assertNotIn("dangerously" + "-skip-permissions", path.read_text(errors="ignore"), path)

    def test_lockfile_is_trackable(self):
        lockfile = ROOT / "nvim/.config/nvim/lazy-lock.json"
        self.assertTrue(lockfile.exists())
        ignored = subprocess.run(["git", "check-ignore", "-q", str(lockfile)], cwd=ROOT)
        self.assertNotEqual(ignored.returncode, 0)

    def test_no_high_confidence_secrets(self):
        patterns = [
            re.compile(r"ghp_[A-Za-z0-9]{20,}"),
            re.compile(r"github_pat_[A-Za-z0-9_]{20,}"),
            re.compile(r"AKIA[0-9A-Z]{16}"),
            re.compile("BEGIN " + r"(?:RSA |OPENSSH |EC )?PRIVATE KEY"),
        ]
        for path in tracked_files():
            if not path.is_file():
                continue
            data = path.read_bytes()
            if b"\0" in data:
                continue
            text = data.decode(errors="ignore")
            for pattern in patterns:
                self.assertIsNone(pattern.search(text), f"secret-like value in {path}")

    def test_no_literal_personal_home(self):
        for path in tracked_files():
            if path.is_file() and path.suffix not in {".jpg", ".png"}:
                self.assertNotIn("/home/" + "davis", path.read_text(errors="ignore"), path)

    def test_hypr_bindings_are_unique(self):
        config = (ROOT / "hypr/.config/hypr/hyprland.conf").read_text()
        seen = set()
        for line in config.splitlines():
            if re.match(r"^bind(?:e|l|el|m)?\s*=", line):
                fields = [part.strip() for part in line.split("=", 1)[1].split(",")]
                key = tuple(fields[:2])
                self.assertNotIn(key, seen, f"duplicate Hypr binding: {key}")
                seen.add(key)

    def test_power_commands_only_in_confirmed_menu_or_idle_policy(self):
        allowed = {
            ROOT / "rofi/.config/rofi/powermenu.sh",
            ROOT / "hypr/.config/hypr/hypridle.conf",
        }
        pattern = re.compile(r"(?:systemctl\s+(?:power" + r"off|reboot|suspend)|shutdown\s|\breboot\b|dispatch\s+exit)")
        for path in tracked_files():
            if path in allowed or not path.is_file():
                continue
            if path.is_relative_to(ROOT / "tests") or path.name == "README.md":
                continue
            if path.suffix in {".jpg", ".png"}:
                continue
            self.assertIsNone(pattern.search(path.read_text(errors="ignore")), path)

    def test_generic_hypr_config_preserves_portable_behavior(self):
        hypr = (ROOT / "hypr/.config/hypr/hyprland.conf").read_text()
        idle = (ROOT / "hypr/.config/hypr/hypridle.conf").read_text()
        paper = (ROOT / "hypr/.config/hypr/hyprpaper.conf").read_text()

        self.assertNotIn("GDK_SCALE", hypr)
        self.assertNotIn("kbd_backlight", hypr)
        self.assertLess(hypr.index("$bar ="), hypr.index("exec-once = $bar"))
        self.assertIn("systemctl suspend", idle)
        self.assertIn("~/.config/hypr/paper.png", paper)
        self.assertNotIn("~/.config/hypr/wallpaper.png", paper)

        expected = {
            ROOT / "hypr/.config/hypr/wallpaper.png": "ca4766d51b5f5edf1a490cea4c20a05ccd419be49a9479604de9741aea423363",
            ROOT / "hypr/.config/hypr/paper.png": "99e0638da7d6881eaa45f724de83408b1d1380b4596fc50a049daaacccce2baa",
        }
        for path, digest in expected.items():
            self.assertTrue(path.is_file(), f"missing preserved wallpaper {path}")
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), digest)

        waybar = (ROOT / "waybar/.config/waybar/waybar.sh").read_text()
        self.assertIn("pkill -USR1 -x waybar", waybar)
        self.assertNotIn("USR2", waybar)

        bootstrap = (ROOT / "dotfiles").read_text()
        self.assertIn("prepare_hypr_host", bootstrap)
        self.assertIn("host.conf.example", bootstrap)

        screenshot_lines = [line for line in hypr.splitlines() if "hyprshot" in line]
        self.assertEqual(len(screenshot_lines), 3)
        for line in screenshot_lines:
            self.assertEqual(line.count(" -m "), 1, f"hyprshot must select exactly one mode: {line}")

    def test_package_manifests_cover_active_workflow(self):
        def packages(path):
            return {
                line.strip() for line in path.read_text().splitlines()
                if line.strip() and not line.startswith("#")
            }

        core = packages(ROOT / "packages/arch/core.txt")
        development = packages(ROOT / "packages/arch/development.txt")
        desktop = packages(ROOT / "packages/arch/desktop-hypr.txt")
        optional = packages(ROOT / "packages/arch/optional.txt")
        aur_desktop = packages(ROOT / "packages/aur/desktop-hypr.txt")

        self.assertTrue({"base-devel", "git-lfs", "ripgrep", "stow", "zsh", "tmux", "neovim"} <= core)
        self.assertTrue({"corepack", "mise", "nodejs", "npm", "python", "uv"} <= development)
        self.assertTrue({"blueman", "firefox", "hyprshot", "procps-ng", "rofi", "ttf-jetbrains-mono-nerd", "wl-clipboard"} <= desktop)
        self.assertTrue({"btop", "cava", "fastfetch"} <= optional)
        self.assertIn("gnome-network-displays", aur_desktop)
        self.assertNotIn("gnome-network-displays", desktop)
        self.assertFalse({"rofi-wayland"} & desktop)
        self.assertNotIn("hyprshot", aur_desktop)

    def test_profile_aware_bootstrap_dry_runs(self):
        for profile, expected, excluded in [
            ("development", ["corepack", "mise", "stow --dir="], ["hyprland"]),
            ("desktop-hypr", ["hyprland", "hyprshot", "gnome-network-displays", "stow --dir="], []),
        ]:
            with tempfile.TemporaryDirectory() as target:
                env = os.environ.copy()
                env["DOTFILES_TARGET"] = target
                result = subprocess.run(
                    [str(ROOT / "dotfiles"), "--dry-run", "bootstrap", profile],
                    cwd=ROOT,
                    text=True,
                    capture_output=True,
                    env=env,
                )
            self.assertEqual(result.returncode, 0, result.stderr)
            output = result.stdout + result.stderr
            for token in expected:
                self.assertIn(token, output)
            for token in excluded:
                self.assertNotIn(token, output)

        with tempfile.TemporaryDirectory() as target:
            env = os.environ.copy()
            env.update(DOTFILES_TARGET=target, AUR_HELPER="not-a-helper")
            invalid_helper = subprocess.run(
                [str(ROOT / "dotfiles"), "--dry-run", "install-packages", "desktop-hypr"],
                cwd=ROOT,
                text=True,
                capture_output=True,
                env=env,
            )
        self.assertNotEqual(invalid_helper.returncode, 0)
        self.assertIn("AUR_HELPER must be paru or yay", invalid_helper.stderr)

    def test_doctor_covers_core_and_desktop_commands(self):
        result = subprocess.run(
            [str(ROOT / "dotfiles"), "doctor", "all"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        output = result.stdout + result.stderr
        for command in ["git-lfs", "node", "npm", "corepack", "rg", "mise", "uv", "wl-copy", "firefox", "hyprshot", "swaync-client", "loginctl", "systemctl", "pgrep", "pkill", "claude", "opencode"]:
            self.assertRegex(output, rf"(?:ok|missing): {re.escape(command)}(?:\s|$)")

        optional = subprocess.run(
            [str(ROOT / "dotfiles"), "doctor", "optional"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        optional_output = optional.stdout + optional.stderr
        for unrelated in ["tmux-256color", "en_US.UTF-8", "Git submodules"]:
            self.assertNotIn(unrelated, optional_output)

        with tempfile.TemporaryDirectory() as bindir:
            for command in ["awk", "dirname", "grep", "infocmp", "locale"]:
                executable = shutil.which(command)
                if executable:
                    Path(bindir, command).symlink_to(executable)
            env = os.environ.copy()
            env["PATH"] = bindir
            missing_git = subprocess.run(
                [str(ROOT / "dotfiles"), "doctor", "core"],
                cwd=ROOT,
                text=True,
                capture_output=True,
                env=env,
            )
        missing_git_output = missing_git.stdout + missing_git.stderr
        self.assertIn("missing: Git unavailable; submodule status not checked", missing_git_output)
        self.assertNotIn("ok: Git submodules initialized", missing_git_output)

    def test_ci_installs_and_exercises_validation_tools(self):
        workflow = (ROOT / ".github/workflows/check.yml").read_text()
        for token in ["stow", "zsh", "tmux", "lua", "./tests/run.sh", "gitleaks/gitleaks-action", "fetch-depth: 0"]:
            self.assertIn(token, workflow)
        runner = (ROOT / "tests/run.sh").read_text()
        self.assertIn("tmux", runner)

    def test_tmux_sessions_persist_across_restarts(self):
        config = (ROOT / "tmux/.tmux.conf").read_text()
        required = [
            "set -g @plugin 'tmux-plugins/tmux-resurrect'",
            "set -g @plugin 'tmux-plugins/tmux-continuum'",
            "set -g @continuum-restore 'on'",
            "set -g @continuum-save-interval '15'",
            "set -g @continuum-boot 'on'",
        ]
        for setting in required:
            self.assertIn(setting, config)

        self.assertLess(config.index("tmux-plugins/tmux-resurrect"), config.index("tmux-plugins/tmux-continuum"))
        self.assertLess(config.index("tmux-plugins/tmux-continuum"), config.index("run '~/.tmux/plugins/tpm/tpm'"))
        self.assertNotIn("@resurrect-processes ':all:'", config)
        self.assertNotIn("@resurrect-capture-pane-contents 'on'", config)

    def test_zsh_non_tty_interactive_startup_is_clean(self):
        if not shutil.which("zsh"):
            self.skipTest("zsh is unavailable")
        with tempfile.TemporaryDirectory() as home:
            Path(home, ".zshrc").symlink_to(ROOT / "zsh/.zshrc")
            plugins = Path(home, ".zsh/plugins")
            plugins.mkdir(parents=True)
            plugins.joinpath("fzf-tab").symlink_to(ROOT / "zsh/.zsh/plugins/fzf-tab")
            env = os.environ.copy()
            env.update(HOME=home, ZDOTDIR=home)
            result = subprocess.run(
                ["zsh", "-i", "-c", "exit"],
                stdin=subprocess.DEVNULL,
                text=True,
                capture_output=True,
                env=env,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn("can't change option", result.stderr)

    def test_fastfetch_asset_extension_matches_content(self):
        image = ROOT / "fastfetch/.config/fastfetch/blue.png"
        self.assertTrue(image.is_file())
        self.assertTrue(image.read_bytes().startswith(b"\x89PNG\r\n\x1a\n"))
        self.assertFalse((ROOT / "fastfetch/.config/fastfetch/blue.jpg").exists())
        config = (ROOT / "fastfetch/.config/fastfetch/config.jsonc").read_text()
        self.assertIn("blue.png", config)
        self.assertNotIn("blue.jpg", config)

    def test_json_files_parse(self):
        for relative in ["swaync/.config/swaync/config.json", "opencode/.config/opencode/opencode.json", "opencode/.config/opencode/tui.json"]:
            json.loads((ROOT / relative).read_text())

    def test_jsonc_files_parse(self):
        for path in ROOT.rglob("*.jsonc"):
            text = re.sub(r"//.*?$", "", path.read_text(), flags=re.MULTILINE)
            text = re.sub(r",\s*([}\]])", r"\1", text)
            json.loads(text)

    def test_no_generated_zsh_artifacts_inside_stow_package(self):
        self.assertFalse((ROOT / "zsh/.zcompdump").exists())
        self.assertFalse((ROOT / "zsh/.zshrc.zwc").exists())

    def test_no_broken_symlinks(self):
        broken = [str(path.relative_to(ROOT)) for path in ROOT.rglob("*") if path.is_symlink() and not path.exists()]
        self.assertEqual(broken, [], f"broken symlinks: {broken}")

    def test_only_scripts_are_executable(self):
        for path in tracked_files():
            if not path.is_file() or not (path.stat().st_mode & stat.S_IXUSR):
                continue
            with path.open("rb") as stream:
                first = stream.readline()
            self.assertTrue(first.startswith(b"#!"), f"executable without shebang: {path}")

    def test_required_nvim_plugins_and_tools(self):
        telescope = (ROOT / "nvim/.config/nvim/lua/plugins/telescope.lua").read_text()
        neotree = (ROOT / "nvim/.config/nvim/lua/plugins/neo-tree.lua").read_text()
        all_lua = "\n".join(p.read_text() for p in (ROOT / "nvim/.config/nvim").rglob("*.lua"))
        self.assertIn("nvim-lua/plenary.nvim", telescope)
        self.assertIn("nvim-tree/nvim-web-devicons", telescope)
        self.assertIn("nvim-lua/plenary.nvim", neotree)
        self.assertIn("nvim-tree/nvim-web-devicons", neotree)
        self.assertIn("ruff", all_lua)
        self.assertNotIn("pylint", all_lua.lower())
        self.assertNotIn("mason-lspconfig", all_lua)

        mason = (ROOT / "nvim/.config/nvim/lua/plugins/mason.lua").read_text()
        self.assertIn("MasonToolsInstall", mason)
        self.assertIn("run_on_start = false", mason)

        init = (ROOT / "nvim/.config/nvim/init.lua").read_text()
        self.assertRegex(init, r"checker\s*=\s*\{\s*enabled\s*=\s*false")


if __name__ == "__main__":
    unittest.main(verbosity=2)
