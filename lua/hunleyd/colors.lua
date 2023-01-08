function ColorMyPencils(color)
	color = color or "mellow"
	vim.cmd.colorscheme(color)

	-- transparent background
	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

	vim.g.mellow_italic_comments = true
	vim.g.mellow_italic_keywords = true
	vim.g.mellow_italic_variables = true
	vim.g.mellow_bold_booleans = true
	vim.g.mellow_bold_keywords = true
end

ColorMyPencils()
