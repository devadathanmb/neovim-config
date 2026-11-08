-- Project-wide search and replace with a reviewable, editable results buffer.
return {
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    opts = {
      -- Scoped to the working directory like the other pickers; ripgrep from PATH.
      windowCreationCommand = "vsplit",
      transient = true,
    },
    keys = {
      { "<leader>sr", function() require("grug-far").open() end, desc = "Search and replace (project)" },
      { "<leader>sr", function() require("grug-far").with_visual_selection() end, mode = "x", desc = "Search and replace selection" },
      {
        "<leader>sw",
        function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end,
        desc = "Search and replace word under cursor",
      },
      {
        "<leader>sR",
        function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } }) end,
        desc = "Search and replace (current file)",
      },
    },
  },
}
