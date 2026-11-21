# Recover a deleted/replaced pane directory before starting external tools.
# Checking the inode also catches a directory replaced at the same pathname.
if [[ ! . -ef $PWD ]]; then
  builtin cd -- "$HOME" || return 1
fi
