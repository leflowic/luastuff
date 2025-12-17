--
-- Adapted from
-- Tweener's easing functions (Penner's Easing Equations)
-- and http://code.google.com/p/tweener/ (jstweener javascript version)
--

-- For all easing functions:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)
--
-- Adapted from
-- Tweener's easing functions (Penner's Easing Equations)
-- and http://code.google.com/p/tweener/ (jstweener javascript version)
--

-- For all easing functions:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)
MATH = {
	POW=function(base--[[@param base number]],exponent--[[@param exponent number]])return Natives.InvokeFloat(0xE3621CC40F31FE2E,base+.0,exponent+.0)end;---@return number
}
local pow = MATH.POW
local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt
local abs = math.abs
local asin = math.asin

-- Constants
local EPSILON = 1e-3
local function linear(t, b, c, d)
	return c * t / d + b
end

local function inQuad(t, b, c, d)
	t = t / d
	return c * pow(t, 2) + b
end

local function outQuad(t, b, c, d)
	t = t / d
	return -c * t * (t - 2) + b
end

local function inOutQuad(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * t * t + b
	else
		t = t - 1
		return -c / 2 * (t * (t - 2) - 1) + b
	end
end

local function outInQuad(t, b, c, d)
	if t < d / 2 then
		return outQuad(t * 2, b, c / 2, d)
	else
		return inQuad((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function outInQuad(t, b, c, d)
	if t < d / 2 then
		return outQuad (t * 2, b, c / 2, d)
	else
		return inQuad((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inCubic (t, b, c, d)
	t = t / d
	return c * pow(t, 3) + b
end

local function outCubic(t, b, c, d)
	t = t / d - 1
	return c * (pow(t, 3) + 1) + b
end

local function inOutCubic(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * t * t * t + b
	else
		t = t - 2
		return c / 2 * (t * t * t + 2) + b
	end
end

local function outInCubic(t, b, c, d)
	if t < d / 2 then
		return outCubic(t * 2, b, c / 2, d)
	else
		return inCubic((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inQuart(t, b, c, d)
	t = t / d
	return c * pow(t, 4) + b
end

local function outQuart(t, b, c, d)
	t = t / d - 1
	return -c * (pow(t, 4) - 1) + b
end

local function inOutQuart(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 4) + b
	else
		t = t - 2
		return -c / 2 * (pow(t, 4) - 2) + b
	end
end

local function outInQuart(t, b, c, d)
	if t < d / 2 then
		return outQuart(t * 2, b, c / 2, d)
	else
		return inQuart((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inQuint(t, b, c, d)
	t = t / d
	return c * pow(t, 5) + b
end

local function outQuint(t, b, c, d)
	t = t / d - 1
	return c * (pow(t, 5) + 1) + b
end

local function inOutQuint(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 5) + b
	else
		t = t - 2
		return c / 2 * (pow(t, 5) + 2) + b
	end
end

local function outInQuint(t, b, c, d)
	if t < d / 2 then
		return outQuint(t * 2, b, c / 2, d)
	else
		return inQuint((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inSine(t, b, c, d)
	return -c * cos(t / d * (pi / 2)) + c + b
end

local function outSine(t, b, c, d)
	return c * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, c, d)
	return -c / 2 * (cos(pi * t / d) - 1) + b
end

local function outInSine(t, b, c, d)
	if t < d / 2 then
		return outSine(t * 2, b, c / 2, d)
	else
		return inSine((t * 2) -d, b + c / 2, c / 2, d)
	end
end

local function inExpo(t, b, c, d)
	if t == 0 then
		return b
	else
		return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
	end
end

local function outExpo(t, b, c, d)
	if t == d then
		return b + c
	else
		return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
	end
end

local function inOutExpo(t, b, c, d)
	if t == 0 then return b end
	if t == d then return b + c end
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
	else
		t = t - 1
		return c / 2 * 1.0005 * (-pow(2, -10 * t) + 2) + b
	end
end

local function outInExpo(t, b, c, d)
	if t < d / 2 then
		return outExpo(t * 2, b, c / 2, d)
	else
		return inExpo((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inCirc(t, b, c, d)
	t = t / d
	return(-c * (sqrt(1 - pow(t, 2)) - 1) + b)
end

local function outCirc(t, b, c, d)
	t = t / d - 1
	return(c * sqrt(1 - pow(t, 2)) + b)
end

local function inOutCirc(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return -c / 2 * (sqrt(1 - t * t) - 1) + b
	else
		t = t - 2
		return c / 2 * (sqrt(1 - t * t) + 1) + b
	end
end

local function outInCirc(t, b, c, d)
	if t < d / 2 then
		return outCirc(t * 2, b, c / 2, d)
	else
		return inCirc((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inElastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d

	if t == 1	then return b + c end

	if not p then p = d * 0.3 end

	local s

	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c/a)
	end

	t = t - 1

	return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

-- a: amplitud
-- p: period
local function outElastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d

	if t == 1 then return b + c end

	if not p then p = d * 0.3 end

	local s

	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c/a)
	end

	return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

-- p = period
-- a = amplitud
local function inOutElastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d * 2

	if t == 2 then return b + c end

	if not p then p = d * (0.3 * 1.5) end
	if not a then a = 0 end

	local s

	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c / a)
	end

	if t < 1 then
		t = t - 1
		return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
	else
		t = t - 1
		return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
	end
end

-- a: amplitud
-- p: period
local function outInElastic(t, b, c, d, a, p)
	if t < d / 2 then
		return outElastic(t * 2, b, c / 2, d, a, p)
	else
		return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
	end
end

local function inBack(t, b, c, d, s)
	if not s then s = 1.70158 end
	t = t / d
	return c * t * t * ((s + 1) * t - s) + b
end

local function outBack(t, b, c, d, s)
	if not s then s = 1.70158 end
	t = t / d - 1
	return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inOutBack(t, b, c, d, s)
	if not s then s = 1.70158 end
	s = s * 1.525
	t = t / d * 2
	if t < 1 then
		return c / 2 * (t * t * ((s + 1) * t - s)) + b
	else
		t = t - 2
		return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
	end
end

local function outInBack(t, b, c, d, s)
	if t < d / 2 then
		return outBack(t * 2, b, c / 2, d, s)
	else
		return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
	end
end

local function outBounce(t, b, c, d)
	t = t / d
	if t < 1 / 2.75 then
		return c * (7.5625 * t * t) + b
	elseif t < 2 / 2.75 then
		t = t - (1.5 / 2.75)
		return c * (7.5625 * t * t + 0.75) + b
	elseif t < 2.5 / 2.75 then
		t = t - (2.25 / 2.75)
		return c * (7.5625 * t * t + 0.9375) + b
	else
		t = t - (2.625 / 2.75)
		return c * (7.5625 * t * t + 0.984375) + b
	end
end

local function inBounce(t, b, c, d)
	return c - outBounce(d - t, 0, c, d) + b
end

local function inOutBounce(t, b, c, d)
	if t < d / 2 then
		return inBounce(t * 2, 0, c, d) * 0.5 + b
	else
		return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
	end
end

local function outInBounce(t, b, c, d)
	if t < d / 2 then
		return outBounce(t * 2, b, c / 2, d)
	else
		return inBounce((t * 2) - d, b + c / 2, c / 2, d)
	end
end


local buttons = {
    { label = "Quad Out",     fn = outQuad },
    { label = "Cubic Out",    fn = outCubic },
    { label = "Quart Out",    fn = outQuart },
    { label = "Quint Out",    fn = outQuint },
    { label = "Sine Out",     fn = outSine },
    { label = "Expo Out",     fn = outExpo },
    { label = "Circ Out",     fn = outCirc },
    { label = "Back Out",     fn = outBack },
    { label = "Bounce Out",   fn = outBounce },
    { label = "Elastic Out",  fn = outElastic },
}

for _, b in ipairs(buttons) do
    b.hoverStart = 0
    b.hoverDur = 0.35
    b.hoverActive = false
    b.hoverScale = 1.0
end

local function AnimateHover(btn, isHovered)
    if isHovered and not btn.hoverActive then
        btn.hoverStart = ImGui.GetTime()
        btn.hoverActive = true
    elseif not isHovered then
        btn.hoverActive = false
    end

    if btn.hoverActive then
        local t = ImGui.GetTime() - btn.hoverStart
        btn.hoverScale = btn.fn(
            math.min(t, btn.hoverDur), 1.0, 0.3, btn.hoverDur
        )
    else
        
        local t = ImGui.GetTime() - btn.hoverStart
        btn.hoverScale = outQuad(
            math.min(t, btn.hoverDur), btn.hoverScale, 1.0 - btn.hoverScale, btn.hoverDur
        )
    end
end

ClickGUI.AddTab("Easing Buttons", function()
    for i, btn in ipairs(buttons) do
        
        if (i - 1) % 3 ~= 0 then
            ImGui.SameLine()
        end

        local pos = V2.New(ImGui.GetCursorPos())
        ImGui.SetCursorPos(pos.x - (btn.hoverScale - 1) * 40, pos.y)

        if ImGui.Button(btn.label, 100 * btn.hoverScale, 35 * btn.hoverScale) then
            Logger.LogInfo(btn.label .. " clicked!")
        end

        AnimateHover(btn, ImGui.IsItemHovered())
    end
end)

return {
	linear = linear,

	quad_in = inQuad,
	quad_out = outQuad,
	quad_in_out = inOutQuad,
	quad_out_in = outInQuad,

	cubic_in = inCubic ,
	cubic_out = outCubic,
	cubic_in_out = inOutCubic,
	cubic_out_in = outInCubic,

	quart_in = inQuart,
	quart_out = outQuart,
	quart_in_out = inOutQuart,
	quart_out_in = outInQuart,

	quint_in = inQuint,
	quint_out = outQuint,
	quint_in_out = inOutQuint,
	quint_out_in = outInQuint,

	sine_in = inSine,
	sine_out = outSine,
	sine_in_out = inOutSine,
	sine_out_in = outInSine,

	expo_in = inExpo,
	expo_out = outExpo,
	expo_in_out = inOutExpo,
	expo_out_in = outInExpo,

	circ_in = inCirc,
	circ_out = outCirc,
	circ_in_out = inOutCirc,
	circ_out_in = outInCirc,

	elastic_in = inElastic,
	elastic_out = outElastic,
	elastic_in_out = inOutElastic,
	elastic_out_in = outInElastic,

	back_in = inBack,
	back_out = outBack,
	back_in_out = inOutBack,
	back_out_in = outInBack,

	bounce_in = inBounce,
	bounce_out = outBounce,
	bounce_in_out = inOutBounce,
	bounce_out_in = outInBounce,
}
