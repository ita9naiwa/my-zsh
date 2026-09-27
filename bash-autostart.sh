# Sourced by the user's Bash startup files; never by batch jobs or the importer.
if [[ $- == *i* && -t 0 && -t 1 &&
      -z ${MY_ZSH_BASH_BRIDGE:-} && ${MY_ZSH_AUTOSTART:-1} != 0 &&
      -x "$HOME/.local/bin/my-zsh" ]]; then
  export MY_ZSH_IMPORT_BASH=0
  exec "$HOME/.local/bin/my-zsh"
fi
