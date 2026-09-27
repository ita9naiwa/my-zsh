#!/usr/bin/env zsh
set -euo pipefail
repo=${0:A:h}
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home" ZDOTDIR="$tmp/dot files"
mkdir -p "$HOME" "$ZDOTDIR"
print 'export MY_ZSH_PRESERVED=yes' > "$ZDOTDIR/.zshrc"
print 'export MY_ZSH_LOCAL=yes' > "$ZDOTDIR/.zshrc.local"
bash "$repo/install.sh" --no-shell-setup --no-launch --no-plugins --preserve-current
first=$(cksum "$ZDOTDIR/.zshrc.local")
bash "$repo/install.sh" --no-shell-setup --no-launch --no-plugins --preserve-current
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
bash "$repo/install.sh" --no-shell-setup --no-launch --no-plugins
zsh -dic '(( $+functions[compdef] ))' 2> "$tmp/err"
[[ ! -s "$tmp/err" ]] || { cat "$tmp/err"; exit 1; }
export ZDOTDIR="$tmp/broken"
mkdir -p "$ZDOTDIR"
ln -s missing "$ZDOTDIR/.zshrc"
bash "$repo/install.sh" --no-shell-setup --no-launch --no-plugins
backups=("$ZDOTDIR"/.my-zsh-backup.*/.zshrc)
[[ -L $backups[1] ]]
if bash "$repo/install.sh" --no-shell-setup --no-launch --no-plugins --invalid 2>/dev/null; then exit 1; fi
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
MY_ZSH_IMPORT_BASH=1 REPO="$repo" zsh -df -i -c '
  source "$REPO/.zshrc"
  [[ $PROJECT_ROOT == "/tmp/project with spaces" && $MY_RC_VALUE == $'"'"'line one\nline two'"'"' ]] || exit 1
  [[ $LITERAL_VALUE == '"'"'$(touch should-not-exist)'"'"' ]] || exit 1
  [[ ${parameters[PROJECT_ROOT]} != *export* && ${parameters[MY_RC_VALUE]} == *export* ]] || exit 1
  (( ! $+functions[array_fn] && ! $+parameters[SAMPLE_ARRAY] )) || exit 1
  [[ $(eval ll) == "alias works" ]] || exit 1
  eval croot
  [[ $PWD == / ]] || exit 1
' > "$tmp/bridge.out" 2> "$tmp/bridge.err" || { cat "$tmp/bridge.err"; exit 1; }
# Account-local launcher works, and forbidden administrative commands are never called.
mock="$tmp/bin"
mkdir -p "$mock"
for tool in sudo chsh brew apt-get dnf pacman apk; do
  cat > "$mock/$tool" <<'SH'
#!/bin/sh
printf 'FORBIDDEN\n' >> "$TEST_LOG"
exit 99
SH
  chmod +x "$mock/$tool"
done
TEST_LOG="$tmp/admin.log" PATH="$mock:$PATH" ZDOTDIR="$tmp/account" bash "$repo/install.sh" --no-shell-setup --no-launch --no-plugins
[[ ! -e $tmp/admin.log ]] || exit 1
[[ -x $HOME/.local/bin/my-zsh ]] || exit 1
ZDOTDIR="$tmp/account" "$HOME/.local/bin/my-zsh" -ic '(( $+functions[my_zsh_precmd] ))' 2> "$tmp/launcher.err"
[[ ! -s "$tmp/launcher.err" ]] || { cat "$tmp/launcher.err"; exit 1; }
# Local plugin files take priority over system installations.
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  mkdir -p "$HOME/.local/share/my-zsh/plugins/$plugin"
  print "typeset -g MY_LOCAL_${plugin//-/_}=yes" > "$HOME/.local/share/my-zsh/plugins/$plugin/$plugin.zsh"
done
REPO="$repo" zsh -df -ic '
  source "$REPO/.zshrc"
  [[ $MY_LOCAL_zsh_autosuggestions == yes && $MY_LOCAL_zsh_syntax_highlighting == yes ]]
