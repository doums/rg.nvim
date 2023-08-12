-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local rg = require('rg.rg')
local cfg = require('rg.config')

local M = {}

function M.setup(config)
  config = cfg.init(config or {})
  if vim.fn.executable('rg') ~= 1 then
    vim.notify('✗ [rg] ripgrep not found on the system', vim.log.levels.WARN)
    config.rg_not_found = true
  end
  rg.init(config)
end

M.rg = rg.rg
M.rgui = rg.rgui

return M
