vim.opt.fillchars = { vert = '│', fold = '─', diff = '─' }
vim.opt.listchars = { tab = '»·', trail = '·' }
vim.opt.list = true

vim.opt.wrap = true
vim.opt.linebreak = true

vim.opt.colorcolumn = { '81', '82' }

vim.opt.signcolumn = 'yes:1'
vim.opt.number = true
vim.opt.scrolloff = 2
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.number = false
    vim.opt_local.scrolloff = 0
    vim.cmd('DisableWhitespace')
  end,
})

vim.opt.joinspaces = false
vim.opt.formatoptions:append '2'

vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.expandtab = true
vim.opt.tabstop = 8
vim.opt.shiftwidth = 4

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false

vim.opt.comments:remove '://'
vim.opt.comments:append { ':///', '://' }

-- We need a way to consistently get to normal mode no matter where we are,
-- ideally without having to leave the home row. Pick something that doesn't
-- seem to conflict with any control sequences in terminal emulators or any
-- utilities.
vim.keymap.set({ 'i', 't', 'c' }, '<C-j>', '<C-\\><C-n>')

vim.keymap.set('n', '<space>wp', ':b#<cr>')
vim.keymap.set({ 'n', 't', 'i' }, '<M-p>', function()
  vim.api.nvim_put({ vim.fn.bufname('#') }, "c", true, true)
end)

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'gitcommit', 'gitrebase' },
  callback = function(ev)
    vim.bo[ev.buf].bufhidden = 'delete'
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    local bufopts = { silent = true, buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, bufopts)
    vim.api.nvim_create_user_command('A', 'ClangdSwitchSourceHeader', {})
  end,
})

local delta_goto_file_at_line_number = function()
  local linenumber = vim.fn.expand('<cword>')
  local filename = string.gsub(vim.fn.getline(vim.fn.search('Δ ', 'bn')), 'Δ ', "", 1)
  vim.cmd(string.format('e +:%s %s', linenumber, filename))
end
vim.keymap.set('n', '<space>gf', delta_goto_file_at_line_number)

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require 'lazy'.setup 'plugins'
