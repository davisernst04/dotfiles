#!/usr/bin/env python3
"""Check notification routing without changing the desktop or real tmux sessions."""

from pathlib import Path
import runpy
import unittest
from unittest.mock import Mock, call, patch

SCRIPT = Path(__file__).resolve().parents[1] / "hypr/.config/hypr/scripts/notification-focus"


class NotificationRoutingTests(unittest.TestCase):
    def setUp(self):
        self.functions = runpy.run_path(str(SCRIPT))
        self.globals = self.functions["capture"].__globals__

    def test_direct_sender_keeps_exact_pane_even_without_a_desktop_window(self):
        with patch.dict(self.globals, environment=lambda pid: {
            "TMUX": "/tmp/custom-server,300,0", "TMUX_PANE": "%17",
        }, ancestors=lambda pid: [pid, 300], windows=lambda: []):
            origin = self.functions["capture"](400)
        self.assertEqual(origin, {"socket": "/tmp/custom-server", "pane": "%17"})

    def test_click_follows_a_pane_moved_to_another_session(self):
        calls = []

        def tmux(socket, *args):
            calls.append((socket, *args))
            if args[0] == "display-message":
                return "$9\t@8"
            return ""

        focus = Mock()
        with patch.dict(self.globals, tmux=tmux, command=focus,
                        tmux_clients=lambda socket: [["500", "/dev/pts/7", "$2", "%1", "10"]],
                        ancestors=lambda pid: [pid, 100],
                        windows=lambda: [{"pid": 100, "address": "0xabc"}]):
            self.functions["activate"]({"socket": "/tmp/custom-server", "pane": "%17"})
        self.assertIn(("/tmp/custom-server", "switch-client", "-c", "/dev/pts/7", "-t", "$9"), calls)
        self.assertIn(("/tmp/custom-server", "select-window", "-t", "@8"), calls)
        self.assertIn(("/tmp/custom-server", "select-pane", "-t", "%17"), calls)
        self.assertEqual(focus.call_args_list, [
            call("swaync-client", "--close-panel"),
            call("hyprctl", "dispatch", 'hl.dsp.focus({window = "address:0xabc"})'),
        ])

    def test_closed_source_does_not_focus_an_unrelated_window(self):
        focus = Mock()
        with patch.dict(self.globals, command=focus,
                        windows=lambda: [{"pid": 100, "address": "0xnew"}]):
            self.functions["activate"]({"pid": 100, "address": "0xold"})
        focus.assert_not_called()

    def test_terminal_notification_prefers_unique_application_pane(self):
        with patch.dict(self.globals, environment=lambda pid: {},
                        ancestors=lambda pid: [pid, 100] if pid != 100 else [100],
                        windows=lambda: [{"pid": 100, "address": "0xabc"}],
                        tmux_clients=lambda socket: [["500", "/dev/pts/7", "$2", "%1", "10"]],
                        tmux=lambda *args: "%1\tnvim\n%17\tcodex"):
            origin = self.functions["capture"](100, "Codex")
        self.assertEqual(origin["pane"], "%17")


if __name__ == "__main__":
    unittest.main()
