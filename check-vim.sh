#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
test_home="$tmp/home with spaces and 'quote"
mkdir -p "$test_home"
printf 'let g:previous_vimrc = 1\n' > "$test_home/.vimrc"
printf 'let g:local_vimrc = 1\nset shiftwidth=3\n' > "$test_home/.vimrc.local"
env HOME="$test_home" bash "$repo/install-vim.sh"
[[ $(readlink "$test_home/.vimrc") == "$repo/vimrc" ]]
first=$(cksum "$test_home/.vimrc.local")
backups=("$test_home"/.my-vim-backup.*)
[[ ${#backups[@]} == 1 && -f ${backups[0]}/previous.vim ]]
cmp "${backups[0]}/.vimrc.local" <(printf 'let g:local_vimrc = 1\nset shiftwidth=3\n')
env HOME="$test_home" bash "$repo/install-vim.sh"
[[ $(cksum "$test_home/.vimrc.local") == "$first" ]]
backups=("$test_home"/.my-vim-backup.*)
[[ ${#backups[@]} == 1 ]]
cat > "$tmp/check.vim" <<'VIM'
call assert_equal(1, get(g:, 'previous_vimrc', 0))
call assert_equal(1, get(g:, 'local_vimrc', 0))
call assert_equal(3, &shiftwidth)
call assert_true(&number && &cursorline && &incsearch && &hlsearch && &smartcase)
call assert_equal('desert', g:colors_name)
call assert_equal(expand('~/.vim/swap//'), &directory)
call assert_true(&swapfile)
if has('persistent_undo')
  call assert_true(&undofile)
  call assert_equal(expand('~/.vim/undo//'), &undodir)
endif
if !empty(v:errors)
  call writefile(v:errors, $VIM_CHECK_ERRORS)
  cquit
endif
qa!
VIM
if ! env HOME="$test_home" VIM_CHECK_ERRORS="$tmp/errors" vim -N -u "$test_home/.vimrc" -i NONE -es -S "$tmp/check.vim"; then
  [[ ! -f $tmp/errors ]] || cat "$tmp/errors"
  exit 1
fi
[[ -n $(find "$test_home/.vim/swap" -prune -type d -perm 700) ]]
[[ -n $(find "$test_home/.vim/undo" -prune -type d -perm 700) ]]

# Opting out of preservation keeps the original in backup, without loading it.
fresh="$tmp/fresh"
mkdir -p "$fresh"
printf 'let g:unwanted_vimrc = 1\n' > "$fresh/.vimrc"
env HOME="$fresh" bash "$repo/install-vim.sh" --no-preserve-current
[[ ! -e $fresh/.vimrc.local ]]
backups=("$fresh"/.my-vim-backup.*)
[[ -f ${backups[0]}/.vimrc && ! -e ${backups[0]}/previous.vim ]]

# A dangling primary link can be replaced; unsafe local overrides cannot.
broken="$tmp/broken"
mkdir -p "$broken"
ln -s missing "$broken/.vimrc"
env HOME="$broken" bash "$repo/install-vim.sh"
backups=("$broken"/.my-vim-backup.*)
[[ -L ${backups[0]}/.vimrc && $(readlink "${backups[0]}/.vimrc") == missing ]]
ln -s missing "$broken/.vimrc.local"
if env HOME="$broken" bash "$repo/install-vim.sh" 2>/dev/null; then exit 1; fi
for name in .vimrc .vimrc.local; do
  refused="$tmp/refused-$name"
  mkdir -p "$refused/$name"
  if env HOME="$refused" bash "$repo/install-vim.sh" 2>/dev/null; then exit 1; fi
  [[ -d $refused/$name ]]
done
if env HOME="$fresh" bash "$repo/install-vim.sh" --invalid 2>/dev/null; then exit 1; fi
printf 'PASS: Vim startup, local storage, preservation, repeat install and unsafe paths\n'
