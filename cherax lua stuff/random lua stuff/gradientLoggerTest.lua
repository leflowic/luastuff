local Colors = {
    {255, 0, 0}, {255, 127, 0}, {255, 255, 0},
    {0, 255, 0}, {0, 0, 255}, {75, 0, 130}, {143, 0, 255}
}

local function RgbToAnsi(r, g, b)
    return string.format("\27[38;2;%d;%d;%dm", r, g, b)
end

function MakeGradientWithAnsi(msg, colors)
    local result = ""
    local len = #msg
    local stops = #colors - 1

    if stops < 1 then return msg end

    for i = 1, len do
        local t = (i - 1) / (len - 1)
        local segment = math.floor(t * stops) + 1
        local localT = (t * stops) % 1
        local r1, g1, b1 = table.unpack(colors[segment])
        local r2, g2, b2 = table.unpack(colors[segment + 1] or colors[segment])
        local r = math.floor(r1 + (r2 - r1) * localT)
        local g = math.floor(g1 + (g2 - g1) * localT)
        local b = math.floor(b1 + (b2 - b1) * localT)
        result = result .. RgbToAnsi(r, g, b) .. msg:sub(i, i)
    end

    return result .. "\27[0m"
end

local function RotateColors(tbl)
    local new = {}
    for i = 2, #tbl do
        table.insert(new, tbl[i])
    end
    table.insert(new, tbl[1])
    return new
end

local msg = "ELF SCRIPT"

function StartDynamicGradient()
    while true do
        local colored = MakeGradientWithAnsi(msg, Colors)
        io.write("\27[2K\r") 
        io.write("[Logger] " .. colored)
        io.flush()
        Script.Yield(1000) 
        Colors = RotateColors(Colors)
    end
end
Script.RegisterLooped(function()
    local colored = MakeGradientWithAnsi(msg, Colors)
    io.write("\27[2K\r") 
    io.write("[Logger] " .. colored)
    io.flush()
    Script.Yield(1000)
    Colors = RotateColors(Colors)
end)
