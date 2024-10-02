# direnv.nvim

A neovim wrapper around `direnv`, in pure lua.

## Why not use `direnv.vim`?

[direnv.vim](https://github.com/direnv/direnv.vim) is the officially blessed vim direnv plugin. This is a pure lua version, with some potential upsides (more control of load order), and some potential downsides (less well-established, less tested and potentially more complicated to configure, depending on what you're trying to achieve).

## Setup

:exclamation: Note - with `direnv`, load order is particularly important! `direnv`'s evaluation takes time, so if Neovim (via e.g. a language plugin's LSP) is expecting a certain environment to be provided by `direnv`, you want to make sure that `direnv.nvim` has executed before other code tries to use that environment.

(Aside for `nix` users: this is particularly pertinent if using `nix-direnv` to load LSP server binaries for your project. In this situation, you might also want to look into `nix_direnv_manual_reload`.)

### lazy.nvim

#### Defaults

In light of the point above, make sure that this entry is added early in your list of plugins, before any language-specific plugins that may require a `direnv` environment:

```lua
{ "actionshrimp/direnv.nvim", opts = {} }
...
```

##### What environment?

By default, the directory passed to direnv is the directory of the __current buffer__, rather than vim's current working directory (controlled by `:cd`, `:set autochdir`, etc). If you would rather have the direnv environment tied to the vim cwd, check out `opts.type = 'dir'` below.

##### Synchronous?

By default, `direnv.nvim` loads the direnv synchronously, which means that navigating to a specific buffer can take the same amount of time it would take to `cd` into a directory controlled by that `direnv` environment. This can be a bit jarring when switching buffers, particularly for longer environment load times, but ensures load order, as mentioned above. If you'd rather avoid this, look into the `async = true` option. With this set, the function `on_env_update` is called after the environment has loaded, which allows you to do any specific setup required.

#### All available options

The full list of available options and their defaults are loaded from [here](./lua/direnv-nvim/opts.lua). Here's a summary of them:

```
{
  type = "buffer", -- "buffer" | "dir"
    -- "buffer" direnv uses directory based on the current buffer. By default this is based around the 'FileType' autocmd.
    -- "dir" direnv uses directory based on vim's cwd (see this with `:pwd`). By default this is based around the 'DirChanged' autocmd.

  buffer_setup = ...
    -- allows you to control the type = 'buffer' setup's autocmd options.

  dir_setup = ...
    -- allows you to control the type = 'dir' setup's autocmd options.

  async = false, -- false | true
    -- if false, loading environment from direnv into vim is done synchronously. This will block the UI, so if the direnv setup takes a while, you may want to look into setting this to true.
    -- if true, vim will evaluate the direnv environment in the background, and then call the function passed as `opts.on_env_update` once evaluation is complete.

  on_hook_start = function () end,
    -- called just before executing direnv.

  on_env_update = function () end,
    -- called after direnv updates.

  on_no_direnv = function () end,
    -- called when no direnv is found for the current buffer.

  on_env_allowed = function () end,
    -- called when the direnv was manually allowed by the user (via :DirenvAllow).

  hook = {
    msg = "status", -- "status" | "diff" | nil
    -- message printed to the status line when direnv environment changes.
    -- - 'status' - shows the output of 'direnv status'.
    -- - 'diff' - shows the diff of environment variables.
    -- - nil - disables the message entirely.
  }
}
```

#### Manually firing the hook

If you'd rather try configuring the `autocmd`s yourself, you can use something like this:

```lua
{
    "actionshrimp/direnv.nvim", config = function() 
     vim.api.nvim_create_autocmd(..., {
         pattern = ...,
         callback = function ()
             require("direnv-nvim").hook(opts)
         end
     })
     end
}
```

There is a variant of the `hook` function, `hook_(dir)`, which takes the target `direnv` directory.

Note that currently `direnv.nvim`'s options still apply in some areas. You can also call the vim command `:DirenvHook` to fire the hook function manually.

The plugin also provides lua functions and vim commands for performing `direnv status` and `direnv allow`, via:

```
:DirenvStatus
:DirenvAllow
```

### LSP config examples

Here are some examples on how to load the direnv before the LSP starts:

``` lua
-- direnv-nvim.lua

-- Setup signals for when direnv.nvim is finished
require("direnv-nvim").setup({
	async = true, -- not strictly necessary
	on_env_update = function()
		vim.api.nvim_exec_autocmds("User", { pattern = "DirenvLoaded" })
	end,
	on_no_direnv = function()
		vim.api.nvim_exec_autocmds("User", { pattern = "DirenvNotFound" })
	end,
})
```

#### Using nvim-lspconfig

``` lua
-- lspconfig.lua

-- configure your LPSs the usual way, but adding `autostart = false`
require("lspconfig").lua_ls.setup({ autostart = false })
require("lspconfig").clangd.setup({ autostart = false })

-- Start lsp only after direnv.nvim is finished
vim.api.nvim_create_autocmd("User", {
	pattern = { "DirenvLoaded", "DirenvNotFound" }, -- this example starts the lsp when the direnv was loaded or when there is no .envrc found
	callback = function()
		vim.cmd("LspStart")
	end,
})
```

#### Using [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)

``` lua
vim.g.rustaceanvim = {
	server = {
		auto_attach = function(bufnr)
			vim.api.nvim_create_autocmd("User", {
				pattern = { "DirenvLoaded", "DirenvNotFound" },
				callback = function()
					require("rustaceanvim.lsp").start(bufnr)
				end,
				once = true,
			})
			return false
		end,
	},
}
```
