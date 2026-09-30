vim.opt.fillchars = { vert = '│', fold = '─', diff = '─' }
vim.opt.listchars = { tab = '»·', trail = '·' }
vim.opt.list = true

vim.opt.wrap = true
vim.opt.linebreak = true

vim.opt.colorcolumn = { '81', '82' }

vim.opt.signcolumn = 'yes:1'
vim.opt.number = true
vim.opt.scrolloff = 2

vim.opt.joinspaces = false
vim.opt.formatoptions:append '2'

vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 2

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false

vim.opt.comments:remove '://'
vim.opt.comments:append { ':///', '://' }

require('vim._core.ui2').enable {}


-- Some plugins use terminal buffers, leave them be
local term_likely_managed = function(buf)
  local b = vim.b[buf]
  local bo = vim.bo[buf]
  return not bo.buflisted or b.guh or bo.filetype:match("^Telescope.*")
end
local term_group = vim.api.nvim_create_augroup('UserTerm', {})
vim.api.nvim_create_autocmd('TermOpen', {
  group = term_group,
  callback = function(ev)
    if term_likely_managed(ev.buf) then
      return
    end
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.number = false
    vim.opt_local.scrolloff = 0
    vim.cmd('DisableWhitespace')
    vim.cmd('keepalt file term-' .. vim.fn.rand())
  end,
})
-- Replace the default TermClose behavior in the nvim.terminal augroup with our
-- own vim-bbye-like behavior
vim.api.nvim_clear_autocmds({ group = 'nvim.terminal', event = 'TermClose' })
vim.api.nvim_create_autocmd('TermClose', {
  group = term_group,
  callback = function(ev)
    if term_likely_managed(ev.buf) then
      return
    end
    -- FIXME: mimic bbye more accurately by finding all other active windows
    -- with the same now-closing term buffer and giving them a new buffer too.
    --
    -- Alternatively, scrape the scrollback into a temporary buffer a-la
    -- discreesteakmachine in
    -- https://www.reddit.com/r/neovim/comments/1se2x4q/differences_in_how_terminal_closing_is_handled/
    vim.cmd.enew()
    vim.cmd.bd('#')
    vim.bo.swapfile = false
    vim.bo.bufhidden = 'wipe'
    vim.bo.buftype = ''
    vim.bo.buflisted = false
  end,
})

local termfeatures = vim.g.termfeatures or {}
termfeatures.osc52 = false
vim.g.termfeatures = termfeatures

-- vim.opt.title = true
-- vim.opt.titlestring = vim.fs.basename(vim.fn.getcwd())
-- vim.api.nvim_create_autocmd('DirChanged', {
--   pattern = { 'global' },
--   callback = function(ev)
--     -- TODO: update titlestring
--   end,
-- })


vim.g.neovide_fullscreen = true
vim.keymap.set("n", "<M-CR>", function() vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen end)
vim.o.winborder = 'rounded'
vim.g.neovide_floating_corner_radius = 0.1
vim.opt.guifont = 'CommitMono Nerd Font Mono:h12:w0:#e-antialias:#h-full'
local get_hl = function(name)
  return vim.api.nvim_get_hl(0, {id=vim.api.nvim_get_hl_id_by_name(name)})
end
vim.g.neovide_title_background_color = string.format("%x", get_hl('Normal').bg)
vim.g.neovide_title_text_color = string.format("%x", get_hl('Normal').fg)
vim.g.neovide_detach_on_quit = 'always_detach'
vim.g.neovide_hide_mouse_when_typing = true
vim.g.neovide_cursor_animation_length = 0
vim.g.neovide_scroll_animation_length = 0.1
local start_scale = 0.9
vim.g.neovide_scale_factor = start_scale
local change_scale_factor = function(delta)
  vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
end
vim.keymap.set("n", "<C-0>", function() vim.g.neovide_scale_factor = start_scale end)
vim.keymap.set("n", "<C-=>", function() change_scale_factor(1.25) end)
vim.keymap.set("n", "<C-->", function() change_scale_factor(1/1.25) end)

local modes = { 'n', 't', 'i' }
vim.keymap.set(modes, '<C-a>c', function() vim.cmd.tabnew() end)
vim.keymap.set(modes, '<C-a>d', function() vim.cmd.tabclose() end)
vim.keymap.set(modes, '<C-a>n', function() vim.cmd.tabnext() end)
vim.keymap.set(modes, '<C-a>p', function() vim.cmd.tabprev() end)
for i = 1, 9 do
  vim.keymap.set(modes, '<C-a>' .. i, function() vim.cmd.tabnext(i) end)
end

-- We need a way to consistently get to normal mode no matter where we are,
-- ideally without having to leave the home row. Pick something that doesn't
-- seem to conflict with any control sequences in terminal emulators or any
-- utilities.
vim.keymap.set({ 'i', 't', 'c' }, '<C-j>', '<C-\\><C-n>')

vim.keymap.set({ 'n' }, '<C-S-v>', '"+p')
vim.keymap.set({ 'i', 'c' }, '<C-S-v>', '<C-r>+')
vim.keymap.set({ 't' }, '<C-S-v>', '<C-\\><C-n>"+pi')
vim.keymap.set({ 'n' }, '<C-S-c>', '"+yy')
vim.keymap.set({ 'v' }, '<C-S-c>', '"+y')

