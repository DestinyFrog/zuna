
---@class Atom
---@field symbol string
---@field charge number
---@field ligations Ligation[]
---@field parent Atom?
---@field parent_ligation Ligation?
---@field ligation_num number
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

---add parent to atom
---@param parent_ligation Ligation
function Atom:set_parent(parent_ligation)
    self.parent = parent_ligation.from
    self.parent_ligation = parent_ligation
    self.ligation_num = self.ligation_num + 1
end

function Atom:add_ligation(ligation)
    table.insert(self.ligations, ligation)
    self.ligation_num = self.ligation_num + 1
end