#!/usr/bin/env bash
# Optional fallback when the host has no zsh. No package manager or root writes.
set -euo pipefail
prefix="$HOME/.local/share/my-zsh/zsh-5.9.2"
[[ ! -f $prefix/.complete || ! -x $prefix/bin/zsh ]] || exit 0
for tool in cc make curl tar; do
  command -v "$tool" >/dev/null || { echo "Local zsh build needs $tool on PATH; no system changes were made." >&2; exit 1; }
done
if command -v sha256sum >/dev/null; then
  checksum=(sha256sum)
else
  command -v shasum >/dev/null || { echo 'Need sha256sum or shasum.' >&2; exit 1; }
  checksum=(shasum -a 256)
fi
mkdir -p "$HOME/.cache/my-zsh"
build_dir=$(mktemp -d "$HOME/.cache/my-zsh/build.XXXXXXXX")
trap 'rm -rf -- "$build_dir"' EXIT
cd "$build_dir"
curl --fail --location --proto '=https' --tlsv1.2 https://www.zsh.org/pub/zsh-5.9.2.tar.xz -o zsh.tar.xz
# Official https://www.zsh.org/pub/SHA256SUM, pinned rather than trusting a fresh digest.
printf '%s  zsh.tar.xz\n' 36fa734374b44783582cec09bcd67822e2f992c779ec1624ab5596df078d2f81 | "${checksum[@]}" -c -
tar -xf zsh.tar.xz
cd zsh-5.9.2
./configure --prefix="$prefix" || {
  echo 'Local build configuration failed. A C toolchain and termcap/ncurses development files are required; no system packages were installed.' >&2
  exit 1
}
make -j2
make install.bin install.modules install.fns
"$prefix/bin/zsh" -fc 'autoload -Uz compinit; compinit -D'
touch "$prefix/.complete"
