local string_format = string.format
local floor = math.floor
local tconcat = table.concat
local os_date = os.date
local string_sub = string.sub
local os_clock = os.clock

local ESC = string.char(27, 91)
local RESET = ESC .. '0m'

local M = {}

M.LOG_LEVEL = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    FATAL = 5
}

M.LOG_LEVEL_NAME = {
    [1] = "DEBUG",
    [2] = "INFO ",
    [3] = "WARN ",
    [4] = "ERROR",
    [5] = "FATAL"
}

M.LOG_COLOR = {
    [1] = ESC .. '34m',
    [2] = ESC .. '32m',
    [3] = ESC .. '33m',
    [4] = ESC .. '31m',
    [5] = ESC .. '35m'
}

M.DEFAULT_CATEGORY = "root"

--- local service name
function M.service_name(category)
    if not category or category == M.DEFAULT_CATEGORY then
        return ".logger"
    end
    return ".logger." .. category
end

function M.log_dir(log_root, date)
    return string_format("%s/%04d-%02d-%02d",
        log_root or ".", 
        date.year, 
        date.month, 
        date.day)
end

function M.log_path(dir, prefix, category, date)
    return string_format("%s/%s%s_%04d-%02d-%02d.log",
        dir or ".", 
        prefix or "", 
        category or M.DEFAULT_CATEGORY, 
        date.year, 
        date.month, 
        date.day)
end

function M.format(addr, level, di, ...)
    local param = {...}
    local date = os_date("*t")
    local ms = string_sub(os_clock(), 3, 6)
    
    local time = string_format("%02d:%02d:%02d.%02d",
        date.hour, date.min, date.sec, ms)

    local fileline = ""
    if di then
        fileline = ("[%s:%d]"):format(di.short_src, di.currentline)
    end

    local msg = string_format("[:%08x][%s][%s]%s %s",
        addr, M.LOG_LEVEL_NAME[level], time, fileline, tconcat(param," "))

    return msg
end

function M.color(level, msg)
    local c = M.LOG_COLOR[level]
    if not c then return msg end
    return c .. msg .. RESET
end

return M