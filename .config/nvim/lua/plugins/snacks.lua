return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { replace_netrw = true },
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            auto_close = false,
            follow_file = true,
            jump = { close = false },
            layout = { preset = "sidebar", preview = false },
          },
        },
      },
    },
    -- auto-open on VimEnter disabled while debugging cmd+1
    -- init = function()
    --   vim.api.nvim_create_autocmd("VimEnter", {
    --     callback = function()
    --       if vim.fn.argc() <= 1 then
    --         vim.schedule(function() Snacks.explorer() end)
    --       end
    --     end,
    --   })
    -- end,
  },
}
