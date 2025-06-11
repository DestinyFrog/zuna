require "Configuration"

---@class SvgHelper
---@field content string
SvgHelper = {
    content = ""
}

---Construct new SVG
---@return SvgHelper
function SvgHelper:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

---Draw a line between point a (ax, ay) and b (bx, by)
---@param ax number
---@param ay number
---@param bx number
---@param by number
---@param className string?
function SvgHelper:line(ax, ay, bx, by, className)
    if className == nil then className = 'svg-ligation' end
    self.content = string.format('%s<line class="%s" x1="%g" y1="%g" x2="%g" y2="%g"></line>', self.content, className, ax, ay, bx, by)
end

---Draw a circle centered in (x, y) with radius (r)
---@param x number
---@param y number
---@param r number
function SvgHelper:circle(x, y, r)
    self.content = string.format('%s<circle class="svg-eletrons" cx="%g" cy="%g" r="%g"></circle>',
        self.content, x, y, r)
end

---Draw a text (symbol) in (x, y)
---@param symbol string
---@param x number
---@param y number
function SvgHelper:text(symbol, x, y)
    self.content = string.format('%s<text class="svg-element svg-element-%s" x="%g" y="%g">%s</text>',
        self.content, symbol, x, y, symbol)
end

---Draw a subtext (symbol) in (x, y)
---@param symbol string
---@param x number
---@param y number
function SvgHelper:subtext(symbol, x, y)
    self.content = string.format('%s<circle class="svg-element-charge-border" cx="%g" cy="%g"/><text class="svg-element-charge" x="%g" y="%g">%s</text>',
        self.content, x, y, x, y, symbol)
end

---Build all svg in template
---@param width number
---@param height number
---@return string
function SvgHelper:build(width, height)
    local css_file = io.open(Z1_CSS, "r")
    if css_file == nil then
        HandleError(404, "Template 'z1.css' não encontrado")
        os.exit(1)
    end

    local css = css_file:read("*a")
    css = css:gsub("[\n|\t]","")
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
