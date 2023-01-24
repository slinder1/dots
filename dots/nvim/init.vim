"" VIM

" Looks
set fillchars=vert:│,fold:─,diff:─
set list
set listchars=tab:»·,trail:·
set wrap
set linebreak

" Columns
set colorcolumn=81,82
set signcolumn=yes:1
au TermOpen * setlocal signcolumn=no

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

" Mouse
set mouse=a

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

" jumplist
nnoremap <C-n> <C-o>
nnoremap <C-m> <C-i>

"" Plugins
call plug#begin(stdpath('data') . '/plugged')
Plug 'airblade/vim-gitgutter'
Plug 'antiagainst/vim-tablegen'
Plug 'embear/vim-localvimrc'
Plug 'itchyny/lightline.vim'
"Plug 'jackguo380/vim-lsp-cxx-highlight'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'justinmk/vim-sneak'
Plug 'moll/vim-bbye'
Plug 'ntpeters/vim-better-whitespace'
Plug 'scott-linder/molokai'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-fugitive'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
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
" Function to paste buffer names while in insert/terminal mode
function! s:bufput(line)
  call feedkeys('i' . split(a:line, '\t')[3] . ' ')
endfunction
function! BuffersPut()
  call fzf#run(fzf#wrap({
    \ 'source': map(fzf#vim#_buflisted_sorted(), 'fzf#vim#_format_buffer(v:val)'),
    \ 'sink': function('s:bufput'),
    \ 'options': ['+m', '-x', '--tiebreak=index', '--header-lines=1', '--ansi',
                 \'-d', '\t', '--with-nth', '3..', '-n', '2,1..2', '--prompt',
                 \'PasteBuf> ', '--query', '', '--preview-window', '+{2}-/2',
                 \'--tabstop', 8]
    \}))
endfunction
" Enable preview window in :GitFiles?
function! s:gfilesput(line)
  call feedkeys('i' . split(a:line, ' ')[1] . ' ')
endfunction
function! GFilesPut()
  let root = split(system('git rev-parse --show-toplevel'), '\n')[0]
  if v:shell_error
    return
  endif
  call fzf#run(fzf#wrap({
    \ 'source':  'git -c color.status=always status --short --untracked-files=all',
    \ 'sink': function('s:gfilesput'),
    \ 'dir': root,
    \ 'options': ['--ansi', '--nth', '2..,..', '--tiebreak=index', '--prompt', 'GitFiles?> ']
    \}))
endfunction
inoremap <silent> <C-u> <cmd>call GFilesPut()<cr>
tnoremap <silent> <C-u> <cmd>call GFilesPut()<cr>
inoremap <silent> <C-o> <cmd>call BuffersPut()<cr>
tnoremap <silent> <C-o> <cmd>call BuffersPut()<cr>
nnoremap <C-i> :GFiles?<cr>
nnoremap <C-o> :Buffers<cr>
nnoremap <C-p> :Files<cr>

" localvimrc
let g:localvimrc_persistent = 2

" LSP
lua << EOF
-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('v', '<leader>f', '<cmd>lua vim.lsp.buf.format()<cr><esc>', bufopts)
  vim.api.nvim_create_user_command('A', 'ClangdSwitchSourceHeader', {})
end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { 'clangd' }
for _, lsp in pairs(servers) do
  require('lspconfig')[lsp].setup {
    on_attach = on_attach,
    flags = {
      -- This will be the default in neovim 0.7+
      debounce_text_changes = 150,
    }
  }
end
EOF

" tree-sitter
lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "cpp" },
  highlight = { enable = true },
}
EOF

" CoC
"set nobackup
"set nowritebackup
"set updatetime=300
"set shortmess+=c
"set tagfunc=CocTagFunc
"inoremap <silent><expr> <c-space> coc#refresh()
"nmap <silent> [g <Plug>(coc-diagnostic-prev)
"nmap <silent> ]g <Plug>(coc-diagnostic-next)
"nmap <silent> gd <Plug>(coc-definition)
"nmap <silent> gt <Plug>(coc-type-definition)
"nmap <silent> gi <Plug>(coc-type-definition)
"nmap <silent> gr <Plug>(coc-references)
"nmap <leader>rn <Plug>(coc-rename)
"xmap <leader>f  <Plug>(coc-format-selected)
"nmap <leader>f  <Plug>(coc-format-selected)
"augroup mygroup
"  autocmd!
"  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
"augroup end
"nmap <leader>qf <Plug>(coc-fix-current)
"nnoremap <silent> K :call <SID>show_documentation()<CR>
"function! s:show_documentation()
"  if (index(['vim','help'], &filetype) >= 0)
"    execute 'h '.expand('<cword>')
"  else
"    call CocAction('doHover')
"  endif
"endfunction
"command! A CocCommand clangd.switchSourceHeader
"command! CN CocNext
"command! CP CocPrev
"command! CL CocListResume

" bbye
command! -bang -complete=buffer -nargs=? Bd Bdelete<bang> <args>
nnoremap <Leader>q :Bdelete<CR>

" better-whitespace
au TermOpen * DisableWhitespace

" sneak
let g:sneak#label = 1

" lightline
set noshowmode

function! CocCurrentFunction()
    return get(b:, 'coc_current_function', '')
endfunction

let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'modified' ], [ 'filename', 'currentfunction' ] ],
      \   'right': [ [ 'cocstatus', 'readonly', ] ]
      \ },
      \ 'component_function': {
      \   'cocstatus': 'coc#status',
      \   'currentfunction': 'CocCurrentFunction'
      \ },
      \ }
