#!/usr/bin/env python3
"""Exercise lock concurrency with a fake locker; never lock the real desktop."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "hypr/.config/hypr/scripts/lock-session"


@unittest.skipUnless(shutil.which("flock"), "flock is unavailable")
class DesktopLockTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.runtime = Path(self.directory.name)
        self.bindir = self.runtime / "bin"
        self.bindir.mkdir()
        locker = self.bindir / "hyprlock"
        locker.write_text(f"#!{sys.executable}\n" + '''
import json, os, sys, time
from pathlib import Path
runtime = Path(os.environ["XDG_RUNTIME_DIR"])
signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "default")
with (runtime / "calls.jsonl").open("a") as handle:
    handle.write(json.dumps([signature, sys.argv[1:]]) + "\\n")
if os.environ.get("TEST_EXIT_CODE"):
    sys.exit(int(os.environ["TEST_EXIT_CODE"]))
while not (runtime / "release").exists():
    time.sleep(0.01)
''')
        locker.chmod(0o755)
        self.env = dict(os.environ, XDG_RUNTIME_DIR=str(self.runtime),
                        HYPRLAND_INSTANCE_SIGNATURE="test-session",
                        PATH=str(self.bindir) + os.pathsep + os.environ["PATH"])
        self.processes = []

    def tearDown(self):
        self.runtime.joinpath("release").touch()
        for process in self.processes:
            try:
                process.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.communicate()
        self.directory.cleanup()

    def launch(self, **environment):
        process = subprocess.Popen([str(LOCK)], env=dict(self.env, **environment),
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.processes.append(process)
        return process

    def calls(self):
        path = self.runtime / "calls.jsonl"
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def wait_for(self, condition):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if condition():
                return
            time.sleep(0.01)
        self.fail("Timed out waiting for the fake locker")

    def finish(self, process, code=0):
        stdout, stderr = process.communicate(timeout=5)
        self.assertEqual(process.returncode, code, stderr.decode())
        self.assertEqual(stdout, b"")

    def test_simultaneous_requests_start_one_locker_then_allow_relocking(self):
        processes = [self.launch() for _ in range(24)]
        self.wait_for(lambda: len(self.calls()) == 1)
        self.wait_for(lambda: sum(p.poll() is None for p in processes) == 1)
        self.assertEqual(self.calls(), [["test-session", ["--grace", "0"]]])
        self.runtime.joinpath("release").touch()
        for process in processes:
            self.finish(process)
        self.finish(self.launch(TEST_EXIT_CODE="0"))
        self.assertEqual(len(self.calls()), 2)

    def test_independent_compositors_do_not_block_each_other(self):
        first = self.launch()
        second = self.launch(HYPRLAND_INSTANCE_SIGNATURE="another-session")
        self.wait_for(lambda: len(self.calls()) == 2)
        self.assertEqual({call[0] for call in self.calls()}, {"test-session", "another-session"})
        self.runtime.joinpath("release").touch()
        self.finish(first)
        self.finish(second)

    def test_locker_failure_propagates_and_releases_guard(self):
        self.finish(self.launch(TEST_EXIT_CODE="7"), code=7)
        self.finish(self.launch(TEST_EXIT_CODE="0"))
        self.assertEqual(len(self.calls()), 2)

    def test_missing_runtime_fails_without_starting_locker(self):
        process = self.launch(XDG_RUNTIME_DIR="")
        stdout, stderr = process.communicate(timeout=5)
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(stdout, b"")
        self.assertIn(b"runtime directory is unset", stderr)
        self.assertEqual(self.calls(), [])

    def test_all_configured_lock_launchers_share_guard(self):
        helper = "~/.config/hypr/scripts/lock-session"
        hypr = (ROOT / "hypr/.config/hypr/hyprland.lua").read_text()
        idle = (ROOT / "hypr/.config/hypr/hypridle.conf").read_text()
        notification = json.loads((ROOT / "swaync/.config/swaync/config.json").read_text())
        self.assertIn('hl.dsp.exec_cmd("' + helper + '")', hypr)
        self.assertIn("lock_cmd = " + helper, idle)
        self.assertIn("inhibit_sleep = 3", idle)
        actions = notification["widget-config"]["buttons-grid"]["actions"]
        self.assertTrue(any(action["command"] == "$HOME/.config/hypr/scripts/lock-session" for action in actions))


class DesktopStartupTests(unittest.TestCase):
    def test_optional_dictation_starts_only_if_enabled(self):
        hypr = (ROOT / "hypr/.config/hypr/hyprland.lua").read_text()
        self.assertIn('hl.exec_cmd("~/.config/hypr/scripts/start-session-services")', hypr)
        startup = ROOT / "hypr/.config/hypr/scripts/start-session-services"
        with tempfile.TemporaryDirectory() as directory:
            bindir = Path(directory)
            command = bindir / "systemctl"
            command.write_text(f"#!{sys.executable}\n" + '''
import os, sys
from pathlib import Path
with Path(os.environ["TEST_LOG"]).open("a") as handle:
    handle.write(" ".join(sys.argv[1:]) + "\\n")
if "is-enabled" in sys.argv:
    sys.exit(int(os.environ["TEST_ENABLED_RESULT"]))
''')
            command.chmod(0o755)
            log = bindir / "calls"
            for result_code in (0, 1, 4):
                log.unlink(missing_ok=True)
                env = dict(os.environ, PATH=str(bindir) + os.pathsep + os.environ["PATH"],
                           TEST_LOG=str(log), TEST_ENABLED_RESULT=str(result_code))
                result = subprocess.run([str(startup)], env=env,
                                        capture_output=True, text=True, timeout=5)
                calls = log.read_text().splitlines()
                self.assertEqual(calls[:3], [
                    "--user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE DISPLAY",
                    "--user restart hypridle.service",
                    "--user is-enabled --quiet voxtype.service",
                ])
                self.assertEqual(result.returncode, 0, result.stderr)
                if result_code == 0:
                    self.assertEqual(calls[3:], ["--user restart voxtype.service"])
                else:
                    self.assertEqual(calls[3:], [])


class IdlePowerTests(unittest.TestCase):
    """Idle suspend applies on battery only; never suspends the real machine."""

    def test_suspend_waits_for_battery_power(self):
        idle = (ROOT / "hypr/.config/hypr/hypridle.conf").read_text()
        self.assertIn("on-timeout = ~/.config/hypr/scripts/on-ac-power || systemctl suspend", idle)

    def test_ac_detection_uses_online_mains_adapters_only(self):
        script = ROOT / "hypr/.config/hypr/scripts/on-ac-power"
        for supplies, expected in [
            ({"AC": ("Mains", "1"), "BAT1": ("Battery", "")}, 0),
            ({"AC": ("Mains", "0"), "BAT1": ("Battery", "")}, 1),
            ({"BAT0": ("Battery", "")}, 1),
            ({"AC": ("Mains", "0"), "ucsi-source-psy": ("USB", "1")}, 1),
            ({}, 1),
        ]:
            with self.subTest(supplies=supplies), tempfile.TemporaryDirectory() as root:
                for name, (kind, online) in supplies.items():
                    supply = Path(root, name)
                    supply.mkdir()
                    (supply / "type").write_text(kind + "\n")
                    if online:
                        (supply / "online").write_text(online + "\n")
                result = subprocess.run([str(script)], env=dict(os.environ, POWER_SUPPLY_ROOT=root),
                                        capture_output=True, timeout=5)
                self.assertEqual(result.returncode, expected)


@unittest.skipUnless(shutil.which("flock"), "flock is unavailable")
class ClipboardHistoryTests(unittest.TestCase):
    """Run the clipboard helper against stub tools; never touch the real clipboard."""

    SCRIPT = ROOT / "hypr/.config/hypr/scripts/clipboard-history"

    def run_helper(self, *args, cliphist=True, wait=""):
        self.bindir = Path(self.directory.name, "bin")
        self.bindir.mkdir(exist_ok=True)
        Path(self.bindir, "flock").unlink(missing_ok=True)
        Path(self.bindir, "flock").symlink_to(shutil.which("flock"))
        tools = {"wl-paste": f"{shutil.which('sleep')} {wait or 0}", "notify-send": ""}
        if cliphist:
            tools["cliphist"] = ""
        for name in ["wl-paste", "notify-send", "cliphist"]:
            Path(self.bindir, name).unlink(missing_ok=True)
        for name, body in tools.items():
            stub = self.bindir / name
            stub.write_text(f'#!/bin/sh\nprintf "%s %s\\n" "{name}" "$*" >>"$TEST_LOG"\n{body}\n')
            stub.chmod(0o755)
        env = dict(PATH=str(self.bindir), TEST_LOG=str(self.log),
                   XDG_RUNTIME_DIR=self.directory.name, HYPRLAND_INSTANCE_SIGNATURE="test")
        return subprocess.Popen([str(self.SCRIPT), *args], env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.log = Path(self.directory.name, "calls")

    def tearDown(self):
        self.directory.cleanup()

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_without_cliphist_watcher_is_silent_and_picker_explains(self):
        watcher = self.run_helper("--watch", cliphist=False)
        self.assertEqual(watcher.wait(5), 0)
        self.assertEqual(self.calls(), [])
        picker = self.run_helper(cliphist=False)
        self.assertEqual(picker.wait(5), 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertTrue(self.calls()[0].startswith("notify-send Clipboard history"))

    def test_one_text_recorder_per_compositor(self):
        first = self.run_helper("--watch", wait="2")
        deadline = time.monotonic() + 5
        while not self.calls() and time.monotonic() < deadline:
            time.sleep(0.05)
        second = self.run_helper("--watch")
        self.assertEqual(second.wait(5), 0)
        self.assertEqual(first.wait(5), 0)
        self.assertEqual(self.calls(), ["wl-paste --type text --watch cliphist store"])


if __name__ == "__main__":
    unittest.main()
