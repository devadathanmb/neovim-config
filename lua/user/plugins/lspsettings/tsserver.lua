return {
  init_options = {
    preferences = {
      -- Apparently this being true slows down lsp
      includeCompletionsForModuleExports = false,
      skipLibCheck = true,
    },
  },
}
