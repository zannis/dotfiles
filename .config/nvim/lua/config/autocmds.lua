-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FocusLost", {
  group = vim.api.nvim_create_augroup("autosave_on_focuslost", { clear = true }),
  desc = "Autosave modified buffers when nvim loses focus",
  callback = function()
    if vim.bo.modified
      and vim.bo.buftype == ""
      and not vim.bo.readonly
      and vim.fn.expand("%") ~= ""
    then
      vim.cmd("silent! write")
    end
  end,
})

local autosave_timers = {}
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  group = vim.api.nvim_create_augroup("autosave_idle", { clear = true }),
  desc = "Autosave 5s after the last edit",
  callback = function(args)
    local buf = args.buf
    if autosave_timers[buf] then
      autosave_timers[buf]:stop()
      autosave_timers[buf]:close()
    end
    autosave_timers[buf] = vim.uv.new_timer()
    autosave_timers[buf]:start(5000, 0, vim.schedule_wrap(function()
      if autosave_timers[buf] then
        autosave_timers[buf]:close()
        autosave_timers[buf] = nil
      end
      if vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].modified
        and vim.bo[buf].buftype == ""
        and not vim.bo[buf].readonly
        and vim.api.nvim_buf_get_name(buf) ~= ""
      then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("silent! write")
        end)
      end
    end))
  end,
})
