local M = {}
M.setup = function()
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*",
		callback = function(ev)
			local cmd = { "direnv", "export", "json" }
			local buf = vim.api.nvim_buf_get_name(0)
			local bufdir = vim.fs.dirname(buf)
			local result = vim.system(cmd, { text = true, cwd = bufdir }):wait()
			local display_msg = result.stderr
			print(display_msg)
			if result.stdout == "" then
				print("in sync already")
			else
				for k, v in pairs(vim.json.decode(result.stdout)) do
					if vim.startswith(v, "-") then
						vim.env[k] = nil
					else
						vim.env[k] = v
					end
				end
			end
		end,
	})
	-- local exports = vim.split(result.stdout, ";")
	-- print("exports22")
	-- print(vim.inspect(exports))
	-- local kvs = {}
	-- for _, export in pairs(exports) do
	-- 	if export ~= "" then
	-- 		local body = string.sub(export, 8)
	-- 		local kv = vim.split(body, "=")
	-- 		local k = kv[1]
	-- 		local v = kv[2]
	-- 		print(v)
	-- 		if vim.startswith(v, "$'-") then
	-- 			kvs[k] = { "remove", string.sub(v, 4, string.len(v)) }
	-- 		elseif vim.startswith(v, "$'") then
	-- 			kvs[k] = { "add", string.sub(v, 3, string.len(v)) }
	-- 		end
	-- 	end
	-- end
	--
	-- print(vim.inspect(kvs))
	-- for k, v in pairs(kvs) do
	-- 	if v[1] == "add" then
	-- 		vim.env[k] = v[2]
	-- 	elseif v[1] == "remove" then
	-- 		vim.env[k] = nil
	-- 	end
	-- end
end
return M
