"" VIM

" Looks
set fillchars=vert:│,fold:─,diff:─
set list
set listchars=tab:»·,trail:·
set wrap
set linebreak

" Columns
set colorcolumn=81,82
set signcolumn="yes"
au TermOpen * setlocal signcolumn="no"

" Paragraphs
set nojoinspaces
set formatoptions+=2

" Buffers
set hidden
command! -nargs=1 E e <args>|bd#
command! BB b#|bd#

" Tabs
set expandtab
set tabstop=8
set shiftwidth=4

" Numbers
set number
set relativenumber
au TermOpen * setlocal nonumber relativenumber

" Search
set incsearch
set ignorecase
set smartcase
set nohlsearch

" Context
set scrolloff=2
au TermOpen * setlocal scrolloff=0

" Persistent undo
set undofile

" Doxygen comments
setlocal comments-=:// | setlocal comments+=:///,://

" We need a way to consistently get to normal mode no matter where we are,
" ideally without having to leave the home row. Pick something that doesn't
" seem to conflict with any control sequences in terminal emulators or any
" utilities.
inoremap <C-j> <C-\><C-n>
tnoremap <C-j> <C-\><C-n>
cnoremap <C-j> <C-\><C-n>

" alt+t to create new tab with terminal
tnoremap <A-t> <C-\><C-N>:tabe +term<CR>a
inoremap <A-t> <C-\><C-N>:tabe +term<CR>a
nnoremap <A-t> :tabe +term<CR>a

" git
let $GIT_EDITOR = 'nvr -cc split --remote-wait'
autocmd FileType gitcommit,gitrebase set bufhidden=delete

autocmd BufNewFile,BufRead *mutt-* set spell

" Mutt mail
augroup filetypedetect
  autocmd BufNewFile,BufRead *mutt-* setf mail
augroup END

"" Plugins
call plug#begin(stdpath('data') . '/plugged')
Plug 'airblade/vim-gitgutter'
Plug 'antiagainst/vim-tablegen'
Plug 'dag/vim-fish'
Plug 'embear/vim-localvimrc'
Plug 'gerw/vim-latex-suite'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'mattn/emmet-vim'
Plug 'neomake/neomake'
Plug 'ntpeters/vim-better-whitespace'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'rhysd/vim-clang-format'
Plug 'scott-linder/molokai'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-sleuth'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'vim-scripts/a.vim'
Plug 'vimoutliner/vimoutliner'
call plug#end()

" Molokai
colorscheme molokai

" A
let g:alternateExtensions_cc = "hh"
let g:alternateExtensions_hh = "cc"

" Latex-Suite
set grepprg=grep\ -nH\ $*
let g:tex_flavor = "latex"
let g:tex_comment_nospell = 1
let g:Tex_Folding = 0
let g:Tex_CompileRule_pdf = 'pdflatex -interaction=nonstopmode $*'
let g:Tex_FormatDependancy_pdf = 'pdf'
let g:Tex_DefaultTargetFormat = 'pdf'
let g:Tex_MultipleCompileFormats = 'pdf'
let g:Tex_ViewRule_pdf = 'evince'

" NERDTree
nmap <C-n> :NERDTreeToggle<CR>
let NERDTreeQuitOnOpen = 1

"" Filetype

" Python
au FileType python setl nosmartindent

" Markdown
au BufRead,BufNewFile *.md setl filetype=markdown spell
au FileType markdown noremap <buffer> <Leader>r :!markdown "%" > "$(basename "%" .md).html"<cr><cr>

" R
au FileType r noremap <buffer> <leader>r :!clear && R --vanilla <% \| less<cr>
au FileType r noremap <buffer> <leader>p :!evince Rplots.pdf >/dev/null 2>&1 &<cr>

" Rust
au FileType rust setl keywordprg=uzbl-rust-std
au FileType rust noremap <buffer> <leader>r :!clear && cargo run<cr>
au FileType rust noremap <buffer> <leader>t :!clear && cargo test<cr>
au FileType rust noremap <buffer> <leader>b :!clear && cargo build<cr>
au FileType rust noremap <buffer> <leader>c :!clear && cargo clean<cr>

" VimOutliner
au FileType votl set tabstop=2
au FileType votl set shiftwidth=2
au FileType votl set noexpandtab

" ClangFormat
"au FileType c,cpp nnoremap <buffer><Leader>f :<C-u>ClangFormat<CR>
au FileType c,cpp vnoremap <buffer><Leader>f :ClangFormat<CR>

" FZF
" Enable preview window in :Files
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)
" Enable preview window in :Rg
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)
nnoremap <C-o> :Buffers<cr>
nnoremap <C-p> :Files<cr>

" NeoMake
call neomake#configure#automake('nw')
let g:neomake_c_enabled_makers = ['clangcheck', 'clangtidy']
let g:neomake_cpp_enabled_makers = ['clangcheck', 'clangtidy']

" localvimrc
let g:localvimrc_persistent = 2

" tabulous
let g:tabulousLabelLeftStr = ' '
let g:tabulousLabelRightStr = '❘'
let g:tabulousLabelNameOptions = ':t'

" vim-airline
let g:airline_theme = 'base16_snazzy'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_tab_nr = 1
" show tab number, not number of splits
let g:airline#extensions#tabline#tab_nr_type = 1
set noshowmode
