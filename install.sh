git submodule update --init --recursive
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

ln -s $(pwd)/prezto "${ZDOTDIR:-$HOME}/.zprezto"

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

# add some common scripts
echo "My common scripts" >> ~/.zshrc
echo "source $(pwd)/.zshrc" >> ~/.zshrc
echo "source $(pwd)/.zpreztorc" >> ~/.zpreztorc

echo "source ~/my/shortcut.sh" >> ~/.zshrc


export PATH=$HOME/miniconda3/bin:$PATH
source ~/.zshrc