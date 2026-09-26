#!/usr/bin/env zsh
# Offline installer. Back up existing files; never download or execute remote code.
set -euo pipefail

repo_dir=${0:A:h}
target_dir=${ZDOTDIR:-$HOME}
mode=${1:-}
[[ $# -le 1 && ( -z $mode || $mode == --preserve-current ) ]] || {
  print -u2 'Usage: zsh install.sh [--preserve-current]'
  exit 2
}
mkdir -p "$target_dir"
rc="$target_dir/.zshrc"
local_rc="$target_dir/.zshrc.local"
if [[ -L $rc && ${rc:A} == "$repo_dir/.zshrc" ]]; then
  print 'Already installed.'
  exit 0
fi
[[ ! -d $rc && ! -d $local_rc ]] || {
  print -u2 'Refusing to replace a directory at .zshrc or .zshrc.local.'
  exit 1
}
# Validate everything before changing the active configuration.
zsh -n "$repo_dir/.zshrc" "$repo_dir/shortcut.sh"
backup_dir=$(mktemp -d "$target_dir/.my-zsh-backup.XXXXXXXX")
chmod 700 "$backup_dir"
if [[ -e $rc || -L $rc ]]; then
  cp -P "$rc" "$backup_dir/.zshrc"
  # Save content separately: relative symlinks must resolve before moving them.
  if [[ $mode == --preserve-current && -f $rc ]]; then
    cp -L "$rc" "$backup_dir/previous.zsh"
    if [[ -e $local_rc || -L $local_rc ]]; then
      cp -P "$local_rc" "$backup_dir/.zshrc.local"
    fi
    print -r -- "source ${(q)backup_dir}/previous.zsh" >> "$local_rc"
  fi
fi
# Atomic replacement; if this fails the original .zshrc still exists.
ln -s "$repo_dir/.zshrc" "$backup_dir/new.zshrc"
mv -f "$backup_dir/new.zshrc" "$rc"
print "Installed: $rc -> $repo_dir/.zshrc"
print "Backup: $backup_dir"
print 'Open a new terminal or run: exec zsh'
