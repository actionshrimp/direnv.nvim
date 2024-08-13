local M = {}
local OPTS = require("direnv-nvim/opts")
local LOADED = nil

local get_cwd = function()
	if OPTS.type == "buffer" then
		local buf = vim.api.nvim_buf_get_name(0)
		if vim.fn.filereadable(buf) == 1 then
			return vim.fs.dirname(buf)
		else
			return nil
		end
	elseif OPTS.type == "dir" then
		return vim.loop.cwd()
	end
end

M.status_ = function(cwd)
	local status_result = vim.system({ "direnv", "status", "--json" }, { text = true, cwd = cwd }):wait()
	local status = vim.json.decode(status_result.stdout)
	if status.state.loadedRC == vim.NIL then
		vim.cmd("redraw")
		vim.notify("direnv: environment clear")
	else
		vim.cmd("redraw")
		local loaded = status.state.loadedRC.allowed == 0
		local s = loaded and "loaded" or "blocked"
		vim.notify("direnv: environment from " .. status.state.loadedRC.path .. " loaded: " .. s)
		return loaded
	end
end
M.status = function()
	local cwd = get_cwd()
	if cwd ~= nil then
		M.status_(cwd)
	end
end
vim.api.nvim_create_user_command("DirenvStatus", M.status, { desc = "direnv status" })

M.allow_ = function(cwd)
	vim.system({ "direnv", "allow" }, { text = true, cwd = cwd }):wait()
	M.status_(cwd)
end

M.allow = function()
	local cwd = get_cwd()
	if cwd ~= nil then
		M.allow_(cwd)
	end
end
vim.api.nvim_create_user_command("DirenvAllow", M.allow, { desc = "direnv allow" })

M.hook_body = function(export_result)
	if export_result.stdout ~= "" then
		vim.notify(export_result.stdout)
		for k, v in pairs(vim.json.decode(export_result.stdout)) do
			if v == vim.NIL then
				vim.env[k] = nil
			else
				vim.env[k] = v
			end
		end

		if OPTS.hook.msg == "diff" then
			local display_msg = export_result.stderr
			if display_msg ~= nil then
				local lines = vim.split(display_msg, "\n", { trimempty = true })
				local diff_msg = lines[#lines]
				if string.len(diff_msg) > vim.o.columns then
					diff_msg = string.sub(diff_msg, 1, vim.o.columns - 20) .. "..."
				end
				vim.cmd("redraw")
				vim.notify(diff_msg, vim.log.levels.INFO)
			end
		elseif OPTS.hook.msg == "status" then
			M.status()
		end
		OPTS.on_env_update()
	end
end

M.hook_ = function(cwd)
	vim.notify("firing hook for " .. cwd)
	if OPTS.async then
		vim.system({ "direnv", "export", "json" }, { text = true, cwd = cwd }, function()
			vim.schedule(function()
				require("direnv-nvim").OPTS.on_env_update()
			end)
		end)
	else
		local res = vim.system({ "direnv", "export", "json" }, { text = true, cwd = cwd })
		local export_result = res:wait()
		M.hook_body(export_result)
	end
end

M.hook = function()
	local cwd = get_cwd()
	if cwd ~= nil then
		if M.status_(cwd) then
			M.hook_(cwd)
		end
	end
end
vim.api.nvim_create_user_command("DirenvHook", M.allow, { desc = "direnv hook" })

local setup_dir = function()
	vim.api.nvim_create_autocmd(OPTS.dir_setup.autocmd_event, {
		pattern = OPTS.dir_setup.autocmd_pattern,
		callback = function()
			M.hook()
		end,
	})
end

local setup_buffer = function()
	-- # TODO double firing due to this guy!
	vim.api.nvim_create_autocmd(OPTS.buffer_setup.autocmd_event, {
		pattern = OPTS.buffer_setup.autocmd_pattern,
		callback = function()
			M.hook()
		end,
	})
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*",
		callback = function()
			M.hook()
		end,
	})
end

M.setup = function(opts)
	OPTS = vim.tbl_deep_extend("force", OPTS, opts)
	M.OPTS = OPTS
	if OPTS.type == "buffer" then
		setup_buffer()
	end
	if OPTS.type == "dir" then
		setup_dir()
	end
end

return M
