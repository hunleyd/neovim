function ColorMyPencils(color)
	color = color or "midnight"
	vim.cmd.colorscheme(color)
end
ColorMyPencils()
