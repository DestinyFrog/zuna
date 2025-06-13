require "zuna.configuration"
require "zuna.helpers.svg_helper"

---@class Plugin
---@field block Block
---@field svg SvgHelper
Plugin = {}

---constroi um novo Plugin padrao
---@param block Block
---@return Plugin
function Plugin:new(block)
    local obj = {
        ['block'] = block,
        ['svg'] = SvgHelper:new()
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Plugin:calcAtomsPosition(atom, dad_atom, ligation, order)
    if atom == nil then atom = self.block.atoms[1] end
    if atom.already == true then return end

    if ligation and dad_atom then
        if not ligation.angle then
            local default_dad_ligation = atom.parent_ligation and atom.parent_ligation.angle or 0
            local antipodal_pai = default_dad_ligation + 180
            local angulo_fatia = 360 / atom.ligation_num
            local angulo = antipodal_pai + angulo_fatia * (order + (atom.parent_ligation and 1 or 0))
            ligation.angle = math.floor(angulo % 360)
        end
    end

    local x = 0
    local y = 0
    if dad_atom ~= nil and ligation then
        local angle_rad = math.pi * ligation.angle / 180
        x = dad_atom.x + math.cos(angle_rad) * STANDARD_LIGATION_SIZE
        y = dad_atom.y + math.sin(angle_rad) * STANDARD_LIGATION_SIZE
    end

    atom.x = x
    atom.y = y
    atom.already = true

    for idx, lig in ipairs(atom.ligations) do
        self:calcAtomsPosition(lig.to, atom, lig, idx)
    end
end

function Plugin:calculateBounds()
    local min_x = 0
    local min_y = 0
    local max_x = 0
    local max_y = 0

    for _, atom in ipairs(self.block.atoms) do
        local x = atom["x"]
        local y = atom["y"]

        if atom["symbol"] == "X" then
            goto continue
        end

        if x > max_x then max_x = x end
        if y > max_y then max_y = y end
        if x < min_x then min_x = x end
        if y < min_y then min_y = y end

        ::continue::
    end

    local cwidth = max_x + math.abs(min_x)
    local cheight = max_y + math.abs(min_y)

    self.width = SVG_BORDER * 2 + cwidth
    self.height = SVG_BORDER * 2 + cheight

    self.center_x = SVG_BORDER + math.abs(min_x)
    self.center_y = SVG_BORDER + math.abs(min_y)
end

function Plugin:drawAtom()
    for _, atom in ipairs(self.block.atoms) do
        local symbol = atom["symbol"]
        local x = self.center_x + atom["x"]
        local y = self.center_y + atom["y"]

        if symbol == "X" then
            goto continue
        end

        self.svg:text(atom["symbol"], x, y)

        local charge = atom["charge"]

        if charge ~= 0 then
            if charge == 1 then
                charge = "+"
            end
            if charge == -1 then
                charge = "-"
            end
            self.svg:subtext(charge, x + STANDARD_ATOM_RADIUS, y - STANDARD_ATOM_RADIUS)
        end

        ::continue::
    end

    return nil
end

function Plugin:drawLigation()
    for _, ligation in pairs(self.block.ligations) do
        local from_atom = ligation.from
        local to_atom = ligation.to

        if to_atom.symbol == "X" then
            goto continue
        end

        local ax = self.center_x + from_atom.x
        local ay = self.center_y + from_atom.y
        local bx = self.center_x + to_atom.x
        local by = self.center_y + to_atom.y

        local angles = STANDARD_WAVES[ligation.eletrons]

        local a_angle = math.atan((by - ay), (bx - ax))
        local b_angle = math.pi + a_angle

        if ligation.type ~= "iônica" then
            for _, angle in ipairs(angles) do
                local nax = ax + math.cos(a_angle - (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS
                local nay = ay + math.sin(a_angle - (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS

                local nbx = bx + math.cos(b_angle + (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS
                local nby = by + math.sin(b_angle + (math.pi * angle / 180)) * STANDARD_ATOM_RADIUS

                self.svg:line(nax, nay, nbx, nby)
            end
        end

        ::continue::
    end

    return nil
end

function Plugin:build()
    self:calcAtomsPosition()
    self:calculateBounds()
    self:drawAtom()
    self:drawLigation()
    return self.svg:build(self.width, self.height)
end
