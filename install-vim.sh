#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
preserve=1
for arg in "$@"; do
  case "$arg" in
    --no-preserve-current) preserve=0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
[[ $EUID != 0 ]] || { echo 'Run as your own account, not root.' >&2; exit 1; }
rc="$HOME/.vimrc"
local_rc="$HOME/.vimrc.local"
[[ ! -d $rc && ! -d $local_rc ]] || {
  echo 'Refusing to replace a directory at .vimrc or .vimrc.local.' >&2; exit 1;
}
if [[ -L $local_rc && ! -e $local_rc ]]; then
  echo 'Refusing to write through a broken .vimrc.local symlink.' >&2; exit 1
fi
mkdir -p "$HOME/.vim/swap" "$HOME/.vim/undo"
chmod 700 "$HOME/.vim/swap" "$HOME/.vim/undo"
if [[ -L $rc && $(readlink "$rc") == "$repo_dir/vimrc" ]]; then
  echo 'Vim already linked.'
  exit 0
fi
backup_dir=$(mktemp -d "$HOME/.my-vim-backup.XXXXXXXX")
chmod 700 "$backup_dir"
if [[ -e $rc || -L $rc ]]; then
  cp -P "$rc" "$backup_dir/.vimrc"
  if (( preserve )) && [[ -f $rc ]]; then
    cp -L "$rc" "$backup_dir/previous.vim"
    if [[ -e $local_rc || -L $local_rc ]]; then cp -P "$local_rc" "$backup_dir/.vimrc.local"; fi
    previous="$backup_dir/previous.vim"
    previous=${previous//\'/\'\'}
    printf "\nexecute 'source' fnameescape('%s')\n" "$previous" >> "$local_rc"
  fi
fi
ln -s "$repo_dir/vimrc" "$backup_dir/new.vimrc"
mv -f "$backup_dir/new.vimrc" "$rc"
echo "Installed: $rc -> $repo_dir/vimrc"
echo "Vim backup: $backup_dir"
if ! command -v vim >/dev/null; then
  echo 'Vim configuration installed; install Vim with your OS package manager to use it.'
fi
