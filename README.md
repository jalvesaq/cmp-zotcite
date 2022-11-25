# cmp-zotcite


Zotero completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) using [zotcite](https://github.com/jalvesaq/zotcite) as backend.


## Installation

Use a plugin manager such as [vim-plug](https://github.com/junegunn/vim-plug)
or [packer](https://github.com/wbthomason/packer.nvim).

## Setup

Register the source for `nvim-cmp`:

```lua
require'cmp'.setup {
  sources = {
    { name = 'cmp_zotcite' },
  }
}
```

## Configuration

The source is enabled for `markdown`, `rmd` and `quarto` file types by
default, but you can change this:

```lua
require'cmp_zotcite'.setup({
    filetypes = {"pandoc", "markdown", "rmd", "quarto"}
})
```
