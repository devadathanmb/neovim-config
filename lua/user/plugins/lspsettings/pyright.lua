return {
  settings = {
    pyright = {
      disableOrganizeImports = true,
      disableTaggedHints = true,
    },
    python = {
      analysis = {
        diagnosticMode = "off",
        typeCheckingMode = "off",
        diagnosticSeverityOverrides = {
          -- https://github.com/microsoft/pyright/blob/main/docs/configuration.md#type-check-diagnostics-settings
          reportUndefinedVariable = "none",
          reportAttributeAccessIssue = "none",
          reportOptionalMemberAccess = "none",
          reportArgumentType = "none",
          reportIncompatibleVariableOverride = "none",
          reportGeneralTypeIssues = "none",
          reportInvalidTypeForm = "none",
          reportCallIssue = "none",
          reportAssignmentType = "none",
        },
      },
    },
  },
}
