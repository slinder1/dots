return {
  {
    'sainnhe/sonokai',
    priority = 1000,
    config = function()
      vim.o.termguicolors = true
      vim.g.sonokai_style = 'default'
      vim.g.sonokai_better_performance = 1
      vim.g.sonokai_dim_inactive_windows = 1
      vim.g.sonokai_diagnostic_virtual_text = 'colored'
      vim.cmd.colorscheme('sonokai')
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = 'lua',
    config = true,
  },
  'airblade/vim-gitgutter',
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      --vim.opt.cmdheight = 0
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
      require 'lualine'.setup {
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
                }, "c", true, true)
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
      { '<space>wd', ':close<cr>' },
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
      { '<space>e', vim.diagnostic.open_float },
      { '[d',       function() vim.diagnostic.jump({ count = -1 }) end },
      { ']d',       function() vim.diagnostic.jump({ count = 1 }) end },
      { '<space>q', vim.diagnostic.setloclist },
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
          vim.api.nvim_create_user_command('A', 'ClangdSwitchSourceHeader', {})
        end,
      })
      require 'lspconfig'.clangd.setup {}
      require 'lspconfig'.lua_ls.setup {}
      require 'lspconfig'.rust_analyzer.setup {}
    end,
  },
  'ntpeters/vim-better-whitespace',
  {
    'p00f/clangd_extensions.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    config = function()
      require 'clangd_extensions.inlay_hints'.setup_autocmd()
      require 'clangd_extensions.inlay_hints'.set_inlay_hints()
    end,
  },
  'tpope/vim-abolish',
  'tpope/vim-fugitive',
  'tpope/vim-sleuth',
  {
    'yazgoo/vmux',
    build = 'cargo install vmux',
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate",
    config = function()
      ---@diagnostic disable: missing-fields
      require("nvim-treesitter.configs").setup({
        ensure_installed = { 'c', 'lua', 'vim', 'vimdoc' },
        sync_install = false,
        highlight = { enable = true, },
        indent = { enable = true, },
      })
    end,
  },
  {
    'gbprod/yanky.nvim',
    keys = {
      { "p",     "<Plug>(YankyPutAfter)",      { "n", "x" } },
      { "P",     "<Plug>(YankyPutBefore)",     { "n", "x" } },
      { "gp",    "<Plug>(YankyGPutAfter)",     { "n", "x" } },
      { "gP",    "<Plug>(YankyGPutBefore)",    { "n", "x" } },
      { "<c-p>", "<Plug>(YankyPreviousEntry)", "n" },
      { "<c-n>", "<Plug>(YankyNextEntry)",     "n" },
    },
    opts = {
      ring = {
        update_register_on_cycle = true,
      },
    },
  }
}
