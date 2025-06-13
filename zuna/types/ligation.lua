require "zuna.types.atom"

---@alias LigationType "covalente" | "iônica" | "hidrogênio" | "covalente dativa"

---@alias EletronsType 1 | 2 | 3

---@class Ligation
---@field from Atom?
---@field to Atom?
---@field type LigationType
---@field eletrons EletronsType
---@field angle number?
---@field angle3d number[]
Ligation = {
    from = nil,
    to = nil
}

---Constructs a ligation object
---@param type LigationType?
---@param eletrons EletronsType?
---@param angle number?
---@return Ligation
function Ligation:new(type, eletrons, angle, angle3d)
    local obj = {
        type = type or "covalente",
        eletrons = eletrons or 1,
        angle = angle,
        angle3d = angle3d
    }

    setmetatable(obj, self)
    self.__index = self
    return obj
end
---@alias LigationType "covalente" | "iônica" | "hidrogênio" | "covalente dativa"

---@alias EletronsType 1 | 2 | 3

---@class Ligation
---@field from Atom?
---@field to Atom?
---@field type LigationType
---@field eletrons EletronsType
---@field angle number?
---@field angle3d number[]
Ligation = {
    from = nil,
    to = nil
}

---Constructs a ligation object
---@param type LigationType?
---@param eletrons EletronsType?
---@param angle number?
---@return Ligation
function Ligation:new(type, eletrons, angle, angle3d)
    local obj = {
        type = type or "covalente",
        eletrons = eletrons or 1,
        angle = angle,
        angle3d = angle3d
    }

    setmetatable(obj, self)
    self.__index = self
    return obj
end