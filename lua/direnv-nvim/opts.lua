local default_opts = {
	setup = {
		autocmd_event = "FileType",
		autocmd_pattern = "*",
	},
	hook = {
		msg = "status", -- "diff" | "status",
	},
}

return default_opts
