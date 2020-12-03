local skynet = require "skynet"
local log_define = require "log_define"

local getinfo = debug.getinfo
local LOG_LEVEL = log_define.LOG_LEVEL
local category_addr = {}

local function get_service(category)
    local addr = category_addr[category]
    if addr then return addr end

    local default_service = log_define.service_name()
    local addr = skynet.call(default_service, "lua", "get_service", category)
    category_addr[category] = addr
    return addr
end

local function sendlog(category, level, ...)
    local di = getinfo(3, "Sl")
    local msg = log_define.format(skynet.self(), level, di, ...)
    skynet.call(get_service(category), "lua", "log", level, msg)
end



local M = {}

function M.d(...)
    sendlog(log_define.DEFAULT_CATEGORY, LOG_LEVEL.DEBUG, ...)
end

function M.d2(category, ...)
    sendlog(category, LOG_LEVEL.DEBUG, ...)
end

function M.i(...)
    sendlog(log_define.DEFAULT_CATEGORY, LOG_LEVEL.INFO, ...)
end

function M.i2(category, ...)
    sendlog(category, LOG_LEVEL.INFO, ...)
end

function M.w(...)
    sendlog(log_define.DEFAULT_CATEGORY, LOG_LEVEL.WARN, ...)
end

function M.w2(category, ...)
    sendlog(category, LOG_LEVEL.WARN, ...)
end

function M.e(...)
    sendlog(log_define.DEFAULT_CATEGORY, LOG_LEVEL.ERROR, ...)
end

function M.e2(category, ...)
    sendlog(category, LOG_LEVEL.ERROR, ...)
end

function M.f(...)
    sendlog(log_define.DEFAULT_CATEGORY, LOG_LEVEL.FATAL, ...)
end

function M.f2(category, ...)
    sendlog(category, LOG_LEVEL.FATAL, ...)
end

return M