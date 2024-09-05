function ColorMyPencils(color)
	color = color or "flow"
	vim.o.background = "dark"
    require("flow").setup{
        aggressive_spell = true,
        fluo_color = 'yellow',
        mode = "normal",
        transparent = false,
    }
	vim.cmd.colorscheme(color)
end
ColorMyPencils()
