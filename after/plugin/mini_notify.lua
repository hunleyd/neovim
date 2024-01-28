require('mini.notify').setup()
-- vim.notify = require('mini.notify').make_notify()
local mini_notify = MiniNotify.make_notify()
vim.notify = function(msg, level, opts)
  opts = opts or {}
  if opts.title ~= nil then msg = string.format('[%s]: %s', opts.title, msg) end
  mini_notify(msg, level)
end
