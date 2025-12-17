local spawnedStuffs = {}
local ScriptLoadTime = Time.GetEpocheMs()
local Features = {}

ENTITY = {
    DELETE_ENTITY=function(entity)return Natives.InvokeVoid(0xAE3CBE5BF394C9C9,entity)end,
    GET_ENTITY_COORDS=function(entity--[[@param entity integer]],alive--[[@param alive boolean]])return Natives.InvokeV3(0x3FEF770D40960D5A,entity,alive)end
}

PLAYER = {
    GET_PLAYER_PED_SCRIPT_INDEX=function(player)return Natives.InvokeInt(0x50FAC3A3E030A6E1,player)end,
}


function CurlExample()
    Script.QueueJob(function() -- wrapping curl things in a Script.QueueJob allows for it to run asynchronous with less of a freeze whenever the curl is performed 
        -- can be used to download natives files or other files
        -- if you just want to use the response then u can just have a return value for the responseString
        local url = "https://example.com"
        local curlObject = Curl.Easy()
        curlObject:Setopt(eCurlOption.CURLOPT_URL, url)
        --curlObject:AddHeader("Content-Type: application/json") -- optional headers
        --curlObject:AddHeader("User-Agent: Lua/1.0")  -- optional headers
        curlObject:Perform()
        while not curlObject:GetFinished() do
            Script.Yield()
        end

        local responseCode, responseString = curlObject:GetResponse()  
        --Logger.LogInfo("Response Preview: " .. responseString) 
        --- ^^^^^ this is just for debugging 
        if responseCode == eCurlCode.CURLE_OK then
            FileMgr.WriteFileContent(imagePath, responseString, true)
        else
            Logger.LogInfo("Error with downloading image: " .. responseCode)
            return
        end
        --return response -- here is the return 
    end)
end

-- local curlResponse = CurlExample()
--Logger.LogInfo(curlResponse)

FeatAdd = function(hash, name, ...)
    local feat = FeatureMgr.AddFeature(hash, name, ...)
    table.insert(Features, feat)
    return feat
end
---
FeatAdd(Utils.Joaat("LUA_Button"), "Button", eFeatureType.Button)

FeatAdd(Utils.Joaat("LUA_Toggle"), "Toggle", eFeatureType.Toggle)
    :SetDefaultValue(true)
    :Reset()

FeatAdd(Utils.Joaat("LUA_SliderInt"), "SliderInt", eFeatureType.SliderInt)
    :SetLimitValues(0, 10)

FeatAdd(Utils.Joaat("LUA_SliderFloat"), "SliderFloat", eFeatureType.SliderFloat)
    :SetLimitValues(-1.0, 1.0)

FeatAdd(Utils.Joaat("LUA_SliderIntToggle"), "SliderIntToggle", eFeatureType.SliderIntToggle)
    :SetLimitValues(0, 10)

FeatAdd(Utils.Joaat("LUA_SliderFloatToggle"), "SliderFloatToggle", eFeatureType.SliderFloatToggle)
    :SetLimitValues(-1.0, 1.0)

FeatAdd(Utils.Joaat("LUA_InputInt"), "InputInt", eFeatureType.InputInt)
    :SetLimitValues(0, 10)
    :SetStepSize(1)
    :SetFastStepSize(10)

FeatAdd(Utils.Joaat("LUA_InputFloat"), "InputFloat", eFeatureType.InputFloat)
    :SetLimitValues(-1.0, 1.0)
    :SetStepSize(0.1)
    :SetFastStepSize(10.0)

FeatAdd(Utils.Joaat("LUA_InputText"), "InputText", eFeatureType.InputText)
    :SetStringValue("InputText")

FeatAdd(Utils.Joaat("LUA_InputColor3"), "InputColor3", eFeatureType.InputColor3)
    :SetDefaultValue(0xFFCCAA)
    :Reset()

FeatAdd(Utils.Joaat("LUA_InputColor4"), "InputColor4", eFeatureType.InputColor4)
    :SetDefaultValue(0xFFFFCCAA)
    :Reset()

FeatAdd(Utils.Joaat("LUA_List"), "List", eFeatureType.List)
    :SetList({"Eins", "Zwei", "Drei"})

FeatAdd(Utils.Joaat("LUA_ListWithInfo"), "ListWithInfo", eFeatureType.ListWithInfo)
    :SetList({"Eins", "Zwei", "Drei"})
    :AddInfoContentFeature(Utils.Joaat("LUA_Button"))


