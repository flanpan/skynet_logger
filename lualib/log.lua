local skynet = require "skynet"
local log_define = require "log_define"

local getinfo = debug.getinfo
local LOG_LEVEL = log_define.LOG_LEVEL
local DEFAULT_CATEGORY = log_define.DEFAULT_CATEGORY
local log_format = log_define.format

local category_addr = {}

local function get_service(category)
    local addr = category_addr[category]
    if addr then
        return addr
    end

    local root_addr = skynet.localname(".logger")
    if not root_addr then
        -- no logger config
        root_addr = skynet.uniqueservice("logger")
    end

    local addr = skynet.call(root_addr, "lua", "get_service", category)
    category_addr[category] = addr
    return addr
end

local function sendlog(category, level, ...)
    local di = getinfo(3, "Sl")
    local msg = log_format(skynet.self(), level, di, ...)
    skynet.call(get_service(category), "lua", "log", level, msg)
end



local M = {}

function M.d(...)
    sendlog(DEFAULT_CATEGORY, LOG_LEVEL.DEBUG, ...)
end

function M.d2(category, ...)
    sendlog(category, LOG_LEVEL.DEBUG, ...)
end

function M.i(...)
    sendlog(DEFAULT_CATEGORY, LOG_LEVEL.INFO, ...)
end

function M.i2(category, ...)
    sendlog(category, LOG_LEVEL.INFO, ...)
end

function M.w(...)
    sendlog(DEFAULT_CATEGORY, LOG_LEVEL.WARN, ...)
end

function M.w2(category, ...)
    sendlog(category, LOG_LEVEL.WARN, ...)
end

function M.e(...)
    sendlog(DEFAULT_CATEGORY, LOG_LEVEL.ERROR, ...)
end

function M.e2(category, ...)
    sendlog(category, LOG_LEVEL.ERROR, ...)
end

function M.f(...)
    sendlog(DEFAULT_CATEGORY, LOG_LEVEL.FATAL, ...)
end

function M.f2(category, ...)
    sendlog(category, LOG_LEVEL.FATAL, ...)
end

return M