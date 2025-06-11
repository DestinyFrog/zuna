require "os"
require "io"

require "helpers.Functions"
require "Block"

---@type string
local file_name = arg[1]
local file = io.open(file_name, "r")
if not file then
    HandleError(404, "file not found")
    os.exit(1)
end

local block = Block:new()
for line in file:lines() do
    block:handle_line(line)
end

file:close()