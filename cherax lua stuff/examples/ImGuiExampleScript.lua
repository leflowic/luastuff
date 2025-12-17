
-- ImGui Builder


local always_try_using_lpeg = true
local register_global_modulwe_table = false
local global_module_name = 'json'
local pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset =
    pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset
local error, require, pcall, select = error, require, pcall, select
local floor, huge = math.floor, math.huge
local strrep, gsub, strsub, strbyte, strchar, strfind, strlen, strformat =
    string.rep, string.gsub, string.sub, string.byte, string.char,
    string.find, string.len, string.format
local strmatch = string.match
local concat = table.concat
local json = { version = "dkjson 2.5" }

if register_global_module_table then
  _G[global_module_name] = json
end

pcall(function()
  local debmeta = require "debug".getmetatable
  if debmeta then getmetatable = debmeta end
end)

json.null = setmetatable({}, {
  __tojson = function() return "null" end
})

local function isarray(tbl)
  local max, n, arraylen = 0, 0, 0
  for k, v in pairs(tbl) do
    if k == 'n' and type(v) == 'number' then
      arraylen = v
      if v > max then
        max = v
      end
    else
      if type(k) ~= 'number' or k < 1 or floor(k) ~= k then
        return false
      end

      if k > max then
        max = k
      end

      n = n + 1
    end
  end

  if max > 10 and max > arraylen and max > n * 2 then
    return false 
  end

  return true, max
end

local escapecodes = {
  ["\""] = "\\\"",
  ["\\"] = "\\\\",
  ["\b"] = "\\b",
  ["\f"] = "\\f",
  ["\n"] = "\\n",
  ["\r"] = "\\r",
  ["\t"] = "\\t"
}

local function escapeutf8(uchar)
  local value = escapecodes[uchar]
  if value then
    return value
  end
  local a, b, c, d = strbyte(uchar, 1, 4)
  a, b, c, d = a or 0, b or 0, c or 0, d or 0
  if a <= 0x7f then
    value = a
  elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
    value = (a - 0xc0) * 0x40 + b - 0x80
  elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
    value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
  elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
    value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
  else
    return ""
  end

  if value <= 0xffff then
    return strformat("\\u%.4x", value)
  elseif value <= 0x10ffff then
    -- encode as UTF-16 surrogate pair
    value = value - 0x10000
    local highsur, lowsur = 0xD800 + floor(value / 0x400), 0xDC00 + (value % 0x400)
    return strformat("\\u%.4x\\u%.4x", highsur, lowsur)
  else
    return ""
  end
end

local function fsub(str, pattern, repl)
  if strfind(str, pattern) then
    return gsub(str, pattern, repl)
  else
    return str
  end
end



local function quotestring(value)
  value = fsub(value, "[%z\1-\31\"\\\127]", escapeutf8)
  if strfind(value, "[\194\216\220\225\226\239]") then
    value = fsub(value, "\194[\128-\159\173]", escapeutf8)
    value = fsub(value, "\216[\128-\132]", escapeutf8)
    value = fsub(value, "\220\143", escapeutf8)
    value = fsub(value, "\225\158[\180\181]", escapeutf8)
    value = fsub(value, "\226\128[\140-\143\168-\175]", escapeutf8)
    value = fsub(value, "\226\129[\160-\175]", escapeutf8)
    value = fsub(value, "\239\187\191", escapeutf8)
    value = fsub(value, "\239\191[\176-\191]", escapeutf8)
  end

  return "\"" .. value .. "\""
end

json.quotestring = quotestring

local function replace(str, o, n)
  local i, j = strfind(str, o, 1, true)

  if i then
    return strsub(str, 1, i - 1) .. n .. strsub(str, j + 1, -1)
  else
    return str
  end
end

local decpoint, numfilter



