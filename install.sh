#!/usr/bin/env bash
# Run with Bash: zsh does not need to be installed yet.
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
target_dir=${ZDOTDIR:-$HOME}
preserve=1 change_shell=1 launch=1 plugins=1
for arg in "$@"; do
  case "$arg" in
    --preserve-current) preserve=1 ;;
    --no-preserve-current) preserve=0 ;;
    --no-chsh) change_shell=0 ;;
    --no-launch) launch=0 ;;
    --no-plugins) plugins=0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
as_root() {
  if [[ $(id -u) == 0 ]]; then "$@"; else sudo -- "$@"; fi
}
install_packages() {
  if command -v brew >/dev/null; then
    brew install "$@"
  elif command -v apt-get >/dev/null; then
    as_root apt-get update
    as_root apt-get install -y "$@"
  elif command -v dnf >/dev/null; then
    as_root dnf install -y "$@"
  elif command -v pacman >/dev/null; then
    as_root pacman -S --needed --noconfirm "$@"
  elif command -v apk >/dev/null; then
    as_root apk add "$@"
  else
    echo "No supported package manager. Install these packages, then rerun: $*" >&2
    exit 1
  fi
}
command -v zsh >/dev/null || install_packages zsh
zsh_bin=$(command -v zsh)
if (( plugins )); then
  packages=()
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    found=0
    for prefix in /opt/homebrew /usr/local /usr; do
      [[ ! -r "$prefix/share/$plugin/$plugin.zsh" ]] || found=1
    done
    (( found )) || packages+=("$plugin")
  done
  (( ${#packages[@]} == 0 )) || install_packages "${packages[@]}"
fi
mkdir -p "$target_dir"
rc="$target_dir/.zshrc"
local_rc="$target_dir/.zshrc.local"
[[ ! -d $rc && ! -d $local_rc ]] || {
  echo 'Refusing to replace a directory at .zshrc or .zshrc.local.' >&2; exit 1;
}
for script in .zshrc shortcut.sh bash-bridge.zsh; do "$zsh_bin" -n "$repo_dir/$script"; done
if [[ -L $rc && $(readlink "$rc") == "$repo_dir/.zshrc" ]]; then
  echo 'Already linked; checking remaining setup.'
else
  backup_dir=$(mktemp -d "$target_dir/.my-zsh-backup.XXXXXXXX")
  chmod 700 "$backup_dir"
  if [[ -e $rc || -L $rc ]]; then
    cp -P "$rc" "$backup_dir/.zshrc"
    if (( preserve )) && [[ -f $rc ]]; then
      cp -L "$rc" "$backup_dir/previous.zsh"
      if [[ -e $local_rc || -L $local_rc ]]; then cp -P "$local_rc" "$backup_dir/.zshrc.local"; fi
      printf '\nsource %q\n' "$backup_dir/previous.zsh" >> "$local_rc"
    fi
  fi
  ln -s "$repo_dir/.zshrc" "$backup_dir/new.zshrc"
  mv -f "$backup_dir/new.zshrc" "$rc"
  echo "Installed: $rc -> $repo_dir/.zshrc"
  echo "Backup: $backup_dir"
fi
if (( change_shell )); then
  current_shell=${SHELL:-}
  if command -v dscl >/dev/null; then
    current_shell=$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')
  elif command -v getent >/dev/null; then
    current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
  fi
  if [[ $current_shell != "$zsh_bin" ]]; then
    grep -Fxq "$zsh_bin" /etc/shells || {
      echo "$zsh_bin is not in /etc/shells; ask your administrator to register it, or use --no-chsh." >&2
      exit 1
    }
    chsh -s "$zsh_bin" || {
      echo 'Configuration installed, but chsh failed. Rerun after resolving authentication, or use --no-chsh.' >&2
      exit 1
    }
  fi
fi
echo 'Setup complete. Bash constants and simple aliases are imported when .bashrc exists.'
if (( launch )) && [[ -t 0 && -t 1 ]]; then
  exec "$zsh_bin" -l
fi
echo "Start the configured shell with: exec $zsh_bin -l"
