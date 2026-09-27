#!/usr/bin/env bash
# Run with Bash: zsh does not need to be installed yet.
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
target_dir=${ZDOTDIR:-$HOME}
preserve=1 launch=1 plugins=1 build_zsh=0
state_dir="$HOME/.local/share/my-zsh"
for arg in "$@"; do
  case "$arg" in
    --preserve-current) preserve=1 ;;
    --no-preserve-current) preserve=0 ;;
    --no-chsh) : ;; # Accepted for older installation commands.
    --build-zsh) build_zsh=1 ;;
    --no-launch) launch=0 ;;
    --no-plugins) plugins=0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
[[ $EUID != 0 ]] || { echo 'Run as your own account, not root.' >&2; exit 1; }
mkdir -p "$state_dir"
if (( build_zsh )) || { ! command -v zsh >/dev/null && [[ ! -x $state_dir/zsh-5.9.2/bin/zsh || ! -f $state_dir/zsh-5.9.2/.complete ]]; }; then
  bash "$repo_dir/build-zsh.sh"
fi
if [[ -x $state_dir/zsh-5.9.2/bin/zsh && -f $state_dir/zsh-5.9.2/.complete ]]; then
  zsh_bin="$state_dir/zsh-5.9.2/bin/zsh"
else
  zsh_bin=$(command -v zsh)
fi
if (( plugins )); then
  command -v git >/dev/null || { echo 'git is required to download plugins; use --no-plugins for offline setup.' >&2; exit 1; }
  for spec in zsh-autosuggestions:v0.7.1 zsh-syntax-highlighting:0.8.0; do
    plugin=${spec%:*} tag=${spec#*:}
    dest="$state_dir/plugins/$plugin"
    if [[ ! -r $dest/$plugin.zsh ]]; then
      [[ ! -e $dest ]] || { echo "Incomplete plugin directory: $dest" >&2; exit 1; }
      mkdir -p "$state_dir/plugins"
      staging=$(mktemp -d "$state_dir/plugins/.download.XXXXXXXX")
      if ! git -c advice.detachedHead=false clone --depth 1 --branch "$tag" "https://github.com/zsh-users/$plugin.git" "$staging"; then
        rm -rf -- "$staging"
        exit 1
      fi
      mv "$staging" "$dest"
    fi
  done
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
# An account-local launcher replaces changes to the OS login-shell database.
mkdir -p "$HOME/.local/bin"
launcher="$HOME/.local/bin/my-zsh"
staging=$(mktemp "$HOME/.local/bin/.my-zsh.XXXXXXXX")
{
  printf '#!/usr/bin/env bash\n'
  printf 'if [[ -z ${ZDOTDIR:-} ]]; then export ZDOTDIR=%q; fi\n' "$target_dir"
  printf 'exec %q -l "$@"\n' "$zsh_bin"
} > "$staging"
chmod 755 "$staging"
if [[ -e $launcher || -L $launcher ]]; then
  if ! cmp -s "$staging" "$launcher"; then
    launcher_backup=$(mktemp "$launcher.backup.XXXXXXXX")
    cp -P "$launcher" "$launcher_backup"
    echo "Launcher backup: $launcher_backup"
  fi
fi
mv -f "$staging" "$launcher"
echo 'Setup complete. Bash constants and simple aliases are imported when .bashrc exists.'
if (( launch )) && [[ -t 0 && -t 1 ]]; then
  exec "$launcher"
fi
printf 'Start the configured shell with: %q\n' "$launcher"
