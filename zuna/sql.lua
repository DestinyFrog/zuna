require "os"
require "io"

local uuid = require "uuid"
uuid.set_rng(uuid.rng.urandom())

require "zuna.helpers.functions"
require "zuna.block"

local sql = "INSERT INTO molecula (`uid`,`name`,`z1`,`term`,`another_names`) VALUES "

---@type string
local file_name = arg[1]
local file = io.open(file_name, "r")
if not file then
    HandleError(404, "file not found")
    os.exit(1)
end

local z1 = file:read("a")
file:close()

local block = Block:new()
for _, line in ipairs(Split_string(z1, "\n")) do
    block:handle_line(line)
end

local uid = uuid.v4()
local name = block.names[1]

local term = {}
for _, atom in ipairs(block.atoms) do
    table.insert(term, atom.symbol)
end
table.sort(term)
local str_term = table.concat(term)

local another_names = {}
for i = 2, #block.names do
    local m_name = '"' .. block.names[i] .. '"'
    table.insert(another_names, m_name)
end
local str_another_names = '[' .. table.concat(another_names, ',') .. ']'

sql = sql .. "('"
    .. uid .. "','"
    .. name .. "','"
    .. z1:gsub('\n\n','\n') .. "','"
    .. str_term .. "','"
    .. str_another_names .. "')"

print(sql)