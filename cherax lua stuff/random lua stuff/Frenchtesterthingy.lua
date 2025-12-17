
SCRIPT_EVNET = {
    SCRIPT_EVENT_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR = -1638522928,
}
FeatureMgr.AddPlayerFeature(Utils.Joaat("AUTOTPFRENCHFAGSTOCASINO"), "Auto TP French Fags to Casino", eFeatureType.Toggle, "", function(f)
    while f:IsToggled() do 
        for i=1, 32 do 
            if i ~= GTA.GetLocalPlayerId() then 
                local PlayerInfo = Players.GetIPInfo(i)
                for label, info in ipairs(PlayerInfo) do 
                    Logger.LogInfo("thing 1 ".. label)
                    Logger.LogInfo("thing 2" .. info)
                end
            end
        end
        Script.Yield()
    end
    local playerID = f:GetPlayerIndex()
    GTA.TriggerScriptEvent(1 << playerID, {
        SCRIPT_EVENT.SCRIPT_EVENT_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR, 
        GTA.GetLocalPlayerId(), 
        1 << playerID, 
        123--[[InteriorID]], 
        0, 
        0, 
        1, 
        -1001291848, 
        -1016910157, 
        1108672448, 
        0, 
        -1, 
        0, 
        2147483647,
        0, 
        -1}
        )
end)