require "zuna.configuration"
require "zuna.helpers.functions"

require "zuna.types.atom"
require "zuna.types.ligation"

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
    if tag then
        block.tags[tag] = true
        Log("+ tag: " .. tag)
    end
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
            atom:add_ligation(block.ligations[ligation_key])
        else
            block.ligations[ligation_key].to = atom
            atom:set_parent(block.ligations[ligation_key])
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

    Log("+ lig: " ..
    ligation_tag ..
    " " ..
    eletrons .. " " .. type .. " " .. (angle or 'nil°') .. " [" .. (angle_azimutal or "n°") .. " " .. (angle_polar or "n°") .. "]")

    if not block.ligations[ligation_tag] then
        block.ligations[ligation_tag] = Ligation:new(type, eletrons, angle, { angle_azimutal, angle_polar })
    else
        if type then block.ligations[ligation_tag].type = type end
        if eletrons then block.ligations[ligation_tag].eletrons = eletrons end
        if angle then block.ligations[ligation_tag].angle = angle end
        if angle_azimutal and angle_polar then block.ligations[ligation_tag].angle3d = { angle_azimutal, angle_polar } end
    end
end

---@class Block
---@field names string[]
---@field tags {[string]: boolean}
---@field atoms Atom[]
---@field ligations Ligation[]
Block = {
    matches = {
        { "@name%s(.+)",                    HandleName },
        { "@tag%s(.+)",                     HandleTag },
        { "@p%s(.+)",                       HandlePattern },
        { "[A-Z][a-z]?%s[+|-0-9]?[%s%d+]*", HandleAtom },
        { "[^@%a+](%s%d+°)",                HandleLigation },
        { "[^@%a+](%s[-=%%])",                HandleLigation }
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

        local id = Generate_random_str()
        self.ligations[id] = ligation

        ::continue::
    end
end