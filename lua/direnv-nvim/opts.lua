local default_opts = {
	type = "buffer", -- "buffer" | "dir"
	buffer_setup = {
		autocmd_event = "BufEnter",
		autocmd_pattern = "*",
	},
	dir_setup = {
		autocmd_event = "DirChanged",
		autocmd_pattern = "*",
	},
	async = false,
	hook = {
		msg = "status", -- "diff" | "status" | nil,
	},
	on_direnv_finished_opts = {
		pattern = { "DirenvReady", "DirenvNotFound" },
	},
	on_direnv_finished = nil,
}

return default_opts
