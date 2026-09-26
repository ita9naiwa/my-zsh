# Shared interactive configuration. Machine-specific settings belong in .zshrc.local.
[[ -o interactive ]] || return

() {
  local repo_dir=$1
  local prefix dir init map
  local config_dir=${ZDOTDIR:-$HOME}
  # Wave temporarily sets ZDOTDIR to its own shell-integration directory.
  [[ -n ${WAVETERM_ZDOTDIR:-} && $config_dir == "$WAVETERM_ZDOTDIR" ]] && config_dir=$HOME
  typeset -gU path fpath
  for prefix in /opt/homebrew /usr/local; do
    [[ -d $prefix/share/zsh/site-functions ]] && fpath+=("$prefix/share/zsh/site-functions")
  done
  for dir in "$HOME/.local/bin" "$HOME/.atuin/bin"; do
    [[ -d $dir ]] && path=("$dir" $path)
  done

  HISTFILE=${HISTFILE:-$config_dir/.zsh_history}
  HISTSIZE=50000
  SAVEHIST=50000
  setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
  setopt HIST_SAVE_NO_DUPS AUTO_CD INTERACTIVE_COMMENTS

  autoload -Uz compinit
  compinit -i -d "$config_dir/.zcompdump"
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
  bindkey -e
  bindkey '^[[H' beginning-of-line
  bindkey '^[[F' end-of-line
  bindkey '^[[3~' delete-char
  bindkey '^[b' backward-word
  bindkey '^[f' forward-word

  # Built-in prompt: no framework, font or external executable required.
  autoload -Uz vcs_info add-zsh-hook
  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:git:*' formats ' (%b)'
  my_zsh_precmd() {
    vcs_info
    return 0 # A failed hook would prevent Wave and other precmd hooks from running.
  }
  add-zsh-hook precmd my_zsh_precmd
  setopt PROMPT_SUBST
  # Escape percent sequences in branch names before prompt expansion.
  PROMPT='%F{cyan}%~%f${vcs_info_msg_0_//\%/%%}'$'\n''%(?.%F{green}.%F{red})%#%f '

  source "$repo_dir/shortcut.sh"
  # Load environments before optional tools so their executables are discoverable.
  [[ -r $config_dir/.zshrc.local ]] && source "$config_dir/.zshrc.local"

  # fzf --zsh requires >= 0.48; older installations keep their own integration.
  if (( $+commands[fzf] )) && init=$(fzf --zsh 2>/dev/null); then
    eval "$init"
  fi
  (( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
  # Keep Up-arrow navigation; Atuin owns Ctrl-R when both it and fzf exist.
  (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"

  for prefix in /opt/homebrew /usr/local; do
    [[ -r $prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && {
      source "$prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
      break
    }
  done
  # Preserve the Mac's existing terminal navigation bindings.
  [[ -r $HOME/.config/zsh/terminal-keys.zsh ]] && source "$HOME/.config/zsh/terminal-keys.zsh"
  # Up/Down filter by the text before the cursor; empty input browses all history.
  for map in emacs viins; do
    bindkey -M "$map" '^[[A' history-beginning-search-backward
    bindkey -M "$map" '^[OA' history-beginning-search-backward
    bindkey -M "$map" '^[[B' history-beginning-search-forward
    bindkey -M "$map" '^[OB' history-beginning-search-forward
  done
  # Load highlighting after all widgets and key bindings.
  for prefix in /opt/homebrew /usr/local; do
    [[ -r $prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && {
      source "$prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
      break
    }
  done
  return 0
} "${${(%):-%N}:A:h}"
