function ColorMyPencils(color)
	color = color or "cyberdream"
	vim.o.background = "dark"
	vim.cmd.colorscheme(color)
end
ColorMyPencils()
