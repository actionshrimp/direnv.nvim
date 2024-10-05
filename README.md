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
    -- if true, vim will evaluate the direnv environment in the background. direnv.nvim will then fire various autocmds depending on how the evaluation went. See below for more detail here!

  hook = {
    msg = "status", -- "status" | "diff" | nil
    -- message printed to the status line when direnv environment changes.
    -- - 'status' - shows the output of 'direnv status'.
    -- - 'diff' - shows the diff of environment variables.
    -- - nil - disables the message entirely.
  }
}
```

#### Autocmds events fired by the plugin

If you're using the `async = true` config option you will likely find these useful.

These are all under the 'User' event, and the 'direnv-nvim' autocmd group.

- `DirenvNotFound` - when no direnv was found for the current context
- `DirenvBlocked` - when a direnv was found, but has not been allowed with `direnv allow` yet
- `DirenvAllowed` - when the direnv has been allowed via the :DirenvAllow function
- `DirenvStart` - when direnv beings evaluation
- `DirenvUpdated` - when vim's environment was actually updated by direnv
- `DirenvReady` - when direnv has finished evaluating - either the env was updated or left unchanged

You can subscribe to these events with something like:

```lua
vim.api.nvim_create_autocmd("User", {
        group = "direnv-nvim",
        pattern = { "DirenvLoaded", "DirenvNotFound" },
        callback = function()
        -- your action here
        end,
})
```

However, the plugin provides a convenience function `on_direnv_finished`, which provides an easy way of subscribing to common events for given filetypes - this is particularly useful for configuring LSPs - see the LSP config examples below.

#### User commands provided by the plugin

The plugin also provides lua functions and vim commands for performing `direnv status` and `direnv allow`, via:

```
:DirenvStatus
:DirenvAllow
```

If you need to reload the environment after running :DirenvAllow, the simplest way to proceed is to just type `:e` and the plugin will retrigger with the newly enabled environment.

### LSP config examples

Here are some examples on how to load the direnv before the LSP starts:

``` lua
#### Using nvim-lspconfig

``` lua
-- lspconfig.lua

-- configure your LPSs the usual way, but adding `autostart = false`
require("lspconfig").lua_ls.setup({ autostart = false })
require("lspconfig").clangd.setup({ autostart = false })

-- Start the LSP on direnv changes for the given filetypes we have defined setup for
M.on_direnv_finished({ filetype = {"lua", "c"} }, function ()
		vim.cmd("LspStart")
end)
```

#### Using [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)

``` lua
vim.g.rustaceanvim = {
	server = {
		auto_attach = function(bufnr)
            M.on_direnv_finished({ once = true }, function ()
					require("rustaceanvim.lsp").start(bufnr)
            end)
			return false
		end,
	},
}
```
