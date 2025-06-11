require "Configuration"
require "helpers.Functions"

require "types.Atom"
require "types.Ligation"

---Handle line [@name ...]
---@param block Block
---@param line string
function HandleName(block, line)
    local name = Match_remove_substr(line, "@name%s")
    table.insert(block.names, name)
    Log("+ name: " .. name)
end

---Handle line [@tag ...]
---@param block Block
---@param line string
function HandleTag(block, line)
    local tag = Match_remove_substr(line, "@tag%s")
    table.insert(block.tags, tag)
    Log("+ tag: " .. tag)
end

---Handle line [@p pattern 1,2,3,...]
---@param block Block
---@param line string
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

    Log("+ pattern: " .. full_pattern_path)
    LOG_TABS = LOG_TABS + 1

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

    LOG_TABS = LOG_TABS - 1
    block:merge(pattern_block, pattern_params)
end

---Handle line [Na (-|+)1 1,2,3,...]
---@param block Block
---@param line string
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
            -- atom:add_ligation(self.ligations[ligation_key])
        else
            block.ligations[ligation_key].to = atom
            -- atom:set_parent(self.ligations[ligation_key])
        end

        ligation_key = my_Split_string()
    end

    Log("+ atom: " .. symbol .. " " .. charge)
end

---Handle line [## (@type-h|c|d|i) (-|=|%) [###° ###°]]
---@param block Block
---@param line string
function HandleLigation(block, line)
    local ligation_params = Split_string(line)

    local name = nil

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

        name = a

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

    Log("+ lig: " ..
        name ..
        " " ..
        eletrons .. " " .. type .. " " .. angle .. " [" .. (angle_azimutal or "n") .. " " .. (angle_polar or "n") .. "]")
    local ligation = Ligation:new(type, eletrons, angle, { angle_azimutal, angle_polar })
    block.ligations[name] = ligation
end

---@class Block
---@field names string[]
---@field tags string[]
---@field atoms Atom[]
---@field ligations Ligation[]
Block = {
    matches = {
        { "@name%s(.+)",                    HandleName },
        { "@tag%s(.+)",                     HandleTag },
        { "@p%s(.+)",                       HandlePattern },
        { "[A-Z][a-z]?%s[+|-0-9]?[%s%d+]*", HandleAtom },
        { "[^@%a+](%s%d+°)",                HandleLigation }
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

---Handle Zuna Line
---@param line string
function Block:handle_line(line)
    for _, obj in ipairs(self.matches) do
        local match = obj[1]
        local fun = obj[2]

        if string.find(line, match) then
            fun(self, line)
        end
    end
end

---Merge Two Blocks
---@param newBlock Block
---@param mask table
function Block:merge(newBlock, mask)
    for i = 1, #newBlock.names do
        table.insert(self.names, newBlock.names[i])
    end

    local tags = {}
    for _, tag in ipairs(newBlock.tags) do table.insert(tags, tag) end
    for _, tag in ipairs(self.tags) do table.insert(tags, tag) end
    self.tags = tags

    local atoms = {}
    for _, atom in ipairs(newBlock.atoms) do table.insert(atoms, atom) end
    for _, atom in ipairs(self.atoms) do table.insert(atoms, atom) end
    self.atoms = atoms

    for _, ligation_mask in ipairs(mask) do
        local in_mask = ligation_mask[1]
        local out_mask = ligation_mask[2]
        self.ligations[in_mask] = newBlock.ligations[out_mask]
    end
end
