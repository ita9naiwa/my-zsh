" Small, plugin-free defaults for the Vim shipped with macOS and Linux.
set nocompatible
syntax enable
filetype plugin indent on
set background=dark
colorscheme desert
set number cursorline ruler laststatus=2 showcmd
set backspace=indent,eol,start
set hidden
set incsearch hlsearch ignorecase smartcase
set wildmenu
set autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4
set scrolloff=5 sidescrolloff=5
set splitbelow splitright
set noerrorbells visualbell
set listchars=tab:>-,trail:.,extends:>,precedes:<
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" Keep recovery I/O off SSHFS; // gives each full file path its own name.
call mkdir(expand('~/.vim/swap'), 'p', 0700)
set directory=~/.vim/swap//
if has('persistent_undo')
    call mkdir(expand('~/.vim/undo'), 'p', 0700)
    set undofile undodir=~/.vim/undo//
endif

" Machine-specific settings and preserved previous configuration win last.
if filereadable(expand('~/.vimrc.local'))
    execute 'source' fnameescape(expand('~/.vimrc.local'))
endif
