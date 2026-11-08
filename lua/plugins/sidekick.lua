return {
  {
    "folke/sidekick.nvim",
    opts = {
      nes = { enabled = false },
      cli = { watch = false, win = { layout = "right" } },
    },
    keys = {
      { "<leader>aa", function() require("sidekick.cli").toggle() end, desc = "Toggle agent panel" },
      { "<leader>as", function() require("sidekick.cli").select({ filter = { installed = true } }) end, desc = "Select agent" },
      { "<leader>ad", function() require("sidekick.cli").close() end, desc = "Detach agent session" },
      { "<leader>af", function() require("sidekick.cli").send({ msg = "{file}" }) end, desc = "Send file to agent" },
      { "<leader>at", function() require("sidekick.cli").send({ msg = "{this}" }) end, mode = { "n", "x" }, desc = "Send context to agent" },
      { "<leader>ap", function() require("sidekick.cli").prompt() end, mode = { "n", "x" }, desc = "Agent prompts" },
    },
  },
}
