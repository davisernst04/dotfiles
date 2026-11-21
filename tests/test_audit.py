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

    def test_agent_aliases_preserve_compiler_and_scope_telemetry(self):
        zsh = (ROOT / "zsh/.zshrc").read_text()
        self.assertNotRegex(zsh, r"(?m)^alias cc=")
        for name in ["codex", "opencode"]:
            self.assertRegex(zsh, rf'alias {name}="[^"\n]*command {name}(?: |")')
        self.assertIn('alias codex-yolo=', zsh)
        self.assertIn('alias opencode-auto=', zsh)
        self.assertNotIn("export OTEL_", zsh)

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
        self.assertIn("~/.config/hypr/wallpaper.png", paper)
        self.assertNotIn("~/.config/hypr/paper.png", paper)

        expected = {
            ROOT / "hypr/.config/hypr/wallpaper.png": "ca4766d51b5f5edf1a490cea4c20a05ccd419be49a9479604de9741aea423363",
            ROOT / "hypr/.config/hypr/paper.png": "99e0638da7d6881eaa45f724de83408b1d1380b4596fc50a049daaacccce2baa",
        }
        for path, digest in expected.items():
            self.assertTrue(path.is_file(), f"missing preserved wallpaper {path}")
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), digest)

        waybar = (ROOT / "waybar/.config/waybar/waybar.sh").read_text()
        self.assertIn("pkill -x waybar", waybar)
        self.assertNotIn("pkill -USR", waybar)

        bootstrap = (ROOT / "dotfiles").read_text()
        self.assertIn("prepare_hypr_host", bootstrap)
        for extension in ["conf", "lua"]:
            self.assertTrue((ROOT / f"hypr/.config/hypr/host.{extension}.example").is_file())

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
        self.assertIn("tree-sitter-cli", development)
        self.assertTrue({"blueman", "firefox", "hyprshot", "procps-ng", "rofi", "ttf-jetbrains-mono-nerd", "wireless-regdb", "wl-clipboard"} <= desktop)
        self.assertTrue({"btop", "cava", "fastfetch"} <= optional)
        self.assertNotIn("gnome-network-displays", aur_desktop)
        self.assertNotIn("gnome-network-displays", desktop)
        self.assertFalse({"rofi-wayland"} & desktop)
        self.assertNotIn("hyprshot", aur_desktop)

    def test_profile_aware_bootstrap_dry_runs(self):
        for profile, expected, excluded in [
            ("development", ["corepack", "mise", "stow --dir="], ["hyprland"]),
            ("desktop-hypr", ["hyprland", "hyprshot", "stow --dir="], ["gnome-network-displays"]),
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
            official_only = subprocess.run(
                [str(ROOT / "dotfiles"), "--dry-run", "install-packages", "desktop-hypr"],
                cwd=ROOT,
                text=True,
                capture_output=True,
                env=env,
            )
        self.assertEqual(official_only.returncode, 0, official_only.stderr)
        self.assertNotIn("paru-or-yay", official_only.stdout)

    def test_doctor_covers_core_and_desktop_commands(self):
        result = subprocess.run(
            [str(ROOT / "dotfiles"), "doctor", "all"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        output = result.stdout + result.stderr
        for command in ["git-lfs", "node", "npm", "corepack", "rg", "uv", "wl-copy", "firefox", "hyprshot", "swaync-client", "loginctl", "systemctl", "pgrep", "pkill", "claude", "opencode"]:
            self.assertRegex(output, rf"(?:ok|missing): {re.escape(command)}(?:\s|$)")
        self.assertRegex(output, r"(?:ok: (?:mise|pyenv) |missing: mise or pyenv runtime manager)")
        if Path("/usr/lib/hyprpolkitagent/hyprpolkitagent").is_file():
            self.assertIn("ok: hyprpolkitagent", output)

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

    def run_doctor_function(self, function, args, env):
        # Source the production functions without invoking the CLI dispatcher.
        definitions = (ROOT / "dotfiles").read_text().split('\n[ "${1:-}" = --dry-run ]', 1)[0]
        return subprocess.run(
            ["/bin/sh", "-c", definitions + '\n' + function + ' "$@"',
             str(ROOT / "dotfiles"), *map(str, args)],
            cwd=ROOT, env=env, capture_output=True, text=True, timeout=10,
        )

    def hypr_stow_fixture(self, root):
        repo = root / "repo"
        target = root / "home"
        target.mkdir()
        for package in ["git", "makepkg", "zsh", "tmux", "nvim", "starship", "ssh", "hypr", "rofi", "waybar", "swaync", "kitty"]:
            (repo / package).mkdir(parents=True)
        shutil.copy2(ROOT / "dotfiles", repo / "dotfiles")
        config = repo / "hypr/.config/hypr"
        config.mkdir(parents=True)
        (config / "hyprland.lua").write_text('require("host")\n')
        for extension in ["conf", "lua"]:
            shutil.copy2(ROOT / f"hypr/.config/hypr/host.{extension}.example", config)
        return repo, target, config

    @unittest.skipUnless(shutil.which("stow"), "Stow is unavailable")
    def test_desktop_stow_creates_only_missing_host_stubs(self):
        for existing in [[], ["conf"], ["lua"], ["conf", "lua"]]:
            with self.subTest(existing=existing), tempfile.TemporaryDirectory() as directory:
                repo, target, config = self.hypr_stow_fixture(Path(directory))
                for extension in existing:
                    (config / f"host.{extension}").write_text(f"preserved {extension}\n")
                result = subprocess.run(
                    [str(repo / "dotfiles"), "stow", "desktop-hypr"],
                    env=dict(os.environ, DOTFILES_TARGET=str(target)),
                    capture_output=True, text=True, timeout=10,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                for extension in ["conf", "lua"]:
                    expected = (f"preserved {extension}\n" if extension in existing else
                                (config / f"host.{extension}.example").read_text())
                    self.assertEqual((config / f"host.{extension}").read_text(), expected)
                    self.assertEqual((target / f".config/hypr/host.{extension}").read_text(), expected)

    @unittest.skipUnless(shutil.which("stow"), "Stow is unavailable")
    def test_desktop_stow_dry_run_reports_missing_hosts_without_creating_them(self):
        with tempfile.TemporaryDirectory() as directory:
            repo, target, config = self.hypr_stow_fixture(Path(directory))
            for existing in [[], ["conf"]]:
                with self.subTest(existing=existing):
                    for extension in existing:
                        (config / f"host.{extension}").write_text("preserve me\n")
                    result = subprocess.run(
                        [str(repo / "dotfiles"), "--dry-run", "stow", "desktop-hypr"],
                        env=dict(os.environ, DOTFILES_TARGET=str(target)),
                        capture_output=True, text=True, timeout=10,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    for extension in ["conf", "lua"]:
                        message = f"would create ignored Hypr host stub: {config}/host.{extension}"
                        if extension in existing:
                            self.assertNotIn(message, result.stdout)
                            self.assertEqual((config / f"host.{extension}").read_text(), "preserve me\n")
                        else:
                            self.assertIn(message, result.stdout)
                            self.assertFalse((config / f"host.{extension}").exists())
                    self.assertEqual(list(target.iterdir()), [])

    @unittest.skipUnless(shutil.which("stow"), "Stow is unavailable")
    def test_private_directories_are_never_folded_into_the_repository(self):
        # A folded ~/.ssh, ~/.claude, or ~/.codex would make SSH, Claude Code,
        # and Codex write keys, credentials, and transcripts into this public
        # repository. Each must be a real private directory with file links.
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory)
            for profile in ["core", "ai-optional"]:
                result = subprocess.run(
                    [str(ROOT / "dotfiles"), "stow", profile],
                    env=dict(os.environ, DOTFILES_TARGET=str(target)),
                    capture_output=True, text=True, timeout=30,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
            for name in [".ssh", ".claude", ".codex"]:
                path = target / name
                self.assertTrue(path.is_dir() and not path.is_symlink(), name)
                self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o700, name)
            shared = ROOT / "agents/.claude/CLAUDE.md"
            self.assertEqual((target / ".ssh/config").resolve(), ROOT / "ssh/.ssh/config")
            self.assertEqual((target / ".claude/CLAUDE.md").resolve(), shared)
            self.assertEqual((target / ".codex/AGENTS.md").resolve(), shared)

    def test_private_package_ignores_admit_only_intended_files(self):
        for allowed, blocked in [
            ("ssh/.ssh/config", "ssh/.ssh/id_ed25519"),
            ("agents/.claude/CLAUDE.md", "agents/.claude/.credentials.json"),
            ("agents/.codex/AGENTS.md", "agents/.codex/auth.json"),
            ("git/.config/git/ignore", "git/.config/git/credentials"),
        ]:
            ignored = lambda path: subprocess.run(
                ["git", "check-ignore", "-q", "--no-index", path], cwd=ROOT).returncode == 0
            self.assertFalse(ignored(allowed), allowed)
            self.assertTrue(ignored(blocked), blocked)

    def test_doctor_checks_the_active_hypr_host_format(self):
        for config_extension, hosts, expected_status, expected_message in [
            ("lua", ["conf"], 1, "missing: Hypr host.lua"),
            ("lua", ["conf", "lua"], 0, "ok: Hypr host configuration present (host.lua)"),
            ("conf", ["conf"], 0, "ok: Hypr host configuration present (host.conf)"),
            (None, [], 0, "optional: Hypr host.lua will be created"),
        ]:
            with self.subTest(config=config_extension, hosts=hosts), tempfile.TemporaryDirectory() as directory:
                config = Path(directory) / ".config/hypr"
                config.mkdir(parents=True)
                if config_extension:
                    (config / f"hyprland.{config_extension}").touch()
                for extension in hosts:
                    (config / f"host.{extension}").touch()
                result = self.run_doctor_function(
                    "hypr_host_status", [], dict(os.environ, DOTFILES_TARGET=directory),
                )
                self.assertEqual(result.returncode, expected_status, result.stderr)
                self.assertIn(expected_message, result.stdout)

    def test_doctor_runtime_manager_preference_and_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            bindir = Path(directory)
            (bindir / "dirname").symlink_to(shutil.which("dirname"))
            env = dict(os.environ, PATH=directory)
            for managers, expected in [
                ([], "missing: mise or pyenv runtime manager"),
                (["pyenv"], "ok: pyenv "),
                (["mise", "pyenv"], "ok: mise "),
            ]:
                with self.subTest(managers=managers):
                    for manager in managers:
                        (bindir / manager).write_text("#!/bin/sh\nexit 0\n")
                        (bindir / manager).chmod(0o755)
                    result = self.run_doctor_function("runtime_manager_status", [], env)
                    self.assertEqual(result.returncode, 0 if managers else 1, result.stderr)
                    self.assertIn(expected, result.stdout)
                    if "mise" in managers:
                        self.assertNotIn("ok: pyenv ", result.stdout)

    def test_doctor_kernel_warning_is_native_arch_only(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            release = root / "os-release"
            modules = root / "modules"
            bindir = root / "bin"
            bindir.mkdir()
            (bindir / "dirname").symlink_to(shutil.which("dirname"))
            (bindir / "uname").write_text("#!/bin/sh\nprintf '%s\\n' 'audit-test-kernel'\n")
            (bindir / "uname").chmod(0o755)
            env = dict(os.environ, PATH=str(bindir))
            env.pop("DOTFILES_TARGET", None)
            release.write_text('ID=arch\n')
            missing = self.run_doctor_function("check_running_kernel", [release, modules], env)
            self.assertEqual(missing.returncode, 1, missing.stderr)
            self.assertIn("warning: running kernel audit-test-kernel has no installed modules", missing.stdout)
            self.assertIn("save work and restart", missing.stdout)

            for distro, simulated, present in [
                ("arch", False, True),
                ("debian", False, False),
                ("arch", True, False),
            ]:
                with self.subTest(distro=distro, simulated=simulated, present=present):
                    release.write_text(f'ID={distro}\n')
                    module_dir = modules / "audit-test-kernel"
                    if present:
                        module_dir.mkdir(parents=True)
                    elif module_dir.exists():
                        module_dir.rmdir()
                    case_env = dict(env)
                    if simulated:
                        case_env["DOTFILES_TARGET"] = str(root / "stow-target")
                    result = self.run_doctor_function("check_running_kernel", [release, modules], case_env)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout, "")

    def test_ci_installs_and_exercises_validation_tools(self):
        workflow = (ROOT / ".github/workflows/check.yml").read_text()
        for token in ["stow", "zsh", "tmux", "lua", "./tests/run.sh", "gitleaks/gitleaks-action", "fetch-depth: 0"]:
            self.assertIn(token, workflow)
        runner = (ROOT / "tests/run.sh").read_text()
        self.assertIn("tmux", runner)

    def test_tmux_session_shortcut_requires_confirmation(self):
        config = (ROOT / "tmux/.tmux.conf").read_text()
        self.assertIn('bind X confirm-before -p "Kill session #S? (y/n)"', config)

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
