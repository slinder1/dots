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

local windowkeys = { 'h', 'j', 'k', 'l', 'v', 's', 'H', 'J', 'K', 'L' }
for _,key in pairs(windowkeys) do
  vim.keymap.set('n', '<space>w' .. key, '<C-w>' .. key)
end
vim.keymap.set('n', '<space>wd', '<C-w>c')

vim.keymap.set('n', '<space>wp', ':b#<cr>')
vim.keymap.set({ 'n', 't', 'i' }, '<M-p>', function()
  vim.api.nvim_put({ vim.fn.bufname('#') }, "c", true, true)
end)

-- jump to previous shell prompt
vim.keymap.set({ 'n', 'x' }, '<space>c', 'k?^[❮❯]<CR>')

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'gitcommit', 'gitrebase' },
  callback = function(ev)
    vim.bo[ev.buf].bufhidden = 'delete'
  end,
})

local delta_goto_file_at_line_number = function()
  local linenumber = vim.fn.expand('<cword>')
  local deltaline = vim.fn.search('Δ ', 'bn')
  if deltaline == 0 then return end
  local filename = string.gsub(vim.fn.getline(deltaline), 'Δ ', "", 1)
  vim.cmd(string.format('e +:%s %s', linenumber, filename))
end
vim.keymap.set('n', '<space>gf', delta_goto_file_at_line_number)

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable: undefined-field
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
