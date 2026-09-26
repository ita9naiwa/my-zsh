#!/usr/bin/env zsh
set -euo pipefail
repo=${0:A:h}
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home" ZDOTDIR="$tmp/dot files"
mkdir -p "$HOME" "$ZDOTDIR"
print 'export MY_ZSH_PRESERVED=yes' > "$ZDOTDIR/.zshrc"
print 'export MY_ZSH_LOCAL=yes' > "$ZDOTDIR/.zshrc.local"
bash "$repo/install.sh" --no-chsh --no-launch --no-plugins --preserve-current
first=$(cksum "$ZDOTDIR/.zshrc.local")
bash "$repo/install.sh" --no-chsh --no-launch --no-plugins --preserve-current
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
bash "$repo/install.sh" --no-chsh --no-launch --no-plugins
zsh -dic '(( $+functions[compdef] ))' 2> "$tmp/err"
[[ ! -s "$tmp/err" ]] || { cat "$tmp/err"; exit 1; }
export ZDOTDIR="$tmp/broken"
mkdir -p "$ZDOTDIR"
ln -s missing "$ZDOTDIR/.zshrc"
bash "$repo/install.sh" --no-chsh --no-launch --no-plugins
backups=("$ZDOTDIR"/.my-zsh-backup.*/.zshrc)
[[ -L $backups[1] ]]
if bash "$repo/install.sh" --no-chsh --no-launch --no-plugins --invalid 2>/dev/null; then exit 1; fi
# Bash import: plain constants, exported values, aliases; no functions or arrays.
cat > "$HOME/.bashrc" <<'BASH'
[[ $- == *i* ]] || return
PROJECT_ROOT='/tmp/project with spaces'
export MY_RC_VALUE=$'line one\nline two'
LITERAL_VALUE='$(touch should-not-exist)'
alias ll='printf "alias works\n"'
alias croot='cd /'
array_fn() { local values=("$@"); printf '<%s>\n' "${values[@]}"; }
SAMPLE_ARRAY=(one two)
BASH
REPO="$repo" zsh -df -i -c '
  source "$REPO/.zshrc"
  [[ $PROJECT_ROOT == "/tmp/project with spaces" && $MY_RC_VALUE == $'"'"'line one\nline two'"'"' ]] || exit 1
  [[ $LITERAL_VALUE == '"'"'$(touch should-not-exist)'"'"' ]] || exit 1
  [[ ${parameters[PROJECT_ROOT]} != *export* && ${parameters[MY_RC_VALUE]} == *export* ]] || exit 1
  (( ! $+functions[array_fn] && ! $+parameters[SAMPLE_ARRAY] )) || exit 1
  [[ $(eval ll) == "alias works" ]] || exit 1
  eval croot
  [[ $PWD == / ]] || exit 1
' > "$tmp/bridge.out" 2> "$tmp/bridge.err" || { cat "$tmp/bridge.err"; exit 1; }
# Missing-zsh bootstrap and chsh are tested with local command doubles only.
mock="$tmp/bin"
mkdir -p "$mock"
for tool in bash dirname mkdir cp mv chmod mktemp readlink awk cut ln; do
  ln -s "$(command -v $tool)" "$mock/$tool"
done
cat > "$mock/id" <<'SH'
#!/bin/bash
if [[ $1 == -u ]]; then echo 0; else echo testuser; fi
SH
cat > "$mock/apt-get" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >> "$TEST_LOG"
if [[ $1 == install ]]; then /bin/ln -s /bin/zsh "$TEST_BIN/zsh"; fi
SH
cat > "$mock/getent" <<'SH'
#!/bin/bash
echo 'testuser:x:1000:1000::/tmp:/bin/bash'
SH
cat > "$mock/grep" <<'SH'
#!/bin/bash
[[ $3 == /etc/shells ]]
SH
cat > "$mock/chsh" <<'SH'
#!/bin/bash
printf 'chsh %s\n' "$*" >> "$TEST_LOG"
SH
chmod +x "$mock"/{id,apt-get,getent,grep,chsh}
TEST_LOG="$tmp/package.log" TEST_BIN="$mock" PATH="$mock" ZDOTDIR="$tmp/bootstrap" /bin/bash "$repo/install.sh" --no-launch --no-plugins
[[ $(<"$tmp/package.log") == *'install -y zsh'* ]] || exit 1
[[ $(<"$tmp/package.log") == *"chsh -s $mock/zsh"* ]] || exit 1
print 'PASS: bootstrap/chsh mocks, install, plugins, Wave, Bash constants/environment/aliases/quoting'
