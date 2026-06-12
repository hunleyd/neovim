-------------------------------------------------------------------------------
-- NEOVIM 0.12 CONFIGURATION (FROM SCRATCH)
-------------------------------------------------------------------------------
-- This configuration is designed to be modular, efficient, and deeply personalized.
-- It strictly leverages the latest native features of Neovim 0.12 (like UI2) 
-- while maintaining a rigid "no-mouse" philosophy to enforce better, faster
-- editing habits.
-------------------------------------------------------------------------------

-- 1. EXPERIMENTAL FEATURES (UI2)
-- Enable the new native UI2 layer for message handling and the command line.
-- Why: Historically, Neovim messages and commands lived at the bottom of the 
-- screen, often causing disruptive "Press ENTER to continue" prompts. UI2 
-- modernizes this by routing these into floating windows or scrollable pagers,
-- keeping your view of the code completely uninterrupted.
pcall(function() 
    require('vim._core.ui2').enable({
        msg = {
            targets = {
                [''] = 'msg',          -- Default for most messages (floats)
                echo = 'msg',          -- Standard :echo outputs (floats)
                echomsg = 'msg',       -- :echomsg history (floats)
                emsg = 'pager',        -- Errors (pager for easier reading)
                lua_error = 'pager',   -- Lua stack traces (pager)
                progress = 'msg',      -- LSP/Plugin progress (floats)
            }
        }
    }) 
end)

-- 2. LEADER KEYS
-- The Leader key acts as the primary prefix for all custom shortcuts.
-- Why: Spacebar is the largest key on the keyboard and is easily accessible 
-- by both thumbs without moving your hands off the home row.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 3. LOAD MODULES
-- We split the config into separate, focused files in the 'lua/' folder.
-- Why: Prevents init.lua from becoming a monolithic, 1000-line mess. It makes
-- debugging and tweaking specific parts of the editor much faster.
require("options")   -- Editor settings (line numbers, boundaries, spellcheck)
require("keymaps")   -- Custom shortcuts, movement overrides, and pasting logic
require("autocmds")  -- Background events (smart numbers, persistence, floats)

-- 4. PLUGIN SYSTEM
-- This delegates all plugin installation, updating, and specific plugin setups.
-- Why: We use a custom pack-manager script instead of heavy plugins like Lazy
-- to maintain absolute control over the load order and keep startup times minimal.
require("plugins").setup()

-- Final visual confirmation that the modular load succeeded.
vim.notify("Neovim 0.12 config initialized!")
