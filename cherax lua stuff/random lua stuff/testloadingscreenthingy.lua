    
if Cherax.GetEdition() == "LE" then 
    CLoadingScreens__AreActive = Memory.Rip(Memory.Scan("83 3D ?? ?? ?? ?? ?? 75 17 8B 43 20 25") + 2)
else
    CLoadingScreens__AreActive = Memory.Rip(Memory.Scan("C7 05 ? ? ? ? ? ? ? ? 80 3D ? ? ? ? ? 74 ? C7 05 ? ? ? ? ? ? ? ? E9") + 2)
end



eLoadingScreenState = {
    Invalid = -1,
    Finished = 0,
    PreLegal = 1,
    Unknown_2 = 2,
    Legals = 3,
    Unknown_4 = 4,
    LandingPage = 5,
    Transition = 6,
    Unknown_7 = 7,
    Unknown_8 = 8,
    Unknown_9 = 9,
    SessionStartLeave = 10
}


function GetLoadingScreenState()
    if not CLoadingScreens__AreActive then return "Unknown (Not Found)" end

    local state = Memory.ReadLong(CLoadingScreens__AreActive) or Memory.ReadUInt(CLoadingScreens__AreActive)
    local name = eLoadingScreenState[state] or "Unknown"

    return name
end

local loadingScreenStateEnum
Script.RegisterLooped(function()
    loadingScreenStateEnum = GetLoadingScreenState()
end)
function RenderLoadingScreenInfo()
    ImGui.Begin("Loading Screen State")
    ImGui.Text("Current State: " .. loadingScreenStateEnum)
    ImGui.End()
end

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, RenderLoadingScreenInfo)



