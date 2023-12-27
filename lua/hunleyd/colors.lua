function ColorMyPencils(color)
	color = color or "modus"
	-- color = color or "nano-theme"
	-- color = color or "midnight"
	vim.o.background = "dark"
	vim.cmd.colorscheme(color)
end
ColorMyPencils()
