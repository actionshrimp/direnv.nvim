local default_opts = {
	setup = {
		autocmd_event = "FileType",
		autocmd_pattern = "*",
	},
	hook = {
		msg = "status", -- "diff" | "status" | nil,
	},
}

return default_opts
