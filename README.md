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
```

Then stow whichever configs you want

Or stow everything at once:

```bash
stow */
```

Stow will create symlinks from each package directory into your home directory, placing configs in the correct locations under `~/.config/`.

## Uninstalling

To remove symlinks for a specific package:

```bash
stow -D nvim
```
