# Import .bashrc scalar values and simple aliases; never import Bash functions.
# Opt in with MY_ZSH_IMPORT_BASH=1; arbitrary .bashrc startup code can block.
[[ ${MY_ZSH_IMPORT_BASH:-0} == 1 && -z ${MY_ZSH_BASH_BRIDGE:-} && -r $HOME/.bashrc ]] || return 0
() {
  setopt localoptions extendedglob
  local _my_zsh_kind _my_zsh_name _my_zsh_value
  while IFS= read -r -d '' _my_zsh_kind && IFS= read -r -d '' _my_zsh_name && IFS= read -r -d '' _my_zsh_value; do
    if [[ $_my_zsh_kind == alias ]]; then
      [[ $_my_zsh_name == [a-zA-Z0-9_.:+-]## ]] && eval -- "$_my_zsh_value"
      continue
    fi
    [[ $_my_zsh_name == [a-zA-Z][a-zA-Z0-9_]# ]] || continue
    case $_my_zsh_name in
      BASH*|ZSH*|ZDOTDIR|WAVETERM*|MY_ZSH*|SHELL|PS[0-9]*|PROMPT*|HIST*) continue ;;
    esac
    [[ ${parameters[$_my_zsh_name]:-} == *readonly* ]] && continue
    [[ ${parameters[$_my_zsh_name]:-} == *special* && $_my_zsh_name != PATH ]] && continue
    if [[ $_my_zsh_kind == env ]]; then
      export "$_my_zsh_name=$_my_zsh_value"
    else
      typeset -g "$_my_zsh_name=$_my_zsh_value"
    fi
  done < <(MY_ZSH_BASH_BRIDGE=1 command bash --noprofile --rcfile "$1" -i -c ':' </dev/null 2>/dev/null)
} "${${(%):-%N}:A:h}/bash-export.sh"
