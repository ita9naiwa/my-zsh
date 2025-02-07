# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/ita/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/ita/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/ita/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/ita/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

fpath+=("$(brew --prefix)/share/zsh/site-functions");
# .zshrc

autoload -U promptinit; promptinit
prompt pure

# change the path color
zstyle :prompt:pure:path color white
# change the color for both `prompt:success` and `prompt:error`
zstyle ':prompt:pure:prompt:*' color cyan
# turn on git stash status
zstyle :prompt:pure:git:stash show yes


echo 'fpath+=("$(pwd)/pure")' >> ~/.zshrc
echo "autoload -U promptinit" >> ~/.zshrc
echo  "promptinit" >> ~/.zshrc
echo "prompt pure" >> ~/.zshrc

source $HOME/.atuin/bin/env
#[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

#my common scripts
source ~/my/shortcut.sh

# llvm/iree path
export PATH="$HOME/src/llvm-project/build-llvm/bin:$PATH"
export PATH="$HOME/src/iree-build/tools:$PATH"

# ccache
alias CC="ccache CC"
alias CXX="ccache CXX"
alias clang="ccache clang"
alias clang++="ccache clang++"
alias gcc="ccache gcc"
alias g++="ccache g++"

# Autin
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"



