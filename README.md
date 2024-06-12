# direnv.nvim

This is currently a work in progress, but seems to work quite nicely for the few cases I've tested it on.

Currently the direnv environment loads synchronously, to make sure it is available for any other plugins, LSPs etc. as required.

## Why not use `direnv.vim`?

[direnv.vim](https://github.com/direnv/direnv.vim) is the officially blessed vim direnv plugin, however I found that due to the load ordering it provides by default, LSPs would try to intialise before my direnv environment had loaded. Perhaps there is a way to configure this? However I was able to write the basic implementation of this in lua more quickly than I was able to understand the vimscript :-)

## Setup

### lazy.nvim

#### Defaults

Make sure this entry is added early in your list of deps, before any LSPs that would be made available by a particular direnv environment are set up.

```lua
{ "actionshrimp/direnv.nvim", opts = {} }
```

This will install direnv.nvim and run the `setup` function, which registers autocmds to automatically update the direnv environment when you open files and switch buffers.


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

#### Options

The default and available options are listed [here](./lua/direnv-nvim/opts.lua).

## TODO

- [ ] Add functions/mappings for 'direnv' allow
- [ ] Further customisation of output
- [ ] Better docs
- [ ] Test more rigorously :)
- [ ] Explore sync loading for FileType, async loading for BufEnter
