#!/usr/bin/env bash
# Prefer a passwordless login-shell change; otherwise use per-account Bash startup.
set -euo pipefail
zsh_bin=$1
mode=${2:-auto}
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
state_dir="$HOME/.local/share/my-zsh"
mkdir -p "$state_dir"
if [[ $mode == none ]]; then
  echo 'Shell activation: skipped (--no-shell-setup).'
  exit 0
fi
user=$(id -un)
current_shell=${SHELL:-}
if command -v getent >/dev/null; then
  current_shell=$(getent passwd "$user" | cut -d: -f7) || current_shell=${SHELL:-}
elif command -v dscl >/dev/null; then
  current_shell=$(dscl . -read "/Users/$user" UserShell 2>/dev/null | awk '{print $2}') || current_shell=${SHELL:-}
fi
if [[ $mode == auto && $current_shell == "$zsh_bin" ]]; then
  echo "Shell activation: login shell is already $zsh_bin."
  exit 0
fi
if [[ $mode == auto ]] && grep -Fxq "$zsh_bin" /etc/shells 2>/dev/null &&
   command -v sudo >/dev/null && command -v chsh >/dev/null; then
  # -n forbids sudo password prompts; root chsh targets ONLY the calling account.
  if sudo -n -- "$(command -v chsh)" -s "$zsh_bin" "$user" </dev/null 2>"$state_dir/shell-change.log"; then
    echo "Shell activation: login shell changed to $zsh_bin using passwordless sudo."
    exit 0
  fi
  echo "Passwordless shell change unavailable; using Bash startup. Details: $state_dir/shell-change.log"
fi
# Both interactive Bash and Bash login shells must find the guard.
cp "$repo_dir/bash-autostart.sh" "$state_dir/bash-autostart.sh"
profile="$HOME/.bash_profile"
for candidate in .bash_profile .bash_login .profile; do
  if [[ -e $HOME/$candidate ]]; then profile="$HOME/$candidate"; break; fi
done
line='[ -n "${BASH_VERSION:-}" ] && [ -r "$HOME/.local/share/my-zsh/bash-autostart.sh" ] && . "$HOME/.local/share/my-zsh/bash-autostart.sh"'
for file in "$HOME/.bashrc" "$profile"; do
  [[ ! -d $file ]] || { echo "Not a regular startup file: $file" >&2; exit 1; }
  if ! grep -Fxq "$line" "$file" 2>/dev/null; then
    if [[ -e $file || -L $file ]]; then
      backup=$(mktemp "$file.my-zsh-backup.XXXXXXXX")
      cp -P "$file" "$backup"
      echo "Startup backup: $backup"
    fi
    printf '\n# my-zsh: interactive terminal auto-start\n%s\n' "$line" >> "$file"
  fi
done
echo 'Shell activation: Bash auto-start installed (no password, no login-shell change).'
echo 'Bash re-import is disabled during auto-start; exported environment variables are retained.'
