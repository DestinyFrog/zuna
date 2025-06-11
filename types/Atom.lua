
---@class Atom
---@field symbol string
---@field charge number
---@field ligations Ligation[]
---@field parent Atom?
---@field parent_ligation Ligation?
Atom = {}

---Constructs a atom object
---@param symbol string
---@param charge number?
---@return Atom
function Atom:new(symbol, charge)
    local obj = {
        symbol = symbol,
        charge = charge or 0,
        ligations = {},
        ligation_num = 0,
    }

    setmetatable(obj, self)
    self.__index = self
    return obj
end