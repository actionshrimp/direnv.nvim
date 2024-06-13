local M = {}

local get_cwd = function()
	local buf = vim.api.nvim_buf_get_name(0)
	if vim.fn.filereadable(buf) == 1 then
		return vim.fs.dirname(buf)
	else
		return nil
	end
end

M.status = function()
	local cwd = get_cwd()
	if cwd ~= nil then
		local status_result = vim.system({ "direnv", "status", "--json" }, { text = true, cwd = get_cwd() }):wait()
		local status = vim.json.decode(status_result.stdout)
		-- print(status_result.stdout)
		-- print(vim.inspect(status))
		if status.state.loadedRC == vim.NIL then
			vim.cmd("redraw")
			vim.notify("direnv: environment clear")
		else
			vim.cmd("redraw")
			vim.notify("direnv: environment from: " .. status.state.loadedRC.path)
		end
	end
end

M.hook = function(opts)
	local cwd = get_cwd()
	if cwd ~= nil then
		local export_result = vim.system({ "direnv", "export", "json" }, { text = true, cwd = cwd }):wait()
		if export_result.stdout ~= "" then
			for k, v in pairs(vim.json.decode(export_result.stdout)) do
				if v == vim.NIL then
					vim.env[k] = nil
				else
					vim.env[k] = v
				end
			end

			if opts.hook.msg == "diff" then
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
			elseif opts.hook.msg == "status" then
				M.status()
			end
		end
	end
end

M.setup = function(opts)
	opts = vim.tbl_deep_extend("force", require("direnv-nvim/opts"), opts)
	if opts == nil or opts == {} then
		opts = require("direnv-nvim/opts")
	end
	vim.api.nvim_create_autocmd(opts.setup.autocmd_event, {
		pattern = opts.setup.autocmd_pattern,
		callback = function()
			M.hook(opts)
		end,
	})
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*",
		callback = function()
			M.hook(opts)
		end,
	})
end

return M
