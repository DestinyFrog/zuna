require "os"
require "io"

PATTERN_FOLDER = "patterns/"

Z1_CSS = "z1.css"
Z1_TEMP_SVG = "z1.temp.svg"

STANDARD_ATOM_RADIUS = 8
STANDARD_DISTANCE_BETWEEN_LIGATIONS = 20
STANDARD_LIGATION_SIZE = 30

STANDARD_WAVES = {
    { 0 },
    { STANDARD_DISTANCE_BETWEEN_LIGATIONS / 2, -STANDARD_DISTANCE_BETWEEN_LIGATIONS / 2 },
    { STANDARD_DISTANCE_BETWEEN_LIGATIONS,     0,                                       -STANDARD_DISTANCE_BETWEEN_LIGATIONS }
}

SVG_BORDER = 10

function HandleError(status, message)
    print(status .. " | " .. message)
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

function Match_substr(text, pattern, from)
    local start_s, end_s = string.find(text, pattern, from)
    if not start_s then return nil end
    return string.sub(text, start_s, end_s), end_s
end

function Match_remove_substr(text, remove)
    local value, end_s = text:gsub(remove, "")
    return value, end_s
end

Atom = {}

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

function Atom:set_parent(parent_ligation)
    self.parent = parent_ligation.from
    self.parent_ligation = parent_ligation
    self.ligation_num = self.ligation_num + 1
end

function Atom:add_ligation(ligation)
    table.insert(self.ligations, ligation)
    self.ligation_num = self.ligation_num + 1
end

Ligation = {
    from = nil,
    to = nil
}

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

Ligation = {
    from = nil,
    to = nil
}

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

function HandleName(block, line)
    local name = Match_remove_substr(line, "@name%s")
    table.insert(block.names, name)
end

function HandleTag(block, line)
    local tag = Match_remove_substr(line, "@tag%s")
    if tag then
        block.tags[tag] = true
    end
end

function HandlePattern(block, line)
    local pattern_text = Match_remove_substr(line, "@p%s")
    local pattern_split = Split_string(pattern_text)

    local pattern_name = pattern_split[1]
    local full_pattern_path = PATTERN_FOLDER .. pattern_name .. ".pre.z1"

    local pattern = io.open(full_pattern_path, "r")
    if pattern == nil then
        HandleError(404, "pattern not found")
        os.exit(1)
    end

    local out_pattern_mask_params = {}
    if pattern_split[2] then
        out_pattern_mask_params = Split_string(pattern_split[2], ',')
    end

    local pattern_block = Block:new()
    local first_line = true
    local pattern_params = {}

    for p_line in pattern:lines() do
        if first_line then
            local pattern_mask_params = Split_string(p_line, ",")
            for idx, mask_param in ipairs(pattern_mask_params) do
                table.insert(pattern_params, { mask_param, out_pattern_mask_params[idx] })
            end
            first_line = false
        else
            pattern_block:handle_line(p_line)
        end
    end
    pattern:close()

    block:merge(pattern_block, pattern_params)
end

function HandleAtom(block, line)
    local symbol, end_symbol = Match_substr(line, "[A-Z][a-z]?")
    if not symbol then
        HandleError(404, "symbol not found")
        os.exit(1)
    end

    local charge_str, end_charge = Match_substr(line, "[+|-]%d")
    local charge = 0
    if charge_str then
        charge_str = charge_str:gsub("[+|-]", "")
        charge = math.tointeger(tonumber(charge_str)) or 0
    end

    local atom = Atom:new(symbol, charge)
    table.insert(block.atoms, atom)

    local init_ligations = (end_charge and end_charge or end_symbol) + 1
    local ligations_str = line:sub(init_ligations)
    if not ligations_str then return end

    local my_Split_string = coroutine.wrap(Couroutine_split_string)
    local ligation_key = my_Split_string(ligations_str)

    while ligation_key do
        if not block.ligations[ligation_key] then
            block.ligations[ligation_key] = Ligation:new()
        end

        if not block.ligations[ligation_key].from then
            block.ligations[ligation_key].from = atom
            atom:add_ligation(block.ligations[ligation_key])
        else
            block.ligations[ligation_key].to = atom
            atom:set_parent(block.ligations[ligation_key])
        end

        ligation_key = my_Split_string()
    end
end

function HandleLigation(block, line)
    local ligation_params = Split_string(line)

    local ligation_tag = nil

    local eletrons = '-'
    local angle = nil
    local type = 'c'
    local angle_azimutal = nil
    local angle_polar = nil

    for _, a in ipairs(ligation_params) do
        local match = Match_substr(a, "[%-%=%%]")
        if match then
            eletrons = match
            goto continue
        end

        match = Match_substr(a, "[cihd]")
        if match then
            type = match
            goto continue
        end

        match = Match_substr(a, "%b[]")
        if match then
            local angles_str = match:gsub('[%[%]]', '')
            local angles = Split_string(angles_str, ',')

            local angle_azimutal_str = angles[1]:gsub('%°', '')
            local angle_polar_str = angles[2]:gsub('%°', '')

            angle_azimutal = tonumber(angle_azimutal_str)
            angle_polar = tonumber(angle_polar_str)
            goto continue
        end

        match = Match_substr(a, "%d+%°")
        if match then
            local angle_str = match:gsub('%°', '')
            angle = tonumber(angle_str)
            goto continue
        end

        ligation_tag = a

        ::continue::
    end

    local eletrons_type = {
        ['-'] = 1,
        ['='] = 2,
        ['%'] = 3
    }

    local types = {
        ["c"] = "covalente",
        ["i"] = "iônica",
        ["h"] = "hidrogênio",
        ["d"] = "covalente dativa"
    }

    eletrons = eletrons_type[eletrons]
    type = types[type]

    if not block.ligations[ligation_tag] then
        block.ligations[ligation_tag] = Ligation:new(type, eletrons, angle, { angle_azimutal, angle_polar })
    else
        if type then block.ligations[ligation_tag].type = type end
        if eletrons then block.ligations[ligation_tag].eletrons = eletrons end
        if angle then block.ligations[ligation_tag].angle = angle end
        if angle_azimutal and angle_polar then block.ligations[ligation_tag].angle3d = { angle_azimutal, angle_polar } end
    end
