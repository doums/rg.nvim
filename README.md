## rg.nvim

[ripgrep](https://github.com/BurntSushi/ripgrep) integration in nvim

### Install

As usual using your plugin manager, e.g. lazy.nvim

```lua
local P = {
  'doums/rg.nvim',
  cmd = { 'Rg', 'Rgf', 'Rgp', 'Rgfp' },
}

return P
```

### Config

```lua
require('rg').setup({
  -- Optional function to be used to format the items in the
  -- quickfix window (:h 'quickfixtextfunc')
  qf_format = nil,
})
```

### Commands

Each of the following commands spawn `rg` with the supplied arguments
and then populates the quickfix list with the match(es)

**NOTE** Do not quote the PATTERN argument as when using `rg` in a
terminal. It is automatically quoted by the plugin as expected.

⚠ Positions of command arguments are strict

#### `Rg PATTERN`

Make a rg search with defaults, in the current directory

```
:Rg a pattern
```

#### `Rgp PATTERN PATH`

Make a rg search with defaults, in the provided path

```
:Rgp a pattern /a/path
```

#### `Rgf FLAGS PATTERN`

Make a rg search with flag(s), in the current directory

Available flags:

- `I` → `--no-ignore`
- `H` → `--hidden`
- `S` → `--smart-case`
- `s` → `--case-sensitive`
- `i` → `--ignore-case`

```
:Rgf HIs a pattern
```

#### `Rgfp FLAGS PATTERN PATH`

Make a rg search with flag(s), in the provided path

Same flags as `Rgf`

```
:Rgfp HIs a pattern /a/path
```

### API

The plugin module exposes the following methods. Each of them
spawn `rg` with the supplied arguments and then populates the
quickfix list with the match(es)

#### `rg`

`rg(pattern`: string`, flags`: listOf[IHSsi]`, path`: string`)`

Example

```lua
require('rg').rg('a pattern', { 'H', 'I' }, '/a/path')
```

#### `rgui`

`rgui(path`: string?`)`

Uses `vim.ui.*` interface to query the flag(s) and the pattern. It
can take an optional path as argument.

Useful when combined with a file explorer plugin to search under
a specific path.

Example with [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua)

In the files'tree window press `<C-f>` to search in the
directory/file under the cursor

```lua
-- nvim-tree config

local function on_attach(bufnr)
  -- ...

  vim.keymap.set('n', '<C-f>', function()
    local node = api.tree.get_node_under_cursor()
    require('rg').rgui(node.absolute_path)
  end, opts(''))
end
```

### License

Mozilla Public License 2.0

