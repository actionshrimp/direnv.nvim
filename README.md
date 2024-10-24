# direnv.nvim

A neovim wrapper around `direnv`, in pure lua.

## Why not use `direnv.vim`?

[direnv.vim](https://github.com/direnv/direnv.vim) is the officially blessed vim direnv plugin. This is a pure lua version, with some potential upsides (more control of load order), and some potential downsides (less well-established, less tested and potentially more complicated to configure, depending on what you're trying to achieve).

## Setup

:exclamation: Note - with `direnv`, load order is particularly important! `direnv`'s evaluation takes time, so if Neovim (via e.g. a language plugin's LSP) is expecting a certain environment to be provided by `direnv`, you want to make sure that `direnv.nvim` has executed before other code tries to use that environment.

(Aside for `nix` users: this is particularly pertinent if using `nix-direnv` to load LSP server binaries for your project. In this situation, you might also want to look into `nix_direnv_manual_reload`, or the `async` setup described further down).

### lazy.nvim

#### Defaults

In light of the point about load order above, make sure that this entry is added early in your list of plugins, before any language-specific plugins that may require a `direnv` environment:

```lua
{ "actionshrimp/direnv.nvim", opts = {} }
...
```

##### What directory is passed to `direnv`?

By default, the directory passed to direnv is the directory of the __current buffer__, rather than vim's current working directory (controlled by `:cd`, `:set autochdir`, etc). If you would rather have the direnv environment tied to the vim cwd, check out `opts.type = 'dir'` below.

##### Synchronous?

By default, `direnv.nvim` loads the direnv synchronously, which means that opening or navigating to a specific buffer can block the UI for the same amount of time it takes to `cd` into a directory controlled by that `direnv` environment in a terminal. This can be a bit jarring when switching buffers, particularly for longer environment load times, but ensures the `direnv` environment will be available before any other buffer setup takes place load order, as mentioned above.

If you'd rather avoid this hang, you can use the `async = true` option. With this set, the function in `on_direnv_finished` is called after direnv has loaded (whether a `direnv` was found or not), which allows you to do any specific setup required, e.g.:

```lua
{
    "actionshrimp/direnv.nvim",
    opts = {
        async = true,
        on_direnv_finished = function ()
            -- You may also want to pair this with `autostart = false` in any `lspconfig` calls
            -- See the 'LSP config examples' section further down.
            vim.cmd("LspStart")
        end
    }
}
```

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
    -- if true, vim will evaluate the direnv environment in the background. direnv.nvim will then fire various autocmds depending on how the evaluation went. See below for more detail here!

  hook = {
    msg = "status", -- "status" | "diff" | nil
    -- message printed to the status line when direnv environment changes.
    -- - 'status' - shows the output of 'direnv status'.
    -- - 'diff' - shows the diff of environment variables.
    -- - nil - disables the message entirely.
  }

  -- if non-nil, this option is called when direnv has finished
  on_direnv_finished = nil -- nil | function () end

  on_direnv_finished_opts = {
		pattern = { "DirenvReady", "DirenvNotFound" }, -- can be amended to include additional autocmd events from the list below
        filetype = nil, -- can be a table of filetypes. the `on_direnv_finished` function will only be called if the buffer filetype is in this list
        once = nil
  }
}
```

#### Autocmds events fired by the plugin

The plugin provides a convenience option, `on_direnv_finished`, which provides a simple easy way of running a callback when `direnv` has finished, but you may want a bit more control.

These plugin fires these, all under the 'User' event, and the 'direnv-nvim' autocmd group:

- `DirenvNotFound` - when no direnv was found for the current context
- `DirenvBlocked` - when a direnv was found, but has not been allowed with `direnv allow` yet
- `DirenvAllowed` - when the direnv has been allowed via the :DirenvAllow function
- `DirenvStart` - when direnv begins evaluation
- `DirenvUpdated` - when vim's environment was actually updated by direnv
- `DirenvReady` - when direnv has finished evaluating - either the env was updated or left unchanged

You can subscribe to these events yourself to get more control, with something like:

```lua
-- This snippet is more or less what `on_direnv_finished` runs under the hood.
vim.api.nvim_create_autocmd("User", {
        group = "direnv-nvim",
        pattern = { "DirenvReady", "DirenvNotFound" },
        callback = function()
        -- your action here
        end,
})
```

#### User commands provided by the plugin

The plugin also provides lua functions and vim commands for performing `direnv status` and `direnv allow`, via:

```
:DirenvStatus
:DirenvAllow
```

If you need to reload the environment after running `:DirenvAllow`, the simplest way to proceed is to just type `:e` and the plugin will retrigger with the newly enabled environment.

### LSP config examples

Here are some examples on how to load the direnv before the LSP starts:

#### Using nvim-lspconfig

``` lua
-- lazy config:
{
    "actionshrimp/direnv.nvim",
    opts = {
        async = true,
        on_direnv_finished = function ()
            -- You probably also want to pair this with `autostart = false` in any `lspconfig` calls - see 'LSP config examples' below!
            vim.cmd("LspStart")
        end
    }
}

-- lspconfig.lua -- configure your LPSs the usual way, but adding `autostart = false`
require("lspconfig").lua_ls.setup({ autostart = false })
require("lspconfig").clangd.setup({ autostart = false })
```

#### Using [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)

``` lua
-- lazy config:
{
    "actionshrimp/direnv.nvim",
    opts = {
        async = true,
        -- we leave on_direnv_finished empty here, and configure the autocmd manually,
        -- to be able to explicitly set the `once` option just for the `rust` filetype.
    }
}
vim.g.rustaceanvim = {
	server = {
		auto_attach = function(bufnr)
            vim.api.nvim_create_autocmd("User", {
				pattern = { "DirenvReady", "DirenvNotFound" },
				once = true,
				callback = function()
                    if vim.bo.filetype == "rust" then
                        require("rustaceanvim.lsp").start(bufnr)
                    end
				end,
			})
			return false
		end,
	},
}
```
