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

" Backup
set nobackup
set nowritebackup

" Tabs
set expandtab
set tabstop=8
set shiftwidth=4

" Numbers
set number
au TermOpen * setlocal nonumber

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
autocmd FileType gitcommit,gitrebase set bufhidden=delete

" Mutt mail
autocmd BufNewFile,BufRead *mutt-* set spell
augroup filetypedetect
  autocmd BufNewFile,BufRead *mutt-* setf mail
augroup END

"" Plugins
call plug#begin(stdpath('data') . '/plugged')
Plug 'airblade/vim-gitgutter'
Plug 'antiagainst/vim-tablegen'
Plug 'embear/vim-localvimrc'
Plug 'jackguo380/vim-lsp-cxx-highlight'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'moll/vim-bbye'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'ntpeters/vim-better-whitespace'
Plug 'scott-linder/molokai'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-sleuth'
Plug 'easymotion/vim-easymotion'
call plug#end()

" Molokai
colorscheme molokai

"" Filetype

" Python
au FileType python setl nosmartindent

" Markdown
au BufRead,BufNewFile *.md setl filetype=markdown spell
au FileType markdown noremap <buffer> <Leader>r :!markdown "%" > "$(basename "%" .md).html"<cr><cr>

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

" localvimrc
let g:localvimrc_persistent = 2

" CoC
set nobackup
set nowritebackup
set updatetime=300
set shortmess+=c
set tagfunc=CocTagFunc
inoremap <silent><expr> <c-space> coc#refresh()
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-type-definition)
nmap <silent> gr <Plug>(coc-references)
nmap <leader>rn <Plug>(coc-rename)
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
augroup mygroup
  autocmd!
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end
nmap <leader>qf <Plug>(coc-fix-current)
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
command! A CocCommand clangd.switchSourceHeader
command! CN CocNext
command! CP CocPrev
command! CL CocListResume

" bbye
command! -bang -complete=buffer -nargs=? Bd Bdelete<bang> <args>
nnoremap <Leader>q :Bdelete<CR>

" easymotion
let g:EasyMotion_do_mapping = 0
let g:EasyMotion_startofline = 0
let g:EasyMotion_smartcase = 1
nmap s <Plug>(easymotion-overwin-f2)
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
