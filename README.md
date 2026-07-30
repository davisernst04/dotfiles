# dotfiles

My personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Setup

### Prerequisites

Make sure GNU Stow is installed:

```bash
# Arch
sudo pacman -S stow

# Debian/Ubuntu
sudo apt install stow
```

### Installation

Clone the repo into your home directory:

```bash
git clone https://github.com/davisernst04/dotfiles.git ~/dotfiles
cd ~/dotfiles
git submodule update --init --recursive
```

If the machine already has files that stow would replace (e.g. a default `~/.zshrc` or `~/.gitconfig`), back them up and remove them first, otherwise stow will refuse to link:

```bash
mv ~/.zshrc ~/.zshrc.bak 2>/dev/null
mv ~/.gitconfig ~/.gitconfig.bak 2>/dev/null
```

Then stow whichever configs you want

Or stow everything at once:

```bash
stow */
```

Stow will create symlinks from each package directory into your home directory, placing configs in the correct locations under `~/.config/`.

### Dependencies

Core packages (Arch):

```bash
sudo pacman -S --needed zsh zsh-autosuggestions zsh-syntax-highlighting \
  fzf fd eza bat zoxide starship tmux neovim git github-cli pyenv \
  hyprland kitty rofi-wayland waybar hyprpaper hypridle hyprlock swaync \
  fastfetch btop xdg-user-dirs

# AUR
yay -S hyprshot
```

Post-install notes:

- Create the screenshot directory: `mkdir -p ~/Pictures`
- tmux plugins are managed by tpm (submodule). Open tmux and press `C-z I` (prefix + I) to install them.
- Neovim plugins are installed automatically by lazy.nvim on first launch.
- Put machine-specific shell settings in `~/.zshrc.local` — sourced at the end of `.zshrc`, not tracked by the repo.

## Uninstalling

To remove symlinks for a specific package:

```bash
stow -D nvim
```