'
print 'PASS: user-only install/launcher, no admin commands, local plugins, Wave, Bash import'
# Test automatic activation without invoking the host's sudo/chsh.
activation_bin="$tmp/activation-bin"
mkdir -p "$activation_bin"
for tool in bash dirname mkdir cp cut mktemp awk id; do
  ln -s "$(command -v $tool)" "$activation_bin/$tool"
done
cat > "$activation_bin/getent" <<'SH'
#!/bin/bash
printf 'test:x:1000:1000::/tmp:%s\n' "${TEST_CURRENT_SHELL:-/bin/bash}"
SH
real_grep=$(command -v grep)
{
  print '#!/bin/bash'
  print 'if [[ ${*: -1} == /etc/shells ]]; then exit "${TEST_SHELL_UNLISTED:-0}"; fi'
  print -r -- "exec ${(q)real_grep} \"\$@\""
} > "$activation_bin/grep"
cat > "$activation_bin/sudo" <<'SH'
#!/bin/bash
[[ $1 == -n && $2 == -- && $4 == -s && -n $6 ]] || exit 98
printf '%s\n' "$*" >> "$TEST_LOG"
exit "${TEST_SUDO_STATUS:-1}"
SH
cat > "$activation_bin/chsh" <<'SH'
#!/bin/bash
exit 99
SH
chmod +x "$activation_bin"/{getent,grep,sudo,chsh}
activation_home="$tmp/activation-home"
mkdir -p "$activation_home"
print 'export EXISTING_VALUE=kept' > "$activation_home/.bashrc"
print '# existing profile' > "$activation_home/.profile"
for run in 1 2; do
  HOME="$activation_home" PATH="$activation_bin" TEST_LOG="$tmp/sudo.log" bash "$repo/setup-shell.sh" /bin/zsh > "$tmp/setup.out"
done
[[ $(grep -c '^\[ -n' "$activation_home/.bashrc") == 1 ]] || exit 1
[[ $(grep -c '^\[ -n' "$activation_home/.profile") == 1 ]] || exit 1
[[ $(find "$activation_home" -name '*.my-zsh-backup.*' | wc -l) -eq 2 ]] || exit 1
[[ $(<"$tmp/setup.out") == *'Bash auto-start installed'* ]] || exit 1
HOME="$tmp/sudo-success" PATH="$activation_bin" TEST_LOG="$tmp/sudo.log" TEST_SUDO_STATUS=0 bash "$repo/setup-shell.sh" /bin/zsh > "$tmp/setup.out"
[[ ! -e $tmp/sudo-success/.bashrc && $(<"$tmp/setup.out") == *'using passwordless sudo'* ]] || exit 1
HOME="$tmp/already-zsh" PATH="$activation_bin" TEST_CURRENT_SHELL=/bin/zsh bash "$repo/setup-shell.sh" /bin/zsh > "$tmp/setup.out"
[[ ! -e $tmp/already-zsh/.bashrc && $(<"$tmp/setup.out") == *'already /bin/zsh'* ]] || exit 1
HOME="$tmp/unlisted" PATH="$activation_bin" TEST_SHELL_UNLISTED=1 bash "$repo/setup-shell.sh" /home/test/custom-zsh > "$tmp/setup.out"
[[ -f $tmp/unlisted/.bashrc ]] || exit 1
rm "$activation_bin/sudo"
HOME="$tmp/no-sudo" PATH="$activation_bin" bash "$repo/setup-shell.sh" /bin/zsh > "$tmp/setup.out"
[[ -f $tmp/no-sudo/.bashrc ]] || exit 1
# Sourcing the guard in a noninteractive job must never replace that job.
HOME="$activation_home" bash -c 'source "$HOME/.bashrc"; [[ $EXISTING_VALUE == kept ]]; echo JOB_SURVIVED' > "$tmp/job.out"
[[ $(<"$tmp/job.out") == JOB_SURVIVED ]] || exit 1
print 'PASS: no-password sudo/failure/missing, unlisted shell, fallback idempotence, batch guard'
