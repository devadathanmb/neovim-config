local status_ok, jdtls = pcall(require, "jdtls")
if not status_ok then
	vim.notify("jdtls not found")
	return
end

-- Setup Workspace
local home = os.getenv("HOME")
local workspace_path = home .. "/.local/share/lunarvim/jdtls-workspace/"
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = workspace_path .. project_name

-- Determine OS
local os_config = "linux"
if vim.fn.has("mac") == 1 then
	os_config = "mac"
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

local status_cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not status_cmp_ok then
	return
end

capabilities.textDocument.completion.completionItem.snippetSupport = false
capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
local extendedClientCapabilities = jdtls.extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

local config = {
	cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xms1g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-javaagent:" .. home .. "/.local/share/nvim/mason/packages/jdtls/lombok.jar",
		"-jar",
		vim.fn.glob(home .. "/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
		"-configuration",
		home .. "/.local/share/nvim/mason/packages/jdtls/config_" .. os_config,
		"-data",
		workspace_dir,
	},
	on_attach = require("njan.lsp.handlers").on_attach,
	root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),
	capabilities = capabilities,
	settings = {
		java = {
			eclipse = {
				downloadSources = true,
			},
			maven = {
				downloadSources = true,
			},
			implementationsCodeLens = {
				enabled = true,
			},
			referencesCodeLens = {
				enabled = true,
			},
			references = {
				includeDecompiledSources = true,
			},
			inlayHints = {
				parameterNames = {
					enabled = "all", -- literals, all, none
				},
			},
			format = {
				enabled = false,
			},
		},
		format = {
			enabled = false,
		},
	},
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	pattern = { "*.java" },
	callback = function()
		local _, _ = pcall(vim.lsp.codelens.refresh)
	end,
})

jdtls.start_or_attach(config)
