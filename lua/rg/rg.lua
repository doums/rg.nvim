-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local M = {}

local lvl = vim.log.levels
local rg_root_cmd = { 'rg', '--vimgrep' }
local _config

local _flags = {
  H = 'hidden',
  h = '', -- alias for '--hidden' and globs excluded files
  I = 'no-ignore',
  S = 'smart-case',
  s = 'case-sensitive',
  i = 'ignore-case',
  e = '', -- add globs excluded files
}

local async_exit = vim.schedule_wrap(function(obj)
  local code = obj.code
  if code == 0 then
    local matches = vim.split(obj.stdout, '\n', { trimempty = true })
    if #matches > 1 then
      vim.notify(string.format('✓ %d matches', #matches), lvl.INFO)
    else
      vim.notify('✓ 1 match', lvl.INFO)
    end
    if vim.tbl_isempty(matches) then
      return
    end
    vim.fn.setqflist({}, 'r', {
      title = 'rg',
      lines = matches,
      quickfixtextfunc = _config.qf_format,
    })
    vim.cmd('copen')
  elseif code == 1 then
    vim.notify(string.format('◌ no match', code), lvl.INFO)
  else
    vim.notify(string.format('✕ [rg] failed [%d]', code), lvl.ERROR)
  end
end)

local function get_excluded_flags()
  return vim
    .iter(_config.excluded)
    :map(function(file)
      return '-g!' .. file
    end)
    :totable()
end

-- Throws an error on unknown flags
local function parse_flags(flags)
  return vim
    .iter(flags)
    :map(function(flag)
      if not _flags[flag] then
        error(flag, 0)
        return nil
      end
      if flag == 'h' then
        return { '--hidden', get_excluded_flags() }
      end
      if flag == 'e' then
        return get_excluded_flags()
      end
      return '--' .. _flags[flag]
    end)
    :flatten(2)
    :totable()
end

function M.rg(pattern, flags, path)
  if _config.rg_not_found then
    vim.notify('✗ [rg] ripgrep not found on the system', vim.log.levels.ERROR)
    return
  end
  local command =
    vim.iter({ rg_root_cmd, flags, pattern, path }):flatten():totable()
  vim.notify(
    string.format('… running [%s] ', vim.iter(command):join(' ')),
    lvl.INFO
  )
  vim.system(command, { text = true }, async_exit)
end

local case_modes = {
  ['default'] = {},
  ['smart'] = { 'S' },
  ['sensitive'] = { 's' },
  ['ignore'] = { 'i' },
}

local filters = {
  ['default'] = {},
  ['hidden'] = { 'H' },
  ['no ignore'] = { 'I' },
  ['both'] = { 'H', 'I' },
}

function M.rgui(path)
  if _config.rg_not_found then
    vim.notify('✗ [rg] ripgrep not found on the system', vim.log.levels.ERROR)
    return
  end
  vim.ui.select({ 'default', 'smart', 'sensitive', 'ignore' }, {
    prompt = 'case',
  }, function(c_mode)
    if not c_mode then
      return
    end
    vim.ui.select({ 'default', 'hidden', 'no ignore', 'both' }, {
      prompt = 'filters',
    }, function(f_mode)
      if not f_mode then
        return
      end
      vim.ui.input({ prompt = 'pattern', default = '' }, function(pattern)
        if not pattern then
          return
        end
        local flags = parse_flags(
          vim.iter({ case_modes[c_mode], filters[f_mode] }):flatten():totable()
        )
        M.rg(pattern, flags, path)
      end)
    end)
  end)
end

local function pick_path(fargs)
  local path = table.remove(fargs)
  if not vim.uv.fs_stat(path) then
    vim.notify('✕ [rg] invalid path argument', lvl.ERROR)
    return nil
  end
  return path
end

local function pick_flags(fargs)
  local flags = table.remove(fargs, 1)
  local res, p_flags = pcall(parse_flags, vim.split(flags, ''))
  if not res then
    vim.notify(
      string.format('✕ [rg] unknown flags "%s", expected [HhISsie]', p_flags),
      lvl.ERROR
    )
    return nil
  end
  return p_flags
end

function M.init(config)
  _config = config

  -- Rg
  -- args: pattern
  -- Ex: `:Rg a pattern`
  vim.api.nvim_create_user_command('Rg', function(a)
    local pattern = table.concat(a.fargs, ' ')
    M.rg(pattern, {})
  end, {
    nargs = '+',
    desc = 'Rg vanilla, command args: pattern',
  })

  -- Rgp
  -- args: pattern path
  -- Ex: `:Rgp a pattern /some/path`
  vim.api.nvim_create_user_command('Rgp', function(a)
    if vim.tbl_count(a.fargs) < 2 then
      vim.notify(
        '✕ [rg] invalid arguments, expected `:Rgb pattern path`',
        lvl.ERROR
      )
      return
    end
    local path = pick_path(a.fargs)
    if not path then
      return
    end
    local pattern = table.concat(a.fargs, ' ')
    M.rg(pattern, {}, path)
  end, {
    nargs = '+',
    desc = 'Rg with path, command args: pattern path',
  })

  -- Rgf
  -- args: flags pattern
  -- Ex: `:Rgf HI a pattern`
  vim.api.nvim_create_user_command('Rgf', function(a)
    if vim.tbl_count(a.fargs) < 2 then
      vim.notify(
        '✕ [rg] invalid arguments, expected `:Rgf flag(s) pattern`',
        lvl.ERROR
      )
      return
    end
    local flags = pick_flags(a.fargs)
    if not flags then
      return
    end
    local pattern = table.concat(a.fargs, ' ')
    M.rg(pattern, flags)
  end, {
    nargs = '+',
    desc = 'Rg with flags, command args: flags pattern',
  })

  -- Rgfp
  -- args: flags pattern path
  -- Ex: `:Rgfp HI a pattern /some/path`
  vim.api.nvim_create_user_command('Rgfp', function(a)
    if vim.tbl_count(a.fargs) < 3 then
      vim.notify(
        '✕ [rg] invalid arguments, expected `:Rgfp flag(s) pattern path`',
        lvl.ERROR
      )
      return
    end
    local flags = pick_flags(a.fargs)
    if not flags then
      return
    end
    local path = pick_path(a.fargs)
    if not path then
      return
    end
    local pattern = table.concat(a.fargs, ' ')
    M.rg(pattern, flags, path)
  end, {
    nargs = '+',
    desc = 'Rg with flags and path, command args: flags pattern path',
  })
end

return M
