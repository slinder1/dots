return {
  {
    'sainnhe/sonokai',
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.termguicolors = true
      vim.g.sonokai_style = 'default'
      vim.g.sonokai_better_performance = 1
      vim.g.dim_inactive_windows = 1
      vim.g.diagnostic_virtual_text = 'colored'
      vim.cmd.colorscheme('sonokai')
    end,
  },
  'airblade/vim-gitgutter',
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      vim.opt.cmdheight = 0
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
      'gbprod/yanky.nvim',
      'debugloop/telescope-undo.nvim',
    },
    config = function()
      local telescope = require 'telescope'
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'
      telescope.setup {
        defaults = {
          mappings = {
            i = {
              ['<M-p>'] = function(prompt_bufnr)
                actions.close(prompt_bufnr)
                vim.api.nvim_put({
                  action_state.get_selected_entry().value
                }, "c", true, true)
              end,
            },
          },
        },
        extensions = {
          undo = {},
          yank_history = {},
        },
        pickers = {
          buffers = {
            ignore_current_buffer = true,
            sort_mru = true,
          },
        },
      }
      local builtin = require 'telescope.builtin'
      local modes = { 'n', 't', 'i' }
      --vim.keymap.set(modes, '<C-g>', builtin.live_grep)
      vim.keymap.set(modes, '<C-o>', builtin.buffers)
      vim.keymap.set(modes, '<C-p>', builtin.find_files)
      modes = { 'n' }
      vim.keymap.set(modes, '<space>th', builtin.help_tags)
      vim.keymap.set(modes, '<space>tu', function()
        telescope.extensions.undo.undo {}
      end)
      vim.keymap.set(modes, '<space>ty', function()
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
    dependencies = {
      { 'folke/neodev.nvim', config = true },
    },
    keys = {
      { '<space>e', vim.diagnostic.open_float },
      { '[d',       vim.diagnostic.goto_prev },
      { ']d',       vim.diagnostic.goto_next },
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
          vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
          vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
          vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
          vim.keymap.set('n', '<space>f', function()
            vim.lsp.buf.format { async = true }
          end, bufopts)
          vim.api.nvim_create_user_command('A', 'ClangdSwitchSourceHeader', {})
        end,
      })
      require 'lspconfig'.clangd.setup {}
      require 'lspconfig'.lua_ls.setup {}
    end,
  },
  'ntpeters/vim-better-whitespace',
  {
    'nvim-treesitter/nvim-treesitter',
    opts = {
      ensure_installed = { "lua", "cpp" },
      highlight = { enable = true },
    },
  },
  {
    'p00f/clangd_extensions.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    config = function()
      require 'clangd_extensions.inlay_hints'.setup_autocmd()
      require 'clangd_extensions.inlay_hints'.set_inlay_hints()
    end,
  },
  {
    'gbprod/yanky.nvim',
    config = function()
      require 'yanky'.setup()
      vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
      vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
      vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
      vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")
      vim.keymap.set("n", "<c-n>", "<Plug>(YankyCycleForward)")
      vim.keymap.set("n", "<c-m>", "<Plug>(YankyCycleBackward)")
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      require 'cmp'.setup {
        mapping = require 'cmp'.mapping.preset.insert {
          ['<C-b>'] = require 'cmp'.mapping.scroll_docs(-4),
          ['<C-f>'] = require 'cmp'.mapping.scroll_docs(4),
          ['<C-Space>'] = require 'cmp'.mapping.complete(),
          ['<C-e>'] = require 'cmp'.mapping.abort(),
          ['<CR>'] = require 'cmp'.mapping.confirm({ select = true }),
        },
        sources = require 'cmp'.config.sources {
          { name = 'nvim_lsp' },
        },
      }
    end
  },
  'tpope/vim-abolish',
  'tpope/vim-fugitive',
  'tpope/vim-sleuth',
  {
    'yazgoo/vmux',
    build = 'cargo install vmux',
  },
}