FeatAdd(Utils.Joaat("PRINTHOVEREDFEATUREINFO"), "Print hovered feature info", eFeatureType.Button, "supposed to be used with hotkeys and triggering it while hovering over a feature", function()
    local f = FeatureMgr.GetHoveredFeature()
    if f ~= nil then 
        local fhash = f:GetHash()
        local fName = f:GetName()
        Logger.LogInfo(("Feature name = %s, Feature hash = %s"):format(fName, fhash))
    end
end)


GameAwardsTable = {
    {name="Golf # of Birdies",                   Stat = "AWD_FM_GOLF_BIRDIES" },
    {name="Golf # of Games Won",                 Stat = "AWD_FM_GOLF_WON"},
    {name="Tennis # of Games Won",               Stat = "AWD_FM_TENNIS_WON"},
    {name="Tennis # of Aces",                    Stat = "AWD_FM_TENNIS_ACE"},
    {name="Freemode # of Races Won",             Stat = "AWD_FM_GTA_RACES_WON"},
    {name="Freemode Races Fastest Lap",          Stat = "AWD_FM_RACES_FASTEST_LAP"},
    {name="Freemode Races Last First",           Stat = "AWD_FM_RACE_LAST_FIRST"},
    {name="Freemode DeathMatch Wins",            Stat = "AWD_FM_DM_WINS"},
    {name="Freemode Team DeathMatch Wins",       Stat = "AWD_FM_TDM_WINS"},
    {name="Freemode Team DeathMatch MVP",        Stat = "AWD_FM_TDM_MVP" },
    {name="Freemode DeathMatch KillStreak",      Stat = "AWD_FM_DM_KILLSTREAK" },
    {name="Freemode Deathmatch Total Kills",     Stat = "AWD_FM_DM_TOTALKILLS" },
    {name="Freemode DeathMatch 3 Kills Same Guy",Stat = "AWD_FM_DM_3KILLSAMEGUY" },
    {name="Freemode DeathMatch Stolen kills",    Stat = "AWD_FM_DM_STOLENKILL" },
}

GameAwardsComboTable = {}
for i, stat in ipairs(GameAwardsTable) do
    table.insert(GameAwardsComboTable, stat.name)
end

FeatAdd(Utils.Joaat("LUA_Combo"), "Stats Combo", eFeatureType.Combo)
:SetList(GameAwardsComboTable):SetListIndex(1)

function MPX()
    local found, MPXENUM = Stats.GetInt(joaat("MPPLY_LAST_MP_CHAR"))
    return "MP" .. MPXENUM .. "_"
end

local stattoputintoImGuiText
Script.RegisterLooped(function()
    local selectedStat = FeatureMgr.GetFeature(Utils.Joaat("LUA_Combo")):GetListIndex() + 1
    local Stat = GameAwardsTable[selectedStat] and GameAwardsTable[selectedStat].Stat
    found, stattoputintoImGuiText = Stats.GetInt(MPX() .. Stat)
    Script.Yield(1000)
end)

FeatAdd(Utils.Joaat("LUA_ComboToggles"), "ComboToggles", eFeatureType.ComboToggles)
    :SetList({"Eins", "Zwei", "Drei"})
    :ToggleListIndex(0, true)

local scripteventhelpertable = {
    SCRIPT_EVENT = {
        [-642704387] = { name = "SCRIPT_EVENT_TICKER_MESSAGE"},
        SpecifigArgumentTable = {
            [800157557] = { -- SCRIPT_EVENT_GENERAL
                [4] = 225624744, -- GENERAL_EVENT_HEIST_PREPLAN_EXIT_GUEST_MODE 
                -- refer to MP_Event_Enums.sch to find the hashes
                -- and remember to change it from Globals.MP_Event_Enums15.sch to _Enums16 whenever they update
                name = "Force Camera Fowrad"
            }
        }
    }
}

