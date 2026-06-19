return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { replace_netrw = true },
      statuscolumn = {
        folds = { open = false, git_hl = false },
      },
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            auto_close = false,
            follow_file = true,
            jump = { close = false },
            layout = { preset = "sidebar", preview = false },
            actions = {
              focus_main = function(picker)
                if picker.main and vim.api.nvim_win_is_valid(picker.main) then
                  vim.api.nvim_set_current_win(picker.main)
                else
                  vim.cmd("wincmd p")
                end
              end,
            },
            win = {
              input = { keys = { ["<Esc>"] = { "focus_main", mode = { "n", "i" } } } },
              list = { keys = { ["<Esc>"] = "focus_main" } },
            },
          },
          git_status = {
            auto_close = false,
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
