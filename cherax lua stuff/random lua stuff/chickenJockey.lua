GET_ENTITY_COORDS=function(entity--[[param integer]], alive--[[param boolean]])return Natives.InvokeV3(0x3FEF770D40960D5A,entity--[[param integer]], alive--[[param boolean]])end;
GET_PLAYER_PED_SCRIPT_INDEX=function(...)return Natives.InvokeInt(0x50FAC3A3E030A6E1,...)end;
ATTACH_ENTITY_TO_ENTITY=function(...)return Natives.InvokeVoid(0x6B9BBD38AB0796DF,...)end;
PLAY_ENTITY_ANIM=function(entity--[[@param entity integer]],animName--[[@param animName string]],animDict--[[@param animDict string]],p3--[[@param p3 number]],loop--[[@param loop boolean]],stayInAnim--[[@param stayInAnim boolean]],p6--[[@param p6 boolean]],delta--[[@param delta number]],bitset--[[@param bitset any]])return Natives.InvokeBool(0x7FB218262B810701,entity,animName,animDict,p3+.0,loop,stayInAnim,p6,delta+.0,bitset)end;---@return boolean

--[[local slider = FeatureMgr.AddFeature(Utils.Joaat("spawnamount"), "Spawn Amount", eFeatureType.SliderInt, ""):SetMinValue(1):SetMaxValue(100):SetValue(5)

FeatureMgr.AddFeature(Utils.Joaat("spawnmonkeys"), "Spawn Monkeys", eFeatureType.Button, "", function()
    local riderModel = 0xA8683715 
    local baseModel = Utils.Joaat("A_C_Pig") 
    local ped = GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
    local x, y, z = GET_ENTITY_COORDS(ped, true)
    local pig = GTA.CreatePed(baseModel, 0, x, y, z, 0.0, true, true)
    local monkey = GTA.CreatePed(riderModel, 0, x, y, z + 1.0, 0.0, true, true)
    ATTACH_ENTITY_TO_ENTITY(monkey, pig, 0, 0.0, 0.0, 1.7, 0.0, 90.0, 0.0, true, true, false, true, 2, true, 0)
end)

ClickGUI.AddTab("Monkey Spawner", function()
    ClickGUI.RenderFeature(Utils.Joaat("spawnmonkeys"))
    ClickGUI.RenderFeature(Utils.Joaat("spawnamount"))
end)]]

local CHICKEN_HASH = 1794449327      
local ZOMBIE_HASH = -1404353274       

local jockeySlider = FeatureMgr.AddFeature(Utils.Joaat("chickenjockey_amount"), "Spawn Amount", eFeatureType.SliderInt, "")
    :SetMinValue(1):SetMaxValue(50):SetValue(5)

FeatureMgr.AddFeature(Utils.Joaat("chickenjockey_spawn"), "Spawn Chicken Jockey", eFeatureType.Button, "", function()
    local playerPed = GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
    local x, y, z = GET_ENTITY_COORDS(playerPed, true)
    
    for i = 1, jockeySlider:GetIntValue() do
        local spawnX = x + i * 1.5
        local spawnY = y
        local chicken = GTA.CreatePed(CHICKEN_HASH, 0, spawnX, spawnY, z, 0.0, true, true)
        if chicken ~= nil then
            local zombie = GTA.CreatePed(ZOMBIE_HASH, 0, spawnX, spawnY, z + 1.0, 0.0, true, true)
            if zombie ~= nil then
                local animDict = "anim@mp_player_intcelebrationfemale@slow_clap"
                local animName = "slow_clap"
                PLAY_ENTITY_ANIM(zombie,animName,animDict,2,true,true,true,120,12)
                ATTACH_ENTITY_TO_ENTITY(zombie, chicken, 0, 
                    0.0, 0.0, 1.0,     
                    0.0, 0.0, 0.0,     
                    false, false, false, false, 2, true)
            end
        end
    end
end)

ClickGUI.AddTab("Chicken Jockey", function()
    ClickGUI.RenderFeature(Utils.Joaat("chickenjockey_spawn"))
    ClickGUI.RenderFeature(Utils.Joaat("chickenjockey_amount"))
end) 
