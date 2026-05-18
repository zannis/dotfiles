-- Wire oxlint into nvim-lint for JS/TS files.
-- oxlint output (-f unix): `path:line:col: message [Severity]`
return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local lint = require("lint")
      local from_pattern = require("lint.parser").from_pattern

      lint.linters.oxlint = {
        cmd = "oxlint",
        stdin = false,
        args = { "-f", "unix", "--quiet" },
        stream = "both",
        ignore_exitcode = true,
        parser = from_pattern(
          "([^:]+):(%d+):(%d+): (.+) %[(%w+)%]",
          { "file", "lnum", "col", "message", "severity" },
          {
            ["Error"] = vim.diagnostic.severity.ERROR,
            ["Warning"] = vim.diagnostic.severity.WARN,
          },
          { source = "oxlint" }
        ),
      }

      opts.linters_by_ft = opts.linters_by_ft or {}
      for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact", "vue", "svelte" }) do
        opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
        table.insert(opts.linters_by_ft[ft], "oxlint")
      end
      return opts
    end,
  },
}
