vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.syntax = 'on'

vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Выход из Insert mode' })

-- Не подставлять текст выделенного варианта автокомплита в буфер,
-- пока не подтвердишь явно (<C-y>) — иначе печатать поверх меню странно.
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert' }

-- Плагины через встроенный в Neovim 0.12+ менеджер vim.pack.
-- nvim-lspconfig: готовые описания LSP-серверов (в т.ч. zls) для новой
-- нативной vim.lsp.config/vim.lsp.enable API.
vim.pack.add({
  { src = 'https://github.com/neovim/nvim-lspconfig' },
})

vim.lsp.enable('zls')

-- Автокомплит через встроенный vim.lsp.completion (Neovim 0.11+):
-- меню всплывает само при вводе, без сторонних плагинов.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
  end,
})

-- zig fmt при сохранении (zls выполняет форматирование через LSP).
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.zig', '*.zon' },
  callback = function() vim.lsp.buf.format({ async = false }) end,
})
