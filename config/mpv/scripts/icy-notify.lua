-- ~/.config/mpv/scripts/icy-notify.lua

local utils = require 'mp.utils'
local msg = require 'mp.msg'
local DEBUG = false

-- table ----------------------------------------------------------------------

table.union = function(a, b)
    local result = {}

    for k, v in pairs(a) do
        table.insert(result, v)
    end
    for k, v in pairs(b) do
        table.insert(result, v)
    end

    return result
end

-- memo module ----------------------------------------------------------------

local memo = {}

memo.name = ('memo_' .. utils.getpid())

memo.store = function(value)
    _G[memo.name] = value

    return memo
end

memo.init = function()
    if _G[memo.name] == nil then
        memo.store({})
    end

    return memo
end

memo.dump = function()
    return _G[memo.name]
end

-- functions ------------------------------------------------------------------

-- @see https://github.com/kikito/inspect.lua
-- @see https://github.com/mpv-player/mpv/blob/master/DOCS/man/lua.rst
function dump(...)
    local inspect = (function()
        if DEBUG then
            local ok, v = pcall(require, 'inspect')

            return (ok and v or utils.to_string)
        end
    end)()

    if inspect ~= nil then
        for _, v in ipairs({...}) do
            print(inspect(v))
        end
    end

    return {...}
end

function notify(summary, body, options)
    local command = { 'run', 'notify-send' }
    for key, value in pairs(options or {}) do
        table.insert(command, string.format('--%s=%s', key:gsub('_', '-'), value))
    end

    mp.command_native(table.union(command, { summary, body }))
end

-- NEW BLOCK
function refresh_dwmblocks()
    mp.command_native({ 'run', 'pkill', '-RTMIN+15', 'dwmblocks' })
end
--

function main()
    local data = mp.get_property_native('metadata')
    local prev = memo.dump()
    local opts = { app_name = 'mpv', icon = 'mpv', expire_time = 4000 }

    for _i, v in ipairs({ 'icy-title', 'icy-name' }) do
        if tostring(data[v]) == '' then
            return
        end
    end

    if data['icy-title'] ~= prev['icy-title'] then
        memo.store(data)
    
    return notify(data['icy-name'], data['icy-title'], opts)

-- NEW BLOCK
--        notify(data['icy-name'], data['icy-title'], opts)
--        refresh_dwmblocks() -- Call the new function here
--        return
--
    end
end

-- execution ------------------------------------------------------------------

mp.register_event("file-loaded", function()
    memo.init()

    mp.add_periodic_timer(0.25, function()
        local callable = main
        if DEBUG then
            callable()
        else
            pcall(callable)
        end
    end)
end)
