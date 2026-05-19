-- Pin neo-tree's root to the directory nvim was opened in (cwd).
-- No auto-following the current file, no jumping root when buffers change dir.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      follow_current_file = { enabled = false },
      filesystem = {
        bind_to_cwd = true,
        follow_current_file = { enabled = false },
        cwd_target = {
          sidebar = "global",
          current = "global",
        },
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },
}