local function updatedecpoint()
  decpoint = strmatch(tostring(0.5), "([^05+])")
  numfilter = "[^0-9%-%+eE" .. gsub(decpoint, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "]+"
end

updatedecpoint()

local function num2str(num)
  return replace(fsub(tostring(num), numfilter, ""), decpoint, ".")
end

local function str2num(str)
  local num = tonumber(replace(str, ".", decpoint))

  if not num then
    updatedecpoint()

    num = tonumber(replace(str, ".", decpoint))
  end

  return num
end



local function addnewline2(level, buffer, buflen)
  buffer[buflen + 1] = "\n"

  buffer[buflen + 2] = strrep("  ", level)

  buflen = buflen + 2

  return buflen
end



function json.addnewline(state)
  if state.indent then
    state.bufferlen = addnewline2(state.level or 0,

      state.buffer, state.bufferlen or #(state.buffer))
  end
end

local encode2 -- forward declaration



local function addpair(key, value, prev, indent, level, buffer, buflen, tables, globalorder, state)
  local kt = type(key)

  if kt ~= 'string' and kt ~= 'number' then
    return nil, "type '" .. kt .. "' is not supported as a key by JSON."
  end

  if prev then
    buflen = buflen + 1

    buffer[buflen] = ","
  end

  if indent then
    buflen = addnewline2(level, buffer, buflen)
  end

  buffer[buflen + 1] = quotestring(key)

  buffer[buflen + 2] = ":"

  return encode2(value, indent, level, buffer, buflen + 2, tables, globalorder, state)
end



local function appendcustom(res, buffer, state)
  local buflen = state.bufferlen

  if type(res) == 'string' then
    buflen = buflen + 1

    buffer[buflen] = res
  end

  return buflen
end



local function exception(reason, value, state, buffer, buflen, defaultmessage)
  defaultmessage = defaultmessage or reason

  local handler = state.exception

  if not handler then
    return nil, defaultmessage
  else
    state.bufferlen = buflen

    local ret, msg = handler(reason, value, state, defaultmessage)

    if not ret then return nil, msg or defaultmessage end

    return appendcustom(ret, buffer, state)
  end
end



function json.encodeexception(reason, value, state, defaultmessage)
  return quotestring("<" .. defaultmessage .. ">")
end

encode2 = function(value, indent, level, buffer, buflen, tables, globalorder, state)
  local valtype = type(value)

  local valmeta = getmetatable(value)

  valmeta = type(valmeta) == 'table' and valmeta  -- only tables

  local valtojson = valmeta and valmeta.__tojson

  if valtojson then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end

    tables[value] = true

    state.bufferlen = buflen

    local ret, msg = valtojson(value, state)

    if not ret then return exception('custom encoder failed', value, state, buffer, buflen, msg) end

    tables[value] = nil

    buflen = appendcustom(ret, buffer, state)
  elseif value == nil then
    buflen = buflen + 1

    buffer[buflen] = "null"
  elseif valtype == 'number' then
    local s
    if value ~= value or value >= huge or -value >= huge then
      -- This is the behaviour of the original JSON implementation.
      s = "null"
    else
      s = num2str(value)
    end

    buflen = buflen + 1

    buffer[buflen] = s
  elseif valtype == 'boolean' then
    buflen = buflen + 1
    buffer[buflen] = value and "true" or "false"
  elseif valtype == 'string' then
    buflen = buflen + 1
    buffer[buflen] = quotestring(value)
  elseif valtype == 'table' then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    level = level + 1
    local isa, n = isarray(value)
    if n == 0 and valmeta and valmeta.__jsontype == 'object' then
      isa = false
    end
    local msg
    if isa then -- JSON array
      buflen = buflen + 1
      buffer[buflen] = "["
      for i = 1, n do
        buflen, msg = encode2(value[i], indent, level, buffer, buflen, tables, globalorder, state)
        if not buflen then return nil, msg end
        if i < n then
          buflen = buflen + 1
          buffer[buflen] = ","
        end
      end
      buflen = buflen + 1
      buffer[buflen] = "]"
    else -- JSON object
      local prev = false
      buflen = buflen + 1
      buffer[buflen] = "{"
      local order = valmeta and valmeta.__jsonorder or globalorder
      if order then
        local used = {}
        n = #order
        for i = 1, n do
          local k = order[i]
          local v = value[k]
          if v then
            used[k] = true
            buflen, msg = addpair(k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            prev = true -- add a seperator before the next element
          end
        end
        for k, v in pairs(value) do
          if not used[k] then
            buflen, msg = addpair(k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            if not buflen then return nil, msg end
            prev = true -- add a seperator before the next element
          end
        end
      else -- unordered
        for k, v in pairs(value) do
          buflen, msg = addpair(k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
          if not buflen then return nil, msg end
          prev = true -- add a seperator before the next element
        end
      end
      if indent then
        buflen = addnewline2(level - 1, buffer, buflen)
      end
      buflen = buflen + 1
      buffer[buflen] = "}"
    end
    tables[value] = nil
  else
    return exception('unsupported type', value, state, buffer, buflen,
      "type '" .. valtype .. "' is not supported by JSON.")
  end
  return buflen
end



function json.encode(value, state)
  state = state or {}
  local oldbuffer = state.buffer
  local buffer = oldbuffer or {}
  state.buffer = buffer
  updatedecpoint()
  local ret, msg = encode2(value, state.indent, state.level or 0,
    buffer, state.bufferlen or 0, state.tables or {}, state.keyorder, state)
  if not ret then
    error(msg, 2)
  elseif oldbuffer == buffer then
    state.bufferlen = ret
    return true
  else
    state.bufferlen = nil
    state.buffer = nil
    return concat(buffer)
  end
end

local function loc(str, where)
  local line, pos, linepos = 1, 1, 0
  while true do
    pos = strfind(str, "\n", pos, true)
    if pos and pos < where then
      line = line + 1
      linepos = pos
      pos = pos + 1
    else
      break
    end
  end

  return "line " .. line .. ", column " .. (where - linepos)
end

local function unterminated(str, what, where)
  return nil, strlen(str) + 1, "unterminated " .. what .. " at " .. loc(str, where)
end

local function scanwhite(str, pos)
  while true do
    pos = strfind(str, "%S", pos)
    if not pos then return nil end
    local sub2 = strsub(str, pos, pos + 1)
    if sub2 == "\239\187" and strsub(str, pos + 2, pos + 2) == "\191" then
      -- UTF-8 Byte Order Mark
      pos = pos + 3
    elseif sub2 == "//" then
      pos = strfind(str, "[\n\r]", pos + 2)
      if not pos then return nil end
    elseif sub2 == "/*" then
      pos = strfind(str, "*/", pos + 2)
      if not pos then return nil end
      pos = pos + 2
    else
      return pos
    end
  end
end

local escapechars = {
  ["\""] = "\"",
  ["\\"] = "\\",
  ["/"] = "/",
  ["b"] = "\b",
  ["f"] = "\f",
  ["n"] = "\n",
  ["r"] = "\r",
  ["t"] = "\t"
}

local function unichar(value)
  if value < 0 then
    return nil
  elseif value <= 0x007f then
    return strchar(value)
  elseif value <= 0x07ff then
    return strchar(0xc0 + floor(value / 0x40), 0x80 + (floor(value) % 0x40))
  elseif value <= 0xffff then
    return strchar(0xe0 + floor(value / 0x1000), 0x80 + (floor(value / 0x40) % 0x40), 0x80 + (floor(value) % 0x40))
  elseif value <= 0x10ffff then
    return strchar(0xf0 + floor(value / 0x40000),
      0x80 + (floor(value / 0x1000) % 0x40),
      0x80 + (floor(value / 0x40) % 0x40),
      0x80 + (floor(value) % 0x40))
  else
    return nil
  end
end

local function scanstring(str, pos)
  local lastpos = pos + 1
  local buffer, n = {}, 0
  while true do
    local nextpos = strfind(str, "[\"\\]", lastpos)
    if not nextpos then
      return unterminated(str, "string", pos)
    end
    if nextpos > lastpos then
      n = n + 1
      buffer[n] = strsub(str, lastpos, nextpos - 1)
    end
    if strsub(str, nextpos, nextpos) == "\"" then
      lastpos = nextpos + 1
      break
    else
      local escchar = strsub(str, nextpos + 1, nextpos + 1)
      local value
      if escchar == "u" then
        value = tonumber(strsub(str, nextpos + 2, nextpos + 5), 16)
        if value then
          local value2
          if 0xD800 <= value and value <= 0xDBff then
            -- we have the high surrogate of UTF-16. Check if there is a
            -- low surrogate escaped nearby to combine them.
            if strsub(str, nextpos + 6, nextpos + 7) == "\\u" then
              value2 = tonumber(strsub(str, nextpos + 8, nextpos + 11), 16)
              if value2 and 0xDC00 <= value2 and value2 <= 0xDFFF then
                value = (value - 0xD800) * 0x400 + (value2 - 0xDC00) + 0x10000
              else
                value2 = nil -- in case it was out of range for a low surrogate
              end
            end
          end
          value = value and unichar(value)
          if value then
            if value2 then
              lastpos = nextpos + 12
            else
              lastpos = nextpos + 6
            end
          end
        end
      end

      if not value then
        value = escapechars[escchar] or escchar
        lastpos = nextpos + 2
      end
      n = n + 1
      buffer[n] = value
    end
  end
  if n == 1 then
    return buffer[1], lastpos
  elseif n > 1 then
    return concat(buffer), lastpos
  else
    return "", lastpos
  end
end
local scanvalue -- forward declaration
local function scantable(what, closechar, str, startpos, nullval, objectmeta, arraymeta)
  local len = strlen(str)
  local tbl, n = {}, 0
  local pos = startpos + 1
  if what == 'object' then
    setmetatable(tbl, objectmeta)
  else
    setmetatable(tbl, arraymeta)
  end
  while true do
    pos = scanwhite(str, pos)
    if not pos then return unterminated(str, what, startpos) end
    local char = strsub(str, pos, pos)
    if char == closechar then
      return tbl, pos + 1
    end
    local val1, err
    val1, pos, err = scanvalue(str, pos, nullval, objectmeta, arraymeta)
    if err then return nil, pos, err end
    pos = scanwhite(str, pos)
    if not pos then return unterminated(str, what, startpos) end
    char = strsub(str, pos, pos)
    if char == ":" then
      if val1 == nil then
        return nil, pos, "cannot use nil as table index (at " .. loc(str, pos) .. ")"
      end
      pos = scanwhite(str, pos + 1)
      if not pos then return unterminated(str, what, startpos) end
      local val2
      val2, pos, err = scanvalue(str, pos, nullval, objectmeta, arraymeta)
      if err then return nil, pos, err end
      tbl[val1] = val2
      pos = scanwhite(str, pos)
      if not pos then return unterminated(str, what, startpos) end
      char = strsub(str, pos, pos)
    else
      n = n + 1
      tbl[n] = val1
    end
    if char == "," then
      pos = pos + 1
    end
  end
end
scanvalue = function(str, pos, nullval, objectmeta, arraymeta)
  pos = pos or 1
  pos = scanwhite(str, pos)
  if not pos then
    return nil, strlen(str) + 1, "no valid JSON value (reached the end)"
  end
  local char = strsub(str, pos, pos)
  if char == "{" then
    return scantable('object', "}", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "[" then
    return scantable('array', "]", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "\"" then
    return scanstring(str, pos)
  else
    local pstart, pend = strfind(str, "^%-?[%d%.]+[eE]?[%+%-]?%d*", pos)
    if pstart then
      local number = str2num(strsub(str, pstart, pend))
      if number then
        return number, pend + 1
      end
    end
    pstart, pend = strfind(str, "^%a%w*", pos)
    if pstart then
      local name = strsub(str, pstart, pend)
      if name == "true" then
        return true, pend + 1
      elseif name == "false" then
        return false, pend + 1
      elseif name == "null" then
        return nullval, pend + 1
      end
    end
    return nil, pos, "no valid JSON value at " .. loc(str, pos)
  end
end
local function optionalmetatables(...)
  if select("#", ...) > 0 then
    return ...
  else
    return { __jsontype = 'object' }, { __jsontype = 'array' }
  end
end
function json.decode(str, pos, nullval, ...)
  local objectmeta, arraymeta = optionalmetatables(...)
  return scanvalue(str, pos, nullval, objectmeta, arraymeta)
end
function json.use_lpeg()
  local g = require("lpeg")
  if g.version() == "0.11" then
    error "due to a bug in LPeg 0.11, it cannot be used for JSON matching"
  end
  local pegmatch = g.match
  local P, S, R = g.P, g.S, g.R
  local function ErrorCall(str, pos, msg, state)
    if not state.msg then
      state.msg = msg .. " at " .. loc(str, pos)
      state.pos = pos
    end
    return false
  end
  local function Err(msg)
    return g.Cmt(g.Cc(msg) * g.Carg(2), ErrorCall)
  end
  local SingleLineComment = P "//" * (1 - S "\n\r") ^ 0
  local MultiLineComment = P "/*" * (1 - P "*/") ^ 0 * P "*/"
  local Space = (S " \n\r\t" + P "\239\187\191" + SingleLineComment + MultiLineComment) ^ 0
  local PlainChar = 1 - S "\"\\\n\r"
  local EscapeSequence = (P "\\" * g.C(S "\"\\/bfnrt" + Err "unsupported escape sequence")) / escapechars
  local HexDigit = R("09", "af", "AF")
  local function UTF16Surrogate(match, pos, high, low)
    high, low = tonumber(high, 16), tonumber(low, 16)
    if 0xD800 <= high and high <= 0xDBff and 0xDC00 <= low and low <= 0xDFFF then
      return true, unichar((high - 0xD800) * 0x400 + (low - 0xDC00) + 0x10000)
    else
      return false
    end
  end
  local function UTF16BMP(hex)
    return unichar(tonumber(hex, 16))
  end
  local U16Sequence = (P "\\u" * g.C(HexDigit * HexDigit * HexDigit * HexDigit))
  local UnicodeEscape = g.Cmt(U16Sequence * U16Sequence, UTF16Surrogate) + U16Sequence / UTF16BMP
  local Char = UnicodeEscape + EscapeSequence + PlainChar
  local String = P "\"" * g.Cs(Char ^ 0) * (P "\"" + Err "unterminated string")
  local Integer = P "-" ^ (-1) * (P "0" + (R "19" * R "09" ^ 0))
  local Fractal = P "." * R "09" ^ 0
  local Exponent = (S "eE") * (S "+-") ^ (-1) * R "09" ^ 1
  local Number = (Integer * Fractal ^ (-1) * Exponent ^ (-1)) / str2num
  local Constant = P "true" * g.Cc(true) + P "false" * g.Cc(false) + P "null" * g.Carg(1)
  local SimpleValue = Number + String + Constant
  local ArrayContent, ObjectContent
  -- The functions parsearray and parseobject parse only a single value/pair
  -- at a time and store them directly to avoid hitting the LPeg limits.
  local function parsearray(str, pos, nullval, state)
    local obj, cont
    local npos
    local t, nt = {}, 0
    repeat
      obj, cont, npos = pegmatch(ArrayContent, str, pos, nullval, state)
      if not npos then break end
      pos = npos
      nt = nt + 1
      t[nt] = obj
    until cont == 'last'
    return pos, setmetatable(t, state.arraymeta)
  end
  local function parseobject(str, pos, nullval, state)
    local obj, key, cont
    local npos
    local t = {}
    repeat
      key, obj, cont, npos = pegmatch(ObjectContent, str, pos, nullval, state)
      if not npos then break end
      pos = npos
      t[key] = obj
    until cont == 'last'
    return pos, setmetatable(t, state.objectmeta)
  end

  local Array = P "[" * g.Cmt(g.Carg(1) * g.Carg(2), parsearray) * Space * (P "]" + Err "']' expected")
  local Object = P "{" * g.Cmt(g.Carg(1) * g.Carg(2), parseobject) * Space * (P "}" + Err "'}' expected")
  local Value = Space * (Array + Object + SimpleValue)
  local ExpectedValue = Value + Space * Err "value expected"
  ArrayContent = Value * Space * (P "," * g.Cc 'cont' + g.Cc 'last') * g.Cp()
  local Pair = g.Cg(Space * String * Space * (P ":" + Err "colon expected") * ExpectedValue)
  ObjectContent = Pair * Space * (P "," * g.Cc 'cont' + g.Cc 'last') * g.Cp()
  local DecodeValue = ExpectedValue * g.Cp()

  function json.decode(str, pos, nullval, ...)
    local state = {}
    state.objectmeta, state.arraymeta = optionalmetatables(...)
    local obj, retpos = pegmatch(DecodeValue, str, pos, nullval, state)
    if state.msg then
      return nil, state.pos, state.msg
    else
      return obj, retpos
    end
  end
  json.use_lpeg = function() return json end
  json.using_lpeg = true
  return json
end

if always_try_using_lpeg then
  pcall(json.use_lpeg)
end

local builder = {
    elements = {},
    selected_element = nil,
    dragging = false,
    drag_offset = { x = 0, y = 0 },
}

local element_types = {
    "Button",
    "Checkbox",
    "Slider",
    "Text",
    "Rect",
    "Line"
}

function builder:add_element(type)
    table.insert(self.elements, {
        type = type,
        pos = { x = 100, y = 100 },
        size = { w = 120, h = 30 },
        label = type .. " Label",
        value = (type == "Checkbox" and { false }) or (type == "Slider" and { 0.0 }) or nil,
    })
end

function builder:draw_element(e, id)
    ImGui.SetCursorPos(e.pos.x, e.pos.y)
    -- iterate through element types and add them accordingly ig
    -- idk i was high asf writing this 
    if e.type == "Button" then
        ImGui.Button(e.label, e.size.w, e.size.h)
    elseif e.type == "Checkbox" then
        e.value[1] = ImGui.Checkbox(e.label, e.value[1])
    elseif e.type == "Slider" then
        e.value[1] = ImGui.SliderFloat(e.label, e.value[1], 0.0, 100.0)
    elseif e.type == "Text" then
        ImGui.Text(e.label)
    elseif e.type == "Rect" then
        local win_pos = { ImGui.GetWindowPos() }
        local start_x = win_pos[1] + e.pos.x
        local start_y = win_pos[2] + e.pos.y
        local end_x = start_x + e.size.w
        local end_y = start_y + e.size.h
        ImGui.AddRect(start_x, start_y, end_x, end_y, 255, 255, 255, 255)
    elseif e.type == "Line" then
        local win_pos = { ImGui.GetWindowPos() }
        local start_x = win_pos[1] + e.pos.x
        local start_y = win_pos[2] + e.pos.y
        local end_x = start_x + e.size.w
        local end_y = start_y + e.size.h
        ImGui.AddLine(start_x, start_y, end_x, end_y, 255, 255, 25, 255)
    end

    local mouse_x, mouse_y = ImGui.GetMousePos()
    local win_pos = { ImGui.GetWindowPos() }
    local element_screen_x = win_pos[1] + e.pos.x
    local element_screen_y = win_pos[2] + e.pos.y
    local element_screen_x2 = element_screen_x + e.size.w
    local element_screen_y2 = element_screen_y + e.size.h

    local hover
    if e.type == "Line" then
        local win_pos = { ImGui.GetWindowPos() }
        local start_x = win_pos[1] + e.pos.x
        local start_y = win_pos[2] + e.pos.y
        local end_x = start_x + e.size.w
        local end_y = start_y + e.size.h

        local dx = end_x - start_x
        local dy = end_y - start_y
        local length_sq = dx * dx + dy * dy
        -- math here was helped with AI cuz i suck at math xDDD 
        local t = ((mouse_x - start_x) * dx + (mouse_y - start_y) * dy) / (length_sq + 0.0001)
        t = math.max(0, math.min(1, t))
        local proj_x = start_x + t * dx
        local proj_y = start_y + t * dy
        local dist = math.sqrt((mouse_x - proj_x) ^ 2 + (mouse_y - proj_y) ^ 2)

        hover = dist <= 5.0
    else
        hover = (mouse_x >= element_screen_x and mouse_x <= element_screen_x2) and
            (mouse_y >= element_screen_y and mouse_y <= element_screen_y2)
    end

    hover = (mouse_x >= element_screen_x and mouse_x <= element_screen_x2) and
        (mouse_y >= element_screen_y and mouse_y <= element_screen_y2)

    local resize_zone = 8
    local resize_hover = (mouse_x >= element_screen_x2 - resize_zone and mouse_x <= element_screen_x2) and
        (mouse_y >= element_screen_y2 - resize_zone and mouse_y <= element_screen_y2)

    if hover and ImGui.IsMouseClicked(0) then
        self.selected_element = id
        self.dragging = true
        self.drag_offset.x = mouse_x - element_screen_x
        self.drag_offset.y = mouse_y - element_screen_y
    end

    if resize_hover and ImGui.IsMouseClicked(0) then
        self.selected_element = id
        self.resizing = true
    end

    if self.selected_element == id then
        if self.dragging and ImGui.IsMouseDown(0) then
            e.pos.x = math.floor((mouse_x - win_pos[1] - self.drag_offset.x) / 10) * 10
            e.pos.y = math.floor((mouse_y - win_pos[2] - self.drag_offset.y) / 10) * 10
        elseif self.resizing and ImGui.IsMouseDown(0) then
            e.size.w = math.max(10, math.floor((mouse_x - element_screen_x) / 10) * 10)
            e.size.h = math.max(10, math.floor((mouse_y - element_screen_y) / 10) * 10)
        else
            self.dragging = false
            self.resizing = false
        end
    end
end

FileMgr.CreateDir(FileMgr.GetMenuRootPath() .. "\\Lua\\ImGuiExample\\MyBuilder")

function builder:save_to_file(path)
    local data = {}
    for _, e in ipairs(self.elements) do
        table.insert(data, {
            type = e.type,
            pos = { x = e.pos.x, y = e.pos.y },
            size = { w = e.size.w, h = e.size.h },
            label = e.label,
            value = e.value,
        })
    end

    -- writing to files to make it look pretty using json and the indent function  
    local encoded = json.encode(data, { indent = true })

    if FileMgr.DoesFileExist(path) then
        FileMgr.DeleteFile(path)
    end

    FileMgr.WriteFileContent(path, encoded, false)
end


function builder:load_from_file(path)
    if not FileMgr.DoesFileExist(path) then
        return
    end

    local encoded = FileMgr.ReadFileContent(path)
    local data = json.decode(encoded)

    self.elements = {}
    for _, e in ipairs(data) do
        table.insert(self.elements, {
            type = e.type,
            pos = { x = e.pos.x, y = e.pos.y },
            size = { w = e.size.w, h = e.size.h },
            label = e.label,
            value = e.value,
        })
    end
end

function builder:draw()
    ImGui.Begin("ImGui Builder", true, ImGuiWindowFlags.NoMove)
    ImGui.Text("Add Element:")
    for _, t in ipairs(element_types) do
        if ImGui.Button("Add " .. t) then
            self:add_element(t)
        end
    end
    ImGui.Separator()
    if self.selected_element then
        local elem = self.elements[self.selected_element]
        ImGui.Text("Selected: " .. elem.type)

        elem.label = ImGui.InputText("Label", elem.label)

        elem.size.w = ImGui.SliderFloat("Width", elem.size.w, 0, 2000)
        elem.size.h = ImGui.SliderFloat("Height", elem.size.h, 0, 2000)

        if elem.type == "Slider" then
            elem.value[1] = ImGui.SliderFloat("Slider Value", elem.value[1], 0.0, 100.0)
        elseif elem.type == "Checkbox" then
            elem.value[1] = ImGui.Checkbox("Checkbox Value", elem.value[1])
        end
        if ImGui.Button("Delete Element") then
            table.remove(self.elements, self.selected_element)
            self.selected_element = nil
        end
        if ImGui.Button("Save") then
            builder:save_to_file(FileMgr.GetMenuRootPath() .. "\\Lua\\MyBuilder\\elements.json")
        end
        if ImGui.Button("Load") then
            builder:load_from_file(FileMgr.GetMenuRootPath() .. "\\Lua\\MyBuilder\\elements.json")
        end
    end
    ImGui.End()

    local display_w, display_h = ImGui.GetDisplaySize()
    ImGui.SetNextWindowPos(300, 50)
    ImGui.SetNextWindowSize(display_w - 320, display_h - 60)

    ImGui.Begin("Canvas", true, ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.NoMove)

    for id, e in ipairs(self.elements) do
        self:draw_element(e, id)
    end

    ImGui.End()
end

FeatureMgr.AddFeature(Utils.Joaat("test1"), "test1",eFeatureType.Button,"desc", function()
	GUI.AddToast("test1", "why", 5000, eToastPos.TOP_RIGHT)
end)

FeatureMgr.AddFeature(Utils.Joaat("test2"), "test2",eFeatureType.Button,"desc", function()
	GUI.AddToast("test2", "w1hy", 5000, eToastPos.TOP_RIGHT)
end)

local Menu = {}
local switchTabs = 0
local pog = false
local ImGui_Active = true 

local ICON_FA_USER = ""
local ICON_FA_BURN = ""
local ICON_FA_MAP_MARKER = ""
local ICON_FA_NETWORK_WIRED = ""
local ICON_FA_CAR = ""
local ICON_FA_MONEY_BILL = ""
local ICON_FA_GLOBE = ""
local ICON_FA_COGS = ""
function Menu.Render()
    ImGui.SetNextWindowSize(570, 521)
    if ImGui.Begin("cherax lookin ass GUI xD", ImGui_Active, ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoScrollbar) then
        ImGui.Columns(2)
        ImGui.SetColumnOffset(1, 65.0)

        ImGui.SetWindowFontScale(2.0)

        if ImGui.Button(ICON_FA_USER, 60, 60) then switchTabs = 0 end
        if ImGui.Button(ICON_FA_BURN, 60, 60) then switchTabs = 1 end
        if ImGui.Button(ICON_FA_MAP_MARKER, 60, 60) then switchTabs = 2 end
        if ImGui.Button(ICON_FA_NETWORK_WIRED, 60, 60) then switchTabs = 3 end
        if ImGui.Button(ICON_FA_CAR, 60, 60) then switchTabs = 4 end
        if ImGui.Button(ICON_FA_MONEY_BILL, 60, 60) then switchTabs = 5 end
        if ImGui.Button(ICON_FA_GLOBE, 60, 60) then switchTabs = 6 end
        if ImGui.Button(ICON_FA_COGS, 60, 60) then switchTabs = 7 end

        ImGui.SetWindowFontScale(1.0)

        ImGui.NextColumn()

        ImGui.SetCursorPos(220, 5)
        ImGui.Text("Cherax looking ass GUI xD")
        ImGui.Separator()

        -- Tab logic
        if switchTabs == 0 then
            Menu.SelfSub()
        elseif switchTabs == 7 then
            Menu.SettingsSub()
        else
            ImGui.Text("This tab is empty.")
        end
        ImGui.End()
    end
end

function Menu.SelfSub()
    if ImGui.BeginChild("Movement", 175, 175, true) then
        ImGui.Separator()
        ImGui.Text("Movement")
        pog = ImGui.Checkbox("Distant", pog)
        ImGui.PushStyleColor(ImGuiCol.Button, 0.8, 0.0, 0.0, 1)
        ClickGUI.RenderFeature(Utils.Joaat("test1"))
        ImGui.PopStyleColor()
		ClickGUI.RenderFeature(Utils.Joaat("test2"))
        ImGui.Button("TEST!")
        ImGui.EndChild()
    end
end

function Menu.SettingsSub()
    ImGui_Active = ImGui.Checkbox("Random checkmark ig?", ImGui_Active)
end

local checkbox_state = false
local float_slider = 0.42
local int_slider = 3
local drag_value = 0.1
local combo_index = 0
local input_text = "Hello"
local color_picker = {1.0, 0.5, 0.2, 1.0}
local radio_option = 1

local texturePath = FileMgr.GetMenuRootPath() .. "\\Lua\\ImGuiExample"
FileMgr.CreateDir(texturePath)

myCustomCheckbox = myCustomCheckbox or false

function DrawCustomCheckbox(id, label, state, onToggle)
    local posX, posY = ImGui.GetCursorScreenPos()
    local boxSize = 16
    local labelOffset = 8

    ImGui.InvisibleButton("##" .. id, boxSize, boxSize)
    local clicked = ImGui.IsItemClicked()

    if clicked then
        state = not state
        if onToggle then
            onToggle(state)
        end
    end

    ImGui.AddRect(posX, posY, posX + boxSize, posY + boxSize, 255, 255, 255, 255, 3.0, 0, 1.5)

    if state then
        local p1x = posX + 3
        local p1y = posY + boxSize / 2

        local p2x = posX + boxSize / 2 - 1
        local p2y = posY + boxSize - 4

        local p3x = posX + boxSize - 3
        local p3y = posY + 4

        ImGui.AddLine(p1x, p1y, p2x, p2y, 0, 255, 0, 255, 2.0)
        ImGui.AddLine(p2x, p2y, p3x, p3y, 0, 255, 0, 255, 2.0)
    end

    ImGui.SameLine()
    ImGui.SetCursorScreenPos(posX + boxSize + labelOffset, posY)
    ImGui.Text(label)

    return state
end


local imagePath = texturePath .. "\\kyuubii1.png"

function DownloadAndSaveImage()
    -- can be used to download natives files or other files
    --if you just want to use the response then u can just have a return value for the responseString
    local url = "https://raw.githubusercontent.com/Elfish-beaker/object-list/main/knight.png"
    local curlObject = Curl.Easy()
    curlObject:Setopt(eCurlOption.CURLOPT_URL, url)
    --curlObject:AddHeader("Content-Type: application/json")
    --curlObject:AddHeader("User-Agent: Lua/1.0")  -- optional headers
    curlObject:Perform()
    while not curlObject:GetFinished() do
        Script.Yield()
    end

    local responseCode, responseString = curlObject:GetResponse()  
    --Logger.LogInfo("Response Preview: " .. responseString) 
    --- ^^^^^ this is just for debugging purposes commented out because it outputs garbage in the console
    if responseCode == eCurlCode.CURLE_OK then
        FileMgr.WriteFileContent(imagePath, responseString, true)
    else
        Logger.LogInfo("Error with downloading image: " .. responseCode)
        return
    end
    --return response
end

-- to use the response as data do something like this 
-- local responsedata = DownloadAndSaveImage() as the return returns the responseString

if not FileMgr.DoesFileExist(imagePath) then
    Logger.LogInfo("Texture does not exist, creating")
    Script.QueueJob(DownloadAndSaveImage)
--[[else 
    Logger.LogInfo("Texture already exists, still downloading for debugging")
    Script.QueueJob(DownloadAndSaveImage)]]

end

local ImageId = Texture.LoadTexture(imagePath) -- must be absolute path
local ImageTexture = Texture.GetTexture(ImageId) -- this returns a D3D11Texture
local features = {
    Utils.Joaat("flagAlwaysAutoResize"),
    Utils.Joaat("flagNoCollapse"),
    Utils.Joaat("flagNoDecoration"),
    Utils.Joaat("flagNoTitleBar"),
    Utils.Joaat("closeGUIwithcherax"),
    Utils.Joaat("textColor"),
    Utils.Joaat("textDisabledColor"),
    Utils.Joaat("windowBgColor"),
    Utils.Joaat("childBgColor"),
    Utils.Joaat("borderColor"),
    Utils.Joaat("borderShadowColor"),
    Utils.Joaat("frameBgColor"),
    Utils.Joaat("titleBgColor"),
    Utils.Joaat("scrollbarBgColor"),
    Utils.Joaat("scrollbarGrabColor"),
    Utils.Joaat("checkMarkColor"),
    Utils.Joaat("sliderGrabColor"),
    Utils.Joaat("sliderGrabActiveColor"),
    Utils.Joaat("buttonColor"),
    Utils.Joaat("headerColor"),
    Utils.Joaat("textColored")
}
local flagAlwaysAutoResize = FeatureMgr.AddFeature(Utils.Joaat("flagAlwaysAutoResize"), "Always Auto Resize", eFeatureType.Toggle):SetBoolValue(true)
local flagNoCollapse = FeatureMgr.AddFeature(Utils.Joaat("flagNoCollapse"), "No Collapse", eFeatureType.Toggle)
local flagNoDecoration = FeatureMgr.AddFeature(Utils.Joaat("flagNoDecoration"), "No Decoration", eFeatureType.Toggle)
local flagNoTitleBar = FeatureMgr.AddFeature(Utils.Joaat("flagNoTitleBar"), "No Title Bar", eFeatureType.Toggle)
local closeGUI = FeatureMgr.AddFeature(Utils.Joaat("closeGUIwithcherax"), "Close GUI", eFeatureType.Toggle)
local textColor = FeatureMgr.AddFeature(Utils.Joaat("textColor"), "Text Color", eFeatureType.InputColor4):SetColor(255, 255, 255, 255)
local textDisabledColor = FeatureMgr.AddFeature(Utils.Joaat("textDisabledColor"), "Text Disabled Color", eFeatureType.InputColor4):SetColor(150, 150, 150, 255)
local windowBgColor = FeatureMgr.AddFeature(Utils.Joaat("windowBgColor"), "Window Background Color", eFeatureType.InputColor4):SetColor(50, 50, 50, 255)
local childBgColor = FeatureMgr.AddFeature(Utils.Joaat("childBgColor"), "Child Background Color", eFeatureType.InputColor4):SetColor(60, 60, 60, 255)
local borderColor = FeatureMgr.AddFeature(Utils.Joaat("borderColor"), "Border Color", eFeatureType.InputColor4):SetColor(100, 100, 100, 255)
local borderShadowColor = FeatureMgr.AddFeature(Utils.Joaat("borderShadowColor"), "Border Shadow Color", eFeatureType.InputColor4):SetColor(0, 0, 0, 255)
local frameBgColor = FeatureMgr.AddFeature(Utils.Joaat("frameBgColor"), "Frame Background Color", eFeatureType.InputColor4):SetColor(80, 80, 80, 255)
local titleBgColor = FeatureMgr.AddFeature(Utils.Joaat("titleBgColor"), "Title Background Color", eFeatureType.InputColor4):SetColor(40, 40, 40, 255)local scrollbarBgColor = FeatureMgr.AddFeature(Utils.Joaat("scrollbarBgColor"), "Scrollbar Background Color", eFeatureType.InputColor4):SetColor(70, 70, 70, 255)
local scrollbarGrabColor = FeatureMgr.AddFeature(Utils.Joaat("scrollbarGrabColor"), "Scrollbar Grab Color", eFeatureType.InputColor4):SetColor(80, 80, 80, 255)
local checkMarkColor = FeatureMgr.AddFeature(Utils.Joaat("checkMarkColor"), "Check Mark Color", eFeatureType.InputColor4):SetColor(255, 255, 255, 255)
local sliderGrabColor = FeatureMgr.AddFeature(Utils.Joaat("sliderGrabColor"), "Slider Grab Color", eFeatureType.InputColor4):SetColor(200, 200, 200, 255)
local sliderGrabActiveColor = FeatureMgr.AddFeature(Utils.Joaat("sliderGrabActiveColor"), "Slider Grab Active Color", eFeatureType.InputColor4):SetColor(255, 255, 255, 255)
local buttonColor = FeatureMgr.AddFeature(Utils.Joaat("buttonColor"), "Button Color", eFeatureType.InputColor4):SetColor(100, 100, 100, 255)
local headerColor = FeatureMgr.AddFeature(Utils.Joaat("headerColor"), "Header Color", eFeatureType.InputColor4):SetColor(80, 80, 80, 255)
local textColored = FeatureMgr.AddFeature(Utils.Joaat("textColored"), "Text Colored", eFeatureType.InputColor4):SetColor(255, 0, 0, 255)
local DrawBuilderTool = FeatureMgr.AddFeature(Utils.Joaat("DrawBuilderTool"), "Draw Builder Tool", eFeatureType.Toggle):SetBoolValue(false)
local DrawcustomGUI = FeatureMgr.AddFeature(Utils.Joaat("DrawcustomGUI"), "Draw Custom GUI", eFeatureType.Toggle):SetBoolValue(false)

local welcome = {
    showSplash = true,
    showWelcomePopup = false,
    progress = 0.0,
    colorChangeInterval = 100,
    lastColorChange = Time.GetEpocheMs(),
    progressSpeed = 0.0095,
    playerName = "Player",
    welcomeStartTime = 0,
    popupSize = 215,
    maxPopupWidth = 391,
    maxPopupHeight = 135,
    popupGrowthDuration = 2000,
    textColorChangeInterval = 300,
    lastTextColorChange = Time.GetEpocheMs(),
    textColor = {1, 1, 1, 255}
}

function welcome.updateColors()
    welcome.textColor = {math.random(0,1), math.random(0,1), math.random(0,1), 1}
end

function welcome.getPlayerName()
    local localPlayerId = GTA.GetLocalPlayerId()
    local localPlayer = Players.GetById(localPlayerId)
    return Players.GetName(localPlayerId) or Natives.InvokeString(0x198D161F458ECC7F) or "Player"
end

function welcome.onLoadingComplete()
    welcome.showSplash = false
    welcome.showWelcomePopup = true
    welcome.playerName = welcome.getPlayerName()
    welcome.welcomeStartTime = Time.GetEpocheMs()
    welcome.popupSize = 100
end

function welcome.renderSplashScreen()
    if not welcome.showSplash then return end
    local currentTime = Time.GetEpocheMs()
    if currentTime - welcome.lastColorChange > welcome.colorChangeInterval then
        welcome.updateColors()
        welcome.lastColorChange = currentTime
    end
    welcome.progress = math.min(welcome.progress + welcome.progressSpeed, 1.0)
    if welcome.progress >= 1.0 then
        welcome.onLoadingComplete()
        return
    end
    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0, 0, 0, 1.0)
    local screenWidth, screenHeight = ImGui.GetDisplaySize()
    ImGui.SetNextWindowSize(275, 100, ImGuiCond.Always)
    ImGui.SetNextWindowPos(screenWidth / 2 - 200, screenHeight / 2 - 125)
    ImGui.Begin("##splash", true, ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoResize)
    ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("ImGui Example Script")) / 2)
    ImGui.TextColored(2, 2, 2, 1, "ImGui Example Script")
    ImGui.Spacing()
    ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Welcome to the ImGui Example Script")) / 2)
    ImGui.TextColored(1, 1, 1, 1, "Welcome to the ImGui Example Script")
    ImGui.Spacing()
    ImGui.PushStyleColor(ImGuiCol.PlotHistogram, welcome.textColor[1], welcome.textColor[2], welcome.textColor[3], 1.0)
    local barWidth = ImGui.GetWindowWidth() - 40
    local barHeight = 20
    ImGui.ProgressBar(welcome.progress, barWidth, barHeight)
    local textWidth = ImGui.CalcTextSize("Loading...")
    ImGui.SetCursorPosX((ImGui.GetWindowWidth() / 2) - (textWidth / 2))
    ImGui.SetCursorPosY(ImGui.GetCursorPosY() - (barHeight / 0.85))
    ImGui.TextColored(0, 0, 0, 1, "Loading...")
    ImGui.PopStyleColor()
    ImGui.End()
    ImGui.PopStyleColor()
end

function welcome.renderWelcomePopup()
    if not welcome.showWelcomePopup then return end
    local screenWidth, screenHeight = ImGui.GetDisplaySize()
    local elapsedTime = Time.GetEpocheMs() - welcome.welcomeStartTime
    local growthFactor = math.min(elapsedTime / welcome.popupGrowthDuration, 1)
    welcome.popupSize = 100 + (welcome.maxPopupWidth - 100) * growthFactor
    local growthFactor1 = math.min(elapsedTime / welcome.popupGrowthDuration, 1)
    local popupSize1 = 50 + (welcome.maxPopupHeight - 50) * growthFactor1
    if elapsedTime > welcome.popupGrowthDuration + 5000 then
        welcome.showWelcomePopup = false
        return
    end
    local currentTime = Time.GetEpocheMs()
    if currentTime - welcome.lastTextColorChange > welcome.textColorChangeInterval then
        welcome.updateColors()
        welcome.lastTextColorChange = currentTime
    end
    ImGui.SetNextWindowSize(welcome.popupSize, popupSize1, ImGuiCond.Always)
    ImGui.SetNextWindowPos(screenWidth / 2 - welcome.popupSize / 2, screenHeight / 2 - welcome.popupSize / 2)
    ImGui.Begin("##welcome_popup", true, ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoResize)
    ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Welcome, " .. welcome.playerName .. "!")) / 2)
    ImGui.TextColored(welcome.textColor[1], welcome.textColor[2], welcome.textColor[3], 1.0, "Welcome, " .. welcome.playerName .. "!")
    ImGui.Spacing()
    ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("to the ImGui Example Script!")) / 2)
    ImGui.TextColored(welcome.textColor[1], welcome.textColor[2], welcome.textColor[3], 1.0, "to the ImGui Example Script!")
    ImGui.Spacing()
    ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Made By Elfish-Beaker")) / 2)
    ImGui.TextColored(welcome.textColor[1], welcome.textColor[2], welcome.textColor[3], 1.0, "Made By Elfish-Beaker")
    ImGui.Spacing()
    ImGui.End()
end

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, welcome.renderSplashScreen)
EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, welcome.renderWelcomePopup)


