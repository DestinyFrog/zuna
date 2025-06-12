require "zuna.Configuration"

---Handle Zuna Erros
---@param status number
---@param message string
function HandleError(status, message)
    print(status .. " | " .. message)
end

---Print as Log
---@param message string
function Log(message)
    for i = 1, LOG_TABS do
        io.write('    ')
    end
    print(message)
end

function Split_string(txt, separator)
    local params = {}
    for param in txt:gmatch("[^" .. (separator or "%s") .. "]+") do
        table.insert(params, param)
    end
    return params
end

function Couroutine_split_string(txt, separator)
    for param in txt:gmatch("[^" .. (separator or "%s") .. "]+") do
        coroutine.yield(param)
    end
end

---matches a pattern in string
---@param text string
---@param pattern string
---@param from number?
---@return string?, number?
function Match_substr(text, pattern, from)
    local start_s, end_s = string.find(text, pattern, from)
    if not start_s then return nil end
    return string.sub(text, start_s, end_s), end_s
end

---matches a pattern in string and remove it
---@param text string
---@param remove string
---@return string?, number?
function Match_remove_substr(text, remove)
    local value, end_s = text:gsub(remove, "")
    return value, end_s
end