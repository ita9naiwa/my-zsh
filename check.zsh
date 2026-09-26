#!/usr/bin/env zsh
set -euo pipefail
repo=${0:A:h}
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home" ZDOTDIR="$tmp/dot files"
mkdir -p "$HOME" "$ZDOTDIR"
print 'export MY_ZSH_PRESERVED=yes' > "$ZDOTDIR/.zshrc"
print 'export MY_ZSH_LOCAL=yes' > "$ZDOTDIR/.zshrc.local"
zsh "$repo/install.sh" --preserve-current
first=$(cksum "$ZDOTDIR/.zshrc.local")
zsh "$repo/install.sh" --preserve-current
[[ $(cksum "$ZDOTDIR/.zshrc.local") == "$first" ]]
[[ $(find "$ZDOTDIR" -maxdepth 1 -type d -name '.my-zsh-backup.*' | wc -l) -eq 1 ]]
before=$(cksum "$repo/.zshrc")
zsh -dic '
  [[ $MY_ZSH_PRESERVED == yes && $MY_ZSH_LOCAL == yes ]] || exit 1
  [[ -o sharehistory && -o interactivecomments ]] || exit 1
  (( $+functions[compdef] && $+functions[my_zsh_precmd] )) || exit 1
  [[ ${aliases[iree-cpu]} == iree-compile* ]] || exit 1
  [[ $(bindkey "^[[A") == *history-beginning-search-backward* ]] || exit 1
  [[ $(bindkey "^[[B") == *history-beginning-search-forward* ]] || exit 1
  if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    (( $+functions[_zsh_autosuggest_start] )) || exit 1
  fi
  if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    (( $+functions[_zsh_highlight] )) || exit 1
  fi
  false
  my_zsh_precmd || exit 1
  source "$ZDOTDIR/.zshrc"
  (( ${#precmd_functions[(r)my_zsh_precmd]} > 0 )) || exit 1
  [[ $(bindkey "^[[3~") == *delete-char* ]] || exit 1
' > "$tmp/out" 2> "$tmp/err"
[[ ! -s "$tmp/err" ]] || { cat "$tmp/err"; exit 1; }
[[ $(cksum "$repo/.zshrc") == "$before" ]]
# Wave's temporary ZDOTDIR must not hide the user's local config/history.
print 'export MY_ZSH_WAVE=yes' > "$HOME/.zshrc.local"
# Load explicitly, as Wave does from its own startup file.
WAVETERM_ZDOTDIR="$tmp/wave" ZDOTDIR="$tmp/wave" REPO="$repo" zsh -df -i -c '
  source "$REPO/.zshrc"
  [[ $MY_ZSH_WAVE == yes && $HISTFILE == "$HOME/.zsh_history" ]] || exit 1
' 2> "$tmp/err"
[[ ! -s "$tmp/err" ]] || { cat "$tmp/err"; exit 1; }
# Empty home, broken symlink and invalid arguments must also be handled safely.
export ZDOTDIR="$tmp/clean"
zsh "$repo/install.sh"
zsh -dic '(( $+functions[compdef] ))' 2> "$tmp/err"
[[ ! -s "$tmp/err" ]] || { cat "$tmp/err"; exit 1; }
export ZDOTDIR="$tmp/broken"
mkdir -p "$ZDOTDIR"
ln -s missing "$ZDOTDIR/.zshrc"
zsh "$repo/install.sh"
backups=("$ZDOTDIR"/.my-zsh-backup.*/.zshrc)
[[ -L $backups[1] ]]
if zsh "$repo/install.sh" --invalid 2>/dev/null; then exit 1; fi
print 'PASS: fresh install, preservation, repeat install, startup, plugins, prefix keys, Wave ZDOTDIR, no self-write, broken symlink'
