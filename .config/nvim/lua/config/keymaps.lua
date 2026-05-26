-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ─────────────────────────────────────────────────────────────────────────────
-- JetBrains-style shortcuts
--
-- These use the JB Linux/Windows defaults (Ctrl/Alt) so they work in terminal
-- nvim. Kitty is configured to translate macOS Cmd shortcuts to the same byte
-- sequences, so Cmd+B and Ctrl+B both fire the same action.
--
-- Vim defaults that get overridden (intentional, for JB muscle memory):
--   <C-b>  scroll half-page up    → go to definition
--   <C-e>  scroll one line down   → recent files
--   <C-d>  scroll half-page down  → duplicate line
--   <C-/>  no default             → toggle comment
-- ─────────────────────────────────────────────────────────────────────────────

local map = vim.keymap.set

local function lsp(method)
  return function()
    vim.lsp.buf[method]()
  end
end

local function picker(name)
  return function()
    local ok, snacks = pcall(require, "snacks")
    if ok and snacks.picker and snacks.picker[name] then
      snacks.picker[name]()
      return
    end
    local fallback = {
      files = "Telescope find_files",
      recent = "Telescope oldfiles",
      commands = "Telescope commands",
      grep = "Telescope live_grep",
    }
    vim.cmd(fallback[name] or "Telescope")
  end
end

-- Navigation ────────────────────────────────────────────────────────────────
map("n", "<C-b>", lsp("definition"), { desc = "JB: Go to definition" })
map("n", "<C-e>", picker("recent"), { desc = "JB: Recent files" })
map("n", "<A-o>", picker("files"), { desc = "JB: Find file (Cmd+Shift+O)" })
map("n", "<A-a>", picker("commands"), { desc = "JB: Find action (Cmd+Shift+A)" })
map("n", "<A-S-f>", picker("grep"), { desc = "JB: Find in path" })
map("n", "<leader>e", function()
  local pickers = Snacks.picker.get({ source = "explorer" })
  if pickers and #pickers > 0 then
    pickers[1]:focus()
  else
    Snacks.explorer({ pattern = "", search = "" })
  end
end, { desc = "Focus/open project tree" })
map("n", "<leader>E", function()
  local pickers = Snacks.picker.get({ source = "explorer" })
  if pickers and #pickers > 0 then
    pickers[1]:close()
  else
    Snacks.explorer({ pattern = "", search = "" })
  end
end, { desc = "Toggle project tree" })
map("n", "<leader>gS", function()
  Snacks.picker.git_status()
end, { desc = "Git status (sidebar)" })

-- Editing ───────────────────────────────────────────────────────────────────
-- Toggle comment (terminals usually send <C-/> as <C-_>)
map({ "n", "v" }, "<C-_>", "gcc", { remap = true, desc = "JB: Toggle comment" })
map({ "n", "v" }, "<C-/>", "gcc", { remap = true, desc = "JB: Toggle comment" })

-- Duplicate line / selection
map("n", "<C-d>", "yyp", { desc = "JB: Duplicate line" })
map("v", "<C-d>", "y`>pgv", { desc = "JB: Duplicate selection" })

-- Move line up/down (Alt+Shift+Up/Down) — works alongside LazyVim's Alt+j/k
map("n", "<A-S-Up>", "<cmd>m .-2<cr>==", { desc = "JB: Move line up" })
map("n", "<A-S-Down>", "<cmd>m .+1<cr>==", { desc = "JB: Move line down" })
map("v", "<A-S-Up>", ":m '<-2<cr>gv=gv", { desc = "JB: Move selection up" })
map("v", "<A-S-Down>", ":m '>+1<cr>gv=gv", { desc = "JB: Move selection down" })
map("i", "<A-S-Up>", "<esc><cmd>m .-2<cr>==gi", { desc = "JB: Move line up" })
map("i", "<A-S-Down>", "<esc><cmd>m .+1<cr>==gi", { desc = "JB: Move line down" })

-- Rename symbol (Shift+F6)
map("n", "<S-F6>", lsp("rename"), { desc = "JB: Rename symbol" })

-- Reformat (Cmd+Alt+L → Alt+L)
map({ "n", "v" }, "<A-l>", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "JB: Reformat code" })

-- Extend / shrink selection (treesitter incremental) — Alt+Up / Alt+Down
-- LazyVim wires these via treesitter-textobjects; we add explicit shortcuts.
map("n", "<A-Up>", function()
  pcall(vim.cmd, "TSNodeIncremental")
end, { desc = "JB: Extend selection" })

-- Folding ───────────────────────────────────────────────────────────────────
map("n", "<A-->", "zc", { desc = "JB: Fold block" })
map("n", "<A-=>", "zo", { desc = "JB: Unfold block" })
map("n", "<A-+>", "zo", { desc = "JB: Unfold block" })

-- Double-click in the gitsigns gutter → dialog with hunk actions.
-- Outside the gutter, fall back to default word selection.
map("n", "<2-LeftMouse>", function()
  local m = vim.fn.getmousepos()
  -- column == 0 ⇒ click was in sign/number/fold column, not on text.
  if m.column == 0 and m.line > 0 and m.winid ~= 0 then
    vim.api.nvim_set_current_win(m.winid)
    vim.api.nvim_win_set_cursor(m.winid, { m.line, 0 })
    vim.schedule(function()
      vim.ui.select(
        { "Preview hunk", "Reset hunk (restore from git)", "Stage hunk" },
        { prompt = "Hunk at line " .. m.line .. ":" },
        function(choice)
          if not choice then return end
          local gs = require("gitsigns")
          if choice == "Preview hunk" then
            gs.preview_hunk()
          elseif choice == "Reset hunk (restore from git)" then
            gs.reset_hunk()
          elseif choice == "Stage hunk" then
            gs.stage_hunk()
          end
        end
      )
    end)
  else
    vim.cmd("normal! viw")
  end
end, { desc = "JB: Gutter dbl-click → hunk dialog" })

-- Quick actions ─────────────────────────────────────────────────────────────
map({ "n", "v" }, "<A-CR>", lsp("code_action"), { desc = "JB: Code action (Alt+Enter)" })
map("n", "<A-p>", lsp("signature_help"), { desc = "JB: Parameter info (Cmd+P)" })
map("n", "<F1>", lsp("hover"), { desc = "JB: Quick docs" })
map("n", "<F2>", vim.diagnostic.goto_next, { desc = "JB: Next problem" })
map("n", "<S-F2>", vim.diagnostic.goto_prev, { desc = "JB: Previous problem" })
