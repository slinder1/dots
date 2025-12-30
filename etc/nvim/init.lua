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
if not vim.uv.fs_stat(lazypath) then
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

local spec = {
  {
    'sainnhe/sonokai',
    priority = 1000,
    config = function()
      vim.o.termguicolors = true
      vim.g.sonokai_style = 'default'
      vim.g.sonokai_better_performance = 1
      vim.g.sonokai_dim_inactive_windows = 0
      vim.g.sonokai_diagnostic_virtual_text = 'colored'
      vim.cmd.colorscheme('sonokai')
    end,
  },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    config = true,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      vim.opt.laststatus = 3
      vim.opt.showmode = false
      local sections_config = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = {},
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      }
      local winbar_config = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      }
      require('lualine').setup {
        options = { theme = 'sonokai', },
        sections = sections_config,
        inactive_sections = sections_config,
        winbar = winbar_config,
        inactive_winbar = winbar_config,
      }
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'keyvchan/telescope-find-pickers.nvim',
      'debugloop/telescope-undo.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', },
      'gbprod/yanky.nvim',
    },
    config = function()
      local telescope = require 'telescope'
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'
      local builtin = require 'telescope.builtin'
      local sorters = require 'telescope.sorters'
      telescope.setup {
        defaults = {
          mappings = {
            i = {
              ['<C-j>'] = function(_)
                vim.cmd.stopinsert()
              end,
              ['<M-p>'] = function(prompt_bufnr)
                actions.close(prompt_bufnr)
                vim.api.nvim_put({
                  action_state.get_selected_entry().value
                }, 'c', true, true)
              end,
            },
          },
        },
        pickers = {
          builtin = {
            previewer = false,
          },
          buffers = {
            ignore_current_buffer = true,
            sort_mru = true,
          },
          git_commits = {
            git_command = { 'git', 'log', '-16', '--pretty=oneline', '--decorate' },
            sorter = sorters.fuzzy_with_index_bias {},
          },
        },
      }
      -- Lazy loading would make find_pickers essentially useless until
      -- the extensions are activated by some other means, so load eagerly
      for _, ext in ipairs({ 'find_pickers', 'undo', 'fzf', 'yank_history' }) do
        telescope.load_extension(ext)
      end
      vim.cmd.cnoreabbrev('T', 'Telescope')
      local modes = { 'n', 't', 'i' }
      vim.keymap.set(modes, '<C-f>', function()
        telescope.extensions.find_pickers.find_pickers {}
      end)
      vim.keymap.set(modes, '<C-o>', builtin.buffers)
      modes = { 'n' }
      vim.keymap.set(modes, '<space><space>f', builtin.find_files)
      vim.keymap.set(modes, '<space><space>g', builtin.live_grep)
      vim.keymap.set(modes, '<space><space>r', builtin.registers)
      vim.keymap.set(modes, '<space><space>h', builtin.help_tags)
      vim.keymap.set(modes, '<space><space>u', function()
        telescope.extensions.undo.undo {}
      end)
      vim.keymap.set(modes, '<space><space>y', function()
        telescope.extensions.yank_history.yank_history {}
      end)
    end,
  },
  {
    'moll/vim-bbye',
    keys = {
      { '<space>d',  ':Bdelete<cr>' },
    },
    config = function()
      vim.api.nvim_create_user_command('Bd', 'Bdelete<bang>', {
        nargs = '?',
        bang = true,
        complete = 'buffer',
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    keys = {
      { '[d',       function() vim.diagnostic.jump({ count = -1 }) end },
      { ']d',       function() vim.diagnostic.jump({ count = 1 }) end },
      { '[e',       function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end },
      { ']e',       function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end },
      { '<space>e', vim.diagnostic.open_float },
      { '<space>le', vim.diagnostic.setloclist },
    },
    config = function()
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
          vim.keymap.set('n', '<space>lD', vim.lsp.buf.type_definition, bufopts)
          vim.keymap.set('n', '<space>lr', vim.lsp.buf.rename, bufopts)
          vim.keymap.set('n', '<space>la', vim.lsp.buf.code_action, bufopts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
          vim.keymap.set({'n', 'v'}, '<space>lf', function()
            vim.lsp.buf.format {}
          end, bufopts)
          vim.keymap.set({'n', 'v'}, '<space>li', function()
            local opts = { bufnr = 0 }
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(opts), opts)
          end, bufopts)
          vim.api.nvim_create_user_command('A', 'ClangdSwitchSourceHeader', {})
        end,
      })
      vim.lsp.enable('clangd')
      vim.lsp.enable('lua_ls')
      vim.lsp.enable('rust_analyzer')
      vim.lsp.config('tblgen_lsp_server', {
          cmd = { 'tblgen-lsp-server', '--tablegen-compilation-database=tablegen_compile_commands.yml' },
      })
    end,
  },
  {
    'p00f/clangd_extensions.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    opts = {},
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      ---@diagnostic disable: missing-fields
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'c', 'lua', 'vim', 'vimdoc', 'tablegen' },
        sync_install = false,
        highlight = { enable = true, },
        indent = { enable = true, },
      })
    end,
  },
  {
    'gbprod/yanky.nvim',
    keys = {
      { 'p',     '<Plug>(YankyPutAfter)',      { 'n', 'x' } },
      { 'P',     '<Plug>(YankyPutBefore)',     { 'n', 'x' } },
      { 'gp',    '<Plug>(YankyGPutAfter)',     { 'n', 'x' } },
      { 'gP',    '<Plug>(YankyGPutBefore)',    { 'n', 'x' } },
      { '<c-p>', '<Plug>(YankyPreviousEntry)', 'n' },
      { '<c-n>', '<Plug>(YankyNextEntry)',     'n' },
    },
    opts = {
      ring = {
        update_register_on_cycle = true,
      },
    },
  },
  {
    'ggandor/leap.nvim',
    config = function ()
      require('leap').set_default_mappings()
      require('leap').opts.preview_filter =
        function (ch0, ch1, ch2)
          return not (
            ch1:match('%s') or
            ch0:match('%a') and ch1:match('%a') and ch2:match('%a')
          )
        end
      require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }
      require('leap').opts.safe_labels = {}
      require('leap').opts.labels = 'hjklhgfdsaqwerpoizxcv/.,mn'
    end,
  },
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
  },
  'airblade/vim-gitgutter',
  'ntpeters/vim-better-whitespace',
  'tpope/vim-abolish',
  'tpope/vim-fugitive',
  'tpope/vim-sleuth',
}

require('lazy').setup({
  spec = spec,
  defaults = { lazy = false },
  change_detection = { enabled = false },
})