local function onPresent()
    if not GUI.IsOpen() and closeGUI:IsToggled() then return end 
    --if gui is not open then make it not run the function until it is open 
    -- since ON_PRESENT is pretty much always active 
    if DrawBuilderTool:IsToggled() then 
        builder:draw()
    end
    if DrawcustomGUI:IsToggled() then 
        Menu.Render()
    end
    local stylepushcount = 0
    local flags = 0  
    -- if the toggle for the flags is true then add the flag to the flags variable 
    if flagAlwaysAutoResize:IsToggled() then flags = flags | ImGuiWindowFlags.AlwaysAutoResize end
    if flagNoCollapse:IsToggled() then flags = flags | ImGuiWindowFlags.NoCollapse end
    if flagNoDecoration:IsToggled() then flags = flags | ImGuiWindowFlags.NoDecoration end
    if flagNoTitleBar:IsToggled() then flags = flags | ImGuiWindowFlags.NoTitleBar end
    local width, height = ImGui.GetWindowSize()

    local colors = {
        { ImGuiCol.Text,        textColor:GetColor() },
        { ImGuiCol.TextDisabled, textDisabledColor:GetColor() },
        { ImGuiCol.WindowBg,    windowBgColor:GetColor() },
        { ImGuiCol.ChildBg,     childBgColor:GetColor() },
        { ImGuiCol.Border,      borderColor:GetColor() },
        { ImGuiCol.BorderShadow, borderShadowColor:GetColor() },
        { ImGuiCol.FrameBg,     frameBgColor:GetColor() },
        { ImGuiCol.TitleBg,     titleBgColor:GetColor() },
        { ImGuiCol.ScrollbarBg, scrollbarBgColor:GetColor() },
        { ImGuiCol.ScrollbarGrab, scrollbarGrabColor:GetColor() },
        { ImGuiCol.CheckMark,   checkMarkColor:GetColor() },
        { ImGuiCol.SliderGrab,  sliderGrabColor:GetColor() },
        { ImGuiCol.SliderGrabActive, sliderGrabActiveColor:GetColor() },
        { ImGuiCol.Button,      buttonColor:GetColor() },
        { ImGuiCol.Header,      headerColor:GetColor() },
    }
    
    for _, color in ipairs(colors) do
        local col, r, g, b, a = table.unpack(color)
        ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, a / 255 )
        stylepushcount = stylepushcount + 1
    end
    if ImGui.Begin("ImGui API Showcase##23423", true, flags) then
        local tex
        if ImageTexture then
            tex = ImageTexture:GetCurrent()
        end
        if tex then
            local tex = ImageTexture:GetCurrent()
            local windowPosX, windowPosY = ImGui.GetWindowPos()
            local windowWidth, windowHeight = ImGui.GetWindowSize()
            local displayHeight = ImGui.GetDisplaySize()
            local imageSize = displayHeight * 0.04

            local centerX = windowPosX + windowWidth / 2
            local centerY = windowPosY + windowHeight / 2
            local imageX1 = centerX - imageSize / 2
            local imageY1 = centerY - imageSize / 2
            local imageX2 = centerX + imageSize / 2
            local imageY2 = centerY + imageSize / 2

            ImGui.AddImage(--[[texture]]tex, --[[minX]]imageX1, --[[minY]]imageY1 - 90, --[[maxX]]imageX2, --[[maxY]]imageY2 - 90 
            --[[these are optional 
            max_y, uv_min_x, uv_min_y, uv_max_x, uv_max_y, color
            check the ImGui documentation 
            link to documentation is 
            https://github.com/SATTY91/Cherax-Lua-API-Documentation]]
            )
        else
            ImGui.Text("Texture SRV is nil")
        end
        if ImGui.BeginTabBar("MyTabBar##rootbar") then 
            -- always make sure to have an end call with these begin functions
            -- or else you will have ImGui errors or crash depending on the usage 

            if ImGui.BeginTabItem("Controls##tab1") then
                ImGui.Text(("FPS: %.1f"):format(ImGui.GetFrameRate())) 
                --using format in a string can allow you to put variables 
                --or index's into the string hence the "format" could also do 
                -- ImGui.Text(string.format("FPS: %.1f", ImGui.GetFrameRate()))
                -- but using :format is cleaner looking imo 
                ImGui.Separator()
                ImGui.AddCircle(--[[X]]width / 2, --[[Y]]height / 2, --[[radius]]90, --[[r]]1, --[[g]]1, --[[b]]1, --[[a]]1, --[[numsegments]]80, --[[thickness]]10)
                ImGui.Text("ImGui API Showcase")

                ImGui.Text("Regular Text")
                local textColoredr, textColoredg, textColoredb, textColoreda = textColored:GetColor()
                ImGui.TextColored(textColoredr / 255, textColoredg / 255, textColoredb / 255, textColoreda / 255,"Colored")
                ImGui.TextDisabled("Disabled")
                ImGui.BulletText("Bullet")

                ImGui.Separator()
                    if ImGui.Button("Click##btn1") then
                        if ImGui.IsItemHovered(ImGuiHoveredFlags.None) then 
                            ImGui.PushStyleColor(ImGuiCol.Button, 1, 0, 0, 1)
                            ImGui.PopStyleColor()
                            GUI.AddToast("ImGui Example Script", "Button Clicked", 5000, eToastPos.TOP_RIGHT)
                        end
                    end
                    
                ImGui.SameLine()
                checkbox_state, _ = ImGui.Checkbox("Enable##chk1", checkbox_state)
                ImGui.SameLine()
                myCustomCheckbox = DrawCustomCheckbox("mycheckbox", "Custom Checkmark", myCustomCheckbox, function(state)
                    myCustomCheckbox = state
                    if state then
                        print("Checkbox is checked")
                    else
                        print("Checkbox is unchecked")
                    end
                end)
                ImGui.Text("WARNING BUILDER TOOL TAKES UP THE WHOLE SCREEN\nSO MOVE THE IMGUI EXAMPLE TO THE TOP OF THE SCREEN\nSO YOU CAN CLICK ON IT\nAND CLICK TO THE WINDOW TO DISABLE IT ")
                ClickGUI.RenderFeature(Utils.Joaat("DrawBuilderTool"))
                ImGui.SameLine()
                ClickGUI.RenderFeature(Utils.Joaat("DrawcustomGUI"))
                ImGui.Text("ALSO BUILDER TOOL IS NOT FINISHED YET\nSO DONT EXPECT IT TO WORK PERFECTLY\nIT IS JUST A PROOF OF CONCEPT")
                
                float_slider, _ = ImGui.SliderFloat("Float##float1", float_slider,0.0, 1.0)
                int_slider, _ = ImGui.SliderInt("Int##int1", int_slider, 0,10)
                drag_value, _ = ImGui.DragFloat("Drag##drag1", drag_value, 0.05)
                local _, changed = ImGui.Combo("Combo##combo1", 1, {"A", "B", "C"}, 3) 
                if changed then
                    GUI.AddToast("ImGui Example Script", "Combo changed", 5000, eToastPos.TOP_RIGHT)
                end
                input_text, _ = ImGui.InputText("Input##text1", input_text, 64)
                color_picker, _ = ImGui.ColorEdit4("Color##col1", color_picker)
                ImGui.ProgressBar(float_slider, 200, 16, "Progress")

                ImGui.Separator()

                if ImGui.TreeNode("GUI customization tree node##tree1") then
                    ImGui.Text("Inside the tree.")
                    for _, feature in ipairs(features) do
                        ClickGUI.RenderFeature(feature)
                    end
                    ImGui.TreePop()
                end

                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Child##tab2") then
                ImGui.Text("Parent Panel")
                if ImGui.BeginChild("ChildPanel##childwin", 250, 100, true) then
                    ImGui.Text("Inside child window.")
                    if ImGui.Button("Click Me##childbtn") then 
                        GUI.AddToast("ImGui Example Script", "Click Me button pressed", 5000, eToastPos.TOP_RIGHT)
                    end
                    ImGui.EndChild()
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Radios##tab3") then
                if ImGui.RadioButton("Radio A##radio1", radio_option == 1) then
                    radio_option = 1
                end
                ImGui.SameLine()
                if ImGui.RadioButton("Radio B##radio2", radio_option == 2) then
                    radio_option = 2
                end
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end
        ImGui.PopStyleColor(stylepushcount)
    end
    ImGui.End()
end

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, onPresent)
