---@class DirenvAutocmdSetup
---@field autocmd_event string
---@field autocmd_pattern string

---@class DirenvHook
---@field msg "status" | "diff" | nil

---@class DirenvOnFinishedOpts
---@field pattern table<string>

---@class DirenvOnFinishedCallbackArgs
---@field buffer number
---@field filetype string

---@class DirenvOpts
---@field type "buffer" | "dir"
---@field buffer_setup DirenvAutocmdSetup
---@field dir_setup DirenvAutocmdSetup
---@field async boolean
---@field get_cwd (fun(): string | nil) | nil
---@field hook DirenvHook
---@field on_direnv_finished_opts DirenvOnFinishedOpts
---@field on_direnv_finished fun(args: DirenvOnFinishedCallbackArgs) | nil
local default_opts = {
	type = "buffer",
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
		msg = "status",
	},
	on_direnv_finished_opts = {
		pattern = { "DirenvReady", "DirenvNotFound" },
	},
	on_direnv_finished = nil,
}

return default_opts