end

Block = {
    matches = {
        { "@name%s(.+)",                    HandleName },
        { "@tag%s(.+)",                     HandleTag },
        { "@p%s(.+)",                       HandlePattern },
        { "[A-Z][a-z]?%s[+|-0-9]?[%s%d+]*", HandleAtom },
        { "[^@%a+](%s%d+°)",                HandleLigation },
        { "[^@%a+](%s[-=%%])",              HandleLigation }
    }
}

function Block:new(obj)
    obj = obj or {}
    obj.names = {}
    obj.tags = {}
    obj.atoms = {}
    obj.ligations = {}

    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Block:handle_line(line)
    for _, obj in ipairs(self.matches) do
        local match = obj[1]
        local fun = obj[2]

        if string.find(line, match) then
            fun(self, line)
        end
    end
end

function Block:merge(newBlock, mask)
    for i = 1, #newBlock.names do
        table.insert(self.names, newBlock.names[i])
    end

    for i = 1, #newBlock.tags do
        table.insert(self.tags, newBlock.tags[i])
    end

    for i = 1, #newBlock.atoms do
        table.insert(self.atoms, newBlock.atoms[i])
    end

    for _, ligation_mask in ipairs(mask) do
        local out_mask = ligation_mask[1]
        local in_mask = ligation_mask[2]

        if self.ligations[in_mask] == nil then
            self.ligations[in_mask] = newBlock.ligations[out_mask]
        else
            if newBlock.ligations[out_mask].from ~= nil then
                self.ligations[in_mask].from = newBlock.ligations[out_mask].from
            end

            if newBlock.ligations[out_mask].to ~= nil then
                self.ligations[in_mask].from = newBlock.ligations[out_mask].to
            end

            self.ligations[in_mask].angle = newBlock.ligations[out_mask].angle
            self.ligations[in_mask].type = newBlock.ligations[out_mask].type
            self.ligations[in_mask].eletrons = newBlock.ligations[out_mask].eletrons
            self.ligations[in_mask].angle3d = newBlock.ligations[out_mask].angle3d
        end
    end

    for key, ligation in pairs(newBlock.ligations) do
        for _, ligation_mask in ipairs(mask) do
            if ligation_mask[1] == key then
                goto continue
            end
        end

        local id = os.date("%x")
        self.ligations[id] = ligation

        ::continue::
    end
end

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

SvgHelper = {
    content = ""
}

function SvgHelper:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function SvgHelper:line(ax, ay, bx, by, className)
    if className == nil then className = 'svg-ligation' end
    self.content = string.format('%s<line class="%s" x1="%g" y1="%g" x2="%g" y2="%g"></line>', self.content, className,
        ax, ay, bx, by)
end

function SvgHelper:circle(x, y, r)
    self.content = string.format('%s<circle class="svg-eletrons" cx="%g" cy="%g" r="%g"></circle>',
        self.content, x, y, r)
end

function SvgHelper:text(symbol, x, y)
    self.content = string.format('%s<text class="svg-element svg-element-%s" x="%g" y="%g">%s</text>',
        self.content, symbol, x, y, symbol)
end

function SvgHelper:subtext(symbol, x, y)
    self.content = string.format(
        '%s<circle class="svg-element-charge-border" cx="%g" cy="%g"/><text class="svg-element-charge" x="%g" y="%g">%s</text>',
        self.content, x, y, x, y, symbol)
end

function SvgHelper:build(width, height)
    local css_file = io.open(Z1_CSS, "r")
    if css_file == nil then
        HandleError(404, "Template 'z1.css' não encontrado")
        os.exit(1)
    end

    local css = css_file:read("*a")
    css = css:gsub("[\n|\t]", "")
    io.close(css_file)

    local svg_template_file = io.open(Z1_TEMP_SVG, "r")
    if svg_template_file == nil then
        HandleError(404, "Template 'z1.temp.svg' não encontrado")
        os.exit(1)
    end

    local svg_template = svg_template_file:read("*a")
    io.close(svg_template_file)

    local svg = string.format(svg_template, width, height, css, self.content)
    return svg
end

local plugin_name = arg[2] or "standard"
local text = nil

if plugin_name == "standard" then
    Plugin = {}

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

    local plugin = Plugin:new(block)
    text = plugin:build()
end

if text == nil then
    HandleError(404, "plugin " .. plugin_name .. " not found")
    os.exit(1)
end

print(text)