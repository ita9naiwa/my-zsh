# git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zprezto"
ln -s $(pwd)/prezto "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zprezto"

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

# add some common scripts
echo "My common scripts" >> ~/.zshrc
echo "source $(pwd)/.zshrc" >> ~/.zshrc
echo "source $(pwd)/.zpreztorc" >> ~/.zpreztorc

echo "source ~/my/shortcut.sh" >> ~/.zshrc



source ~/.zshrc