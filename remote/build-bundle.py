#!/usr/bin/env python3
"""Snapshot only allowlisted shell/editor configs and locally installed plugins."""
from pathlib import Path
import json
import shutil
import subprocess
import sys
import tarfile
import tempfile

source = Path(__file__).resolve().parent
repo = source.parent
home = Path.home()
output = Path(sys.argv[1]).expanduser().resolve() if len(sys.argv) > 1 else home / "remote-dev-env.tar.gz"
with tempfile.TemporaryDirectory(prefix="remote-dev-bundle-") as temporary:
    root = Path(temporary) / "remote-dev-env"
    payload = root / "payload"
    payload.mkdir(parents=True)
    paths = []

    def copy(original, relative):
        original = Path(original).resolve(strict=True)
        target = payload / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if original.is_dir():
            shutil.copytree(original, target, ignore=shutil.ignore_patterns(
                ".git", "*.zwc", "*.swp", "__pycache__", "*.pyc", "node_modules"))
        else:
            shutil.copy2(original, target)
        return target

    configs = {
        ".zshrc": repo / "zsh/.zshrc",
        ".tmux.conf": repo / "tmux/.tmux.conf",
        ".config/nvim": repo / "nvim/.config/nvim",
        ".config/starship.toml": repo / "starship/.config/starship.toml",
        ".config/btop": repo / "btop/.config/btop",
        ".config/yazi": repo / "yazi/.config/yazi",
        ".gitconfig": repo / "git/.gitconfig",
        ".local/bin/dev-shell": source / "dev-shell",
    }
    for relative, original in configs.items():
        copy(original, relative)
        paths.append(relative)
    # Strip AI integrations from the snapshot without changing the workstation.
    nvim = payload / ".config/nvim"
    (nvim / "lua/plugins/copilot.lua").unlink(missing_ok=True)
    lockfile = nvim / "lazy-lock.json"
    lock = json.loads(lockfile.read_text())
    lock.pop("copilot.lua", None)
    lockfile.write_text(json.dumps(lock, indent=2) + "\n")
    completion = nvim / "lua/plugins/nvim-cmp.lua"
    text = completion.read_text()
    text = text.replace(
        'if require("copilot.suggestion").is_visible() then\n'
        '\t\t\t\t\t\t\trequire("copilot.suggestion").accept()\n'
        '\t\t\t\t\t\telseif luasnip.expand_or_jumpable() then',
        'if luasnip.expand_or_jumpable() then',
    )
    if "copilot" in text.lower():
        raise SystemExit("Copilot completion mapping changed; update the portable filter before building.")
    completion.write_text(text)
    copy(repo / "zsh/.zsh/plugins/fzf-tab", ".zsh/plugins/fzf-tab")
    for plugin in ("zsh-autosuggestions", "zsh-syntax-highlighting"):
        candidates = [home / ".zsh" / plugin, Path("/usr/share/zsh/plugins") / plugin,
                      Path("/usr/share") / plugin]
        original = next((p for p in candidates if p.is_dir()), None)
        if original is None:
            raise SystemExit(f"Missing local plugin: {plugin}")
        copy(original, f".zsh/{plugin}")
    paths.append(".zsh")
    for plugin in ("tpm", "vim-tmux-navigator", "tmux-yank", "extrakto"):
        copy(home / ".tmux/plugins" / plugin, f".tmux/plugins/{plugin}")
    paths.append(".tmux/plugins")
    copy(repo / "tmux/.tmux/scripts", ".tmux/scripts")
    paths.append(".tmux/scripts")
    # Adapt the snapshot only. The workstation config remains untouched.
    zshrc = payload / ".zshrc"
    text = zshrc.read_text()
    text = "".join(line for line in text.splitlines(keepends=True)
                   if not line.startswith(("alias codex=", "alias codex-yolo=",
                                           "alias opencode=", "alias opencode-auto="))
                   and "$HOME/.opencode/bin" not in line)
    text = text.replace(" --exclude .hermes", "").replace(" --exclude .codex", "")
    text = text.replace("export LANG=en_US.UTF-8\nexport LC_CTYPE=en_US.UTF-8", """# C.UTF-8 avoids requiring the en_US locale to be installed system-wide.
export LANG=C.UTF-8
export LC_CTYPE=C.UTF-8
typeset -U path PATH
path=("$HOME/.local/share/dev-env-neovim/bin" "$HOME/.local/share/dev-env/bin" $path)
fpath=("$HOME/.local/share/dev-env/share/zsh/site-functions" $fpath)""")
    # Use the portable fzf before distribution integrations; load before fzf-tab.
    text = text.replace("for _fzf_dir in /usr/share/fzf", 'for _fzf_dir in "$HOME/.local/share/dev-env/share/fzf" /usr/share/fzf')
    zshrc.write_text(text)
    (payload / ".fzf.zsh").write_text('eval "$(fzf --zsh)"\n')
    paths.append(".fzf.zsh")
    tmux = payload / ".tmux.conf"
    text = tmux.read_text()
    text = text.replace("run '~/.tmux/plugins/tpm/tpm'", """# Use the user-installed Zsh even when the account login shell is Bash.
set -g default-shell "$HOME/.local/share/dev-env/bin/zsh"
run '~/.tmux/plugins/tpm/tpm'""")
    tmux.write_text(text)
    for filename in ("install.sh", "repair-login.sh", "environment.txt", "README.md"):
        shutil.copy2(source / filename, root / filename)
    (root / "config-paths.txt").write_text("\n".join(paths) + "\n")
    with (root / "terminals.ti").open("w") as definitions:
        for terminal in ("xterm-kitty", "tmux-256color", "xterm-256color"):
            result = subprocess.run(["infocmp", "-x", terminal], text=True, capture_output=True, check=True)
            definitions.write(result.stdout + "\n")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tarfile.open(output, "w:gz", dereference=True) as archive:
        archive.add(root, arcname="remote-dev-env")
print(output)
