local skynet = require "skynet"
local log_define = require "log_define"
local queue = require "skynet.queue"
require "skynet.manager"

local LOG_LEVEL = log_define.LOG_LEVEL
local DEFAULT_CATEGORY = log_define.DEFAULT_CATEGORY
local log_format = log_define.format
local color = log_define.color
local log_service_name = log_define.service_name
local string_match = string.match

local log_root = skynet.getenv("log_root")
local log_prefix = skynet.getenv("log_prefix")
local log_console = skynet.getenv("log_console")
local log_level = tonumber(skynet.getenv("log_level") or LOG_LEVEL.INFO)

local last_day	= -1
local category = ...
local is_master = not category
local category_addr = {}
local lock = queue()
local file


local function close_file()
    if not file then return end
    file:close()
    file = nil
end

local function open_file(date)
    date = date or os.date("*t")

    local dir = log_define.log_dir(log_root, date)
    if not os.rename(dir, dir) then
        os.execute("mkdir -p " .. dir)
    end

    if file then
        close_file()
    end

    local path = log_define.log_path(dir, log_prefix, category, date)
    local f, e = io.open(path, "a")
    if not f then
        print("logger error:", tostring(e))
        return
    end

    file = f
    last_day = date.day
end


local CMD = {}

function CMD.console(level, msg)
    print(color(level, msg))
end

function CMD.log(level, msg)
    if level < log_level then
        return
    end

    msg = msg or ""
    local date = os.date("*t")
    if not file or date.day ~= last_day then
        open_file(date)
    end

    file:write(msg .. '\n')
    file:flush()

    if log_console then
        if is_master then
            CMD.console(level, msg)
        else
            skynet.call(log_service_name(), "lua", "console", level, msg)
        end
    end
end

function CMD.set_console(is_open)
    log_console = is_open
    if is_master then
        for _, addr in pairs(category_addr) do
            skynet.call(addr, "lua", "set_console", is_open)
        end
    end
end

function CMD.set_level(level)
    log_level = level
    if is_master then
        for _, addr in pairs(category_addr) do
            skynet.call(addr, "lua", "set_level", level)
        end
    end
end

function CMD.get_service(category)
    if not is_master then
        return
    end

    local addr
    lock(function()
        addr = category_addr[category]
        if not addr then
            addr = skynet.newservice("logger", category)
            category_addr[category] = addr
        end
    end)
    return addr
end


if is_master then

    skynet.info_func(function()
        return {
            log_console = log_console,
            log_level = log_level
        }
    end)

    skynet.register_protocol {
        name = "text",
        id = skynet.PTYPE_TEXT,
        unpack = skynet.tostring,
        dispatch = function(_, addr, msg)
            local level = LOG_LEVEL.DEBUG
            if string_match(msg, "maybe in an endless loop") then
                level = LOG_LEVEL.WARN
            end
            if string_match(msg, "stack traceback:") then
                level = LOG_LEVEL.ERROR
            end
            msg = log_format(addr, level, nil, msg)
            CMD.log(level, msg)
        end
    }
    
    skynet.register_protocol {
        name = "SYSTEM",
        id = skynet.PTYPE_SYSTEM,
        unpack = function(...) return ... end,
        dispatch = function(_, addr)
            local level = LOG_LEVEL.FATAL
            local msg = log_format(addr, level, nil, "SIGHUP")
            CMD.log(level, msg)
        end
    }

    category_addr[DEFAULT_CATEGORY] = skynet.self()
end


skynet.dispatch("lua", function(_, _, cmd, ...)
    local f = CMD[cmd]
    assert(f, cmd)
    return skynet.retpack(f(...))
end)

open_file()
skynet.register(log_service_name(category))
skynet.start(function() end)