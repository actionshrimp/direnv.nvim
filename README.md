# direnv.nvim

A neovim wrapper around `direnv`, in pure lua.

## Why not use `direnv.vim`?

[direnv.vim](https://github.com/direnv/direnv.vim) is the officially blessed vim direnv plugin, however I found that with the out-of-the-box configuration, the neovim LSP would try to intialise before my direnv environment had loaded, which, if the LSP server itself is provided by the direnv environment (e.g. via [nix-direnv](https://github.com/nix-community/nix-direnv)) can cause some problems!

There is likely a way of working around that problem with direnv/direnv.vim, but I was able to write the basic implementation of this in lua more quickly than I was able to understand the vimscript, and learn a bit about lua, neovim and direnv in the process.

## Setup

### lazy.nvim

#### Defaults

Make sure this entry is added early in your list of deps, before any LSPs that would be made available by a particular direnv environment are set up.

```lua
{ "actionshrimp/direnv.nvim", opts = {} }
```

This will install direnv.nvim and run the `setup` function, which registers autocmds to automatically update the direnv environment when you open files and switch buffers.

*Note:*

By default, the directory passed to direnv is the directory of the _current buffer_, rather than vim's current working directory (controlled by `:cd`, `:set autochdir`, etc). If you would rather have the direnv environment tied to the vim cwd, check out `opts.type = 'dir'` below.


#### Available options

The full list of available options and their defaults are loaded from [here](./lua/direnv-nvim/opts.lua). Here's a summary of them:

```
{
  type = "buffer", -- "buffer" | "dir"
    -- "buffer" direnv uses directory based on the current buffer
    -- "dir" direnv uses directory based on vim's cwd (see this with `:pwd`)

  buffer_setup = ...
    -- allows you to control the type = 'buffer' setup's autocmd options

  dir_setup = ...
    -- allows you to control the type = 'dir' setup's autocmd options

  async = false, -- false | true
    -- if false, loading environment from direnv into vim is done synchronously. This will block the UI, so if the direnv setup takes a while, you may want to look into setting this to true.
    -- if true, vim will evaluate the direnv environment in the background, and then call the function passed as opts.async_cb once evaluation is complete.

  async_cb = function () end,
    -- called after direnv evaluation if opts.async = true

  hook = {
    msg = "status", -- "status" | "diff" | nil
    -- Message printed to the status line when direnv environment changes.
    -- - 'status' - shows the output of 'direnv status'
    -- - 'diff' - shows the diff of environment variables
    -- - nil - disabled the message
  }
}
```

#### Manually firing the hook

If you'd rather try configuring the autocmds yourself, you can use something like:

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

or to bind the direnv hook to a key, you can use:
```lua
{
    "actionshrimp/direnv.nvim", config = function() 
        vim.keymap.set("n", "<LEADER>dr", function ()
            require("direnv-nvim").hook(opts)
        end
     end
}
```


## TODO

- [x] Add functions/mappings for 'direnv' allow
- [ ] Further customisation of output
- [ ] Better docs
- [ ] Test more rigorously :)
- [ ] Explore sync loading for FileType, async loading for BufEnter
