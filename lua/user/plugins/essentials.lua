local M = {
	"tamton-aquib/essentials.nvim",
}

function M.config()
	local cmd = vim.cmd

	-- Go to link
	cmd("command! Gotolink lua require('essentials').go_to_url()")
	cmd("command! Cheat lua require('essentials').cheat_sh()")
	cmd("command! Link lua require('essentials').null_pointer()")
	cmd("command! Runfile lua require('essentials').run_file()")
end

return M
