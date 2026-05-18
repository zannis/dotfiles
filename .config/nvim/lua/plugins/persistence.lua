-- Auto-restore the per-cwd session when nvim launches with no file args.
-- Combined with `zj`, every project session opens nvim back where you left off.
return {
  {
    "folke/persistence.nvim",
    lazy = false,
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("persistence-auto-load", { clear = true }),
        nested = true,
        callback = function()
          -- only when launched bare (no files passed, no stdin)
          if vim.fn.argc() ~= 0 then return end
          if vim.g.started_with_stdin then return end
          require("persistence").load()
        end,
      })
    end,
  },
}