---@param sender? CNetGamePlayer
---@param args integer[]
---@return boolean # return true to block
local function scriptedGameEvent(sender, args)
    if sender then
        local eventId = args[1]
        local found, name = GTA.GetScriptEventName(eventId)
        if eventId == scripteventhelpertable.SCRIPT_EVENT[eventId] then 
            local reason = scripteventhelpertable.SCRIPT_EVENT[eventId].name 
            Logger.LogInfo(("Blocked %s, from %s"):format(reason, sender:GetName()))
            return true
        end
        for index, value in ipairs(args) do
            if value == scripteventhelpertable.SCRIPT_EVENT.SpecifigArgumentTable[args[1][index]] then
                local reason = scripteventhelpertable.SCRIPT_EVENT.SpecifigArgumentTable[args[1]].name
                Logger.LogInfo(("Blocked Specific script event %s, from %s"):format(reason, sender:GetName()))
                return true
            end
        end
        if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_BlockSEs"), sender.PlayerId) then
            Logger.LogInfo(("Blocked Script Event: %s, from %s"):format(name, sender:GetName()))
            return true
        end
    end
    return false
end

SCRIPT_EVENT = {
    SCRIPT_EVENT_GENERAL = 800157557,
    GENERAL_EVENT = {
        GENERAL_EVENT_HEIST_PREPLAN_EXIT_GUEST_MODE = 225624744
    }
}


--[[
    from net_events.sch
    to get more take the eventId in this case 800157557 and search for it in the decompiled scripts 

    STRUCT SCRIPT_EVENT_GENERAL_EVENT
        STRUCT_EVENT_COMMON_DETAILS Details 
        GENERAL_EVENT_TYPE 			GeneralType
        INT							iGeneralEventID
    ENDSTRUCT

    PROC BROADCAST_GENERAL_EVENT(GENERAL_EVENT_TYPE GeneralEventType, INT bs_Players)
        SCRIPT_EVENT_GENERAL_EVENT Event
        Event.Details.Type = SCRIPT_EVENT_GENERAL
        Event.Details.FromPlayerIndex = PLAYER_ID()
        Event.GeneralType = GeneralEventType
        Event.iGeneralEventID = GET_RANDOM_INT_IN_RANGE(0, 9999)
        IF NOT (bs_Players = 0)
            IF NETWORK_IS_GAME_IN_PROGRESS()
                SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), bs_Players)
            ENDIF
        ELSE
            NET_PRINT("BROADCAST_GENERAL_EVENT - playerflags = 0 so not broadcasting") NET_NL()
        ENDIF
    ENDPROC
]]

FeatureMgr.AddPlayerFeature(Utils.Joaat("Script Event thingy"), "Script event test", eFeatureType.Button, "Uses the SCRIPT_EVENT_GENERAL, and the GENERAL_EVENT_HEIST_PREPLAN_EXIT_GUEST_MODE to force the players camera forward", function(f)
    local playerId = f:GetPlayerIndex()
    GTA.TriggerScriptEvent((1 << playerId), 
    {--[[Script event type]] SCRIPT_EVENT.SCRIPT_EVENT_GENERAL, 
    GTA.GetLocalPlayerId(), 
    --[[GENERAL_EVENT_TYPE]] SCRIPT_EVENT.GENERAL_EVENT.GENERAL_EVENT_HEIST_PREPLAN_EXIT_GUEST_MODE, 
    --[[GET_RANDOM_INT_IN_RANGE]]math.random(1, 9999)})            
end, true)

FeatAdd(
Utils.Joaat("pedSpawn"), -- Hash
"Spawn a Ped",           -- Feature name
eFeatureType.Button,     -- Feature type
"Spawns a ped near your player.", -- Description
function(f)
    local pedHash = 2627665880
    local coords = V3.New(ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(Utils.GetSelectedPlayer()), true)) 
    -- V3.New allows you to do 'this.x, this.y, this.z',  instead of just applying 3 variables to the ENTITY.GET_ENTITY_COORDS call 
    local ped = GTA.CreatePed(pedHash, 26, coords.x + 2.0, coords.y, coords.z, 0.0, true, true)
    table.insert(spawnedStuffs, ped) -- used to store peds so they can be cleared on session change 
    if ped then
        GUI.AddToast("Ped Spawn", "Ped spawned successfully!", 5000, eToastPos.TOP_RIGHT)
    else
        GUI.AddToast("Ped Spawn", "Failed to spawn the ped.", 5000, eToastPos.TOP_RIGHT)
    end
end)

FeatAdd(Utils.Joaat("SelfPedSpawn"), "Spawn a ped on yourself", eFeatureType.Button, "", function()
    local pedHash = 2627665880
    local selfCoords = V3.New(ENTITY.GET_ENTITY_COORDS(GTA.PointerToHandle(GTA.GetLocalPed()), true))
    local ped, err = pcall(function() GTA.CreatePed(pedHash, 26, selfCoords.x, selfCoords.y, selfCoords.z + 4, 0.0, true, true) end)
    table.insert(spawnedStuffs, ped)
    if ped then 
        GUI.AddToast("Ped Spawn", "Ped spawned successfully", 5000, eToastPos.TOP_RIGHT)
    else
        GUI.AddToast("Ped span", "Ped failed to spawn error: " .. err, 5000, eToastPos.TOP_RIGHT)
    end
end)

