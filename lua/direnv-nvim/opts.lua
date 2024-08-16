local default_opts = {
	type = "buffer", -- "buffer" | "dir"
	buffer_setup = {
		autocmd_event = "FileType",
		autocmd_pattern = "*",
	},
	dir_setup = {
		autocmd_event = "DirChanged",
		autocmd_pattern = "*",
	},
	async = false,
	on_env_update = function() end,
	hook = {
		msg = "status", -- "diff" | "status" | nil,
	},
}

return default_opts
