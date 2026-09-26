# Bash --rcfile: evaluate .bashrc in Bash, export only changed scalar values/aliases.
_my_zsh_before=$(declare -p)
source "$HOME/.bashrc" >/dev/null
# ponytail: linear scan of a small startup-variable snapshot; no persistent cache.
while IFS= read -r _my_zsh_name; do
  [[ $_my_zsh_name == _* ]] && continue
  _my_zsh_decl=$(declare -p "$_my_zsh_name" 2>/dev/null) || continue
  [[ $'\n'$_my_zsh_before$'\n' == *$'\n'"$_my_zsh_decl"$'\n'* ]] && continue
  _my_zsh_flags=${_my_zsh_decl#declare -}
  _my_zsh_flags=${_my_zsh_flags%% *}
  [[ $_my_zsh_flags == *a* || $_my_zsh_flags == *A* ]] && continue
  _my_zsh_kind=value
  [[ $_my_zsh_flags == *x* ]] && _my_zsh_kind=env
  printf '%s\0%s\0%s\0' "$_my_zsh_kind" "$_my_zsh_name" "${!_my_zsh_name}"
done < <(compgen -v)
while IFS= read -r _my_zsh_name; do
  printf 'alias\0%s\0%s\0' "$_my_zsh_name" "$(alias "$_my_zsh_name")"
done < <(compgen -a)