FeatAdd(Utils.Joaat("MemoryTest"), "Memory Test", eFeatureType.Button, "This will print the Online version number currently 1.71 as i am making this", function()
    local MemoryScanAddress = Memory.Rip(Memory.Scan("4C 8D 0D ? ? ? ? 48 8D 74 24 ? 48 89 F1 48 89 FA") + 0x03) -- 7FF7D058F777
    local MemoryScanResult = Memory.ReadString(MemoryScanAddress)
    Logger.LogInfo(MemoryScanResult)
end)

local function onPresent()
    local flags = ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoCollapse | ImGuiWindowFlags.NoDecoration

    if GUI.IsOpen() then
        ImGui.Begin("Window", true, flags)

        ImGui.BeginGroup()
        ImGui.Text("Some text")
        ImGui.Text(("FPS %0.1f"):format(ImGui.GetFrameRate()))
        ImGui.EndGroup()

        ImGui.SameLine()

        ImGui.BeginGroup()
        ClickGUI.RenderFeature(Utils.Joaat("LUA_Button"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_Toggle"))
        ImGui.EndGroup()

        ImGui.End()
    end
end

local function renderTab()
    if ImGui.BeginTabBar("MainTabBar") then
        if ImGui.BeginTabItem("Tab") then
            if ClickGUI.BeginCustomChildWindow("EXAMPLE") then
                ImGui.Text("This is the content of the main tab.")
                ImGui.Separator()
                ClickGUI.RenderFeature(Utils.Joaat("LUA_Combo"))
                ImGui.Separator()
                ImGui.Text("Selected stat value: " .. stattoputintoImGuiText)
                ImGui.Separator()
                ClickGUI.RenderFeature(Utils.Joaat("SelfPedSpawn"))
                ClickGUI.RenderFeature(Utils.Joaat("MemoryTest"))
                ClickGUI.EndCustomChildWindow()
            end
        end
    end
end

local function renderPlayerTab()
    if ImGui.BeginTabBar("MainTabBar") then
        if ImGui.BeginTabItem("PlayerTab") then
            if ClickGUI.BeginCustomChildWindow("Ped Features", -1, 200) then
                ClickGUI.RenderFeature(Utils.Joaat("pedSpawn")) 
                ClickGUI.RenderFeature(Utils.Joaat("Script Event thingy"), Utils.GetSelectedPlayer()) -- for FeatureMgr.AddPlayerFeature you can use ClickGUI.RenderFeature(Utils.Joaat(str), Utils.GetSelectedPlayer())
                ClickGUI.EndCustomChildWindow()
            end
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

---@param playerId integer
local function onPlayerJoin(playerId)
    if playerId ~= INVALID_PLAYER_INDEX then
        local name = PLAYER.GET_PLAYER_NAME(playerId)
        GUI.AddToast("onPlayerJoin", ("Player %s joined"):format(name), 3000)
    end
end

EventMgr.RegisterHandler(eLuaEvent.SCRIPTED_GAME_EVENT, scriptedGameEvent)
EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, onPresent)
EventMgr.RegisterHandler(eLuaEvent.ON_PLAYER_JOIN, onPlayerJoin)
EventMgr.RegisterHandler(eLuaEvent.ON_SESSION_CHANGE, function()
    local mem = Memory.AllocInt()
    for i=1, #spawnedStuffs do 
        local thing = spawnedStuffs[i]
        Logger.LogInfo(("Deleting %s entities"):format(#spawnedStuffs))
        Memory.WriteInt(mem, thing)
        ENTITY.DELETE_ENTITY(mem)
    end
    Memory.Free(mem)
end)

Script.QueueJob(function()
    local lasttime = Time.GetEpocheMs()
    local time = math.abs(ScriptLoadTime - lasttime)
    Logger.LogInfo(("Script loaded in %s, ms."):format(time))
    Logger.LogInfo(string.format("Loaded %s, features ", #Features))
end)

ClickGUI.AddTab("Tab", renderTab)
ClickGUI.AddPlayerTab("PlayerTab", renderPlayerTab)