local windowkeys = { 'h', 'j', 'k', 'l', 'v', 's', 'H', 'J', 'K', 'L' }
for _, key in ipairs(windowkeys) do
  vim.keymap.set('n', '<space>w' .. key, '<C-w>' .. key)
end
vim.keymap.set('n', '<space>wd', '<C-w>c')

vim.keymap.set('n', '<space>wp', ':b#<cr>')
vim.keymap.set({ 'n', 't', 'i' }, '<M-p>', function()
  vim.api.nvim_put({ vim.fn.bufname('#') }, "c", true, true)
end)

-- jump to previous shell prompt
-- TODO support proper prompt markers when available
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
      vim.api.nvim_set_hl(0, 'GuhDiffFile', { link = 'DiffChange' })
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
      local tabline_config = {
        lualine_a = {
          {
            'tabs',
            mode = 2,
            show_modified_status = false,
            fmt = function(name, context)
              return vim.fs.basename(vim.fn.getcwd(-1, context.tabnr))
            end,
          }
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      }
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
        options = {
          theme = 'sonokai',
          always_show_tabline = true,
        },
        tabline = tabline_config,
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
      local put = function(prompt_bufnr)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local v = ''
        if #current_picker:get_multi_selection() > 0 then
          local values = vim.iter(ipairs(current_picker:get_multi_selection())):map(function(_, v)
            return v.value
          end):totable()
          v = table.concat(values, ' ')
        else
          v = action_state.get_selected_entry().value
        end
        actions.close(prompt_bufnr)
        vim.api.nvim_put({v}, 'c', true, true)
      end
      telescope.setup {
        defaults = {
          mappings = {
            i = {
              ['<C-j>'] = function(_)
                vim.cmd.stopinsert()
              end,
              ['<C-p>'] = put,
              ['<C-s>'] = actions.select_all,
              ['<C-d>'] = actions.drop_all,
            },
            n = {
              ['<C-p>'] = put,
              ['<C-s>'] = actions.select_all,
              ['<C-d>'] = actions.drop_all,
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
      modes = { 'n', 't', 'i' }
      vim.keymap.set(modes, '<C-f>', function()
        telescope.extensions.find_pickers.find_pickers {}
      end)
      vim.keymap.set(modes, '<C-o>', function()
        builtin.buffers { only_cwd = true }
      end)
      vim.keymap.set(modes, '<C-S-o>', function()
        builtin.buffers {}
      end)
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
      { '<space>d', ':Bdelete<cr>' },
    },
    config = function()
      for _, name in ipairs({ 'Bd', 'BD' }) do
        vim.api.nvim_create_user_command(name, 'Bdelete<bang>', {
          nargs = '?',
          bang = true,
          complete = 'buffer',
        })
      end
    end,
  },
  {
    'neovim/nvim-lspconfig',
    keys = {
      { '[d',        function() vim.diagnostic.jump({ count = -1 }) end },
      { ']d',        function() vim.diagnostic.jump({ count = 1 }) end },
      { '[e',        function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end },
      { ']e',        function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end },
      { '<space>e',  vim.diagnostic.open_float },
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
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
          vim.keymap.set('n', '<space>lD', vim.lsp.buf.type_definition, bufopts)
          vim.keymap.set('n', '<space>lr', vim.lsp.buf.rename, bufopts)
          vim.keymap.set('n', '<space>la', vim.lsp.buf.code_action, bufopts)
          vim.keymap.set({ 'n', 'v' }, '<space>li', function()
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
    'stevearc/conform.nvim',
    config = function()
      require('conform').setup({
        formatters_by_ft = {
          cpp = { 'clang-format' },
          rust = { 'rustfmt' },
          ['*'] = { 'trim_whitespace' },
        },
      })
      vim.o.formatexpr = 'v:lua.require("conform").formatexpr()'
    end,
  },
  {
    'p00f/clangd_extensions.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    opts = {},
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
    url = "https://codeberg.org/andyg/leap.nvim",
    config = function()
      local leap = require('leap')
      vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap)')
      vim.keymap.set('n',             'S', '<Plug>(leap-from-window)')
      leap.opts.preview_filter =
          function(ch0, ch1, ch2)
            return not (
              ch1:match('%s') or
              ch0:match('%a') and ch1:match('%a') and ch2:match('%a')
            )
          end
      leap.opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }
      leap.opts.safe_labels = {}
      leap.opts.labels = 'hjklhgfdsaqwerpoizxcv/.,mn'
    end,
  },
  'airblade/vim-gitgutter',
  'ntpeters/vim-better-whitespace',
  'tpope/vim-abolish',
  'tpope/vim-fugitive',
  'tpope/vim-sleuth',
  {
    'justinmk/guh.nvim',
    lazy = false,
    keys = {
      { 'go', '<cmd>tab Guh .<cr>', 'n' },
    },
  },
  'barrettruth/diffs.nvim',
  {
    'nvim-treesitter/nvim-treesitter-context',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    lazy = false,
    keys = {
      { '<space>lc', '<cmd>TSContext toggle<cr>', { 'n', 'v' } },
    },
    opts = {
      enable = false,
      mode = 'topline',
    },
  },
}

require('lazy').setup({
  spec = spec,
  defaults = { lazy = false },
  change_detection = { enabled = false },
})
