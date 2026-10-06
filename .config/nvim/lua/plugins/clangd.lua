return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          mason = false,
          cmd = {
            "/bin/clangd",
            "--background-index",
            "--background-index-priority=low",
            "--header-insertion=never",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--pch-storage=memory",
            -- lets clangd invoke the cross gcc to learn its target-specific
            -- builtin defines/include paths (kernel arm64 cross builds)
            "--query-driver=/usr/bin/aarch64-linux-gnu-gcc*,/usr/bin/gcc*,/usr/bin/clang*",
          },
        },
      },
    },
  },
}
