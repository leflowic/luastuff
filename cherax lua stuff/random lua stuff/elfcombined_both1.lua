-- Injected Native Tables
local AllThingsForScriptCleanup = {}
local isDev = true 
local isAdmin = true
local isSupporter = true
local menuRootPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Elf"
local scriptloadtime = Time.GetEpocheMs()
local joaat = Utils.Joaat
local Features = {
    PlayerFeatures = {
        HashAndName = {}
    },
    GuiFeatures = {}, -- just a list
    GuiHashAndName = {},
    HashNameMap = {}
}

local _tooltipState = {
    hash = nil,
    name = nil,
    desc = nil,
    anim = 0.0,
    open = false
}

RendF = function(feature, ...)
    local f = FeatureMgr.GetFeature(feature)
    local hovered = false
    ImGui.PushID(feature)
    ClickGUI.RenderFeature(feature, ...)
    hovered = ImGui.IsItemHovered()
    ImGui.PopID()
    if hovered and f then
        if _tooltipState.hash ~= f:GetHash() then
            _tooltipState.anim = 0.0
            _tooltipState.hash = f:GetHash()
            _tooltipState.name = f:GetName()
            _tooltipState.desc = f:GetDesc()
        end
        _tooltipState.anim = math.min(_tooltipState.anim + 0.2, 1.0)
        if _tooltipState.anim > 0.01 and _tooltipState.name then
            local offset = math.sin(_tooltipState.anim * math.pi) * 10.0
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + offset)
            ImGui.BeginTooltip()
            local hue = (os.clock() * 0.5) % 1.0
            local r = math.floor(255 * (0.5 + 0.5 * math.sin(hue * math.pi * 2)))
            local g = math.floor(255 * (0.5 + 0.5 * math.sin(hue * math.pi * 2 + 2)))
            local b = math.floor(255 * (0.5 + 0.5 * math.sin(hue * math.pi * 2 + 4)))
            ImGui.TextColored(r / 255, g / 255, b / 255, 1, _tooltipState.name)
            ImGui.Separator()
            ImGui.TextColored(1, 1, 1, 1, _tooltipState.desc or "No Description")
            ImGui.EndTooltip()
        end
    else
        _tooltipState.anim = math.max(_tooltipState.anim - 0.2, 0.0)
        if _tooltipState.anim <= 0.01 then
            _tooltipState.hash = nil
            _tooltipState.name = nil
            _tooltipState.desc = nil
        end
    end
end

EventMgr.RegisterHandler(eLuaEvent.ON_POST_PRESENT, function()
    _tooltipState.hash = nil
    _tooltipState.name = nil
    _tooltipState.desc = nil
    _tooltipState.anim = 0.0
end)

GUIFeatAdd = function(hash, name, ...)
    local FeatureAdd = FeatureMgr.AddFeature(hash, name, ...)
    table.insert(Features.GuiFeatures, FeatureAdd)
    Features.GuiHashAndName[hash] = name
    return FeatureAdd
end

PlayerFeatAdd = function(hash, name, ...)
    local playerFeat = FeatureMgr.AddPlayerFeature(hash, name, ...)
    table.insert(Features.PlayerFeatures, playerFeat)
    Features.PlayerFeatures.HashAndName[hash] = name
    return playerFeat
end

FeatAdd = function(hash, name, ...)
    local feat = FeatureMgr.AddFeature(hash, name, ...)
    table.insert(Features, feat)
    Features.HashNameMap[hash] = name
    return feat
end


local GetFname = FeatureMgr.GetFeatureByName
local RemFeat = FeatureMgr.RemoveFeature

DLC = {
    GET_IS_LOADING_SCREEN_ACTIVE=function()return Natives.InvokeBool(0x10D0A8F259E93EC9)end,
    GET_IS_INITIAL_LOADING_SCREEN_ACTIVE=function()return Natives.InvokeBool(0xC4637A6D03C24CC3)end,
}

ENTITY = {
    IS_ENTITY_A_PED=function(entity--[[@param entity integer]])return Natives.InvokeBool(0x524AC5ECEA15343E,entity)end;---@return boolean
	GET_ENTITY_BONE_POSTION=function(entity--[[@param entity integer]],boneIndex--[[@param boneIndex integer]])return Natives.InvokeV3(0x46F8696933A63C9B,entity,boneIndex)end;---@return V3
    GET_ENTITY_HEIGHT_ABOVE_GROUND=function(entity--[[@param entity integer]])return Natives.InvokeFloat(0x1DD55701034110E5,entity)end;---@return number
    GET_ENTITY_ROTATION=function(entity,rotationOrder)return Natives.InvokeV3(0xAFBD61CC738D9EB9,entity,rotationOrder)end;---@return V3
    IS_ENTITY_PLAYING_ANIM=function(entity,animDict,animName,taskFlag)return Natives.InvokeBool(0x1F0B79228E461EC9,entity,animDict,animName,taskFlag)end;---@return boolean
    GET_ENTITY_FORWARD_VECTOR=function(entity)return Natives.InvokeV3(0x0A794A5A57F8DF91,entity)end;---@return V3
    APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS=function(entity,forceType,x,y,z,p5,isDirectionRel,isForceRel,p8)return Natives.InvokeVoid(0x18FF00FC7EFF559E,entity,forceType,x+.0,y+.0,z+.0,p5,isDirectionRel,isForceRel,p8)end;
    SET_ENTITY_COORDS_NO_OFFSET=function(entity,xPos,yPos,zPos,xAxis,yAxis,zAxis)return Natives.InvokeVoid(0x239A3351AC1DA385,entity,xPos+.0,yPos+.0,zPos+.0,xAxis,yAxis,zAxis)end,
    SET_ENTITY_MAX_SPEED=function(entity,speed)return Natives.InvokeVoid(0x0E46A3FCBDE2A1B1,entity,speed+.0)end,
    GET_ENTITY_HEADING=function(entity)return Natives.InvokeFloat(0xE83D4F9BA2A38914,entity)end,
    GET_ENTITY_COORDS=function(entity,alive)return Natives.InvokeV3(0x3FEF770D40960D5A,entity,alive)end,
    SET_ENTITY_COLLISION=function(entity,toggle,keepPhysics)return Natives.InvokeVoid(0x1A9205C1B9EE827F,entity,toggle,keepPhysics)end,
    GET_ENTITY_MODEL=function(entity)return Natives.InvokeInt(0x9F47B058362C84B5,entity)end,
    DETACH_ENTITY=function(entity,dynamic,collision)return Natives.InvokeVoid(0x961AC54BF0613F5D,entity,dynamic,collision)end,
    ATTACH_ENTITY_TO_ENTITY=function(entity1,entity2,boneIndex,xPos,yPos,zPos,xRot,yRot,zRot,p9,useSoftPinning,collision,isPed,vertexIndex,fixedRot,p15)return Natives.InvokeVoid(0x6B9BBD38AB0796DF,entity1,entity2,boneIndex,xPos+.0,yPos+.0,zPos+.0,xRot+.0,yRot+.0,zRot+.0,p9,useSoftPinning,collision,isPed,vertexIndex,fixedRot,p15)end,
    SET_ENTITY_COORDS=function(entity,xPos,yPos,zPos,xAxis,yAxis,zAxis,clearArea)return Natives.InvokeVoid(0x06843DA7060A026B,entity,xPos+.0,yPos+.0,zPos+.0,xAxis,yAxis,zAxis,clearArea)end,
    SET_ENTITY_VISIBLE=function(entity,toggle,p2)return Natives.InvokeVoid(0xEA1C610A04DB6BBB,entity,toggle,p2)end,
    DELETE_ENTITY=function(entity)return Natives.InvokeVoid(0xAE3CBE5BF394C9C9,entity)end,
    FREEZE_ENTITY_POSITION=function(entity,toggle)return Natives.InvokeVoid(0x428CA6DBD1094446,entity,toggle)end,
    SET_ENTITY_VELOCITY=function(entity,x,y,z)return Natives.InvokeVoid(0x1C99BB7B6E96D16F,entity,x+.0,y+.0,z+.0)end,
    SET_ENTITY_HEADING=function(entity,heading)return Natives.InvokeVoid(0x8E2530AA8ADA980E,entity,heading+.0)end,
    GET_ENTITY_SPEED=function(entity)return Natives.InvokeFloat(0xD5037BA82E12416F,entity)end,
    SET_ENTITY_AS_MISSION_ENTITY=function(entity,p1,p2)return Natives.InvokeVoid(0xAD738C3085FE7E11,entity,p1,p2)end,
    SET_ENTITY_INVINCIBLE=function(entity,toggle)return Natives.InvokeVoid(0x3882114BDE571AD4,entity,toggle)end,
    ATTACH_ENTITY_TO_ENTITY_PHYSICALLY=function(entity1,entity2,boneIndex1,boneIndex2,xPos1,yPos1,zPos1,xPos2,yPos2,zPos2,xRot,yRot,zRot,breakForce,fixedRot,p15,collision,p17,p18)return Natives.InvokeVoid(0xC3675780C92F90F9,entity1,entity2,boneIndex1,boneIndex2,xPos1+.0,yPos1+.0,zPos1+.0,xPos2+.0,yPos2+.0,zPos2+.0,xRot+.0,yRot+.0,zRot+.0,breakForce+.0,fixedRot,p15,collision,p17,p18)end,
    SET_ENTITY_HEALTH=function(entity,health,instigator,weaponType)return Natives.InvokeVoid(0x6B76DC1F3AE6E6A3,entity,health,instigator,weaponType)end,
    DOES_ENTITY_EXIST=function(entity)return Natives.InvokeBool(0x7239B21A38F536BA,entity)end,
    SET_ENTITY_ROTATION=function(entity,pitch,roll,yaw,rotationOrder,p5)return Natives.InvokeVoid(0x8524A8B0171D5E07,entity,pitch+.0,roll+.0,yaw+.0,rotationOrder,p5)end,
    APPLY_FORCE_TO_ENTITY=function(entity,forceFlags,x,y,z,offX,offY,offZ,boneIndex,isDirectionRel,ignoreUpVec,isForceRel,p12,p13)return Natives.InvokeVoid(0xC5F68BE9613E2D18,entity,forceFlags,x+.0,y+.0,z+.0,offX+.0,offY+.0,offZ+.0,boneIndex,isDirectionRel,ignoreUpVec,isForceRel,p12,p13)end,
}

GRAPHICS = {
    DRAW_RECT=function(x--[[@param x number]],y--[[@param y number]],width--[[@param width number]],height--[[@param height number]],r--[[@param r integer]],g--[[@param g integer]],b--[[@param b integer]],a--[[@param a integer]],p8--[[@param p8 boolean]])return Natives.InvokeVoid(0x3A618A217E5154F0,x+.0,y+.0,width+.0,height+.0,r,g,b,a,p8)end;    CLEAR_TIMECYCLE_MODIFIER=function()return Natives.InvokeVoid(0x0F07E7745A236711)end;
    SET_TIMECYCLE_MODIFIER=function(modifierName)return Natives.InvokeVoid(0x2C933ABF17A1DF41,modifierName)end;
	SET_TIMECYCLE_MODIFIER_STRENGTH=function(strength)return Natives.InvokeVoid(0x82E7FFCD5B2326B3,strength+.0)end;
    SET_PARTICLE_FX_NON_LOOPED_COLOUR=function(r,g,b)return Natives.InvokeVoid(0x26143A59EF48B262,r+.0,g+.0,b+.0)end;
    DRAW_MARKER=function(type,posX,posY,posZ,dirX,dirY,dirZ,rotX,rotY,rotZ,scaleX,scaleY,scaleZ,red,green,blue,alpha,bobUpAndDown,faceCamera,p19,rotate,textureDict,textureName,drawOnEnts)return Natives.InvokeVoid(0x28477EC23D892089,type,posX+.0,posY+.0,posZ+.0,dirX+.0,dirY+.0,dirZ+.0,rotX+.0,rotY+.0,rotZ+.0,scaleX+.0,scaleY+.0,scaleZ+.0,red,green,blue,alpha,bobUpAndDown,faceCamera,p19,rotate,textureDict,textureName,drawOnEnts)end,
    TRIGGER_SCREENBLUR_FADE_IN=function(transitionTime)return Natives.InvokeBool(0xA328A24AAA6B7FDC,transitionTime+.0)end,
    TRIGGER_SCREENBLUR_FADE_OUT=function(transitionTime)return Natives.InvokeBool(0xEFACC8AEF94430D5,transitionTime+.0)end,
    DRAW_LINE=function(x1,y1,z1,x2,y2,z2,red,green,blue,alpha)return Natives.InvokeVoid(0x6B7256074AE34680,x1+.0,y1+.0,z1+.0,x2+.0,y2+.0,z2+.0,red,green,blue,alpha)end,
	START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE=function(effectName,entity,xOffset,yOffset,zOffset,xRot,yRot,zRot,boneIndex,scale,xAxis,yAxis,zAxis,r,g,b,a)return Natives.InvokeInt(0xDDE23F30CC5A0F03,effectName,entity,xOffset+.0,yOffset+.0,zOffset+.0,xRot+.0,yRot+.0,zRot+.0,boneIndex,scale+.0,xAxis,yAxis,zAxis,r+.0,g+.0,b+.0,a+.0)end;---@return integer
    USE_PARTICLE_FX_ASSET=function(name)return Natives.InvokeVoid(0x6C38AF3693A69A91,name)end;
    STOP_PARTICLE_FX_LOOPED=function(ptfxHandle,p1)return Natives.InvokeVoid(0x8F75998877616996,ptfxHandle,p1)end;
    START_PARTICLE_FX_NON_LOOPED_ON_ENTITY=function(effectName,entity,offsetX,offsetY,offsetZ,rotX,rotY,rotZ,scale,axisX,axisY,axisZ)return Natives.InvokeBool(0x0D53A3B8DA0809D2,effectName,entity,offsetX+.0,offsetY+.0,offsetZ+.0,rotX+.0,rotY+.0,rotZ+.0,scale+.0,axisX,axisY,axisZ)end;---@return boolean
	START_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE=function(effectName,entity,offsetX,offsetY,offsetZ,rotX,rotY,rotZ,boneIndex,scale,axisX,axisY,axisZ)return Natives.InvokeBool(0x02B1F2A72E0F5325,effectName,entity,offsetX+.0,offsetY+.0,offsetZ+.0,rotX+.0,rotY+.0,rotZ+.0,boneIndex,scale+.0,axisX,axisY,axisZ)end;---@return boolean

}

HUD = {
    BEGIN_TEXT_COMMAND_GET_SCREEN_WIDTH_OF_DISPLAY_TEXT=function(text--[[@param text string]])return Natives.InvokeVoid(0x54CE8AC98E120CAB,text)end;
    END_TEXT_COMMAND_GET_SCREEN_WIDTH_OF_DISPLAY_TEXT=function(p0--[[@param p0 boolean]])return Natives.InvokeFloat(0x85F061DA64ED2F67,p0)end;---@return number
    GET_BLIP_COORDS=function(blip)return Natives.InvokeV3(0x586AFE3FF72D996E,blip)end,
    SET_TEXT_OUTLINE=function()return Natives.InvokeVoid(0x2513DFB0FB8400FE)end,
    SET_TEXT_COLOUR=function(red,green,blue,alpha)return Natives.InvokeVoid(0xBE6B23FFA53FB442,red,green,blue,alpha)end,
    ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME=function(text)return Natives.InvokeVoid(0x6C188BE134E074AA,text)end,
    SET_TEXT_FONT=function(fontType)return Natives.InvokeVoid(0x66E0276CC5F6B9DA,fontType)end,
    GET_FIRST_BLIP_INFO_ID=function(blipSprite)return Natives.InvokeInt(0x1BEDE233E6CD2A1F,blipSprite)end,
    GET_FILENAME_FOR_AUDIO_CONVERSATION=function(labelName)return Natives.InvokeString(0x7B5280EBA9840C72,labelName)end,
    HIDE_HUD_COMPONENT_THIS_FRAME=function(id)return Natives.InvokeVoid(0x6806C51AD12B83B8,id)end,
    END_TEXT_COMMAND_DISPLAY_TEXT=function(x,y,p2)return Natives.InvokeVoid(0xCD015E5BB0D96A57,x+.0,y+.0,p2)end,
    BEGIN_TEXT_COMMAND_DISPLAY_TEXT=function(text)return Natives.InvokeVoid(0x25FBB336DF1804CB,text)end,
    SET_TEXT_CENTRE=function(align)return Natives.InvokeVoid(0xC02F4DBFB51D988B,align)end,
    SET_TEXT_SCALE=function(scale,size)return Natives.InvokeVoid(0x07C837F9A01C34C9,scale+.0,size+.0)end,
}

MISC = {
    DISPLAY_ONSCREEN_KEYBOARD=function(--[[int]] p0, --[[String]] windowTitle, --[[String]] p2, --[[String]] defaultText, --[[String]] defaultConcat1, --[[String]] defaultConcat2, --[[String]] defaultConcat3, --[[int]] maxInputLength) Natives.InvokeVoid(0x00DC833F2568DBF6, p0, windowTitle, p2, defaultText, defaultConcat1, defaultConcat2, defaultConcat3, maxInputLength) end, 
    UPDATE_ONSCREEN_KEYBOARD=function() return Natives.InvokeInt(0x0CF2B696BBF945AE) end,
    GET_ONSCREEN_KEYBOARD_RESULT=function() return Natives.InvokeString(0x8362B09B91893647) end,
    GET_GROUND_Z_FOR_3D_COORD=function(x,y,z,groundZ,ignoreWater,p5)return Natives.InvokeBool(0xC906A7DAB05C8D2B,x+.0,y+.0,z+.0,groundZ,ignoreWater,p5)end;---@return boolean
    SET_TIME_SCALE=function(timeScale)return Natives.InvokeVoid(0x1D408577D440E81E,timeScale+.0)end;
    GET_HASH_KEY=function(string)return Natives.InvokeInt(0xD24D37CC275948CC,string)end,
    GET_FRAME_TIME=function()return Natives.InvokeFloat(0x15C40837039FFAF7)end,
	SET_GRAVITY_LEVEL=function(level)return Natives.InvokeVoid(0x740E14FAD5842351,level)end;
}

NETWORK = {
    NETWORK_IS_PLAYER_CONNECTED=function(player)return Natives.InvokeBool(0x93DC1BE4E1ABE9D1,player)end;---@return boolean
    NETWORK_HASH_FROM_PLAYER_HANDLE=function(player)return Natives.InvokeInt(0xBC1D768F2F5D6C05,player)end;---@return integer*
    NETWORK_GET_NETWORK_ID_FROM_ENTITY=function(entity)return Natives.InvokeInt(0xA11700682F3AD45C,entity)end,
    PED_TO_NET=function(ped)return Natives.InvokeInt(0x0EDEC3C276198689,ped)end,
    SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES=function(netId,toggle)return Natives.InvokeVoid(0xE05E81A888FA63C8,netId,toggle)end,
    NETWORK_GET_GAME_MODE=function()return Natives.InvokeInt(0x4C9034162368E206)end,
    NETWORK_EXPLODE_VEHICLE=function(vehicle,isAudible,isInvisible,netId)return Natives.InvokeBool(0x301A42153C9AD707,vehicle,isAudible,isInvisible,netId)end,
    SHUTDOWN_AND_LOAD_MOST_RECENT_SAVE=function()return Natives.InvokeBool(0x9ECA15ADFE141431)end,
    NETWORK_IS_SESSION_STARTED=function()return Natives.InvokeBool(0x9DE624D2FC4B603F)end,
    NETWORK_HAS_ROS_PRIVILEGE=function(index)return Natives.InvokeBool(0xA699957E60D80214,index)end,
    NETWORK_HAS_CONTROL_OF_ENTITY=function(entity)return Natives.InvokeBool(0x01BF60A500E28887,entity)end,
    NETWORK_REGISTER_ENTITY_AS_NETWORKED=function(entity)return Natives.InvokeVoid(0x06FAACD625D80CAA,entity)end,
    NETWORK_REQUEST_CONTROL_OF_ENTITY=function(entity)return Natives.InvokeBool(0xB69317BF5E782347,entity)end,
    NETWORK_IS_PLAYER_ACTIVE=function(player)return Natives.InvokeBool(0xB8DFD30D6973E135,player)end,
}

DECORATOR = {
    DECOR_REGISTER=function(propertyName,type)return Natives.InvokeVoid(0x9FD90732F56403CE,propertyName,type)end;
    DECOR_EXIST_ON=function(entity,propertyName)return Natives.InvokeBool(0x05661B80A8C9165F,entity,propertyName)end;---@return boolean
    DECOR_SET_BOOL=function(entity,propertyName,value)return Natives.InvokeBool(0x6B1E8E2ED1335B71,entity,propertyName,value)end;---@return boolean
    DECOR_SET_INT=function(entity,propertyName,value)return Natives.InvokeBool(0x0CE3AA5E1CA19E10,entity,propertyName,value)end;---@return boolean
}

PAD = {
    IS_CONTROL_JUST_PRESSED=function(control,action)return Natives.InvokeBool(0x580417101DDB492F,control,action)end;---@return boolean
    DISABLE_CONTROL_ACTION=function(control,action,disableRelatedActions)return Natives.InvokeVoid(0xFE99B66D079CF6BC,control,action,disableRelatedActions)end;
	IS_CONTROL_PRESSED=function(control,action)return Natives.InvokeBool(0xF3A21BCD95725A4A,control,action)end;---@return boolean
}   

NIGGER = {
    END_TEXT_COMMAND_THEFEED_POST_TICKER=function(blink,p1)return Natives.InvokeInt(0x2ED7843F8F801023,blink,p1)end;---@return integer*
    BEGIN_TEXT_COMMAND_THEFEED_POST=function(text)return Natives.InvokeVoid(0x202709F4C58A0424,text)end;
    ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME=function(text)return Natives.InvokeVoid(0x6C188BE134E074AA,text)end,
    SET_TEXT_FONT=function(fontType)return Natives.InvokeVoid(0x66E0276CC5F6B9DA,fontType)end,
    SET_TEXT_CENTRE=function(align)return Natives.InvokeVoid(0xC02F4DBFB51D988B,align)end,
    SET_TEXT_EDGE=function(p0,r,g,b,a)return Natives.InvokeVoid(0x441603240D202FA6,p0,r,g,b,a)end,
    SET_TEXT_SCALE=function(scale,size)return Natives.InvokeVoid(0x07C837F9A01C34C9,scale+.0,size+.0)end,
    END_TEXT_COMMAND_DISPLAY_TEXT=function(x,y,p2)return Natives.InvokeVoid(0xCD015E5BB0D96A57,x+.0,y+.0,p2)end,
    SET_TEXT_DROPSHADOW=function(distance,r,g,b,a)return Natives.InvokeVoid(0x465C84BC39F1C351,distance,r,g,b,a)end,
    BEGIN_TEXT_COMMAND_DISPLAY_TEXT=function(text)return Natives.InvokeVoid(0x25FBB336DF1804CB,text)end,
    SET_TEXT_PROPORTIONAL=function(p0)return Natives.InvokeVoid(0x038C1F517D7FDCF8,p0)end,
    MP_TEXT_CHAT_DISABLE=function(toggle)return Natives.InvokeVoid(0x1DB21A44B09E8BA3,toggle)end,
    SET_TEXT_WRAP=function(start,end_)return Natives.InvokeVoid(0x63145D9C883A1A70,start+.0,end_+.0)end,
    SET_TEXT_OUTLINE=function()return Natives.InvokeVoid(0x2513DFB0FB8400FE)end,
    SET_TEXT_COLOUR=function(red,green,blue,alpha)return Natives.InvokeVoid(0xBE6B23FFA53FB442,red,green,blue,alpha)end,
}

CAM = {
    GET_GAMEPLAY_CAM_ROT=function(rotationOrder)return Natives.InvokeV3(0x837765A25378F0BB,rotationOrder)end;---@return V3
}
PED = {
    GET_VEHICLE_PED_IS_USING=function(ped)return Natives.InvokeInt(0x6094AD011A2EA87D,ped)end;---@return integer
    IS_PED_FALLING=function(ped)return Natives.InvokeBool(0xFB92A102F1C4DFA3,ped)end;---@return boolean
	SET_PED_CAN_RAGDOLL=function(ped,toggle)return Natives.InvokeVoid(0xB128377056A54E2A,ped,toggle)end;
    SET_PED_CONFIG_FLAG=function(ped,flagId,value)return Natives.InvokeVoid(0x1913FE4CBF41C463,ped,flagId,value)end;
    IS_PED_RUNNING=function(ped)return Natives.InvokeBool(0xC5286FFC176F28A2,ped)end;---@return boolean
    SET_BLOCKING_OF_NON_TEMPORARY_EVENTS=function(ped,toggle)return Natives.InvokeVoid(0x9F8AA94D6D97DBF4,ped,toggle)end,
    IS_PED_A_PLAYER=function(ped)return Natives.InvokeBool(0x12534C348C6CB68B,ped)end,
    SET_DRIVER_AGGRESSIVENESS=function(driver,aggressiveness)return Natives.InvokeVoid(0xA731F608CA104E3C,driver,aggressiveness+.0)end,
    SET_PED_COMBAT_RANGE=function(ped,combatRange)return Natives.InvokeVoid(0x3C606747B23E497B,ped,combatRange)end,
    SET_PED_RELATIONSHIP_GROUP_HASH=function(ped,hash)return Natives.InvokeVoid(0xC80A74AC829DDD92,ped,hash)end,
    SET_PED_COMBAT_MOVEMENT=function(ped,combatMovement)return Natives.InvokeVoid(0x4D9CA1009AFBD057,ped,combatMovement)end,
    SET_PED_COMPONENT_VARIATION=function(ped,componentId,drawableId,textureId,paletteId)return Natives.InvokeVoid(0x262B14F48D29DE80,ped,componentId,drawableId,textureId,paletteId)end,
    IS_PED_DEAD_OR_DYING=function(ped,p1)return Natives.InvokeBool(0x3317DEDB88C95038,ped,p1)end,
    SET_PED_SHOOTS_AT_COORD=function(ped,x,y,z,toggle)return Natives.InvokeVoid(0x96A05E4FB321B1BA,ped,x+.0,y+.0,z+.0,toggle)end,
    SET_PED_ACCURACY=function(ped,accuracy)return Natives.InvokeVoid(0x7AEFB85C1D49DEB6,ped,accuracy)end,
    SET_PED_KEEP_TASK=function(ped,toggle)return Natives.InvokeVoid(0x971D38760FBC02EF,ped,toggle)end,
    SET_PED_COMBAT_ATTRIBUTES=function(ped,attributeId,enabled)return Natives.InvokeVoid(0x9F7794730795E019,ped,attributeId,enabled)end,
    CREATE_PED_INSIDE_VEHICLE=function(vehicle,pedType,modelHash,seat,isNetwork,bScriptHostPed)return Natives.InvokeInt(0x7DD959874C1FD534,vehicle,pedType,modelHash,seat,isNetwork,bScriptHostPed)end,
    IS_PED_IN_ANY_VEHICLE=function(ped,atGetIn)return Natives.InvokeBool(0x997ABD671D25CA0B,ped,atGetIn)end,
    SET_PED_INTO_VEHICLE=function(ped,vehicle,seatIndex)return Natives.InvokeVoid(0xF75B0D629E1C063D,ped,vehicle,seatIndex)end,
    DELETE_PED=function(ped)return Natives.InvokeVoid(0x9614299DCB53E54B,ped)end,
    SET_DRIVER_ABILITY=function(driver,ability)return Natives.InvokeVoid(0xB195FFA8042FC5C3,driver,ability+.0)end,
    GET_VEHICLE_PED_IS_IN=function(ped,includeEntering)return Natives.InvokeInt(0x9A9112A0FE9A4713,ped,includeEntering)end,
    SET_PED_COMBAT_ABILITY=function(ped,abilityLevel)return Natives.InvokeVoid(0xC7622C0D36B2FDA8,ped,abilityLevel)end,
    IS_PED_IN_VEHICLE=function(ped,vehicle,atGetIn)return Natives.InvokeBool(0xA3EE4A07279BB9DB,ped,vehicle,atGetIn)end,
    GET_PED_BONE_INDEX=function(ped,boneId)return Natives.InvokeInt(0x3F428D08BE5AAE31,ped,boneId)end;---@return integer
	IS_PED_IN_PARACHUTE_FREE_FALL=function(ped)return Natives.InvokeBool(0x7DCE8BDA0F1C1200,ped)end;---@return boolean
	GET_PED_PARACHUTE_STATE=function(ped)return Natives.InvokeInt(0x79CFD9827CC979B6,ped)end;---@return integer
}

PLAYER = {
	IS_PLAYER_WANTED_LEVEL_GREATER=function(...)return Natives.InvokeBool(0x238DB2A2C23EE9EF,...)end;
    IS_REMOTE_PLAYER_IN_NON_CLONED_VEHICLE=function(player--[[@param player integer]])return Natives.InvokeBool(0x690A61A6D13583F6,player)end;---@return boolean
    IS_PLAYER_DEAD=function(player)return Natives.InvokeBool(0x424D4687FA1E5652,player)end;---@return boolean
	GET_PLAYERS_LAST_VEHICLE=function()return Natives.InvokeInt(0xB6997A7EB3F5C8C0)end;---@return integer
    START_PLAYER_TELEPORT=function(player,x,y,z,heading,p5,findCollisionLand,p7)return Natives.InvokeVoid(0xAD15F075A4DA0FDE,player,x+.0,y+.0,z+.0,heading+.0,p5,findCollisionLand,p7)end,
    PLAYER_ID=function()return Natives.InvokeInt(0x4F8644AF03D0E0D6)end,
    GET_PLAYER_PED=function(player)return Natives.InvokeInt(0x43A66C31C68491C0,player)end,
    GET_PLAYER_PED_SCRIPT_INDEX=function(player)return Natives.InvokeInt(0x50FAC3A3E030A6E1,player)end,
    PLAYER_PED_ID=function()return Natives.InvokeInt(0xD80958FC74E988A6)end,
    GET_PLAYER_NAME=function(player)return Natives.InvokeString(0x6D0DE6A7B5DA71F8,player)end,
}

SCRIPT = {
    GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH=function(scriptHash)return Natives.InvokeInt(0x2C83A9DA6BFFC4F9,scriptHash)end,
}

STATS = {
    STAT_INCREMENT=function(statName,value)return Natives.InvokeVoid(0x9B5A68C6489E9909,statName,value+.0)end,
    STAT_SET_INT=function(statName,value,save)return Natives.InvokeBool(0xB3271D7AB655B441,statName,value,save)end,
    STAT_SET_BOOL=function(statName,value,save)return Natives.InvokeBool(0x4B33C4243DE0C432,statName,value,save)end,
    SET_PACKED_STAT_INT_CODE=function(index,value,characterSlot)return Natives.InvokeVoid(0x1581503AE529CD2E,index,value,characterSlot)end,
    SET_PACKED_STAT_BOOL_CODE=function(index,value,characterSlot)return Natives.InvokeVoid(0xDB8A58AEAA67CD07,index,value,characterSlot)end,
    STAT_SET_FLOAT=function(statName,value,save)return Natives.InvokeBool(0x4851997F37FE9B3C,statName,value+.0,save)end,
    STAT_SET_STRING=function(statName,value,save)return Natives.InvokeBool(0xA87B2335D12531D7,statName,value,save)end,
    STAT_GET_STRING=function(statHash,p1)return Natives.InvokeString(0xE50384ACC2C3DB74,statHash,p1)end,
}

STREAMING = {
    HAS_MODEL_LOADED=function(model)return Natives.InvokeBool(0x98A4EB5D89A0C952,model)end,
    SET_MODEL_AS_NO_LONGER_NEEDED=function(model)return Natives.InvokeVoid(0xE532F5D78798DAAB,model)end,
    REQUEST_MODEL=function(model)return Natives.InvokeVoid(0x963D27A58DF860AC,model)end,
    SET_FOCUS_POS_AND_VEL=function(x,y,z,offsetX,offsetY,offsetZ)return Natives.InvokeVoid(0xBB7454BAFF08FE25,x+.0,y+.0,z+.0,offsetX+.0,offsetY+.0,offsetZ+.0)end,
    CLEAR_FOCUS=function()return Natives.InvokeVoid(0x31B73D1EA9F01DA2)end,
    REQUEST_NAMED_PTFX_ASSET=function(fxName)return Natives.InvokeVoid(0xB80D8756B4668AB6,fxName)end;
	HAS_NAMED_PTFX_ASSET_LOADED=function(fxName)return Natives.InvokeBool(0x8702416E512EC454,fxName)end;---@return boolean
  	REQUEST_ANIM_DICT=function(animDict)return Natives.InvokeVoid(0xD3BD40951412FEF6,animDict)end;
	HAS_ANIM_DICT_LOADED=function(animDict)return Natives.InvokeBool(0xD031A9162D01088C,animDict)end;---@return boolean

}

TASK = {
    CLEAR_PED_TASKS=function(ped)return Natives.InvokeVoid(0xE1EF3C1216AFF2CD,ped)end;
	TASK_SKY_DIVE=function(ped,instant)return Natives.InvokeVoid(0x601736CFE536B0A0,ped,instant)end;

    TASK_VEHICLE_MISSION_PED_TARGET=function(ped,vehicle,pedTarget,missionType,maxSpeed,drivingStyle,minDistance,straightLineDistance,DriveAgainstTraffic)return Natives.InvokeVoid(0x9454528DF15D657A,ped,vehicle,pedTarget,missionType,maxSpeed+.0,drivingStyle,minDistance+.0,straightLineDistance+.0,DriveAgainstTraffic)end,
    TASK_COMBAT_PED=function(ped,targetPed,combatFlags,threatResponseFlags)return Natives.InvokeVoid(0xF166E48407BAC484,ped,targetPed,combatFlags,threatResponseFlags)end,
    TASK_PLANE_MISSION=function(pilot,aircraft,targetVehicle,targetPed,destinationX,destinationY,destinationZ,missionFlag,angularDrag,targetReached,targetHeading,maxZ,minZ,precise)return Natives.InvokeVoid(0x23703CD154E83B88,pilot,aircraft,targetVehicle,targetPed,destinationX+.0,destinationY+.0,destinationZ+.0,missionFlag,angularDrag+.0,targetReached+.0,targetHeading+.0,maxZ+.0,minZ+.0,precise)end,
    TASK_VEHICLE_DRIVE_WANDER=function(ped,vehicle,speed,drivingStyle)return Natives.InvokeVoid(0x480142959D337D00,ped,vehicle,speed+.0,drivingStyle)end,
    TASK_START_SCENARIO_IN_PLACE=function(ped,scenarioName,unkDelay,playEnterAnim)return Natives.InvokeVoid(0x142A02425FF02BD9,ped,scenarioName,unkDelay,playEnterAnim)end,
    SET_DRIVE_TASK_DRIVING_STYLE=function(ped,drivingStyle)return Natives.InvokeVoid(0xDACE1BE37D88AF67,ped,drivingStyle)end,
    TASK_VEHICLE_FOLLOW=function(driver,vehicle,targetEntity,speed,drivingStyle,minDistance)return Natives.InvokeVoid(0xFC545A9F0626E3B6,driver,vehicle,targetEntity,speed+.0,drivingStyle,minDistance)end,
    TASK_PLAY_ANIM=function(ped,animDictionary,animationName,blendInSpeed,blendOutSpeed,duration,flag,playbackRate,lockX,lockY,lockZ)return Natives.InvokeVoid(0xEA47FE3719165B94,ped,animDictionary,animationName,blendInSpeed+.0,blendOutSpeed+.0,duration,flag,playbackRate+.0,lockX,lockY,lockZ)end;
    TASK_VEHICLE_TEMP_ACTION=function(...)return Natives.InvokeVoid(0xC429DCEEB339E129,...)end;

}

VEHICLE = {
    GET_VEHICLE_CLASS=function(vehicle--[[@param vehicle integer]])return Natives.InvokeInt(0x29439776AAA00A62,vehicle)end;---@return integer
    SET_VEHICLE_IS_CONSIDERED_BY_PLAYER=function(vehicle,toggle)return Natives.InvokeVoid(0x31B927BBC44156CD,vehicle,toggle)end;
    SET_VEHICLE_PETROL_TANK_HEALTH=function(vehicle,health)return Natives.InvokeVoid(0x70DB57649FA8D0D8,vehicle,health+.0)end;
    SET_VEHICLE_HAS_BEEN_OWNED_BY_PLAYER=function(vehicle,owned)return Natives.InvokeVoid(0x2B5F9D2AF1F1722D,vehicle,owned)end;
	SET_VEHICLE_NEEDS_TO_BE_HOTWIRED=function(vehicle,toggle)return Natives.InvokeVoid(0xFBA550EA44404EE6,vehicle,toggle)end;
	SET_VEHICLE_IS_STOLEN=function(vehicle,isStolen)return Natives.InvokeVoid(0x67B2C79AA7FF5738,vehicle,isStolen)end;
    GET_VEHICLE_MAX_BRAKING=function(vehicle)return Natives.InvokeFloat(0xAD7E85FC227197C4,vehicle)end;---@return number
	GET_VEHICLE_MAX_TRACTION=function(vehicle)return Natives.InvokeFloat(0xA132FB5370554DB0,vehicle)end;---@return number
	GET_VEHICLE_ACCELERATION=function(vehicle)return Natives.InvokeFloat(0x5DD35C8D074E57AE,vehicle)end;---@return number
	GET_VEHICLE_ESTIMATED_MAX_SPEED=function(vehicle)return Natives.InvokeFloat(0x53AF99BAA671CA47,vehicle)end;---@return number
    GET_VEHICLE_NEON_ENABLED=function(vehicle,index)return Natives.InvokeBool(0x8C4B92553E4766A5,vehicle,index)end,
    GET_NUM_VEHICLE_MODS=function(vehicle,modType)return Natives.InvokeInt(0xE38E9162A2500646,vehicle,modType)end,
    SET_VEHICLE_GRAVITY=function(vehicle,toggle)return Natives.InvokeVoid(0x89F149B6131E57DA,vehicle,toggle)end,
    GET_VEHICLE_LIVERY=function(vehicle)return Natives.InvokeInt(0x2BB9230590DA5E8A,vehicle)end,
    CONTROL_LANDING_GEAR=function(vehicle,state)return Natives.InvokeVoid(0xCFC8BE9A5E1FE575,vehicle,state)end,
    SET_VEHICLE_WINDOW_TINT=function(vehicle,tint)return Natives.InvokeVoid(0x57C51E6BAD752696,vehicle,tint)end,
    SET_PLANE_TURBULENCE_MULTIPLIER=function(vehicle,multiplier)return Natives.InvokeVoid(0xAD2D28A1AFDFF131,vehicle,multiplier+.0)end,
    IS_VEHICLE_EXTRA_TURNED_ON=function(vehicle,extraId)return Natives.InvokeBool(0xD2E6822DBFD6C8BD,vehicle,extraId)end,
    SET_VEHICLE_COLOURS=function(vehicle,colorPrimary,colorSecondary)return Natives.InvokeVoid(0x4F1D4BE3A7F24601,vehicle,colorPrimary,colorSecondary)end,
    SET_VEHICLE_TYRE_SMOKE_COLOR=function(vehicle,r,g,b)return Natives.InvokeVoid(0xB5BA80F839791C0F,vehicle,r,g,b)end,
    SET_HELI_BLADES_FULL_SPEED=function(vehicle)return Natives.InvokeVoid(0xA178472EBB8AE60D,vehicle)end,
    SET_VEHICLE_EXTRA=function(vehicle,extraId,disable)return Natives.InvokeVoid(0x7EE3A3C5E4A40CC9,vehicle,extraId,disable)end,
    DOES_EXTRA_EXIST=function(vehicle,extraId)return Natives.InvokeBool(0x1262D55792428154,vehicle,extraId)end,
    SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX=function(vehicle,plateIndex)return Natives.InvokeVoid(0x9088EB5A43FFB0A1,vehicle,plateIndex)end,
    SET_VEHICLE_NEON_COLOUR=function(vehicle,r,g,b)return Natives.InvokeVoid(0x8E0A582209A62695,vehicle,r,g,b)end,
    GET_PED_IN_VEHICLE_SEAT=function(vehicle,seatIndex,p2)return Natives.InvokeInt(0xBB40DD2270B65366,vehicle,seatIndex,p2)end,
    SET_VEHICLE_XENON_LIGHT_COLOR_INDEX=function(vehicle,colorIndex)return Natives.InvokeVoid(0xE41033B25D003A07,vehicle,colorIndex)end,
    SET_VEHICLE_ENGINE_ON=function(vehicle,value,instantly,disableAutoStart)return Natives.InvokeVoid(0x2497C4717C8B881E,vehicle,value,instantly,disableAutoStart)end,
    SET_VEHICLE_ON_GROUND_PROPERLY=function(vehicle,p1)return Natives.InvokeBool(0x49733E92263139D1,vehicle,p1+.0)end,
    GET_VEHICLE_WHEEL_TYPE=function(vehicle)return Natives.InvokeInt(0xB3ED1BFB4BE636DC,vehicle)end,
    SET_VEHICLE_MOD=function(vehicle,modType,modIndex,customTires)return Natives.InvokeVoid(0x6AF0636DDEDCB6DD,vehicle,modType,modIndex,customTires)end,
    SET_VEHICLE_EXTRA_COLOURS=function(vehicle,pearlescentColor,wheelColor)return Natives.InvokeVoid(0x2036F561ADD12E33,vehicle,pearlescentColor,wheelColor)end,
    TOGGLE_VEHICLE_MOD=function(vehicle,modType,toggle)return Natives.InvokeVoid(0x2A1F4F37F95BAD08,vehicle,modType,toggle)end,
    GET_VEHICLE_NEON_COLOUR=function(vehicle,r,g,b)return Natives.InvokeVoid(0x7619EEE8C886757F,vehicle,r,g,b)end,
    GET_VEHICLE_MOD=function(vehicle,modType)return Natives.InvokeInt(0x772960298DA26FDB,vehicle,modType)end,
    GET_VEHICLE_NUMBER_PLATE_TEXT=function(vehicle)return Natives.InvokeString(0x7CE1CCB9B293020E,vehicle)end,
    SET_VEHICLE_WHEEL_TYPE=function(vehicle,WheelType)return Natives.InvokeVoid(0x487EB21CC7295BA1,vehicle,WheelType)end,
    GET_CLOSEST_VEHICLE=function(x,y,z,radius,modelHash,flags)return Natives.InvokeInt(0xF73EB622C4F1689B,x+.0,y+.0,z+.0,radius+.0,modelHash,flags)end,
    IS_TOGGLE_MOD_ON=function(vehicle,modType)return Natives.InvokeBool(0x84B233A8C8FC8AE7,vehicle,modType)end,
    SET_VEHICLE_NUMBER_PLATE_TEXT=function(vehicle,plateText)return Natives.InvokeVoid(0x95A88F0B409CDA47,vehicle,plateText)end,
    GET_VEHICLE_MOD_KIT=function(vehicle)return Natives.InvokeInt(0x6325D1A044AE510D,vehicle)end,
    GET_VEHICLE_EXTRA_COLOURS=function(vehicle,pearlescentColor,wheelColor)return Natives.InvokeVoid(0x3BC4245933A166F7,vehicle,pearlescentColor,wheelColor)end,
    GET_VEHICLE_COLOURS=function(vehicle,colorPrimary,colorSecondary)return Natives.InvokeVoid(0xA19435F193E081AC,vehicle,colorPrimary,colorSecondary)end,
    SET_VEHICLE_TYRES_CAN_BURST=function(vehicle,toggle)return Natives.InvokeVoid(0xEB9DC3C7D8596C46,vehicle,toggle)end,
    GET_VEHICLE_XENON_LIGHT_COLOR_INDEX=function(vehicle)return Natives.InvokeInt(0x3DFF319A831E0CDB,vehicle)end,
    SET_VEHICLE_MOD_KIT=function(vehicle,modKit)return Natives.InvokeVoid(0x1F2AA07F00B3217A,vehicle,modKit)end,
    GET_DISPLAY_NAME_FROM_VEHICLE_MODEL=function(modelHash)return Natives.InvokeString(0xB215AAC32D25D019,modelHash)end,
    GET_VEHICLE_WINDOW_TINT=function(vehicle)return Natives.InvokeInt(0x0EE21293DAD47C95,vehicle)end,
    SET_VEHICLE_LIVERY=function(vehicle,livery)return Natives.InvokeVoid(0x60BF608F1B8CD1B6,vehicle,livery)end,
    GET_VEHICLE_TYRE_SMOKE_COLOR=function(vehicle,r,g,b)return Natives.InvokeVoid(0xB635392A4938B3C3,vehicle,r,g,b)end,
    SET_VEHICLE_NEON_ENABLED=function(vehicle,index,toggle)return Natives.InvokeVoid(0x2AA720E4287BF269,vehicle,index,toggle)end,
    SET_VEHICLE_DIRT_LEVEL=function(vehicle,dirtLevel)return Natives.InvokeVoid(0x79D3B596FE44EE8B,vehicle,dirtLevel+.0)end,
    IS_VEHICLE_DRIVEABLE=function(vehicle,isOnFireCheck)return Natives.InvokeBool(0x4C241E39B23DF959,vehicle,isOnFireCheck)end,
    SET_VEHICLE_FORWARD_SPEED=function(vehicle,speed)return Natives.InvokeVoid(0xAB54A438726D25D5,vehicle,speed+.0)end,
    GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX=function(vehicle)return Natives.InvokeInt(0xF11BC2DD9A3E7195,vehicle)end,
}

ZONE = {
    OVERRIDE_POPSCHEDULE_VEHICLE_MODEL=function(scheduleId,vehicleHash)return Natives.InvokeVoid(0x5F7D596BAC2E7777,scheduleId,vehicleHash)end;
	CLEAR_POPSCHEDULE_OVERRIDE_VEHICLE_MODEL=function(scheduleId)return Natives.InvokeVoid(0x5C0DE367AA0D911C,scheduleId)end;
}

WEAPON = {
    REFILL_AMMO_INSTANTLY=function(ped)return Natives.InvokeBool(0x8C0D57EA686FAD87,ped)end,
    GIVE_WEAPON_TO_PED=function(ped,weaponHash,ammoCount,isHidden,bForceInHand)return Natives.InvokeVoid(0xBF0FD6E56C964FCB,ped,weaponHash,ammoCount,isHidden,bForceInHand)end,
    GET_CURRENT_PED_WEAPON_ENTITY_INDEX=function(ped,p1)return Natives.InvokeInt(0x3B390A939AF0B5FC,ped,p1)end,
    GIVE_DELAYED_WEAPON_TO_PED=function(ped,weaponHash,ammoCount,bForceInHand)return Natives.InvokeVoid(0xB282DC6EBD803C75,ped,weaponHash,ammoCount,bForceInHand)end,
	HAS_PED_GOT_WEAPON=function(ped,weaponHash,p2)return Natives.InvokeBool(0x8DECB02F88F428BC,ped,weaponHash,p2)end;---@return boolean
}

SOCIALCLUB = {
    SC_ACCOUNT_INFO_GET_NICKNAME=function()return Natives.InvokeString(0x198D161F458ECC7F)end;---@return string
}


    welcometextcolor = FeatAdd(joaat("welcometxtclr"), "Welcome Text Color", eFeatureType.InputColor4,
        "Sets the welcome text color")
    welcometextcolor:SetColor(255, 0, 0, 255)

    on_screen_text = {}

    WelcomeText = function(text, pos, scale, size, r, g, b, a, center, font, wrap_start, wrap_end)       -- nigger text 
        NIGGER.SET_TEXT_SCALE(scale, size)
        NIGGER.SET_TEXT_COLOUR(r, g, b, a)
        NIGGER.SET_TEXT_CENTRE(center)
        NIGGER.SET_TEXT_FONT(font)
        NIGGER.SET_TEXT_DROPSHADOW(0, 0, 0, 0, 0)
        NIGGER.SET_TEXT_EDGE(0, 0, 0, 0, 0)
        NIGGER.SET_TEXT_PROPORTIONAL(1)
        NIGGER.SET_TEXT_WRAP(wrap_start, wrap_end)
        NIGGER.SET_TEXT_OUTLINE()
        NIGGER.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("CELL_EMAIL_BCON")
        NIGGER.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
        NIGGER.END_TEXT_COMMAND_DISPLAY_TEXT(pos.x, pos.y - 0.1, 0)
    end

    local loadingscreendone = nil
    function WelcomeScreen()
        if NETWORK.NETWORK_GET_GAME_MODE() == -1 or 0 then
            local blur_speed = 500.0
            GRAPHICS.TRIGGER_SCREENBLUR_FADE_IN(blur_speed)
            local playerName = PLAYER.GET_PLAYER_NAME(GTA.GetLocalPlayerId())
            local message = "Welcome " .. playerName .. ", to Elf Script"

            if version == "EE" then
                message = "Welcome " .. playerName .. ", to Elf Script E&E"
                if isDev then
                    message = "Welcome " .. playerName .. ", to Elf Script E&E, Developer"
                elseif isAdmin then
                    message = "Welcome " .. playerName .. ", to Elf Script E&E, Admin"
                end
            else
                if isDev then
                    message = "Welcome " .. playerName .. ", to Elf Script, Developer"
                elseif isAdmin then
                    message = "Welcome " .. playerName .. ", to Elf Script, Admin"
                end
            end

            local timer = Time.GetEpocheMs()
            local delay = 3000
            local alpha = 0
            local r, g, b = welcometextcolor:GetColor()
            while (Time.GetEpocheMs() - timer < delay) do
                alpha = math.min(alpha + (255 / (0.5 / MISC.GET_FRAME_TIME() / (1000 / (3000 / 1.0)))), 255)
                WelcomeText(message, V2.New(0.5, 0.5), 2.1, 1.0, r, g, b, alpha, true, 1, 0.0, 1.0)
                WelcomeText("~italic~Join the Discord &lt;3~BLIP_YUSUF~", V2.New(0.5, 0.62), 2.1, 1.0, r,g,b, alpha, true, 1, 00, 1.0)
                Script.Yield()
            end
            loadingscreendone = true
            GRAPHICS.TRIGGER_SCREENBLUR_FADE_OUT(blur_speed)
        end
    end

    debug = nil   
    UID = Cherax.GetUID()

    --- inxlua starts here
    function load_base64_lib()
        local base64 = {}

        local extract = load [[return function( v, from, width )
            return ( v >> from ) & ((1 << width) - 1)
        end]]()


        function base64.makeencoder(s62, s63, spad)
            local encoder = {}
            for b64code, char in pairs { [0] = 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
                'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y',
                'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
                'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2',
                '3', '4', '5', '6', '7', '8', '9', s62 or '+', s63 or '/', spad or '=' } do
                encoder[b64code] = char:byte()
            end
            return encoder
        end

        function base64.makedecoder(s62, s63, spad)
            local decoder = {}
            for b64code, charcode in pairs(base64.makeencoder(s62, s63, spad)) do
                decoder[charcode] = b64code
            end
            return decoder
        end

        local DEFAULT_ENCODER = base64.makeencoder()
        local DEFAULT_DECODER = base64.makedecoder()

        local char, concat = string.char, table.concat

        function base64.encode(str, encoder, usecaching)
            encoder = encoder or DEFAULT_ENCODER
            local t, k, n = {}, 1, #str
            local lastn = n % 3
            local cache = {}
            for i = 1, n - lastn, 3 do
                local a, b, c = str:byte(i, i + 2)
                local v = a * 0x10000 + b * 0x100 + c
                local s
                if usecaching then
                    s = cache[v]
                    if not s then
                        s = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)],
                            encoder[extract(v, 0, 6)])
                        cache[v] = s
                    end
                else
                    s = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)],
                        encoder[extract(v, 0, 6)])
                end
                t[k] = s
                k = k + 1
            end
            if lastn == 2 then
                local a, b = str:byte(n - 1, n)
                local v = a * 0x10000 + b * 0x100
                t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)], encoder[64])
            elseif lastn == 1 then
                local v = str:byte(n) * 0x10000
                t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[64], encoder[64])
            end
            return concat(t)
        end

        function base64.decode(b64, decoder, usecaching)
            decoder = decoder or DEFAULT_DECODER
            local pattern = '[^%w%+%/%=]'
            if decoder then
                local s62, s63
                for charcode, b64code in pairs(decoder) do
                    if b64code == 62 then
                        s62 = charcode
                    elseif b64code == 63 then
                        s63 = charcode
                    end
                end
                pattern = ('[^%%w%%%s%%%s%%=]'):format(char(s62), char(s63))
            end
            b64 = b64:gsub(pattern, '')
            local cache = usecaching and {}
            local t, k = {}, 1
            local n = #b64
            local padding = b64:sub(-2) == '==' and 2 or b64:sub(-1) == '=' and 1 or 0
            for i = 1, padding > 0 and n - 4 or n, 4 do
                local a, b, c, d = b64:byte(i, i + 3)
                local s
                if usecaching then
                    local v0 = a * 0x1000000 + b * 0x10000 + c * 0x100 + d
                    s = cache[v0]
                    if not s then
                        local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40 + decoder[d]
                        s = char(extract(v, 16, 8), extract(v, 8, 8), extract(v, 0, 8))
                        cache[v0] = s
                    end
                else
                    local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40 + decoder[d]
                    s = char(extract(v, 16, 8), extract(v, 8, 8), extract(v, 0, 8))
                end
                t[k] = s
                k = k + 1
            end
            if padding == 1 then
                local a, b, c = b64:byte(n - 3, n - 1)
                local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40
                t[k] = char(extract(v, 16, 8), extract(v, 8, 8))
            elseif padding == 2 then
                local a, b = b64:byte(n - 3, n - 2)
                local v = decoder[a] * 0x40000 + decoder[b] * 0x1000
                t[k] = char(extract(v, 16, 8))
            end
            return concat(t)
        end

        return base64
    end

    local function load_json_lib()
        local always_try_using_lpeg = true
        local register_global_module_table = false
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
        
        local _ENV = nil 
        
        pcall (function()
          local debmeta = require "debug".getmetatable
          if debmeta then getmetatable = debmeta end
        end)
        
        json.null = setmetatable ({}, {
          __tojson = function() return "null" end
        })
        
        local function isarray (tbl)
          local max, n, arraylen = 0, 0, 0
          for k,v in pairs (tbl) do
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
          ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
          ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t"
        }
        
        local function escapeutf8 (uchar)
          local value = escapecodes[uchar]
          if value then
            return value
          end
          local a, b, c, d = strbyte (uchar, 1, 4)
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
            return strformat ("\\u%.4x", value)
          elseif value <= 0x10ffff then
            value = value - 0x10000
            local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)
            return strformat ("\\u%.4x\\u%.4x", highsur, lowsur)
          else
            return ""
          end
        end
        
        local function fsub (str, pattern, repl)
          if strfind (str, pattern) then
            return gsub (str, pattern, repl)
          else
            return str
          end
        end
        
        local function quotestring (value)
          value = fsub (value, "[%z\1-\31\"\\\127]", escapeutf8)
          if strfind (value, "[\194\216\220\225\226\239]") then
            value = fsub (value, "\194[\128-\159\173]", escapeutf8)
            value = fsub (value, "\216[\128-\132]", escapeutf8)
            value = fsub (value, "\220\143", escapeutf8)
            value = fsub (value, "\225\158[\180\181]", escapeutf8)
            value = fsub (value, "\226\128[\140-\143\168-\175]", escapeutf8)
            value = fsub (value, "\226\129[\160-\175]", escapeutf8)
            value = fsub (value, "\239\187\191", escapeutf8)
            value = fsub (value, "\239\191[\176-\191]", escapeutf8)
          end
          return "\"" .. value .. "\""
        end
        json.quotestring = quotestring
        
        local function replace(str, o, n)
          local i, j = strfind (str, o, 1, true)
          if i then
            return strsub(str, 1, i-1) .. n .. strsub(str, j+1, -1)
          else
            return str
          end
        end
        
        local decpoint, numfilter
        
        local function updatedecpoint ()
          decpoint = strmatch(tostring(0.5), "([^05+])")
          numfilter = "[^0-9%-%+eE" .. gsub(decpoint, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "]+"
        end
        
        updatedecpoint()
        
        local function num2str (num)
          return replace(fsub(tostring(num), numfilter, ""), decpoint, ".")
        end
        
        local function str2num (str)
          local num = tonumber(replace(str, ".", decpoint))
          if not num then
            updatedecpoint()
            num = tonumber(replace(str, ".", decpoint))
          end
          return num
        end
        
        local function addnewline2 (level, buffer, buflen)
          buffer[buflen+1] = "\n"
          buffer[buflen+2] = strrep ("  ", level)
          buflen = buflen + 2
          return buflen
        end
        
        function json.addnewline (state)
          if state.indent then
            state.bufferlen = addnewline2 (state.level or 0,
                                   state.buffer, state.bufferlen or #(state.buffer))
          end
        end
        
        local encode2 
        
        local function addpair (key, value, prev, indent, level, buffer, buflen, tables, globalorder, state)
          local kt = type (key)
          if kt ~= 'string' and kt ~= 'number' then
            return nil, "type '" .. kt .. "' is not supported as a key by JSON."
          end
          if prev then
            buflen = buflen + 1
            buffer[buflen] = ","
          end
          if indent then
            buflen = addnewline2 (level, buffer, buflen)
          end
          buffer[buflen+1] = quotestring (key)
          buffer[buflen+2] = ":"
          return encode2 (value, indent, level, buffer, buflen + 2, tables, globalorder, state)
        end
        
        local function appendcustom(res, buffer, state)
          local buflen = state.bufferlen
          if type (res) == 'string' then
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
            local ret, msg = handler (reason, value, state, defaultmessage)
            if not ret then return nil, msg or defaultmessage end
            return appendcustom(ret, buffer, state)
          end
        end
        
        function json.encodeexception(reason, value, state, defaultmessage)
          return quotestring("<" .. defaultmessage .. ">")
        end
        
        encode2 = function(value, indent, level, buffer, buflen, tables, globalorder, state)
          local valtype = type (value)
          local valmeta = getmetatable (value)
          valmeta = type (valmeta) == 'table' and valmeta
          local valtojson = valmeta and valmeta.__tojson
          if valtojson then
            if tables[value] then
              return exception('reference cycle', value, state, buffer, buflen)
            end
            tables[value] = true
            state.bufferlen = buflen
            local ret, msg = valtojson (value, state)
            if not ret then return exception('custom encoder failed', value, state, buffer, buflen, msg) end
            tables[value] = nil
            buflen = appendcustom(ret, buffer, state)
          elseif value == nil then
            buflen = buflen + 1
            buffer[buflen] = "null"
          elseif valtype == 'number' then
            local s
            if value ~= value or value >= huge or -value >= huge then
              s = "null"
            else
              s = num2str (value)
            end
            buflen = buflen + 1
            buffer[buflen] = s
          elseif valtype == 'boolean' then
            buflen = buflen + 1
            buffer[buflen] = value and "true" or "false"
          elseif valtype == 'string' then
            buflen = buflen + 1
            buffer[buflen] = quotestring (value)
          elseif valtype == 'table' then
            if tables[value] then
              return exception('reference cycle', value, state, buffer, buflen)
            end
            tables[value] = true
            level = level + 1
            local isa, n = isarray (value)
            if n == 0 and valmeta and valmeta.__jsontype == 'object' then
              isa = false
            end
            local msg
            if isa then 
              buflen = buflen + 1
              buffer[buflen] = "["
              for i = 1, n do
                buflen, msg = encode2 (value[i], indent, level, buffer, buflen, tables, globalorder, state)
                if not buflen then return nil, msg end
                if i < n then
                  buflen = buflen + 1
                  buffer[buflen] = ","
                end
              end
              buflen = buflen + 1
              buffer[buflen] = "]"
            else 
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
                    buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
                    prev = true  
                  end
                end
                for k,v in pairs (value) do
                  if not used[k] then
                    buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
                    if not buflen then return nil, msg end
                    prev = true 
                  end
                end
              else 
                for k,v in pairs (value) do
                  buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
                  if not buflen then return nil, msg end
                  prev = true
                end
              end
              if indent then
                buflen = addnewline2 (level - 1, buffer, buflen)
              end
              buflen = buflen + 1
              buffer[buflen] = "}"
            end
            tables[value] = nil
          else
            return exception ('unsupported type', value, state, buffer, buflen,
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
          local ret, msg = encode2 (value, state.indent, state.level or 0,
                           buffer, state.bufferlen or 0, state.tables or {}, state.keyorder, state)
          if not ret then
            error (msg, 2)
          elseif oldbuffer == buffer then
            state.bufferlen = ret
            return true
          else
            state.bufferlen = nil
            state.buffer = nil
            return concat (buffer)
          end
        end
        
        local function loc (str, where)
          local line, pos, linepos = 1, 1, 0
          while true do
            pos = strfind (str, "\n", pos, true)
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
        
        local function unterminated (str, what, where)
          return nil, strlen (str) + 1, "unterminated " .. what .. " at " .. loc (str, where)
        end
        
        local function scanwhite (str, pos)
          while true do
            pos = strfind (str, "%S", pos)
            if not pos then return nil end
            local sub2 = strsub (str, pos, pos + 1)
            if sub2 == "\239\187" and strsub (str, pos + 2, pos + 2) == "\191" then
              pos = pos + 3
            elseif sub2 == "//" then
              pos = strfind (str, "[\n\r]", pos + 2)
              if not pos then return nil end
            elseif sub2 == "/*" then
              pos = strfind (str, "*/", pos + 2)
              if not pos then return nil end
              pos = pos + 2
            else
              return pos
            end
          end
        end
        
        local escapechars = {
          ["\""] = "\"", ["\\"] = "\\", ["/"] = "/", ["b"] = "\b", ["f"] = "\f",
          ["n"] = "\n", ["r"] = "\r", ["t"] = "\t"
        }
        
        local function unichar (value)
          if value < 0 then
            return nil
          elseif value <= 0x007f then
            return strchar (value)
          elseif value <= 0x07ff then
            return strchar (0xc0 + floor(value/0x40),
                            0x80 + (floor(value) % 0x40))
          elseif value <= 0xffff then
            return strchar (0xe0 + floor(value/0x1000),
                            0x80 + (floor(value/0x40) % 0x40),
                            0x80 + (floor(value) % 0x40))
          elseif value <= 0x10ffff then
            return strchar (0xf0 + floor(value/0x40000),
                            0x80 + (floor(value/0x1000) % 0x40),
                            0x80 + (floor(value/0x40) % 0x40),
                            0x80 + (floor(value) % 0x40))
          else
            return nil
          end
        end
        
        local function scanstring (str, pos)
          local lastpos = pos + 1
          local buffer, n = {}, 0
          while true do
            local nextpos = strfind (str, "[\"\\]", lastpos)
            if not nextpos then
              return unterminated (str, "string", pos)
            end
            if nextpos > lastpos then
              n = n + 1
              buffer[n] = strsub (str, lastpos, nextpos - 1)
            end
            if strsub (str, nextpos, nextpos) == "\"" then
              lastpos = nextpos + 1
              break
            else
              local escchar = strsub (str, nextpos + 1, nextpos + 1)
              local value
              if escchar == "u" then
                value = tonumber (strsub (str, nextpos + 2, nextpos + 5), 16)
                if value then
                  local value2
                  if 0xD800 <= value and value <= 0xDBff then
                    if strsub (str, nextpos + 6, nextpos + 7) == "\\u" then
                      value2 = tonumber (strsub (str, nextpos + 8, nextpos + 11), 16)
                      if value2 and 0xDC00 <= value2 and value2 <= 0xDFFF then
                        value = (value - 0xD800)  * 0x400 + (value2 - 0xDC00) + 0x10000
                      else
                        value2 = nil
                      end
                    end
                  end
                  value = value and unichar (value)
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
            return concat (buffer), lastpos
          else
            return "", lastpos
          end
        end
        
        local scanvalue
        
        local function scantable (what, closechar, str, startpos, nullval, objectmeta, arraymeta)
          local len = strlen (str)
          local tbl, n = {}, 0
          local pos = startpos + 1
          if what == 'object' then
            setmetatable (tbl, objectmeta)
          else
            setmetatable (tbl, arraymeta)
          end
          while true do
            pos = scanwhite (str, pos)
            if not pos then return unterminated (str, what, startpos) end
            local char = strsub (str, pos, pos)
            if char == closechar then
              return tbl, pos + 1
            end
            local val1, err
            val1, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
            if err then return nil, pos, err end
            pos = scanwhite (str, pos)
            if not pos then return unterminated (str, what, startpos) end
            char = strsub (str, pos, pos)
            if char == ":" then
              if val1 == nil then
                return nil, pos, "cannot use nil as table index (at " .. loc (str, pos) .. ")"
              end
              pos = scanwhite (str, pos + 1)
              if not pos then return unterminated (str, what, startpos) end
              local val2
              val2, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
              if err then return nil, pos, err end
              tbl[val1] = val2
              pos = scanwhite (str, pos)
              if not pos then return unterminated (str, what, startpos) end
              char = strsub (str, pos, pos)
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
          pos = scanwhite (str, pos)
          if not pos then
            return nil, strlen (str) + 1, "no valid JSON value (reached the end)"
          end
          local char = strsub (str, pos, pos)
          if char == "{" then
            return scantable ('object', "}", str, pos, nullval, objectmeta, arraymeta)
          elseif char == "[" then
            return scantable ('array', "]", str, pos, nullval, objectmeta, arraymeta)
          elseif char == "\"" then
            return scanstring (str, pos)
          else
            local pstart, pend = strfind (str, "^%-?[%d%.]+[eE]?[%+%-]?%d*", pos)
            if pstart then
              local number = str2num (strsub (str, pstart, pend))
              if number then
                return number, pend + 1
              end
            end
            pstart, pend = strfind (str, "^%a%w*", pos)
            if pstart then
              local name = strsub (str, pstart, pend)
              if name == "true" then
                return true, pend + 1
              elseif name == "false" then
                return false, pend + 1
              elseif name == "null" then
                return nullval, pend + 1
              end
            end
            return nil, pos, "no valid JSON value at " .. loc (str, pos)
          end
        end
        
        local function optionalmetatables(...)
          if select("#", ...) > 0 then
            return ...
          else
            return {__jsontype = 'object'}, {__jsontype = 'array'}
          end
        end
        
        function json.decode (str, pos, nullval, ...)
          local objectmeta, arraymeta = optionalmetatables(...)
          return scanvalue (str, pos, nullval, objectmeta, arraymeta)
        end
        
        function json.use_lpeg ()
          local g = require ("lpeg")
        
          if g.version() == "0.11" then
            error "due to a bug in LPeg 0.11, it cannot be used for JSON matching"
          end
        
          local pegmatch = g.match
          local P, S, R = g.P, g.S, g.R
        
          local function ErrorCall (str, pos, msg, state)
            if not state.msg then
              state.msg = msg .. " at " .. loc (str, pos)
              state.pos = pos
            end
            return false
          end
        
          local function Err (msg)
            return g.Cmt (g.Cc (msg) * g.Carg (2), ErrorCall)
          end
        
          local SingleLineComment = P"//" * (1 - S"\n\r")^0
          local MultiLineComment = P"/*" * (1 - P"*/")^0 * P"*/"
          local Space = (S" \n\r\t" + P"\239\187\191" + SingleLineComment + MultiLineComment)^0
        
          local PlainChar = 1 - S"\"\\\n\r"
          local EscapeSequence = (P"\\" * g.C (S"\"\\/bfnrt" + Err "unsupported escape sequence")) / escapechars
          local HexDigit = R("09", "af", "AF")
          local function UTF16Surrogate (match, pos, high, low)
            high, low = tonumber (high, 16), tonumber (low, 16)
            if 0xD800 <= high and high <= 0xDBff and 0xDC00 <= low and low <= 0xDFFF then
              return true, unichar ((high - 0xD800)  * 0x400 + (low - 0xDC00) + 0x10000)
            else
              return false
            end
          end
          local function UTF16BMP (hex)
            return unichar (tonumber (hex, 16))
          end
          local U16Sequence = (P"\\u" * g.C (HexDigit * HexDigit * HexDigit * HexDigit))
          local UnicodeEscape = g.Cmt (U16Sequence * U16Sequence, UTF16Surrogate) + U16Sequence/UTF16BMP
          local Char = UnicodeEscape + EscapeSequence + PlainChar
          local String = P"\"" * g.Cs (Char ^ 0) * (P"\"" + Err "unterminated string")
          local Integer = P"-"^(-1) * (P"0" + (R"19" * R"09"^0))
          local Fractal = P"." * R"09"^0
          local Exponent = (S"eE") * (S"+-")^(-1) * R"09"^1
          local Number = (Integer * Fractal^(-1) * Exponent^(-1))/str2num
          local Constant = P"true" * g.Cc (true) + P"false" * g.Cc (false) + P"null" * g.Carg (1)
          local SimpleValue = Number + String + Constant
          local ArrayContent, ObjectContent
        
          local function parsearray (str, pos, nullval, state)
            local obj, cont
            local npos
            local t, nt = {}, 0
            repeat
              obj, cont, npos = pegmatch (ArrayContent, str, pos, nullval, state)
              if not npos then break end
              pos = npos
              nt = nt + 1
              t[nt] = obj
            until cont == 'last'
            return pos, setmetatable (t, state.arraymeta)
          end
        
          local function parseobject (str, pos, nullval, state)
            local obj, key, cont
            local npos
            local t = {}
            repeat
              key, obj, cont, npos = pegmatch (ObjectContent, str, pos, nullval, state)
              if not npos then break end
              pos = npos
              t[key] = obj
            until cont == 'last'
            return pos, setmetatable (t, state.objectmeta)
          end
        
          local Array = P"[" * g.Cmt (g.Carg(1) * g.Carg(2), parsearray) * Space * (P"]" + Err "']' expected")
          local Object = P"{" * g.Cmt (g.Carg(1) * g.Carg(2), parseobject) * Space * (P"}" + Err "'}' expected")
          local Value = Space * (Array + Object + SimpleValue)
          local ExpectedValue = Value + Space * Err "value expected"
          ArrayContent = Value * Space * (P"," * g.Cc'cont' + g.Cc'last') * g.Cp()
          local Pair = g.Cg (Space * String * Space * (P":" + Err "colon expected") * ExpectedValue)
          ObjectContent = Pair * Space * (P"," * g.Cc'cont' + g.Cc'last') * g.Cp()
          local DecodeValue = ExpectedValue * g.Cp ()
        
          function json.decode (str, pos, nullval, ...)
            local state = {}
            state.objectmeta, state.arraymeta = optionalmetatables(...)
            local obj, retpos = pegmatch (DecodeValue, str, pos, nullval, state)
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
          pcall (json.use_lpeg)
        end
        
        return json
    end

    local base64 = load_base64_lib()
    local json = load_json_lib()


    local toastX = GUIFeatAdd(joaat("toast_x"), "Toast X Position", eFeatureType.SliderFloat, "Adjust toast X position")
    local toastY = GUIFeatAdd(joaat("toast_y"), "Toast Y Position", eFeatureType.SliderFloat, "Adjust toast Y position")

    local function updateToastAnchors()
        local displayWidth, displayHeight = ImGui.GetDisplaySize()
        toastX:SetMinValue(0.0)
        toastX:SetMaxValue(displayWidth)
        toastY:SetMinValue(0.0)
        toastY:SetMaxValue(displayHeight)
        toastY:SetValue(displayHeight / 2)
        toastX:SetValue(25.0)
    end

    local toasts = {}
    function AddToast(title, message)
        table.insert(toasts, {
            title = title or "inx + elf Fusion",
            msg = message,
            time = os.clock(),
            duration = 5.0,
            alpha = 0.0
        })
    end

    local drawtoast = {}

    function DrawToasts()
        drawtoast.now = os.clock()
        drawtoast.screenW, drawtoast.screenH = ImGui.GetDisplaySize()


        drawtoast.padding = 10
        drawtoast.y = toastY:GetFloatValue()

        for i = #toasts, 1, -1 do
            drawtoast.toast = toasts[i]
            drawtoast.toastW, drawtoast.toastH = ImGui.CalcTextSize(drawtoast.toast.msg) + 10, 50 + 15
            drawtoast.age = drawtoast.now - drawtoast.toast.time
            drawtoast.remaining = math.max(0, drawtoast.toast.duration - drawtoast.age)
            drawtoast.progress = 1.0 - (drawtoast.remaining / drawtoast.toast.duration)

            if drawtoast.age < 0.25 then
                drawtoast.toast.alpha = math.min(1, drawtoast.age / 0.25)
            elseif drawtoast.age > drawtoast.toast.duration - 0.5 then
                drawtoast.toast.alpha = math.max(0, 1 - ((drawtoast.age - (drawtoast.toast.duration - 0.5)) / 0.5))
            else
                drawtoast.toast.alpha = 1
            end

            if drawtoast.age > drawtoast.toast.duration then
                if drawtoast.toast.alpha <= 0 then
                    table.remove(toasts, i)
                end
            else
                drawtoast.y = drawtoast.y - (drawtoast.toastH + drawtoast.padding)
                drawtoast.x = toastX:GetFloatValue()

                ImGui.SetNextWindowBgAlpha(drawtoast.toast.alpha * 0.9)
                ImGui.SetNextWindowPos(drawtoast.x, drawtoast.y)
                ImGui.SetNextWindowSize(drawtoast.toastW, drawtoast.toastH)
                ImGui.PushStyleColor(ImGuiCol.WindowBg, 0, 0, 0, 255)
                ImGui.PushStyleColor(ImGuiCol.Border, 0, 0, 0, 0)
                ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 0)
                ImGui.Begin("##toast_" .. i, true,
                    ImGuiWindowFlags.NoTitleBar |
                    ImGuiWindowFlags.NoResize |
                    ImGuiWindowFlags.AlwaysAutoResize |
                    ImGuiWindowFlags.NoMove |
                    ImGuiWindowFlags.NoScrollbar
                )
                ImGui.PopStyleVar(1)
                ImGui.PopStyleColor(2)

                ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 10)

                drawtoast.hueShift = (drawtoast.now * 0.2) % 1.0
                drawtoast.r = math.floor(255 * (0.5 + 0.5 * math.sin(drawtoast.hueShift * math.pi * 2)))
                drawtoast.g = math.floor(255 * (0.5 + 0.5 * math.sin(drawtoast.hueShift * math.pi * 2 + 2)))
                drawtoast.b = math.floor(255 * (0.5 + 0.5 * math.sin(drawtoast.hueShift * math.pi * 2 + 4)))

                ImGui.TextColored(drawtoast.r / 255, drawtoast.g / 255, drawtoast.b / 255, drawtoast.toast.alpha,
                    drawtoast.toast.title)

                drawtoast.barW = drawtoast.toastW
                drawtoast.barH = 5
                drawtoast.barX, drawtoast.barY = ImGui.GetWindowPos()
                drawtoast.barX = drawtoast.barX
                drawtoast.barY = drawtoast.barY

                drawtoast.fillW = math.floor(drawtoast.progress * drawtoast.barW)

                ImGui.AddRectFilled(drawtoast.barX, drawtoast.barY, drawtoast.barX + drawtoast.fillW,
                    drawtoast.barY + drawtoast.barH, drawtoast.r, drawtoast.g, drawtoast.b,
                    math.floor(drawtoast.toast.alpha * 255), 10)

                ImGui.AddRect(drawtoast.barX, drawtoast.barY, drawtoast.barX + drawtoast.barW,
                    drawtoast.barY + drawtoast.barH, 0, 0, 0, 0, 10)

                ImGui.Spacing()
                ImGui.TextColored(255 / 255, 255 / 255, 255 / 255, drawtoast.toast.alpha, drawtoast.toast.msg)
                ImGui.End()
            end
        end
    end

    EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
        DrawToasts()
        updateToastAnchors() 
    end)

    local function inxNoti(text)
        AddToast("Inx + Elf Fusion", text)
    end


    local function plainTextReplace(input, pattern, replacement)
        local escapedPattern = pattern:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")

        local escapedReplacement = replacement:gsub("%%", "%%%%")

        return input:gsub(escapedPattern, escapedReplacement)
    end

    previous_global_values = {}
    SetGlobalInt = function(id, value)
        previous_global_values[id] = ScriptGlobal.GetInt(id)
        ScriptGlobal.SetInt(id, value)
    end
    UndoGlobalInt = function(id)
        ScriptGlobal.SetInt(id, previous_global_values[id])
        previous_global_values[id] = nil
    end
    set_global_bool = function(id, value)
        previous_global_values[id] = ScriptGlobal.GetBool(id)
        ScriptGlobal.SetBool(id, value)
    end
    revert_global_bool = function(id)
        ScriptGlobal.SetBool(id, previous_global_values[id])
        previous_global_values[id] = nil
    end
    SetGlobalFloat = function(id, value)
        previous_global_values[id] = ScriptGlobal.GetFloat(id)
        ScriptGlobal.SetFloat(id, value) 
    end
    UndoGlobalFloat = function(id)
        ScriptGlobal.SetFloat(id, previous_global_values[id])
        previous_global_values[id] = nil
    end

    width, height = ImGui.GetDisplaySize()
    FeatAdd(joaat("CustomCrosshair"), "Custom Crosshair", eFeatureType.Toggle, "Enables the custom crosshair.")
    crosshair_size = FeatAdd(joaat("CrosshairSize"), "Crosshair Size", eFeatureType.SliderInt,
        "Controls the size of the custom crosshair."):SetMinValue(1):SetMaxValue(100):SetValue(2)

    crosshair_color = FeatAdd(joaat("CrosshairColor"), "Crosshair Color", eFeatureType.InputColor4,
        "Controls the color of the custom crosshair."):SetColor(255, 255, 255, 255)

    crosshair_shape = FeatAdd(joaat("CrosshairShape"), "Crosshair Shape", eFeatureType.Combo,
        "Controls the shape of the custom crosshair."):SetList({ "circle", "rectangle", "x shape", "+ shape",
        "upside down star shape", "star shape", "pentagram", "upside down cross" })

    crosshair_rectangle_width = FeatAdd(joaat("CrosshairRectangleWidth"), "Rectangle Crosshair Width",
    eFeatureType.InputInt, "Controls the width of the rectangle-shaped crosshair."):SetMinValue(1):SetMaxValue(2147483647)
    :SetValue(5)
    crosshair_rectangle_height = FeatAdd(joaat("CrosshairRectangleHeight"), "Rectangle Crosshair Width",
        eFeatureType.InputInt, "Controls the height of the rectangle-shaped crosshair."):SetMinValue(1):SetMaxValue(2147483647)
    :SetValue(5)
    crosshair_rectangle_rounding = FeatAdd(joaat("CrosshairRectangleRounding"), "Rectangle Rounding",
        eFeatureType.InputFloat, "Controls the rounding of the rectangle-shaped crosshair."):SetMinValue(0.0):SetMaxValue(
    math.huge):SetStepSize(0.1):SetValue(0.0)

    crosshair_line_thickness = FeatAdd(joaat("CrosshairLineThickness"), "Line Thickness", eFeatureType.InputFloat,
        "Controls the thickness of the lines for certain crosshair shapes."):SetMinValue(0.001):SetMaxValue(math.huge)
    :SetValue(2.0):SetStepSize(0.1)

    function save_crosshair()
        local s = {}
        s["size"] = crosshair_size:GetIntValue()
        local r, g, b, a = crosshair_color:GetColor()
        s["color_r"] = r
        s["color_g"] = g
        s["color_b"] = b
        s["color_a"] = a
        s["shape"] = crosshair_shape:GetListIndex()
        s["width"] = crosshair_rectangle_width:GetIntValue()
        s["height"] = crosshair_rectangle_height:GetIntValue()
        s["rounding"] = crosshair_rectangle_rounding:GetFloatValue()
        s["thickness"] = crosshair_line_thickness:GetFloatValue()

        return base64.encode(json.encode(s))
    end

    function apply_crosshair(s)
        crosshair_size:SetIntValue(s["size"])
        crosshair_color:SetColor(s["color_r"], s["color_g"], s["color_b"], s["color_a"])
        crosshair_shape:SetListIndex(s["shape"])
        crosshair_rectangle_width:SetIntValue(s["width"])
        crosshair_rectangle_height:SetIntValue(s["height"])
        crosshair_rectangle_rounding:SetFloatValue(s["rounding"])
        crosshair_line_thickness:SetFloatValue(s["thickness"])
    end

    FeatAdd(joaat("CustomCrosshairCopy"), "Copy Crosshair Code", eFeatureType.Button,
        "Copies the crosshair code to your clipboard.", function(f)
        local crosshair_code = save_crosshair()
        ---@diagnostic disable-next-line: undefined-field
        ImGui.SetClipboardText(crosshair_code)
        inxNoti("Copied crosshair code!")
    end)

    FeatAdd(joaat("CustomCrosshairApply"), "Apply Crosshair Code", eFeatureType.Button,
        "Applies the custom crosshair code you have copied.", function(f)
        ---@diagnostic disable-next-line: undefined-field
        apply_crosshair(json.decode(base64.decode(ImGui.GetClipboardText())))
        inxNoti("Applied custom crosshair settings!")
    end)

    EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
        if FeatureMgr.IsFeatureEnabled(joaat("CustomCrosshair")) then
            local r, g, b, a = crosshair_color:GetColor()
            local shape = crosshair_shape:GetListIndex()
            if shape == 0 then
                ImGui.AddCircleFilled(width / 2, height / 2, crosshair_size:GetIntValue(), r, g, b, a)
            elseif shape == 1 then
                ImGui.AddRectFilled((width / 2) - (crosshair_rectangle_width:GetIntValue() / 2),
                    (height / 2) - (crosshair_rectangle_height:GetIntValue() / 2),
                    (width / 2) + (crosshair_rectangle_width:GetIntValue() / 2),
                    (height / 2) + (crosshair_rectangle_height:GetIntValue() / 2), r, g, b, a,
                    crosshair_rectangle_rounding:GetFloatValue())
            elseif shape == 2 then
                local half_size = crosshair_size:GetIntValue() / 2
                ImGui.AddLine((width / 2) - half_size, (height / 2) - half_size,
                    (width / 2) + half_size, (height / 2) + half_size,
                    r, g, b, a, crosshair_line_thickness:GetFloatValue())
                ImGui.AddLine((width / 2) + half_size, (height / 2) - half_size,
                    (width / 2) - half_size, (height / 2) + half_size,
                    r, g, b, a, crosshair_line_thickness:GetFloatValue())
            elseif shape == 3 then
                local half_size = crosshair_size:GetIntValue() / 2
                ImGui.AddLine((width / 2) - half_size, height / 2,
                    (width / 2) + half_size, height / 2,
                    r, g, b, a, crosshair_line_thickness:GetFloatValue())
                ImGui.AddLine(width / 2, (height / 2) - half_size,
                    width / 2, (height / 2) + half_size,
                    r, g, b, a, crosshair_line_thickness:GetFloatValue())
            elseif shape == 4 then
                local size = crosshair_size:GetIntValue()
                local center_x, center_y = width / 2, height / 2
                local outer_radius = size
                local inner_radius = size * 0.4

                for i = 0, 4 do
                    local outer_angle = math.rad(90 + i * 72)
                    local inner_angle = math.rad(90 + i * 72 + 36)
                    local x1 = center_x + outer_radius * math.cos(outer_angle)
                    local y1 = center_y + outer_radius * math.sin(outer_angle)
                    local x2 = center_x + inner_radius * math.cos(inner_angle)
                    local y2 = center_y + inner_radius * math.sin(inner_angle)
                    local next_outer_angle = math.rad(90 + (i + 1) * 72)
                    local x3 = center_x + outer_radius * math.cos(next_outer_angle)
                    local y3 = center_y + outer_radius * math.sin(next_outer_angle)

                    ImGui.AddLine(x1, y1, x2, y2, r, g, b, a, crosshair_line_thickness:GetFloatValue())
                    ImGui.AddLine(x2, y2, x3, y3, r, g, b, a, crosshair_line_thickness:GetFloatValue())
                end
            elseif shape == 5 then
                local size = crosshair_size:GetIntValue()
                local center_x, center_y = width / 2, height / 2
                local outer_radius = size
                local inner_radius = size * 0.4

                for i = 0, 4 do
                    local outer_angle = math.rad(-90 + i * 72)
                    local inner_angle = math.rad(-90 + i * 72 + 36)
                    local x1 = center_x + outer_radius * math.cos(outer_angle)
                    local y1 = center_y + outer_radius * math.sin(outer_angle)
                    local x2 = center_x + inner_radius * math.cos(inner_angle)
                    local y2 = center_y + inner_radius * math.sin(inner_angle)
                    local next_outer_angle = math.rad(-90 + (i + 1) * 72)
                    local x3 = center_x + outer_radius * math.cos(next_outer_angle)
                    local y3 = center_y + outer_radius * math.sin(next_outer_angle)

                    ImGui.AddLine(x1, y1, x2, y2, r, g, b, a, crosshair_line_thickness:GetFloatValue())
                    ImGui.AddLine(x2, y2, x3, y3, r, g, b, a, crosshair_line_thickness:GetFloatValue())
                end
            elseif shape == 6 then
                local size = crosshair_size:GetIntValue()
                local center_x, center_y = width / 2, height / 2
                local outer_radius = size
                local inner_radius = size * 0.4

                ImGui.AddCircle(center_x, center_y, outer_radius, r, g, b, a, 100, crosshair_line_thickness:GetFloatValue())

                local points = {}
                for i = 0, 4 do
                    local outer_angle = math.rad(90 + i * 72)
                    local x1 = center_x + outer_radius * math.cos(outer_angle)
                    local y1 = center_y + outer_radius * math.sin(outer_angle)
                    points[i + 1] = { x = x1, y = y1 }

                    local inner_angle = math.rad(90 + i * 72 + 36)
                    local x2 = center_x + inner_radius * math.cos(inner_angle)
                    local y2 = center_y + inner_radius * math.sin(inner_angle)
                    points[i + 6] = { x = x2, y = y2 }
                end

                ImGui.AddLine(points[1].x, points[1].y, points[3].x, points[3].y, r, g, b, a,
                    crosshair_line_thickness:GetFloatValue())
                ImGui.AddLine(points[1].x, points[1].y, points[4].x, points[4].y, r, g, b, a,
                    crosshair_line_thickness:GetFloatValue())
                ImGui.AddLine(points[2].x, points[2].y, points[4].x, points[4].y, r, g, b, a,
                    crosshair_line_thickness:GetFloatValue())
                ImGui.AddLine(points[2].x, points[2].y, points[5].x, points[5].y, r, g, b, a,
                    crosshair_line_thickness:GetFloatValue())
                ImGui.AddLine(points[3].x, points[3].y, points[5].x, points[5].y, r, g, b, a,
                    crosshair_line_thickness:GetFloatValue())
            elseif shape == 7 then
                local size = crosshair_size:GetIntValue()
                local center_x, center_y = width / 2, height / 2
                local vertical_length = size * 2.0
                local horizontal_length = size * 1.5
                local thickness = crosshair_line_thickness:GetFloatValue()

                ImGui.AddRectFilled(
                    center_x - thickness / 2,
                    center_y - vertical_length / 2,
                    center_x + thickness / 2,
                    center_y + vertical_length / 2,
                    r, g, b, a
                )

                ImGui.AddRectFilled(
                    center_x - horizontal_length / 2,
                    center_y + vertical_length / 3.5 - thickness / 2, 
                    center_x + horizontal_length / 2,
                    center_y + vertical_length / 3.5 + thickness / 2,
                    r, g, b, a
                )
            end
        end
    end)

    Script.RegisterLooped(function()
        if FeatureMgr.IsFeatureEnabled(joaat("CustomCrosshair")) then
            Script.QueueJob(function() HUD.HIDE_HUD_COMPONENT_THIS_FRAME(14) end)
        end
    end)


    tp_feats = {}

    function add_tp(hash, name, x, y, z, heading)
        table.insert(tp_feats, hash)
        FeatAdd(joaat(hash), name, eFeatureType.Button, "", function()
            PLAYER.START_PLAYER_TELEPORT(PLAYER.PLAYER_ID(), x, y, z, heading, true, false, true)
        end)
    end

    add_tp("VINEWOODGARAGE", "Vinewood Garage", 182.97068786621094, -1158.740234375, 29.445926666259766, 207.99546813964844)

    FeatAdd(joaat("BetterTpToWaypoint"), "Better Teleport to Waypoint", eFeatureType.Button, "Teleports you to your waypoint",
        function()
            local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
            local coords = HUD.GET_BLIP_COORDS(blip)
            STREAMING.SET_FOCUS_POS_AND_VEL(coords.x, coords.y, coords.z, 0, 0, 0)
            Script.Yield(1000)
            ---@diagnostic disable-next-line: undefined-field
            local _, z = GTA.GetGroundZ(coords.x, coords.y)
            if PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), true) then
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true), coords.x,
                    coords.y, z, true, true, true)
            else
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), coords.x, coords.y + 10, z, true, true, true)
            end
            STREAMING.CLEAR_FOCUS()

            inxNoti("Better-Teleported to waypoint!")
        end)

    FeatAdd(joaat("Spawn Random Saved Vehicle"), "Spawn Random Saved Vehicle", eFeatureType.Button,
        "Spawns a random saved .json vehicle from Cherax/Vehicles", function(f)
        local feature = FeatureMgr.GetFeature(514776905)
        local spawn_feature = FeatureMgr.GetFeature(521937511)

        feature:SetListIndex(math.random(#feature:GetList()) - 1)
        spawn_feature:TriggerCallback()

        inxNoti("Spawned random saved vehicle!")
    end)

    FeatureMgr.AddFeature(
        Utils.Joaat("print hovered feature info"),
        "print hovered feature info",
        eFeatureType.Button,
        "",
        function(f)
            local feature = FeatureMgr.GetHoveredFeature()
            if feature and feature ~= nil then
                Logger.LogInfo(("Feature name is %s, Hash = %s"):format(feature:GetName(), feature:GetHash()))
            else
                Logger.LogInfo("No feature is currently hovered.")
            end
        end
    )


    FeatAdd(joaat("ForgeModelName"), "Spoofed name", eFeatureType.InputText, "Name of the model to spoof the vehicle")
    :SetStringValue("adder")

    local previous_model_info = 0
    local previous_model_hash = 0

    FeatAdd(joaat("ForgeModelSpoof"), "Spoof Vehicle", eFeatureType.Button, "Spoof vehicle with given model", function(f)
        local spoof_name = FeatureMgr.GetFeatureString(joaat("ForgeModelName"))
        local spoof_hash = joaat(spoof_name)

        local localpid = GTA.GetLocalPlayerId()


        local cveh = Players.GetCPed(localpid).CurVehicle
        local info = CVehicleModelInfo.FromBaseModelInfo(cveh.ModelInfo)

        previous_model_info = cveh.ModelInfo
        previous_model_hash = info.Model

        info.Model = spoof_hash

        inxNoti("Vehicle spoofed as " .. spoof_name)
    end)

    FeatAdd(joaat("ForgeModelUnspoof"), "Unspoof Vehicle", eFeatureType.Button, "Revert spoof", function(f)
        local ped = PLAYER.PLAYER_PED_ID()
        if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            inxNoti("You are not in a vehicle!")
            return
        end

        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if veh == 0 then return end

        local cveh = Players.GetCPed(ped).CurVehicle
        local info = CVehicleModelInfo.FromBaseModelInfo(cveh.ModelInfo)

        if previous_model_info ~= 0 then
            info.Model = previous_model_hash
        end

        inxNoti("Vehicle spoof reverted!")
    end)


    function get_character_slot()
        local _, slot = Stats.GetInt(joaat("MPPLY_LAST_MP_CHAR"))
        return slot
    end

    FeatAdd(joaat("UnlockChameleonPaints"), "Unlock Chameleon Paints", eFeatureType.Button,
        "Unlocks all chameleon paints from GTA+", function(f)
        local stat_names = {
            "MPPLY_XMASLIVERIES0", "MPPLY_XMASLIVERIES1", "MPPLY_XMASLIVERIES2",
            "MPPLY_XMASLIVERIES3", "MPPLY_XMASLIVERIES4", "MPPLY_XMASLIVERIES5",
            "MPPLY_XMASLIVERIES6", "MPPLY_XMASLIVERIES7", "MPPLY_XMASLIVERIES8",
            "MPPLY_XMASLIVERIES9", "MPPLY_XMASLIVERIES10", "MPPLY_XMASLIVERIES11",
            "MPPLY_XMASLIVERIES12", "MPPLY_XMASLIVERIES13", "MPPLY_XMASLIVERIES14",
            "MPPLY_XMASLIVERIES15", "MPPLY_XMASLIVERIES16",
            "MPPLY_XMAS22CPAINT0", "MPPLY_XMAS22CPAINT1",
            "MPPLY_SUM23WHEELCPAINT0", "MPPLY_SUM23WHEELCPAINT1"
        }

        for _, statName in ipairs(stat_names) do
            STATS.STAT_SET_INT(MISC.GET_HASH_KEY(statName), -1, true)
        end

        inxNoti("Unlocked Chameleon Paints!")
    end)

    FeatAdd(joaat("OpenStatsWebsite"), "Copy Stats List URL", eFeatureType.Button,
        "Copies the link to a website which contains a list of stats.", function(f)
        ---@diagnostic disable-next-line: undefined-field
        ImGui.SetClipboardText("https://gist.githubusercontent.com/1337Nexo/945fe9724b9dd20d33e7afeabd2746dc/raw/46af3968b55677688a1bc98798adcd174e72e48d/stats.txt")
        inxNoti("Copied link! Open it in your browser.")
    end)

    FeatAdd(joaat("StatType"), "Stat Type", eFeatureType.Combo, "Stat Type"):SetList({ "int", "float", "bool", "string",
        "packed bool (single)" })

    FeatAdd(joaat("StatValueInt"), "Int value:", eFeatureType.InputInt, "Int value"):SetIntValue(-1):SetMinValue(-2147483647)
        :SetMaxValue(2147483647)
    FeatAdd(joaat("StatValueBool"), "", eFeatureType.Toggle, "Bool value"):SetBoolValue(false)
    FeatAdd(joaat("StatValueFloat"), "Float value:", eFeatureType.InputFloat, "Float value"):SetFloatValue(420.69)
        :SetMinValue(-math.huge):SetMaxValue(math.huge)
    FeatAdd(joaat("StatValueString"), "", eFeatureType.InputText, "String value"):SetValue("Example string")

    FeatAdd(joaat("StatName"), "", eFeatureType.InputText, "name of the stat to edit"):SetValue("MP0_KILLS")

    FeatAdd(joaat("SetStatInt"), "Set Int Stat", eFeatureType.Button, "Sets the int stat", function(f)
        STATS.STAT_SET_INT(MISC.GET_HASH_KEY(FeatureMgr.GetFeatureString(joaat("StatName"))),
            FeatureMgr.GetFeatureInt(joaat("StatValueInt")), true)
        inxNoti("Integer stat set!")
    end)

    FeatAdd(joaat("SetStatBool"), "Set Bool Stat", eFeatureType.Button, "Sets the bool stat", function(f)
        STATS.STAT_SET_BOOL(MISC.GET_HASH_KEY(FeatureMgr.GetFeatureString(joaat("StatName"))),
            FeatureMgr.IsFeatureEnabled(joaat("StatValueBool")), true)
        inxNoti("Boolean stat set!")
    end)

    FeatAdd(joaat("SetStatFloat"), "Set Float Stat", eFeatureType.Button, "Sets the float stat", function(f)
        STATS.STAT_SET_FLOAT(MISC.GET_HASH_KEY(FeatureMgr.GetFeatureString(joaat("StatName"))),
            FeatureMgr.GetFeatureFloat(joaat("StatValueFloat")), true)
        inxNoti("Float stat set!")
    end)

    FeatAdd(joaat("SetStatString"), "Set String/Text Stat", eFeatureType.Button, "Sets the string stat", function(f)
        STATS.STAT_SET_STRING(MISC.GET_HASH_KEY(FeatureMgr.GetFeatureString(joaat("StatName"))),
            FeatureMgr.GetFeatureString(joaat("StatValueString")), true)
        inxNoti("String stat set!")
    end)

    FeatAdd(joaat("PackedBoolSingleIndex"), "Packed Bool Index", eFeatureType.InputInt, "Index of the packed bool")
        :SetMinValue(-2147483647):SetMaxValue(2147483647)

    FeatAdd(joaat("PackedBoolSingleValue"), "Value (checked is true)", eFeatureType.Toggle,
        "Value of the packed bool you want to edit")

    FeatAdd(joaat("SetPackedBoolStatSingle"), "Set Packed Bool", eFeatureType.Button,
        "Sets the selected packed bool stat to the specified value.", function(f)
        STATS.SET_PACKED_STAT_BOOL_CODE(FeatureMgr.GetFeatureInt(joaat("PackedBoolSingleIndex")),
            FeatureMgr.IsFeatureEnabled(joaat("PackedBoolSingleValue")), get_character_slot())
        inxNoti("Packed boolean stat set!")
    end)

    FeatAdd(joaat("PackedIntIndex"), "Packed Int Index", eFeatureType.InputInt, "Index of the packed int"):SetMinValue(-2147483647)
        :SetMaxValue(2147483647)

    FeatAdd(joaat("PackedIntValue"), "Value", eFeatureType.InputInt, "Value of the packed int you want to edit"):SetMinValue(-2147483647)
        :SetMaxValue(2147483647)

    FeatAdd(joaat("SetPackedInt"), "Set Packed Int", eFeatureType.Button,
        "Sets the selected packed int stat to the specified value.", function(f)
        STATS.SET_PACKED_STAT_INT_CODE(FeatureMgr.GetFeatureInt(joaat("PackedIntIndex")),
            FeatureMgr.GetFeatureInt(joaat("PackedIntValue")), get_character_slot())
        inxNoti("Packed integer stat set!")
    end)

    FeatAdd(joaat("PackedBoolRangeValue"), "Value (checked is true)", eFeatureType.Toggle, "Value for the ranged packed bool")

    FeatAdd(joaat("PackedBoolRangeIndexStart"), "Packed Bool Start Index", eFeatureType.InputInt,
        "Start index of the ranged packed bool"):SetMinValue(-2147483647):SetMaxValue(2147483647)
    FeatAdd(joaat("PackedBoolRangeIndexEnd"), "Packed Bool End Index", eFeatureType.InputInt,
        "End index of the ranged packed bool"):SetMinValue(-2147483647):SetMaxValue(2147483647)

    FeatAdd(joaat("SetPackedBoolStatRange"), "Set Packed Bool Range", eFeatureType.Button,
        "Sets the selected packed bool range from start to end, to the specified value.", function(f)

        for i = FeatureMgr.GetFeatureInt(joaat("PackedBoolRangeIndexStart")), FeatureMgr.GetFeatureInt(joaat("PackedBoolRangeIndexEnd")), 1 do
            STATS.SET_PACKED_STAT_BOOL_CODE(i, FeatureMgr.IsFeatureEnabled(joaat("PackedBoolRangeValue")),
                get_character_slot())
        end
        inxNoti("Packed boolean range set!")
    end)

    FeatAdd(joaat("StatLimitBypassStatName"), "Stat name", eFeatureType.InputText, "Stat name"):SetValue(
    "MP0_TOTAL_PLAYING_TIME")

    FeatAdd(joaat("StatLimitBypassValue"), "Value", eFeatureType.InputText, "Value for the selected stat", function(f)
        local value = f:GetStringValue()
        local numeric = value:gsub("[^0-9]", "")
        f:SetValue(numeric)
    end):SetValue("86400000000")

    FeatAdd(joaat("StatLimitSetStat"), "Set Stat", eFeatureType.Button,
        "Uses increments to set the stat, bypassing the 32 bit integer limit.", function(f)
        local stat_name = FeatureMgr.GetFeatureString(joaat("StatLimitBypassStatName"))
        local value = tonumber(FeatureMgr.GetFeatureString(joaat("StatLimitBypassValue")))
        if value == nil then return end

        if math.abs(value) <= 2147483647 then
            inxNoti(
            "The selected value falls inside the 32 bit integer limit. There's no point using this, you should use the regular stat editor.")
            return
        end

        local loop_amount = math.floor(math.abs(value) / 2147483647)
        local remainder = math.abs(value) - (loop_amount * 2147483647)

        local negative = nil
        if value < 0 then
            negative = -1
        else
            negative = 1
        end

        STATS.STAT_SET_INT(joaat(stat_name), 0, true)
        for i = 1, loop_amount, 1 do
            STATS.STAT_INCREMENT(joaat(stat_name), negative * 2147483647)
        end
        STATS.STAT_INCREMENT(joaat(stat_name), negative * remainder)

        inxNoti("Stat incremented succesfully! It looped " ..
        loop_amount ..
        " times.\nKeep in mind that reading the stat might not work properly now, as it is outside the 32 bit integer limit!")
    end)

    function get_string_stat(hash)
        return true, STATS.STAT_GET_STRING(hash, -1)
    end

    previous_read_stat = nil
    previous_read_stat_value = nil
    previous_read_stat_type = nil

    function read_stat(index)
        local func

        if index == 0 then
            func = Stats.GetInt
        elseif index == 1 then
            func = Stats.GetFloat
        elseif index == 2 then
            func = Stats.GetBool
        elseif index == 3 then
            func = get_string_stat
        end

        local stat_hash = joaat(FeatureMgr.GetFeatureString(joaat("StatName")))
        if previous_read_stat ~= nil and previous_read_stat_type ~= nil and previous_read_stat == stat_hash and previous_read_stat_type == index then
            return previous_read_stat_value
        else
            previous_read_stat = stat_hash
            previous_read_stat_type = index
        end

        local success, value = func(stat_hash)
        if success then
            previous_read_stat_value = value
            return tostring(value)
        end
        previous_read_stat_value = "FAILED TO READ"
        return "FAILED TO READ"
    end

    hasher_output = nil
    FeatAdd(joaat("HasherInput"), "String to hash", eFeatureType.InputText, "String to hash using the JOAAT algorithm.",
        function(f)
            local input = f:GetStringValue()
            GradientLogger(input)
            if input == "" then
                hasher_output = nil
                return
            end
            hasher_output = joaat(input)
        end)

    FeatAdd(joaat("HasherCopy"), "Copy hash to clipboard", eFeatureType.Button,
        "Copies the hasher output to your system clipboard.", function(f)
        if hasher_output == nil then
            inxNoti("Please type something in the 'String to hash' box first!")
            return
        end
        ---@diagnostic disable-next-line: undefined-field
        ImGui.SetClipboardText(tostring(hasher_output), "")
    end)

    FeatAdd(joaat("GlobalEditorInput"), "Global to edit", eFeatureType.InputInt, "The global you want to change the value of")
        :SetMinValue(-2147483647):SetMaxValue(2147483647)

    FeatAdd(joaat("GlobalEditorType"), "Type", eFeatureType.Combo, "Type of the global"):SetList({ "int", "bool", "float",
        "string" })

    FeatAdd(joaat("GlobalEditorValueInt"), "Int value", eFeatureType.InputInt, "Integer value of the global"):SetMinValue(-2147483647)
        :SetMaxValue(2147483647)
    FeatAdd(joaat("GlobalEditorValueBool"), "", eFeatureType.Toggle, "Bool value of the global"):SetBoolValue(false)
    FeatAdd(joaat("GlobalEditorValueFloat"), "Float value:", eFeatureType.InputFloat, "Float value of the global")
        :SetMinValue(-math.huge):SetMaxValue(math.huge)
    FeatAdd(joaat("GlobalEditorValueString"), "", eFeatureType.InputText, "String value of the global")

    FeatAdd(joaat("GlobalEditorSet"), "Set Global", eFeatureType.Button, "Sets the global to the specified value",
        function(f)
            local global = FeatureMgr.GetFeatureInt(joaat("GlobalEditorInput"))
            local type = FeatureMgr.GetFeatureListIndex(joaat("GlobalEditorType"))
            if type == 0 then
                ScriptGlobal.SetInt(global, FeatureMgr.GetFeatureInt(joaat("GlobalEditorValueInt")))
            elseif type == 1 then
                ScriptGlobal.SetBool(global, FeatureMgr.IsFeatureEnabled(joaat("GlobalEditorValueBool")))
            elseif type == 2 then
                ScriptGlobal.SetFloat(global, FeatureMgr.GetFeatureFloat(joaat("GlobalEditorValueFloat")))
            elseif type == 3 then
                ScriptGlobal.SetString(global, FeatureMgr.GetFeatureString(joaat("GlobalEditorValueString")))
            end

            inxNoti("Global set!")
        end)

    function RGBtoHSV(r, g, b)
        r, g, b = r / 255, g / 255, b / 255

        local max = math.max(r, g, b)
        local min = math.min(r, g, b)
        local delta = max - min

        local h, s, v

        if delta == 0 then
            h = 0
        elseif max == r then
            h = (60 * ((g - b) / delta) + 360) % 360
        elseif max == g then
            h = (60 * ((b - r) / delta) + 120) % 360
        elseif max == b then
            h = (60 * ((r - g) / delta) + 240) % 360
        end
        
        if max == 0 then
            s = 0
        else
            s = delta / max
        end

        v = max

        h = math.floor((h / 360) * 255)
        s = math.floor(s * 255)
        v = math.floor(v * 255)

        return h, s, v
    end

    function HSVtoRGB(h, s, v)
        h, s, v = h / 255, s / 255, v / 255

        local r, g, b

        if s == 0 then
            r, g, b = v, v, v
        else
            local sector = math.floor(h * 6)
            local f = h * 6 - sector
            local p = v * (1 - s)
            local q = v * (1 - f * s)
            local t = v * (1 - (1 - f) * s)

            if sector == 0 then
                r, g, b = v, t, p
            elseif sector == 1 then
                r, g, b = q, v, p
            elseif sector == 2 then
                r, g, b = p, v, t
            elseif sector == 3 then
                r, g, b = p, q, v
            elseif sector == 4 then
                r, g, b = t, p, v
            elseif sector == 5 then
                r, g, b = v, p, q
            end
        end

        r = math.floor(r * 255)
        g = math.floor(g * 255)
        b = math.floor(b * 255)


        return r, g, b
    end

    speed = FeatAdd(joaat("BreathingNeonSlider"), "Speed", eFeatureType.SliderInt):SetMaxValue(20):SetMinValue(1)
    :SetValue(3)

    colorfeat = FeatureMgr.GetFeature(2505178166)
    currentAlpha = 0
    down = false
    FeatAdd(joaat("BreathingNeon"), "Breathing Neon Kit", eFeatureType.Toggle, "Toggles the breathing neon kit effect.",
        function(feat) 
            while feat:IsToggled() do
                if colorfeat then 
                    if down then
                        currentAlpha = currentAlpha - speed:GetIntValue()
                    else
                        currentAlpha = currentAlpha + speed:GetIntValue()
                    end

                    if currentAlpha >= 254 and not down then
                        currentAlpha = 254
                        down = true
                    elseif currentAlpha <= 1 and down then
                        currentAlpha = 1
                        down = false
                    end



                    local r, g, b = colorfeat:GetColor()
                    local h, s, v = RGBtoHSV(r, g, b)

                    local nr, ng, nb = HSVtoRGB(h, s, currentAlpha)
                    ---@diagnostic disable-next-line: missing-parameter
                    colorfeat:SetColor(nr, ng, nb)
                    colorfeat:TriggerCallback()


                    Script.Yield()
                else
                    inxNoti("Cherax's color feature is nil, maybe you are not in a vehicle\nif you are and this is still showing report it in the elf script discord")
                    feat:Reset()
                    return
                end
            end
        end, true)

    vehicle_config_dir = menuRootPath .. "\\VehicleConfigs"
    FileMgr.CreateDir(vehicle_config_dir)

    FeatAdd(joaat("Saved Vehicle Configs"), "Saved Vehicle Configs", eFeatureType.Combo, "Select a saved vehicle config")

    function update_vehicle_configs()
        local files = FileMgr.FindFiles(vehicle_config_dir, ".txt", false) or {}
        local parsed_files = {}
        for _, file in ipairs(files) do
            table.insert(parsed_files, (plainTextReplace(plainTextReplace(file, vehicle_config_dir .. "\\", ""), ".txt", "")))
        end
        FeatureMgr.GetFeature(joaat("Saved Vehicle Configs")):SetList(parsed_files)
    end

    update_vehicle_configs()

    FeatAdd(joaat("Config Name"), "Config name", eFeatureType.InputText, "Name for the config you want to save")

    FeatAdd(joaat("Save Vehicle Config"), "Save Vehicle Config", eFeatureType.Button,
        "Saves the modification on the current vehicle, for applying them to other cars later.", function(f)
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        if vehicle == 0 then
            inxNoti("You're not inside a vehicle!")
            return
        end

        local primary_color = Memory.AllocInt()
        local secondary_color = Memory.AllocInt()
        local pearlescent_color = Memory.AllocInt()
        local wheel_color = Memory.AllocInt()

        local neon_r = Memory.AllocInt()
        local neon_g = Memory.AllocInt()
        local neon_b = Memory.AllocInt()
        local tyre_r = Memory.AllocInt()
        local tyre_g = Memory.AllocInt()
        local tyre_b = Memory.AllocInt()

        VEHICLE.GET_VEHICLE_COLOURS(vehicle, primary_color, secondary_color)
        VEHICLE.GET_VEHICLE_EXTRA_COLOURS(vehicle, pearlescent_color, wheel_color)
        VEHICLE.GET_VEHICLE_NEON_COLOUR(vehicle, neon_r, neon_g, neon_b)
        VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, tyre_r, tyre_g, tyre_b)

        local function bool_to_number(v)
            return v and 1 or 0
        end

        local config = string.format(
            "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%s\n%d\n%d\n%d\n%d\n%d",
            VEHICLE.GET_VEHICLE_WHEEL_TYPE(vehicle),
            VEHICLE.GET_VEHICLE_MOD(vehicle, 23),
            VEHICLE.GET_VEHICLE_WINDOW_TINT(vehicle),
            Memory.ReadInt(primary_color),
            Memory.ReadInt(secondary_color),
            Memory.ReadInt(pearlescent_color),
            Memory.ReadInt(wheel_color),
            bool_to_number(VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 0)),
            bool_to_number(VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 1)),
            bool_to_number(VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 2)),
            bool_to_number(VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 3)),
            Memory.ReadInt(neon_r),
            Memory.ReadInt(neon_g),
            Memory.ReadInt(neon_b),
            VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle),
            tonumber(VEHICLE.GET_VEHICLE_MOD(vehicle, 22)),
            VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle),
            tostring(VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(vehicle)),
            Memory.ReadInt(tyre_r),
            Memory.ReadInt(tyre_g),
            Memory.ReadInt(tyre_b),
            bool_to_number(VEHICLE.IS_TOGGLE_MOD_ON(vehicle, 20)),
            tonumber(VEHICLE.GET_VEHICLE_MOD(vehicle, 14))
        )

        Memory.Free(primary_color)
        Memory.Free(secondary_color)
        Memory.Free(pearlescent_color)
        Memory.Free(wheel_color)
        Memory.Free(neon_r)
        Memory.Free(neon_g)
        Memory.Free(neon_b)
        Memory.Free(tyre_r)
        Memory.Free(tyre_g)
        Memory.Free(tyre_b)

        local filename = FeatureMgr.GetFeatureString(joaat("Config Name"))
        if filename == "" then
            inxNoti("You need to type a valid config name!")
            return
        end

        local path = vehicle_config_dir .. "\\" .. filename .. ".txt"
        FileMgr.WriteFileContent(path, config, false)
        inxNoti("Saved vehicle config as " .. filename .. ".txt!")
        update_vehicle_configs()
    end)

    FeatAdd(joaat("Refresh Vehicle Configs"), "Refresh Files", eFeatureType.Button, "Refreshes the vehicle configs",
        function(f)
            update_vehicle_configs()
            inxNoti("Vehicle configs refreshed!")
        end)

    FeatAdd(joaat("VehicleConfigSpawnUpgraded"), "Apply Performance Upgrades", eFeatureType.Toggle,
        "If enabled, the vehicle will have performance upgrades applied as well.", function(f)
        if FeatureMgr.IsFeatureEnabled(joaat("VehicleFullyUpgraded")) then
            FeatureMgr.GetFeature(joaat("VehicleFullyUpgraded")):SetBoolValue(false)
        end
    end):Toggle(true)

    FeatAdd(joaat("VehicleFullyUpgraded"), "Apply Full Upgrade", eFeatureType.Toggle,
        "If enabled, the vehicle will have everything upgraded.", function(f)
        if FeatureMgr.IsFeatureEnabled(joaat("VehicleConfigSpawnUpgraded")) then
            FeatureMgr.GetFeature(joaat("VehicleConfigSpawnUpgraded")):SetBoolValue(false)
        end
    end):Toggle(false)

    FeatAdd(joaat("Apply Vehicle Config"), "Load Vehicle Config", eFeatureType.Button,
        "Applies your selected vehicle config to the car you're inside of.", function(f)
        if #FeatureMgr.GetFeatureList(joaat("Saved Vehicle Configs")) == 0 then
            inxNoti("No saved vehicles found.")
            return
        end

        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        if vehicle == 0 then
            inxNoti("You're not inside a vehicle!")
            return
        end

        local file = FeatureMgr.GetFeatureList(joaat("Saved Vehicle Configs"))
        [FeatureMgr.GetFeature(joaat("Saved Vehicle Configs")):GetListIndex() + 1]

        file = vehicle_config_dir .. "\\" .. file .. ".txt"

        local file_content = FileMgr.ReadFileContent(file)
        local values = {}
        for line in file_content:gmatch("[^\r\n]+") do
            table.insert(values, line)
        end

        local function upgrade_vehicle_mod(vehicle, mod)
            VEHICLE.SET_VEHICLE_MOD(vehicle, mod, VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, mod) - 1, false)
        end

        VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)

        if FeatureMgr.IsFeatureEnabled(joaat("VehicleFullyUpgraded")) then
            for i = 0, 49, 1 do
                upgrade_vehicle_mod(vehicle, i)
            end
            VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, false) -- bulletproof tyres
        end

        if FeatureMgr.IsFeatureEnabled(joaat("VehicleConfigSpawnUpgraded")) then
            upgrade_vehicle_mod(vehicle, 11)                    -- engine
            upgrade_vehicle_mod(vehicle, 12)                    -- brakes
            upgrade_vehicle_mod(vehicle, 13)                    -- transmission
            upgrade_vehicle_mod(vehicle, 15)                    -- suspension
            upgrade_vehicle_mod(vehicle, 16)                    -- armor
            upgrade_vehicle_mod(vehicle, 18)                    -- turbo/hsw
            upgrade_vehicle_mod(vehicle, 36)                    -- for hsw cars this is the HSW performance upgrade

            VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, false) -- bulletproof tyres
        end

        --     VEHICLE.GET_VEHICLE_WHEEL_TYPE(vehicle),
        --     VEHICLE.GET_VEHICLE_MOD(vehicle, 23),
        --     VEHICLE.GET_VEHICLE_WINDOW_TINT(vehicle),
        --     Memory.ReadInt(primary_color),
        --     Memory.ReadInt(secondary_color),
        --     Memory.ReadInt(pearlescent_color),
        --     Memory.ReadInt(wheel_color),
        --     VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 0),
        --     VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 1),
        --     VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 2),
        --     VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 3),
        --     Memory.ReadInt(neon_r),
        --     Memory.ReadInt(neon_g),
        --     Memory.ReadInt(neon_b),
        --     VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle),
        --     VEHICLE.IS_TOGGLE_MOD_ON(vehicle, 22),
        --     VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle),
        --     tostring(VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(vehicle))

        VEHICLE.SET_VEHICLE_WHEEL_TYPE(vehicle, tonumber(values[1]))
        VEHICLE.SET_VEHICLE_MOD(vehicle, 23, tonumber(values[2]), false)
        VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, tonumber(values[3]))
        VEHICLE.SET_VEHICLE_COLOURS(vehicle, tonumber(values[4]), tonumber(values[5]))
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(vehicle, tonumber(values[6]), tonumber(values[7]))
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, 0, tonumber(values[8]))
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, 1, tonumber(values[9]))
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, 2, tonumber(values[10]))
        VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, 3, tonumber(values[11]))
        VEHICLE.SET_VEHICLE_NEON_COLOUR(vehicle, tonumber(values[12]), tonumber(values[13]), tonumber(values[14]))
        VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle, tonumber(values[15]))
        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 22, tonumber(values[16]))
        VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle, tonumber(values[17]))
        VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, values[18])
        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 20, tonumber(values[22]) == 1 and true or false)
        VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, tonumber(values[19]), tonumber(values[20]), tonumber(values[21]))
        VEHICLE.SET_VEHICLE_MOD(vehicle, 14, tonumber(values[23]), false)

        inxNoti("Applied selected vehicle config!")
    end)

    function get_closest_vehicle()
        local player_coords = V3.New(ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true))
        local vehicletofind = VEHICLE.GET_CLOSEST_VEHICLE(player_coords.x, player_coords.y, player_coords.z, 1000, 0, 70)
        local vehicleCoords = V3.New(ENTITY.GET_ENTITY_COORDS(vehicletofind, true))
        if vehicle_coords > 1000 - player_coords then 
            inxNoti("failed to find a vehicle, be within 1000 feet of a vehicle")
            return
        end
        return vehicletofind 
    end

    copied_vehicle = nil

    ---@param vehicle integer
    function extract_vehicle_settings(vehicle)
        local s = {}
        s["model"] = ENTITY.GET_ENTITY_MODEL(vehicle)
        local a = {
            primary_color = Memory.AllocInt(),
            secondary_color = Memory.AllocInt(),
            pearlescent_color = Memory.AllocInt(),
            wheel_color = Memory.AllocInt(),
            tyre_smoke_r = Memory.AllocInt(),
            tyre_smoke_g = Memory.AllocInt(),
            tyre_smoke_b = Memory.AllocInt(),
            neon_r = Memory.AllocInt(),
            neon_g = Memory.AllocInt(),
            neon_b = Memory.AllocInt()
        }
        VEHICLE.GET_VEHICLE_COLOURS(vehicle, a.primary_color, a.secondary_color)
        s["primary_color"] = Memory.ReadInt(a.primary_color)
        s["secondary_color"] = Memory.ReadInt(a.secondary_color)
        VEHICLE.GET_VEHICLE_EXTRA_COLOURS(vehicle, a.pearlescent_color, a.wheel_color)
        s["pearlescent_color"] = Memory.ReadInt(a.pearlescent_color)
        s["wheel_color"] = Memory.ReadInt(a.wheel_color)
        VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, a.tyre_smoke_r, a.tyre_smoke_g, a.tyre_smoke_b)
        s["tyre_smoke_r"] = Memory.ReadInt(a.tyre_smoke_r)
        s["tyre_smoke_g"] = Memory.ReadInt(a.tyre_smoke_g)
        s["tyre_smoke_b"] = Memory.ReadInt(a.tyre_smoke_b)
        VEHICLE.GET_VEHICLE_NEON_COLOUR(vehicle, a.neon_r, a.neon_g, a.neon_b)
        s["neon_r"] = Memory.ReadInt(a.neon_r)
        s["neon_g"] = Memory.ReadInt(a.neon_g)
        s["neon_b"] = Memory.ReadInt(a.neon_b)
        s["neon_left"] = VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 0)
        s["neon_front"] = VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 1)
        s["neon_right"] = VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 2)
        s["neon_back"] = VEHICLE.GET_VEHICLE_NEON_ENABLED(vehicle, 3)

        s["plate_text"] = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(vehicle)
        s["plate_index"] = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle)
        s["window_tint"] = VEHICLE.GET_VEHICLE_WINDOW_TINT(vehicle)
        s["livery"] = VEHICLE.GET_VEHICLE_LIVERY(vehicle)
        s["headlights"] = VEHICLE.IS_TOGGLE_MOD_ON(vehicle, 22)
        s["headlight_index"] = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle)
        s["has_tyre_smoke"] = VEHICLE.IS_TOGGLE_MOD_ON(vehicle, 20)

        s["extras"] = {}
        for i = 0, 12, 1 do
            if VEHICLE.DOES_EXTRA_EXIST(vehicle, i) then
                s["extras"][tostring(i)] = not VEHICLE.IS_VEHICLE_EXTRA_TURNED_ON(vehicle, i)
            end
        end

        local mods = {}
        for i = 0, 49, 1 do
            mods[tostring(i)] = (VEHICLE.GET_VEHICLE_MOD(vehicle, i))
        end
        s["mods"] = mods

        s["wheel_type"] = VEHICLE.GET_VEHICLE_WHEEL_TYPE(vehicle)

        for _, addr in ipairs(a) do
            Memory.Free(addr)
        end

        return s
    end

    function spawn_vehicle_from_settings(s)
        local v = GTA.SpawnVehicleForPlayer(s["model"], PLAYER.PLAYER_ID())
        VEHICLE.SET_VEHICLE_MOD_KIT(v, 0)

        VEHICLE.SET_VEHICLE_WHEEL_TYPE(v, s["wheel_type"])

        for i = 0, 49, 1 do
            VEHICLE.SET_VEHICLE_MOD(v, i, s["mods"][tostring(i)], false)
        end

        if s["extras"] ~= nil then
            for key, value in pairs(s["extras"]) do
                
                VEHICLE.SET_VEHICLE_EXTRA(v, tonumber(key), value)
            end
        end

        VEHICLE.SET_VEHICLE_COLOURS(v, s["primary_color"], s["secondary_color"])
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(v, s["pearlescent_color"], s["wheel_color"])
        VEHICLE.SET_VEHICLE_NEON_COLOUR(v, s["neon_r"], s["neon_g"], s["neon_b"])
        VEHICLE.SET_VEHICLE_NEON_ENABLED(v, 0, s["neon_left"])
        VEHICLE.SET_VEHICLE_NEON_ENABLED(v, 1, s["neon_front"])
        VEHICLE.SET_VEHICLE_NEON_ENABLED(v, 2, s["neon_right"])
        VEHICLE.SET_VEHICLE_NEON_ENABLED(v, 3, s["neon_back"])
        VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(v, s["plate_index"])
        VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(v, s["plate_text"])
        VEHICLE.SET_VEHICLE_WINDOW_TINT(v, s["window_tint"])
        VEHICLE.SET_VEHICLE_LIVERY(v, s["livery"])
        VEHICLE.SET_VEHICLE_DIRT_LEVEL(v, 0)

        if s["headlights"] then
            VEHICLE.TOGGLE_VEHICLE_MOD(v, 22, s["headlights"])
            VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(v, s["headlight_index"])
        end

        if s["has_tyre_smoke"] then
            VEHICLE.TOGGLE_VEHICLE_MOD(v, 20, s["has_tyre_smoke"])
            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(v, s["tyre_smoke_r"], s["tyre_smoke_g"], s["tyre_smoke_b"])
        end
    end

    FeatAdd(joaat("VehicleStealer"), "Copy Closest Vehicle", eFeatureType.Button, "Copies the closest vehicle to you.",
        function(f)
            local vehicle = get_closest_vehicle()
            if vehicle == nil or vehicle == 0 then
                inxNoti("Failed to find closest vehicle! The radius is 1000, please step closer.")
                return
            end

            copied_vehicle = extract_vehicle_settings(vehicle)

            inxNoti("Vehicle copied! Spawn it using 'Spawn Copied Vehicle'.")
        end)

    FeatAdd(joaat("VehicleStealerSpawn"), "Spawn Copied Vehicle", eFeatureType.Button,
        "Spawn a car with the copied settings.", function(f)
        if copied_vehicle == nil then
            inxNoti("You must copy a vehicle first.")
            return
        end
        spawn_vehicle_from_settings(copied_vehicle)
    end)

    FeatAdd(joaat("VehicleStealerCopyCode"), "Copy Vehicle Code to Clipboard", eFeatureType.Button,
        "Copies the current vehicle as a code in the clipboard, for spawning later.", function()
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
        if vehicle == 0 then
            inxNoti("Enter a vehicle first.")
            return
        end

        local vehicle_settings = extract_vehicle_settings(vehicle)
        local json_encoded_settings = json.encode(vehicle_settings)
        local base64_encoded_settings = base64.encode(json_encoded_settings)

        ImGui.SetClipboardText(base64_encoded_settings)
        inxNoti("Vehicle code copied to the clipboard!")
    end)

    FeatAdd(joaat("VehicleStealerSpawnFromCode"), "Spawn Vehicle from Code", eFeatureType.Button,
        "Spawns a vehicle from the code you have copied.", function()
        local settings = json.decode(base64.decode(ImGui.GetClipboardText()))
        spawn_vehicle_from_settings(settings)

        inxNoti("Vehicle spawned!")
    end)

    FeatAdd(joaat("ClearCopiedVehicleCode"), "Clear copied vehicle code", eFeatureType.Button, "Clears the copied vehilcle i guess, idk this is elf making it lol", function()
        copied_vehicle = nil
    end)
    --- inxlua section ends here

    -- Elf script v6        

    local Colors = {
        {255, 0, 0},   
        {255, 255, 255},
        {0, 0, 255},   
    }

    function RgbToAnsi(r, g, b)
        return string.format("\27[38;2;%d;%d;%dm", r, g, b)
    end

    function utf8_iter(str)
        local pos = 1
        local len = #str
        return function()
            if pos > len then return nil end
            local c = str:byte(pos)
            local char_len = 1
            if c >= 0xF0 then char_len = 4
            elseif c >= 0xE0 then char_len = 3
            elseif c >= 0xC0 then char_len = 2
            end
            local char = str:sub(pos, pos + char_len - 1)
            pos = pos + char_len
            return char
        end
    end

    function MakeGradientWithAnsi(msg, colorList)
        local chars = {}
        for ch in utf8_iter(msg) do
            table.insert(chars, ch)
        end
        local len = #chars
        local segments = #colorList - 1
        if segments < 1 or len == 0 then return msg end

        local result = ""
        for i, char in ipairs(chars) do
            local t = (i - 1) / (len - 1)
            local seg = math.floor(t * segments) + 1
            local localT = (t * segments) % 1
            local c1 = colorList[seg]
            local c2 = colorList[seg + 1] or c1

            local r = math.floor(c1[1] + (c2[1] - c1[1]) * localT)
            local g = math.floor(c1[2] + (c2[2] - c1[2]) * localT)
            local b = math.floor(c1[3] + (c2[3] - c1[3]) * localT)

            result = result .. RgbToAnsi(r, g, b) .. char
        end

        return result .. "\27[0m"
    end
    
    function GradientLogger(msg)
        if not msg or msg == "" then return end
        local gradient = MakeGradientWithAnsi("\n" .. msg, Colors)
        io.write(gradient)
        io.flush()
    end

    local isinstoryMode = false
    function GetPlayerState()
        local count = 0
        for i = 0, 31 do
            if Players.GetById(i) then
                count = count + 1
            end
        end
        if not NETWORK.NETWORK_IS_SESSION_STARTED() then 
            isinstoryMode = true
        end
        return count
    end

    function DiscordRPC()
        local pipe = io.open('\\\\.\\pipe\\discord-ipc-0', 'r+b')

        if not pipe or pipe == nil then
            GradientLogger("Pipe is not accesible")
            return
        end

        local handshake = {
            v = 1,
            client_id = "1364943026425954385"
        }

        local handshakeStr = json.encode(handshake)

        local success, err = pcall(function()
            pipe:write(string.pack("<II", 0, #handshakeStr))
            pipe:write(handshakeStr)
            pipe:flush()
        end)

        if not success then
            GradientLogger("Failed to send handshake: " .. err)
            return
        end

        local header = pipe:read(8)
        if not header then
            GradientLogger("Failed to read header from Discord.")
            return
        end

        local opcode, length = string.unpack("<II", header)

        local payload = pipe:read(length)
        if not payload then
            GradientLogger("Failed to read payload body.")
        end

        local playerCount = GetPlayerState()

       
        local presence = {
            cmd = "SET_ACTIVITY",
            args = {
                pid = 1234,
                activity = {
                    details = "Very good Cherax script",
                    state = "Quite Complex, and good features ",
                    timestamps = { start = os.time() },
                    assets = {
                        large_image = "discord_logo",
                        large_text = isinstoryMode and "In Story mode" or ("in a session with %d players"):format(playerCount),
                    },
                    buttons = {
                    {
                        label = "No more discord",
                        url = "https://discord.gg/8shmkdWWx6"
                    },
                    {
                        label = "no more script",
                        url = "https://dash.cherax.menu/script/146"
                    }
                },
                    instance = true

                },
                instance = true
            },
            nonce = tostring(os.time())
        }

        
        local presenceStr = json.encode(presence)

        success, err = pcall(function()
            pipe:write(string.pack("<II", 1, #presenceStr))
            pipe:write(presenceStr) -- this is the payload 
            pipe:flush()
        end)
        if not success then
            GradientLogger("Failed to send presence payload: " .. err)
            return
        end

        Script.RegisterLooped(function()
            local heartbeat = json.encode({ cmd = "PING", nonce = tostring(os.time()) })
            success, err = pcall(function()
                pipe:write(string.pack("<II", 3, #heartbeat))
                pipe:write(heartbeat) -- actual heartbeat for the RPC, to keep it as my script cuz discord mega gay 
                pipe:flush()
            end)
            if not success then
                GradientLogger("Failed to send RPC heartbeat: " .. err)
                return
            end
            Script.Yield(10000) 
        end)
    end
    DiscordRPC()
    
    isPlayerModder = {}
    limits = {
        SE = {
            default = {
                limit = 50,
                interval = 1,
                isTimeouted = {},
                currentRate = {}
            },
            strict = {
                limit = 1,
                interval = 15*1000,
                currentRate = {}, -- Time.GetEpocheMs() per PID
                events = {  
                    [-1704545346] = "SCRIPT_EVENT_REMOVE_WANTED_LEVEL",
                    [-642704387] = "SCRIPT_EVENT_TICKER_MESSAGE",
                    [-1321657966] = "INVITE_NEARBY_PLAYERS_INTO_APARTMENT",
                    [1450115979] = "SCRIPT_EVENT_GB_NON_BOSS_CHALLENGE_REQUEST",
                    [-375628860] = "SCRIPT_EVENT_ISLAND_BACKUP_HELI_LAUNCH",
                    [-366707054] = "SCRIPT_EVENT_FORCE_PLAYER_ONTO_MISSION",
                    [1757622014] = "SCRIPT_EVENT_CONFIRMATION_LAUNCH_MISSION",
                    [-1986344798] = "SCRIPT_EVENT_INVITE_TO_SIMPLE_INTERIOR",
                    [606464409] = "SCRIPT_EVENT_CREATE_FMC_INVITE",
                    [-901348601] = "SCRIPT_EVENT_BAIL_ME_FOR_SCTV",
                    [968269233] = "SCRIPT_EVENT_COLLECTIBLE_COLLECTED",
                    [-1773335296] = "SCRIPT_EVENT_SEND_BASIC_TEXT"
                }
            },
            loose = {
                limit = 2,
                interval = 25*1000,
                currentRate = {},
                events = {  
                    [1517551547] = "bounty AKA SCRIPT_EVENT_SET_BOUNTY_ON_PLAYER",
                    [-1253241415] = "freeze aka SCRIPT_EVENT_WARP_TO_QUICK_TRAVEL_DESTINATION",
                    [-245642440] = "phone invite spam in jinx AKA SCRIPT_EVENT_GB_INVITE_TO_GANG",
                }
            },
            specificArgs = { 
                [800157557] = {
                    [4] = 225624744, --GENERAL_EVENT_HEIST_PREPLAN_EXIT_GUEST_MODE
                    name = "force cam forwad"
                }
            }
        },
        NE = {
            ptfx = {            
                strict = {
                    currentRate = {},             
                    interval = 3*1000,
                    limit = 1
                },
                loose = {
                    currentRate = {},
                    interval = 15*1000,
                    limit = 6
                }
            },
            sound = {
                strict = {
                    currentRate = {},             
                    interval = 3*1000,
                    limit = 1
                },
                loose = {
                    currentRate = {},
                    interval = 15*1000,
                    limit = 6
                }
            }   
        }    
    }

    for i=0,31 do
        limits.SE.default.currentRate[i] = {}
        
        limits.SE.strict.currentRate[i] = {}
        limits.SE.loose.currentRate[i] = {}

        limits.NE.ptfx.strict.currentRate[i] = {}
        limits.NE.ptfx.loose.currentRate[i] = {}

        limits.NE.sound.strict.currentRate[i] = {}
        limits.NE.sound.loose.currentRate[i] = {}
    end

    netEvents = { 
        [0x0] = { name = "OBJECT_ID_FREED_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x1] = { name = "OBJECT_ID_REQUEST_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x2] = { name = "ARRAY_DATA_VERIFY_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x3] = { name = "SCRIPT_ARRAY_DATA_VERIFY_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x4] = { name = "REQUEST_CONTROL_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x5] = { name = "GIVE_CONTROL_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x6] = { name = "WEAPON_DAMAGE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x7] = { name = "REQUEST_PICKUP_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x8] = { name = "REQUEST_MAP_PICKUP_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x9] = { name = "GAME_CLOCK_EVENT", decide = shouldBlockNE, func = LogNE },
        [0xA] = { name = "GAME_WEATHER_EVENT", decide = shouldBlockNE, func = LogNE },
        [0xB] = { name = "RESPAWN_PLAYER_PED_EVENT", decide = shouldBlockNE, func = LogNE },
        [0xC] = { name = "GIVE_WEAPON_EVENT", decide = shouldBlockNE, func = LogNE },
        [0xD] = { name = "REMOVE_WEAPON_EVENT", decide = shouldBlockNE, func = LogNE },
        [0xE] = { name = "REMOVE_ALL_WEAPONS_EVENT", decide = shouldBlockNE, func = LogNE },
        [0xF] = { name = "VEHICLE_COMPONENT_CONTROL_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x10] = { name = "FIRE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x11] = { name = "EXPLOSION_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x12] = { name = "START_PROJECTILE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x13] = { name = "UPDATE_PROJECTILE_TARGET_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x14] = { name = "REMOVE_PROJECTILE_ENTITY_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x15] = { name = "BREAK_PROJECTILE_TARGET_LOCK_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x16] = { name = "ALTER_WANTED_LEVEL_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x17] = { name = "CHANGE_RADIO_STATION_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x18] = { name = "RAGDOLL_REQUEST_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x19] = { name = "PLAYER_TAUNT_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x1A] = { name = "PLAYER_CARD_STAT_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x1B] = { name = "DOOR_BREAK_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x1C] = { name = "SCRIPTED_GAME_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x1D] = { name = "REMOTE_SCRIPT_INFO_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x1E] = { name = "REMOTE_SCRIPT_LEAVE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x1F] = { name = "MARK_AS_NO_LONGER_NEEDED_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x20] = { name = "CONVERT_TO_SCRIPT_ENTITY_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x21] = { name = "SCRIPT_WORLD_STATE_EVENT", decide = shouldBlockWorldStateEvent, func = logWorldStateEvent },
        [0x22] = { name = "CLEAR_AREA_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x23] = { name = "CLEAR_RECTANGLE_AREA_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x24] = { name = "NETWORK_REQUEST_SYNCED_SCENE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x25] = { name = "NETWORK_START_SYNCED_SCENE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x26] = { name = "NETWORK_STOP_SYNCED_SCENE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x27] = { name = "NETWORK_UPDATE_SYNCED_SCENE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x28] = { name = "INCIDENT_ENTITY_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x29] = { name = "GIVE_PED_SCRIPTED_TASK_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x2A] = { name = "GIVE_PED_SEQUENCE_TASK_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x2B] = { name = "CLEAR_PED_TASKS_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x2C] = { name = "NETWORK_START_PED_ARREST_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x2D] = { name = "NETWORK_START_PED_UNCUFF_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x2E] = { name = "NETWORK_SOUND_CAR_HORN_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x2F] = { name = "NETWORK_ENTITY_AREA_STATUS_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x30] = { name = "NETWORK_GARAGE_OCCUPIED_STATUS_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x31] = { name = "PED_CONVERSATION_LINE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x32] = { name = "SCRIPT_ENTITY_STATE_CHANGE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x33] = { name = "NETWORK_PLAY_SOUND_EVENT", decide = shouldBlockSoundEvent, func = logPlaySoundEvent },
        [0x34] = { name = "NETWORK_STOP_SOUND_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x35] = { name = "NETWORK_PLAY_AIRDEFENSE_FIRE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x36] = { name = "NETWORK_BANK_REQUEST_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x37] = { name = "NETWORK_AUDIO_BARK_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x38] = { name = "REQUEST_DOOR_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x39] = { name = "NETWORK_TRAIN_REPORT_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x3A] = { name = "NETWORK_TRAIN_REQUEST_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x3B] = { name = "NETWORK_INCREMENT_STAT_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x3C] = { name = "MODIFY_VEHICLE_LOCK_WORD_STATE_DATA", decide = shouldBlockNE, func = LogNE },
        [0x3D] = { name = "MODIFY_PTFX_WORD_STATE_DATA_SCRIPTED_EVOLVE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x3E] = { name = "REQUEST_PHONE_EXPLOSION_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x3F] = { name = "REQUEST_DETACHMENT_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x40] = { name = "KICK_VOTES_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x41] = { name = "GIVE_PICKUP_REWARDS_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x42] = { name = "BLOW_UP_VEHICLE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x43] = { name = "NETWORK_SPECIAL_FIRE_EQUIPPED_WEAPON", decide = shouldBlockNE, func = LogNE },
        [0x44] = { name = "NETWORK_RESPONDED_TO_THREAT_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x45] = { name = "NETWORK_SHOUT_TARGET_POSITION", decide = shouldBlockNE, func = LogNE },
        [0x46] = { name = "VOICE_DRIVEN_MOUTH_MOVEMENT_FINISHED_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x47] = { name = "PICKUP_DESTROYED_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x48] = { name = "UPDATE_PLAYER_SCARS_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x49] = { name = "NETWORK_CHECK_EXE_SIZE_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x4A] = { name = "NETWORK_PTFX_EVENT", decide = shouldBlockPTFXEvent, func = logPTFXEvent },
        [0x4B] = { name = "NETWORK_PED_SEEN_DEAD_PED_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x4C] = { name = "REMOVE_STICKY_BOMB_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x4D] = { name = "NETWORK_CHECK_CODE_CRCS_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x4E] = { name = "INFORM_SILENCED_GUNSHOT_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x4F] = { name = "PED_PLAY_PAIN_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x50] = { name = "CACHE_PLAYER_HEAD_BLEND_DATA_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x51] = { name = "REMOVE_PED_FROM_PEDGROUP_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x52] = { name = "REPORT_MYSELF_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x53] = { name = "REPORT_CASH_SPAWN_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x54] = { name = "ACTIVATE_VEHICLE_SPECIAL_ABILITY_EVENT", decide = shouldBlockNE, func = LogNE },
        [0x55] = { name = "BLOCK_WEAPON_SELECTION", decide = shouldBlockNE, func = LogNE },
        [0x56] = { name = "NETWORK_CHECK_CATALOG_CRC", decide = shouldBlockNE, func = LogNE },
    }
    local ratelimits = { default = { isTimeouted = {} } }

    function handleScriptEvent(sender, args)
        local senderId = sender.PlayerId
        local wantsToLog = false
        local blockSE, reason  = checkScriptEventRatelimits(args, senderId)

        if FeatureMgr.IsFeatureEnabled(joaat("LogAllSEs")) or FeatureMgr.IsFeatureEnabled(joaat("LogPlayerSEs"), senderId) then
            wantsToLog = true
        end
        if FeatureMgr.IsFeatureEnabled(joaat("LogModderSEs")) and isPlayerModder[senderId] then
            wantsToLog = true
        end

        if FeatureMgr.IsFeatureEnabled(joaat("BlockPlayerSEs"), senderId) then
            blockSE = true
        end	
        if wantsToLog then
            LogSE(senderId, args, blockSE, reason)
        end
        return blockSE
    end

    function handleNetEvent(sender, eventId, datBitBuffer)
        if netEvents[eventId] and netEvents[eventId].name == "SCRIPTED_GAME_EVENT" then 
            return false
        end
        local senderId = sender.PlayerId
        local wantsToLog = false
        local blockNE = false

        if FeatureMgr.IsFeatureEnabled(joaat("LogAllNEs")) or FeatureMgr.IsFeatureEnabled(joaat("LogPlayerNEs"), senderId) then
            wantsToLog = true
        end
        if FeatureMgr.IsFeatureEnabled(joaat("LogModderNEs")) and isPlayerModder[senderId] then
            wantsToLog = true
        end

        if netEvents[eventId] and netEvents[eventId].decide then
            if not wantsToLog then 
                blockNE, wantsToLog = netEvents[eventId].decide(datBitBuffer, senderId)
            else
                blockNE = netEvents[eventId].decide(datBitBuffer, senderId)
            end
        end	

        if FeatureMgr.IsFeatureEnabled(joaat("BlockPlayerNEs"), senderId) then
            blockNE = true
            GradientLogger("blockNE..  "..tostring(blockNE))
        end

        if wantsToLog then
            if netEvents[eventId] and netEvents[eventId].func then
                netEvents[eventId].func(senderId, eventId, blockNE, datBitBuffer)
            else
                LogNE(senderId, eventId, blockNE, datBitBuffer)
            end
        end
        return blockNE
    end

    PlayerFeatAdd(joaat("LogPlayerSEs"), "Log Players Script events", eFeatureType.Toggle, "logs script events sent by players ", function(f) end, false)
    PlayerFeatAdd(joaat("BlockPlayerSEs"), "Block Players Script events", eFeatureType.Toggle, "Blocks all script events sent by an individual player", function(f) end, false)
    FeatAdd(joaat("LogModderSEs"), "Log Modder Script events", eFeatureType.Toggle, "logs all script events sent my modding players", function(f) end, false):SetDefaultValue(true):Reset()
    FeatAdd(joaat("LogAllSEs"), "Log All Script events", eFeatureType.Toggle, "", function(f) end, false)

    PlayerFeatAdd(joaat("NotifyPlayerTimeout"), "Is Player in Timeout", eFeatureType.Button, "", function(f)
        local pid = f:GetPlayerIndex()
        if ratelimits.default.isTimeouted[pid] then
            GUI.AddToast("Protection", Players.GetName(pid) .. " is in Timeout", 5000)
            GradientLogger(Players.GetName(pid) .. " is in Timeout")
        else
            GUI.AddToast("Protection", Players.GetName(pid) .. " is not in Timeout", 5000)
            GradientLogger(Players.GetName(pid) .. " is not in Timeout")
        end
    end, false)

    PlayerFeatAdd(joaat("LogPlayerNEs"), "Log Players Network events", eFeatureType.Toggle, "", function(f) end, false)
    PlayerFeatAdd(joaat("BlockPlayerNEs"), "Block Players Networkevents", eFeatureType.Toggle, "", function(f) end, false)
    FeatAdd(joaat("LogModderNEs"), "Log Modder Network events", eFeatureType.Toggle, "", function(f) end, false)
    FeatAdd(joaat("LogAllNEs"), "Log All Networkevents", eFeatureType.Toggle, "", function(f) end, false)

    EventMgr.RegisterHandler(eLuaEvent.SCRIPTED_GAME_EVENT, handleScriptEvent)
    EventMgr.RegisterHandler(eLuaEvent.NET_EVENT, handleNetEvent)

    function getCPhysicalFromNetId(netId)
        if not netId then
            return GradientLogger("No netId in GEFNI")
        end
        local netObj = NetworkObjectMgr.GetNetworkObject(netId)
        if netObj then
            local CPhysical = netObj:GetEntity()
            if CPhysical then
                return CPhysical
            end
        end
        return 0
    end

    function getModelHashFromNetId(netId)
        if not netId then
            return GradientLogger("No netId in GMHFNI")
        end
        local hash = 0
        local CPhysical = getCPhysicalFromNetId(netId)
        if CPhysical ~= 0 and CPhysical.ModelInfo then
            hash = CPhysical.ModelInfo.Model
        end
        return hash
    end

    function checkModder()
        if not ShouldUnload() then
            Script.Yield(1000)
        end
        for _,pid in pairs(Players.Get()) do
            if string.find(Players.GetTags(pid), "%[M%]") then
                isPlayerModder[pid] = true
            else
                isPlayerModder[pid] = false
            end
        end
    end

    function checkTimeouts()
        if not ShouldUnload() then
            Script.Yield(100)
        end
        local time = Time.GetEpocheMs()
        for i=0,31 do
            removeOlderThan(limits.SE.default.currentRate[i], limits.SE.default.interval, time)

            removeOlderThan(limits.SE.strict.currentRate[i], limits.SE.strict.interval, time)
            removeOlderThan(limits.SE.loose.currentRate[i], limits.SE.loose.interval, time)

            if limits.SE.default.isTimeouted[i] and #limits.SE.default.currentRate[i] < limits.SE.default.limit then
                GUI.AddToast("Protection", string.format("%s is no longer spamming Scriptevents",Players.GetName(pid)), 5000, eToastPos.TOP_RIGHT)
                GradientLogger(string.format("%s is no longer spamming Scriptevents, disabled Scriptevent timeout", Players.GetName(pid)))
                limits.SE.default.isTimeouted[i] = false
            end
            for key,_ in pairs(limits.NE) do
                removeOlderThan(limits.NE[key].strict.currentRate[i], limits.NE[key].strict.interval, time)
                removeOlderThan(limits.NE[key].loose.currentRate[i], limits.NE[key].loose.interval, time)
            end		
        end
    end

    function removeOlderThan(tbl, interval, currentTime)
        for i=1,#tbl do
            if not tbl[i] then
                return tbl
            end
            if tbl[i] + interval < currentTime then
                table.remove(tbl, i)
            end
        end
        return tbl
    end

    function ConcatArgsToString(tb)
        local out = "\n{"
        for i=1,#tb do
            out = out .. tb[i]
            if i ~= #tb then out = out .. ", " end
        end
        return out .. "}"
    end

    function readBitBuffer(dbb)
        local out = ""
        local count = 0
        while not ShouldUnload() do
            count = count + 1
            local val, success = dbb:ReadBool()
            if not success or count > 1000 then
                break
            end
            out = out .. (val and "1" or "0")
        end
        return out
    end

    function LogSE(senderId, args, blockSE, reason)
        local playerName = Players.GetName(senderId) or "Unknown Player"
        local action = blockSE and "Blocked" or "Incoming"
        local success, seName = GTA.GetScriptEventName(args[1])

        local msgParts = {}
        local senderInfo = string.format("%s(%d)", playerName, senderId)
        table.insert(msgParts, senderInfo)
        if reason and reason ~= "" then
            table.insert(msgParts, reason)
        end
        if success then
            table.insert(msgParts, seName)
        end
        table.insert(msgParts, ConcatArgsToString(args))
        local msg = table.concat(msgParts, " + ")

        GradientLogger(msg)
    end

    function LogNE(senderId, eventId, blockNE, dbb)
        local eventName = "Unknown Event(" .. tostring(eventId) .. ")"
        if netEvents[eventId] and netEvents[eventId].name then
            eventName = netEvents[eventId].name
        end
        local playerName = Players.GetName(senderId) or "Unknown Player"
        local action = blockNE and "Blocked" or "Incoming"
        
        local msg = string.format("%s %s from %s \n%s", action, eventName, playerName, readBitBuffer(dbb))
        
        GradientLogger(msg)
    end

    function getOwnObjectID()
        if not GTA.GetLocalPed().NetObject then return 0 end
        return GTA.GetLocalPed().NetObject.ObjectID
    end

    function getPlayerObjectID(playerID)
        if not Players.GetCPed(playerID).NetObject then return 0 end
        return Players.GetCPed(playerID).NetObject.ObjectID
    end

    function getPlayersVehicleObjectID(playerID)
        local cPed = Players.GetCPed(playerID)
        if not cPed or not cPed:IsInVehicle() then
            return 0
        end
        local cVeh = cPed.LastVehicle
        if not cVeh or cVeh == 0 or not cVeh.NetObject then
            return 0
        end
        return cVeh.NetObject.ObjectID
    end

    function manhattanDistance(v1, v2)
        return math.abs(v1.x - v2.x) + math.abs(v1.y - v2.y) + math.abs(v1.z - v2.z)
    end

    function shouldBlockNE(dbb)
        return false
    end

    function serialisePosition(dbb)
        local pos = V3.New()
        pos.x = dbb:ReadInt(0x13) 
        pos.y = dbb:ReadInt(0x13) 
        pos.z = dbb:ReadInt(0x13) 
        return pos
    end

    function getPTFXData(dbb)
        local event = {}
        dbb:Seek(0)
        event.m_PtFXHash = dbb:ReadUns(32)
        event.m_PtFXAssetHash = dbb:ReadUns(32)

        event.m_FxPos = serialisePosition(dbb)
        event.m_FxRot = serialisePosition(dbb)

        event.m_Scale = dbb:ReadUns(10)
        event.m_InvertAxes = dbb:ReadUns(3)
        event.m_bUseEntity = dbb:ReadBool()
        if event.m_bUseEntity then
            event.m_EntityID = dbb:ReadUns(13)
        end
        event.m_bUseBoneIndex = dbb:ReadBool()
        if event.m_bUseBoneIndex then
            event.m_boneIndex = dbb:ReadUns(32)
        end
        event.m_bHasColor = dbb:ReadBool()
        if event.m_bHasColor then
            event.m_bHasColor = {}
            event.m_bHasColor.r = dbb:ReadInt(8)
            event.m_bHasColor.g = dbb:ReadInt(8)
            event.m_bHasColor.b = dbb:ReadInt(8)
        end
        event.m_bHasAlpha = dbb:ReadBool()
        if event.m_bHasAlpha then
            event.m_alpha = dbb:ReadInt(8)
        end
        return event
    end

    function shouldBlockPTFXEvent(dbb, senderId)
        local blockedHashList = {
            [0x8e76ca0e] = "Smoke Player (Cherax)", 
            [0xfd433834] = "Overwork Scaleform (JinxScript)",
            [0x87f63517] = "Orbital player (Cherax?)"
        }

        local event = getPTFXData(dbb)

        if blockedHashList[event.m_PtFXHash] then
            GradientLogger(string.format("Blocked blacklisted PTFX (%s) from %s", blockedHashList[event.m_PtFXHash], Players.GetName(senderId)))
            return true
        end

        table.insert(limits.NE.ptfx.strict.currentRate[senderId], Time.GetEpocheMs())
        table.insert(limits.NE.ptfx.loose.currentRate[senderId], Time.GetEpocheMs())
        if #limits.NE.ptfx.strict.currentRate[senderId] > limits.NE.ptfx.strict.limit then
            GradientLogger(string.format("Blocked PTFX spam v1 from %s", Players.GetName(senderId)))
            return true
        end
        if #limits.NE.ptfx.loose.currentRate[senderId] > limits.NE.ptfx.loose.limit then
            GradientLogger(string.format("Blocked PTFX spam v2 from %s", Players.GetName(senderId)))
            return true
        end
        
        if event.m_bUseEntity then
            local hash = getModelHashFromNetId(event.m_EntityID)
            if hash == joaat("mp_f_freemode_01") or hash == joaat("mp_m_freemode_01") then
                GradientLogger(string.format("Blocked PTFX from %s due to attached to a freemode model", Players.GetName(senderId)))
                return true
            end
            if event.m_EntityID == getOwnObjectID() then
                GradientLogger(string.format("Blocked PTFX attached to you from %s", Players.GetName(senderId)))
                return true
            end
            if event.m_EntityID == getPlayersVehicleObjectID(GTA.GetLocalPlayerId()) then
                GradientLogger(string.format("Blocked PTFX attached to your car from %s", Players.GetName(senderId)))
                return true
            end
            local CPhysical = getCPhysicalFromNetId(event.m_EntityID)
            local CPhysical2 = GTA.GetLocalPed()
            if CPhysical ~= 0 and CPhysical2 and manhattanDistance(CPhysical.Position, CPhysical2.Position) < 150.0 then
                GradientLogger(string.format("Blocked PTFX too close to you from %s", Players.GetName(senderId)))
                return true
            end		
        end

        return false
    end

    function logPTFXEvent(senderId, eventId, blockNE, dbb)
        local event = getPTFXData(dbb)
        local eventName = netEvents[eventId].name
        local playerName = Players.GetName(senderId) or "Unknown Player"
        local action = blockNE and "Blocked" or "Incoming"

        GradientLogger(string.format("%s %s from %s %s", action, eventName, playerName, readBitBuffer(dbb)))    
        GradientLogger(string.format("\t m_PtFXHash: 0x%x", event.m_PtFXHash)) 
        GradientLogger(string.format("\t m_PtFXAssetHash: 0x%x", event.m_PtFXAssetHash))
        if event.m_bUseEntity then
            GradientLogger("\t modelHash: " .. GTA.GetModelNameFromHash(getModelHashFromNetId(event.m_EntityID)))
        end
        if event.m_bUseBoneIndex then
            GradientLogger("\t m_boneIndex:" .. event.m_bUseBoneIndex)
        end
        return event
    end

    function checkScriptEventRatelimits(args, senderId)
        local blockSE = false

        local wantsToLog = false
        table.insert(limits.SE.default.currentRate[senderId], Time.GetEpocheMs())
            if #limits.SE.default.currentRate[senderId] > limits.SE.default.limit and not limits.SE.default.isTimeouted[senderId] then
                limits.SE.default.isTimeouted[senderId] = true
                GUI.AddToast("Elf Script", Players.GetName(senderId) .. " is spamming Scriptevents", 5000)
                GradientLogger(Players.GetName(senderId) .. " is spamming Scriptevents, enabled Scriptevent timeout")
            end
            if limits.SE.default.isTimeouted[senderId] then
                reason = "General Ratelimit"
                blockSE = true
            end

        if not blockSE and limits.SE.strict.events[args[1]] then
            table.insert(limits.SE.strict.currentRate[senderId], Time.GetEpocheMs())
            if #limits.SE.strict.currentRate[senderId] > limits.SE.strict.limit then
                reason = "Strict Ratelimit"
                blockSE = true
                wantsToLog = true
            end
        end
        if not blockSE and limits.SE.loose.events[args[1]] then
            table.insert(limits.SE.loose.currentRate[senderId], Time.GetEpocheMs())
            if #limits.SE.loose.currentRate[senderId] > limits.SE.loose.limit then
                reason = "Loose Ratelimit"
                blockSE = true
            end
        end
        if not blockSE and limits.SE.specificArgs[args[1]] then
            for idx, val in ipairs(args) do
                if val == limits.SE.specificArgs[args[1]][idx] then
                    reason = limits.SE.specificArgs[args[1]].name
                    blockSE = true
                end
            end
        end
        return blockSE, reason
    end

    function getPlaySoundData(dbb)
        local event = {}
        dbb:Seek(0)
        event.m_bUseEntity = dbb:ReadBool()
        if (event.m_bUseEntity) then
            event.m_EntityID = dbb:ReadUns(13)
        else
            event.m_Position = serialisePosition(dbb)
        end
        
        event.bSetNameValid = dbb:ReadBool()
        if (event.bSetNameValid) then
            event.m_setNameHash = dbb:ReadUns(32)
        else
            event.m_setNameHash = 0;
        end

        event.m_soundNameHash = dbb:ReadUns(32)

        event.m_SoundID = dbb:ReadUns(8)

        event.bSetScriptValid = dbb:ReadBool()
        if (event.bSetScriptValid) then
            event.m_ScriptId = dbb:ReadUns(32)
        else
            event.m_ScriptId = "invalid"
        end
        return event
    end

    function shouldBlockSoundEvent(dbb, senderId)
        local blockedHashList = {
            [0x9E7C293F] = "Sound spam Air_Defences_Activated (Stand)",
            [0x9542F458] = "Sound spam (Stand)",
        }

        local event = getPlaySoundData(dbb)

        if blockedHashList[event.m_soundNameHash] then
            GradientLogger(string.format("Blocked blacklisted sound (%s) from %s", blockedHashList[event.m_soundNameHash], Players.GetName(senderId)))
            return true
        end

        table.insert(limits.NE.sound.strict.currentRate[senderId], Time.GetEpocheMs())
        table.insert(limits.NE.sound.loose.currentRate[senderId], Time.GetEpocheMs())
        if #limits.NE.sound.strict.currentRate[senderId] > limits.NE.sound.strict.limit then
            GradientLogger(string.format("Blocked sound spam v1 from %s", Players.GetName(senderId)))
            return true, true
        end
        if #limits.NE.sound.loose.currentRate[senderId] > limits.NE.sound.loose.limit then
            GradientLogger(string.format("Blocked sound spam v2 from %s", Players.GetName(senderId)))
            return true
        end

        if event.m_bUseEntity then
            local hash = getModelHashFromNetId(event.m_EntityID)
            if hash == joaat("mp_f_freemode_01") or hash == joaat("mp_m_freemode_01") then
                GradientLogger(string.format("Blocked Soundspam from %s due to being on a freemode model. Hash: %s", Players.GetName(senderId), event.m_soundNameHash))
                return true
            end
            if event.m_EntityID == getOwnObjectID()  then
                GradientLogger(string.format("Blocked Soundspam from %s on your ped. Hash: %s", Players.GetName(senderId), event.m_soundNameHash))
                return true
            end
            if event.m_EntityID == getPlayersVehicleObjectID(GTA.GetLocalPlayerId()) then
                GradientLogger(string.format("Blocked Soundspam from %s on your car. Hash: %s", Players.GetName(senderId), event.m_soundNameHash))
                return true
            end
        end	
        return false
    end

    function logPlaySoundEvent(senderId, eventId, blockNE, dbb)
        local event = getPlaySoundData(dbb)
        local eventName = netEvents[eventId].name
        local playerName = Players.GetName(senderId) or "Unknown Player"
        local action = blockNE and "Blocked" or "Incoming"

        GradientLogger(string.format("%s %s from %s %s", action, eventName, playerName, readBitBuffer(dbb)))
        if not event.m_bUseEntity then
            GradientLogger(string.format("\t m_Position: x %s + y %s + z %s", event.m_Position.x, event.m_Position.y, event.m_Position.z))
        else
            GradientLogger("\t modelHash: " .. GTA.GetModelNameFromHash(getModelHashFromNetId(event.m_EntityID)))
        end

        if event.bSetNameValid then
            GradientLogger(tostring(string.format("\t m_setNameHash: 0x%x", event.m_setNameHash)))
        end
        GradientLogger(tostring(string.format("\t m_soundNameHash: 0x%x", event.m_soundNameHash)))
        if event.bSetScriptValid then
            GradientLogger("\t m_ScriptId: " .. tostring(event.m_ScriptId))
        end

        return event
    end
    local NetScriptWorldStateTypes = {
        NET_WORLD_STATE_CAR_GEN = 0,
        NET_WORLD_STATE_ENTITY_AREA = 1,
        NET_WORLD_STATE_POP_GROUP_OVERRIDE = 2,
        NET_WORLD_STATE_POP_MULTIPLIER_AREA = 3,
        NET_WORLD_STATE_PTFX = 4,
        NET_WORLD_STATE_ROAD_NODE = 5,
        NET_WORLD_STATE_ROPE = 6,
        NET_WORLD_STATE_SCENARIO_BLOCKING_AREA = 7,
        NET_WORLD_STATE_VEHICLE_PLAYER_LOCKING = 8,
    }
    local function placeholder()
    end

    local function getPTFXdata(dbb) 
        local event = {}
        event.scrtiptId = {}
        dbb:ReadUns(69)
        event.scrtiptId.m_TimeStamp = dbb:ReadUns(32)
        event.scrtiptId.bHasPosition = dbb:ReadBool()
        if event.scrtiptId.bHasPosition then
            event.scrtiptId.m_PositionHash = dbb:ReadUns(32)
        end

        event.scrtiptId.bHasInstanceId = dbb:ReadBool()
        if event.scrtiptId.bHasInstanceId then
            event.scrtiptId.m_InstanceId = dbb:ReadUns(8)
        end

        event.m_uniqueID = dbb:ReadUns(32)
        event.m_PtFXHash = dbb:ReadUns(32)
        event.m_PtFXAssetHash = dbb:ReadUns(32)
        event.m_FxRot = serialisePosition(dbb)
        event.m_Scale = dbb:ReadInt(10)
        event.m_InvertAxes = dbb:ReadUns(3)

        event.m_bUseEntity = dbb:ReadBool()
        if (event.m_bUseEntity) then    
            event.m_EntityID = dbb:ReadUns(13)
            event.m_FxPos = serialisePosition(dbb) 
        else    
            event.m_FxPos = serialisePosition(dbb)
        end

        event.m_hasColour = dbb:ReadBool();
        if (event.m_hasColour) then
            event.color = {}
            event.color.r = dbb:ReadUns(8)
            event.color.g = dbb:ReadUns(8)
            event.color.b = dbb:ReadUns(8)
        end

        event.bHasBoneIndex = dbb:ReadBool()
        if (event.bHasBoneIndex) then    
            event.m_boneIndex = dbb:ReadInt(32)
        end

        event.bHasEvoIDA = dbb:ReadBool()
        if (event.bHasEvoIDA) then    
            event.m_evoHashA = dbb:ReadUns(32)
            event.m_evoValA = dbb:ReadInt(10)    
        end

        event.bHasEvoIDB = dbb:ReadBool()
        if (event.bHasEvoIDB) then
            event.m_evoHashB = dbb:ReadUns(32)
            event.m_evoValB = dbb:ReadInt(10)
        end

        event.m_bAttachedToWeapon = dbb:ReadBool()

        event.m_bTerminateOnOwnerLeave = dbb:ReadBool()
        if (event.m_bTerminateOnOwnerLeave) then
            event.m_ownerPeerID = dbb:ReadUns(64)
        end    
        return event
    end

    function shouldBlockWorldPTFXevent(dbb,senderId,event)
        local event = getPTFXdata(dbb)
        local senderId = dbb:ReadUns(64)
        return false
    end

    function logWorldPTFXevent(senderId, eventId, blockNE, dbb, typ)
        local event = getPTFXdata(dbb)
        local eventName = netEvents[eventId].name
        local playerName = Players.GetName(senderId) or "Unknown Player"
        local action = blockNE and "Blocked" or "Incoming"
        GradientLogger(string.format("%s %s from %s %s + type: %s", action, eventName, playerName, readBitBuffer(dbb), typ))
        GradientLogger(string.format("\t m_uniqueID: 0x%x", event.m_uniqueID))
        GradientLogger(string.format("\t m_PtFXHash: 0x%x", event.m_PtFXHash))
        GradientLogger(string.format("\t m_PtFXAssetHash: 0x%x", event.m_PtFXAssetHash))    
        GradientLogger(string.format("\t m_Scale: %s", event.m_Scale))
        GradientLogger(string.format("\t m_InvertAxes: %s", event.m_InvertAxes))
        if event.m_bUseEntity then
            GradientLogger(string.format("\t ModelHash: %s", GTA.GetModelNameFromHash(getModelHashFromNetId(event.m_EntityID))))
        end
        GradientLogger(string.format("\t m_FxPos x %s + y %s + z %s", event.m_FxPos.x, event.m_FxPos.y, event.m_FxPos.z))
        if event.bHasBoneIndex then
            GradientLogger(string.format("\t m_boneIndex: %s", event.m_boneIndex))
        end
        if (event.bHasEvoIDA) then
            GradientLogger(string.format("\t m_evoHashA: %s", event.m_evoHashA))
            GradientLogger(string.format("\t m_evoValA: %s", event.m_evoValA))  
        end
        if (event.bHasEvoIDB) then
            GradientLogger(string.format("\t m_evoHashB: %s", event.m_evoHashB))
            GradientLogger(string.format("\t m_evoValB: %s", event.m_evoValB))
        end
        GradientLogger(string.format("\t m_bAttachedToWeapon: %s", event.m_bAttachedToWeapon))

        if (event.m_bTerminateOnOwnerLeave) then
            GradientLogger(string.format("\t m_ownerPeerID: %s", event.m_ownerPeerID))
        end
    end


    function getCorrectFunc(typ)
        if typ == NetScriptWorldStateTypes.NET_WORLD_STATE_CAR_GEN then
            
        elseif typ == NetScriptWorldStateTypes.NET_WORLD_STATE_ENTITY_AREA then
            
        elseif typ == NetScriptWorldStateTypes.NET_WORLD_STATE_POP_GROUP_OVERRIDE then
            
        elseif typ == NetScriptWorldStateTypes.NET_WORLD_STATE_POP_MULTIPLIER_AREA then
            
        elseif typ == NetScriptWorldStateTypes.NET_WORLD_STATE_PTFX then
            return shouldBlockWorldPTFXevent,logWorldPTFXevent
        elseif typ == NetScriptWorldStateTypes.NET_WORLD_STATE_ROAD_NODE then
            
        elseif typ == NetScriptWorldStateTypes.NET_WORLD_STATE_ROPE then
            
        elseif typ == NetScriptWorldStateTypes.NET_WORLD_STATE_SCENARIO_BLOCKING_AREA then
            
        elseif typ == NetScriptWorldStateTypes.NET_WORLD_STATE_VEHICLE_PLAYER_LOCKING then
            
        else
            GradientLogger(string.format("Invalid NetScriptWorldStateTypes(%s)", typ))
        end
        return placeholder,placeholder
    end

    function logWorldStateEvent(senderId, eventId, blockNE, dbb)
        dbb:Seek(0)
        local typ = dbb:ReadUns(4)
        local m_ChangeState = dbb:ReadBool()
        local blockFunc,logFunc = getCorrectFunc(typ)
        logFunc(senderId, eventId, blockNE, dbb, typ)
        GradientLogger(blockFunc,logFunc)
    end
    function shouldBlockWorldStateEvent(dbb, senderId)
        dbb:Seek(0)
        local typ = dbb:ReadUns(4)
        local m_ChangeState = dbb:ReadBool()
        local blockFunc = getCorrectFunc(typ)
        return blockFunc(dbb, senderId)
    end

        
    Script.RegisterLooped(checkTimeouts)
    Script.RegisterLooped(checkModder)


    FileMgr.CreateDir(menuRootPath)


    GradientLogger("Welcome, To get supporter make a ticket in the discord and tell me your UID Which is " .. UID)

    version = Cherax.GetEdition()

    function exit()
        Script.Yield(3000)
        os.exit()
        if ShouldUnload() then
            os.exit()
            return
        end
    end

    if UID == 1616 then
        GUI.AddToast("Elf Script", "Get Pwned bro", 5000, eToastPos.TOP_RIGHT)
        EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, exit)
        return
    end

    originalMemoryScan = Memory.Scan
    scanQueue = {}
    totalSignatures = 0

    function tableContains(tbl, value)
        for _, v in ipairs(tbl) do
            if v == value then
                return true
            end
        end
        return false
    end

    Memory.Scan = function(name, signature, ripOffset, callback)
        if type(ripOffset) == "function" then
            callback = ripOffset
            ripOffset = nil
        end

        table.insert(scanQueue, {
            name = name,
            signature = signature,
            ripOffset = ripOffset,
            callback = callback
        })
    end

    function RunScans()
        local startTime = Time.GetEpocheMs()
        totalSignatures = 0
        local failedPatterns = {}
        local successPatterns = {}
        for _, scanData in ipairs(scanQueue) do
            local scan = originalMemoryScan(scanData.signature)
            local success = false

            if scan ~= 0 then
                local rip = scanData.ripOffset and Memory.Rip(scan + scanData.ripOffset) or scan

                if rip ~= 0 then
                    if scanData.callback then
                        local status, err = pcall(scanData.callback, rip)
                        if not status then
                            GradientLogger("Callback error for '"..scanData.name.."': "..err)
                        else
                            success = true
                        end
                    else
                        success = true
                    end
                end
            end

            if success then
                totalSignatures = totalSignatures + 1
                table.insert(successPatterns, scanData.name)
            else
                table.insert(failedPatterns, scanData.name)
            end
        end

        for _, name in ipairs(successPatterns) do
            GradientLogger("Found Signature for '"..name.."'")
        end
        
        for _, name in ipairs(failedPatterns) do
            GradientLogger("Failed to find '"..name.."'")
        end

        local elapsed = Time.GetEpocheMs() - startTime
        GradientLogger(("Scanned %d patterns in %dms"):format(totalSignatures, elapsed))
            
        return totalSignatures, elapsed
    end

    local Globals = {}
    getrevratio = 0x08C8
    setnextgear = 0x0880
    gethighgear = 0x0886
    getcurrentgear = 0x0882
    local GenericPedPool
    if version == "LE" then 
        GradientLogger([[

    ▄███████▄  ▄█         ▄███████▄  ▄███████▄  ▄███████▄   ▄███████▄   ▄█     ▄███████▄     ███
    ███    ███ ███        ███    ███ ███    ███ ███    ███  ███    ███  ███    ███    ███ ▀█████████▄
    ███    █▀  ███        ███    █▀  ███    █▀  ███    █▀   ███    ███  ███▌   ███    ███    ▀███▀▀██
   ▄███▄▄▄     ███       ▄███▄▄▄     ███        ███        ▄███▄▄▄▄██▀  ███▌   ███    ███     ███   ▀
  ▀▀███▀▀▀     ███      ▀▀███▀▀▀   ▀██████████▄ ███       ▀▀███▀▀▀▀▀    ███▌ ▀█████████▀      ███
    ███    █▄  ███        ███               ███ ███    █▄ ▀██████████▄  ███    ███            ███
    ███    ███ ███▌    ▄  ███         ▄█    ███ ███    ███  ███    ███  ███    ███            ███
    ██████████ █████▄▄██  ███       ▄████████▀  ████████▀   ███    ███  █▀    ▄████▀         ▄████▀
    ]])
        Globals = {
            vehPersonalVehicle = 2740054 + 309,     -- to find search for [0] == veParam0) in am_contact_requests
            CEOWORK = {
                SightSeer = {
                    TimeLimit = 262145 + 12955,          -- GB_SIGHTSEER_TIME_LIMIT
                    DefaultCash = 262145 + 12959,        -- GB_SIGHTSEER_DEFAULT_CASH_REWARD
                    ParticipationCash = 262145 + 12961,  -- GB_SIGHTSEER_MINIMUM_PARTICIPATION_CASH
                    ParticipationRP = 262145 + 12962,    -- GB_SIGHTSEER_MINIMUM_PARTICIPATION_RP
                    CoolDown = 262145 + 12956,           -- GB_SIGHTSEER_COOLDOWN 
                    CashMultiplier = 262145 + 12964      -- GB_SIGHTSEER_EVENT_MULTIPLIER_CASH
                },
                YachtAttack = {
                    TimeLimit = 262145 + 12966,          -- GB_YACHTATTACK_TIME_LIMIT
                    DefaultCash = 262145 + 12975,        -- GB_YACHTATTACK_DEFAULT_CASH_REWARD
                    ParticipationCash = 262145 + 12977,  -- GB_YACHTATTACK_MINIMUM_PARTICIPATION_CASH
                    ParticipationRP = 262145 + 12978,    -- GB_YACHTATTACK_MINIMUM_PARTICIPATION_RP
                    CoolDown = 262145 + 12974,           -- GB_YACHTATTACK_COOLDOWN 
                    CashMultiplier = 262145 + 12980      -- GB_YACHTATTACK_EVENT_MULTIPLIER_CASH
                }
            
            },
        }

        -- CLoadingScreens::AreActive
        Memory.Scan("LSAA", "83 3D ?? ?? ?? ?? ?? 75 17 8B 43 20 25", 2, function(scan)
            CLoadingScreens__AreActive = Memory.ReadLong(scan)
        end)
        --cMiniMap::GetWaypointData  -- idk if this is correct but its a nigger to find 
        Memory.Scan("GWD", "48 8D 0D ? ? ? ? 48 98 4C 8B C6", 3, function(scan)
            CMiniMap__GetWaypointData = scan
        end)
    else
        GradientLogger([[

     ______  __     ______   _____  ______ ____   ____  ____  ______   ______   ___        ______
    / ____/ / /    / ____/  / ___/ / ____// __ \ /  _/ / __ \/_  __/  / ____/  ( _ )      / ____/
   / __/   / /    / /_      \__ \ / /    / /_/ / / /  / /_/ / / /    / __/    / __ \/|  / __/   
  / /___  / /___ / __/     ___/ // /___ / _, _/_/ /  / ____/ / /    / /___   / /_/  <   / /___   
 /_____/ /_____//_/       /____/ \____//_/ |_|/___/ /_/     /_/    /_____/   \____/\/  /_____/    

    ]])
        Globals = {
            vehPersonalVehicle = 2740191 + 309,    -- to find search for [0] == veParam0) in am_contact_requests 
            CEOWORK = {
                SightSeer = { 
                    TimeLimit = 262145 + 12955,          -- GB_SIGHTSEER_TIME_LIMIT
                    DefaultCash = 262145 + 12959,        -- GB_SIGHTSEER_DEFAULT_CASH_REWARD
                    ParticipationCash = 262145 + 12961,  -- GB_SIGHTSEER_MINIMUM_PARTICIPATION_CASH
                    ParticipationRP = 262145 + 12962,    -- GB_SIGHTSEER_MINIMUM_PARTICIPATION_RP
                    CoolDown = 262145 + 12956,           -- GB_SIGHTSEER_COOLDOWN
                    CashMultiplier = 262145 + 12964      -- GB_SIGHTSEER_EVENT_MULTIPLIER_CASH
                },
                YachtAttack = { 
                    TimeLimit = 262145 + 12970,         -- GB_YACHTATTACK_TIME_LIMIT
                    DefaultCash = 262145 + 12975,       -- GB_YACHTATTACK_DEFAULT_CASH_REWARD
                    ParticipationCash = 262145 + 12977, -- GB_YACHTATTACK_MINIMUM_PARTICIPATION_CASH
                    ParticipationRP = 262145 + 12978,   -- GB_YACHTATTACK_MINIMUM_PARTICIPATION_RP
                    CoolDown = 262145 + 12974,          -- GB_YACHTATTACK_COOLDOWN
                    CashMultiplier = 262145 + 12980,    -- GB_YACHTATTACK_EVENT_MULTIPLIER_CASH
                }
            },
        }

        -- CLoadingScreens::AreActive
        Memory.Scan("LSAA", "C7 05 ? ? ? ? ? ? ? ? 80 3D ? ? ? ? ? 74 ? C7 05 ? ? ? ? ? ? ? ? E9", 2, function(Long)
            CLoadingScreens__AreActive = Memory.ReadLong(Long) 
        end)
        --cMiniMap::GetWaypointData  -- idk if this is correct but its a nigger to find 
        Memory.Scan("GWD", "48 8D 0D ? ? ? ? C6 44 08 ? ? 48 83 C4", 3, function(scan)
            CMiniMap__GetWaypointData = scan
        end)
    end


    function waitForGameLoad()
        while true do
            if not DLC.GET_IS_LOADING_SCREEN_ACTIVE() or DLC.GET_IS_INITIAL_LOADING_SCREEN_ACTIVE() and CLoadingScreens__AreActive == 0 and SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("maintransition")) > 0 and not NETWORK.NETWORK_IS_PLAYER_ACTIVE(GTA.GetLocalPlayerId()) then
                break
            end 
            Script.Yield(100)
        end
    end

    Script.QueueJob(function()
        waitForGameLoad()
    end)    

    function MPX()
        local found, MPXENUM = Stats.GetInt(joaat("MPPLY_LAST_MP_CHAR"))
        return "MP" .. MPXENUM .. "_"
    end

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
    FeatAdd(joaat("Stats to change Combo"), "Game Award Stats", eFeatureType.Combo, ""):SetList(GameAwardsComboTable):SetListIndex(0)

    FeatAdd(joaat("Stats Int input"), "Game Award Stats Int", eFeatureType.InputInt, ""):SetMinValue(1):SetMaxValue(999999999):SetValue(42069)

    FeatAdd(joaat("Change Stat Value"), "Change Selected Stat Value", eFeatureType.Button, "", function()
        local selectedStat = FeatureMgr.GetFeature(joaat("Stats to change Combo")):GetListIndex() + 1
        local Stat    = GameAwardsTable[selectedStat] and GameAwardsTable[selectedStat].Stat or ""
        local valuetoChange = FeatureMgr.GetFeature(joaat("Stats Int input")):GetIntValue()
        local hashedStat = joaat(MPX() .. Stat)
        Stats.SetInt(hashedStat, valuetoChange)
    end)

    FeatAdd(joaat("SightSeerRig"), "Sightseer Rig", eFeatureType.Toggle, "", function(feat)
        if feat:IsToggled() then 
            SetGlobalInt(Globals.CEOWORK.SightSeer.TimeLimit, 100)
            SetGlobalInt(Globals.CEOWORK.SightSeer.DefaultCash, 100000)
            SetGlobalInt(Globals.CEOWORK.SightSeer.ParticipationCash, 50000)
            SetGlobalInt(Globals.CEOWORK.SightSeer.ParticipationRP, 200000)
            SetGlobalInt(Globals.CEOWORK.SightSeer.CoolDown, 100)
            SetGlobalFloat(Globals.CEOWORK.SightSeer.CashMultiplier, 2.0)
        else
            UndoGlobalFloat(Globals.CEOWORK.SightSeer.CashMultiplier)
            UndoGlobalInt(Globals.CEOWORK.SightSeer.DefaultCash)
            UndoGlobalInt(Globals.CEOWORK.SightSeer.TimeLimit)
            UndoGlobalInt(Globals.CEOWORK.SightSeer.CoolDown)
            UndoGlobalInt(Globals.CEOWORK.SightSeer.ParticipationCash)
            UndoGlobalInt(Globals.CEOWORK.SightSeer.ParticipationRP)
        end
    end)

    FeatAdd(joaat("YachtAttackRig"), "Yacht Attack Rig", eFeatureType.Toggle, "", function(feat)
        if feat:IsToggled() then
            SetGlobalInt(Globals.CEOWORK.YachtAttack.TimeLimit, 100)
            SetGlobalInt(Globals.CEOWORK.YachtAttack.DefaultCash, 100000)
            SetGlobalInt(Globals.CEOWORK.YachtAttack.ParticipationCash, 50000)
            SetGlobalInt(Globals.CEOWORK.YachtAttack.ParticipationRP, 200000)
            SetGlobalInt(Globals.CEOWORK.YachtAttack.CoolDown, 100)
            SetGlobalFloat(Globals.CEOWORK.YachtAttack.CashMultiplier, 2.0)
        else
            UndoGlobalFloat(Globals.CEOWORK.YachtAttack.CashMultiplier)
            UndoGlobalInt(Globals.CEOWORK.YachtAttack.DefaultCash)
            UndoGlobalInt(Globals.CEOWORK.YachtAttack.TimeLimit)
            UndoGlobalInt(Globals.CEOWORK.YachtAttack.CoolDown)
            UndoGlobalInt(Globals.CEOWORK.YachtAttack.ParticipationCash)
            UndoGlobalInt(Globals.CEOWORK.YachtAttack.ParticipationRP)
        end
    end)

    FeatAdd(joaat("SHSTEAL"), "Better Force Script Host", eFeatureType.Toggle,
        "Better version of Cherax's force script host. Useful for script host battles between modders.", function(feat)
            if feat:IsToggled() then
                while feat:IsToggled() do
                    local localplayer = GTA.GetLocalPlayerId()
                    local tags = Players.GetTags(localplayer) or ""
                    local hasSHTag = tags:find("SH") ~= nil
                    if not hasSHTag then
                        local forceSHFeature = GetFname("Force Script Host")
                        if forceSHFeature then
                            forceSHFeature:TriggerCallback()
                        else
                            GUI.AddToast("Error", "Force Script Host feature not found!", 5000, eToastPos.TOP_RIGHT)
                            break
                        end
                    end
                    Script.Yield(100)
                end
            end
        end)

    FeatAdd(joaat("Forcequit"), "force quit to SP", eFeatureType.Button, "Force yourself from the clouds, to SinglePlayer (basically cherax's super bail feature)", function()
        NETWORK.SHUTDOWN_AND_LOAD_MOST_RECENT_SAVE()
    end)

    FeatAdd(joaat("discordInv1"), "Discord Invite", eFeatureType.Button, "Join the discord", function()
        ImGui.SetClipboardText("discord.gg/hXPJEgG25N")
        GUI.AddToast("Elf Script", "Discord Invite link copied to clipboard!", 5000, eToastPos.TOP_RIGHT)
    end)

    featureCooldown = false

    function startFeatureCooldown()
        featureCooldown = true
        Script.QueueJob(function()
            Script.Yield(12000)
            featureCooldown = false
        end)
    end

    function isFeatureOnCooldown()
        return featureCooldown
    end
    isvehfeatureon = false
    
    function getPlayerPed()
        return GTA.PointerToHandle(GTA.GetLocalPlayerId())
    end

    function GetPersonalVehicle()
        return ScriptGlobal.GetInt(Globals.vehPersonalVehicle)
    end


    FeatureMgr.AddFeature(Utils.Joaat("tpintopersonalveh"), "tp into personal veh", eFeatureType.Button, "", function()
        local personalveh = GetPersonalVehicle()
        PED.SET_PED_INTO_VEHICLE(GTA.GetLocalPed(), personalveh, 1)
    end)

    Utils.GetPlayer = function(playertype)
        local localped 
        if playertype == localped then 
            return getPlayerPed()
        else
            return GTA.HandleToPointer(Utils.GetSelectedPlayer())
        end
    end

    function GetVehicle()
        return GTA.HandleToPointer(GTA.GetLocalVehicle())
    end

    function GetPlayerCar()
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(target, false)
        if vehicle and PED.IS_PED_IN_ANY_VEHICLE(target, true) then
            return vehicle
        end
    end

    local toastQueue = {}
    ShowGlowNotification = function(msg, duration, r, g, b)
        table.insert(toastQueue, {
            msg = msg,
            r = r or 255,
            g = g or 255,
            b = b or 255,
            start = Time.GetEpocheMs(),
            duration = duration or 3000
        })
    end

    EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
        local now = Time.GetEpocheMs()
        local screenX, screenY = ImGui.GetDisplaySize()

        local toastHeight = 75      
        local spacing = 10
        local baseY = screenY / 2 + 350

        local remove = {}

        for i, toast in ipairs(toastQueue) do
            local elapsed = now - toast.start
            if elapsed > toast.duration then
                table.insert(remove, i)
            else
                local pulse = 0.5 + 0.5 * math.sin(ImGui.GetTime() * 4.2)
                local alpha = math.floor(180 + 75 * pulse)
                local windowAlpha = 0.12 + 0.45 * pulse
                local r = 1
                local g = 0
                local b = 0
                local a = alpha / 255

                local screenX, screenY = ImGui.GetDisplaySize()
                ImGui.SetNextWindowPos(screenX / 2, screenY / 2 + 350, ImGuiCond.Always, 0.5, 0.5)
                ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 12, 12)
                ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 0)
                ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 10)
                ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 14)

                ImGui.PushStyleColor(ImGuiCol.WindowBg, 0, 0, 0, windowAlpha) 
                ImGui.PushStyleColor(ImGuiCol.Text, 1, 1, 1, a)                      
                ImGui.PushStyleColor(ImGuiCol.Border, r, g, b, 0.25)                
                ImGui.PushStyleColor(ImGuiCol.FrameBg, 1, 0.0, 0.15, 0.4)        
                ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, r, g, b, 0.1)
                ImGui.PushStyleColor(ImGuiCol.FrameBgActive, r, g, b, 0.2)
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram, r, g, b, 1.0)          
                ImGui.PushStyleColor(ImGuiCol.PlotHistogramHovered, r, g, b, 1.0)
                ImGui.PushStyleColor(ImGuiCol.ChildBg, r * 0.2, g * 0.2, b * 0.2, 0.3)

                if ImGui.Begin("CyberToast##12", true,
                    ImGuiWindowFlags.NoTitleBar |
                    ImGuiWindowFlags.AlwaysAutoResize |
                    ImGuiWindowFlags.NoScrollbar |
                    ImGuiWindowFlags.NoInputs |
                    ImGuiWindowFlags.NoSavedSettings)
                then
                    ImGui.PushStyleColor(ImGuiCol.Text, TextColor1:GetColor())
                    ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 6)
                    ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Elf Menu")) / 2)
                    ImGui.Text("Elf Menu")
                    ImGui.PopStyleColor()
                    ImGui.Text(toast.msg)

                    local progress = 1.0 - (elapsed / toast.duration)
                    local availW = ImGui.GetContentRegionAvail()
                    ImGui.ProgressBar(progress, availW, 4, "")
                end

                ImGui.PopStyleColor(9)
                ImGui.PopStyleVar(4)
                ImGui.End()
            end
        end

        for i = #remove, 1, -1 do
            table.remove(toastQueue, remove[i])
        end
    end)

  
    licensePlate = {
        unitSpeed = 2.23694,
        speedUnit = "MPH",
        cachedPlate = nil
    }

    FeatAdd(joaat("SpeedPlateKMH"), "Speed Plate", eFeatureType.Toggle, "Changes your license plate to your current speed.", function(f)
        while f:IsToggled() do
            local vehicle = GTA.PointerToHandle(GTA.GetLocalVehicle())
            local entitySpeed = math.floor(ENTITY.GET_ENTITY_SPEED(vehicle) * licensePlate.unitSpeed)

            if not licensePlate.cachedPlateText then
                licensePlate.cachedPlateText = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(vehicle)
            end
            
            local plateText = (entitySpeed > 100) and (entitySpeed .. "  " .. licensePlate.speedUnit) or (entitySpeed .. " " .. licensePlate.speedUnit)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, plateText)
            Script.Yield(10)
        end
        if not f:IsToggled() then
            if licensePlate.cachedPlateText then
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, licensePlate.cachedPlateText)
                licensePlate.cachedPlateText = nil
            end
        end 
    end)

    FeatAdd(joaat("SpeedPlateUnits"), "Unit Type", eFeatureType.Combo, "", function(feature)
        if feature:GetListIndex() == 0 then
            licensePlate.unitSpeed = 2.23694
            licensePlate.speedUnit = "MPH"
        elseif feature:GetListIndex() == 1 then
            licensePlate.unitSpeed = 3.6
            licensePlate.speedUnit = "KMH"
        end
    end):SetList({"MPH", "KMH"})

    FeatAdd(joaat("getbanstatus1"), "Check Account ROS Privilege", eFeatureType.Button, "", function(feat)
        if NETWORK.NETWORK_HAS_ROS_PRIVILEGE(Utils.GetSelectedPlayer()) == false then
            GradientLogger("that Account is Banned!")
        else
           GradientLogger("that Account is Unbanned!")
        end
    end)
    
    FeatAdd(
        joaat("LicensePlateScroller"),
        "Scrolling License Plate",
        eFeatureType.Toggle,
        "Automatically scrolls through custom text on the vehicle license plate",
        function(feat)
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
            if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) or not ENTITY.DOES_ENTITY_EXIST(vehicle) then
                FeatureMgr.ResetFeature(joaat("LicensePlateScroller"))
                GUI.AddToast("Elf Script", "Feature disabled. Get in a vehicle to use this feature", 5000,
                    eToastPos.TOP_RIGHT)
                return
            end

            local customlicTexts = {
                { '       ', '      T',  '     Th',  '    Tha',  '   Than',  '  Thank',  ' Thanks',  'Thanks ',  'hanks f',   'anks fo',   'nks for',   'ks for ',   's for u',   ' for us',   'for usi',   'or usin',  'r using',  ' using ',  'using E',  'sing El',  'ing Elf',  'ng Elf ',  'g Elf S',  ' Elf Sc',  'Elf Scr',  'lf Scri',  'f Scrip', ' Script',  'Script!',  'cript! ',  'ript!  ', 'ipt!   ', 'pt!    ', 't!     ', '!      ', '       ' },
                { ' ',       '       C', '      CH', '     CHE', '    CHER', '   CHERA', '  CHERAX', ' CHERAX ', 'CHERAX O',  'HERAX ON',  'ERAX ON ',  'RAX ON T',  'AX ON TO',  'X ON TOP',  ' ON TOP ',  'ON TOP  ', 'N TOP   ', ' TOP    ', 'TOP     ', 'OP      ', 'P       ', ' ',        'CHERAX',   ' ',        ' VIP',     ' ',        'CHERAX',  ' ',        ' VIP',     ' ',        'CHERAX',  ' ',       ' VIP' },
                { ' ',       '       4', '      42', '     420', '    420 ', '   420 S', '  420 SA', ' 420 SAD', '420 SAD  ', '20 SAD   ', '0 SAD    ', ' SAD     ', 'SAD      ', 'AD       ', 'D        ', ' ',        '999',      'SAD',      '999',      'SAD',      '999',      'SAD' },
                { '       ', '      H',  '     He',  '    Hel',  '   Hell',  '  Hello',  ' Hello ',  'Hello M',  'ello Mo',   'llo Mon',   'lo Monk',   'o Monke',   ' Monkey',   'Monkey ',   'onkey H',   'nkey Ho',  'key How',  'ey Hows',  'y Hows ',  ' Hows i',  'Hows it',  'ows it ',  'ws it h',  's it ha',  ' it han',  'it hang',  't hangi', ' hanging', 'hanging?', 'anging? ', 'nging? ', 'ging?  ', 'ing?   ', 'ng?    ', 'g?     ', '?      ', '       ' },
                { '       ', '      G',  '     Go',  '    Goo',  '   Good',  '  Good ',  ' Good M',  'Good Mo',  'ood Mor',   'od Morn',   'd Morni',   ' Morning',  'Morning',   'orning ',   'rning V',   'ning Vi',  'ing Vie',  'ng Viet',  'g Vietn',  ' Vietnam', 'Vietnam',  'ietnam ',  'tnam   ',  'nam    ',  'am     ',  'm      ',  '       ' },
                { '       ', '      R',  '     Ru',  '    Run',  '   Run!',  '  Run! ',  ' Run F',   'Run Fo',   'un For',    'n Fore',    ' Forest',   'Forest ',   'orest R',   'rest Ru',   'est Run',   'st Run ',  't Run  ',  ' Run   ',  'Run    ',  'un     ',  'n      ',  '       ' },
                { '       ', '      D',  '     Do',  '    Don',  '   Dont',  '  Dont ',  ' Dont S',  'Dont St',  'ont Sto',   'nt Stop',   't Stop ',   ' Stop B',   'Stop Be',   'top Bel',   'op Beli',   'p Belie',  ' Believ',  'Believe',  'elievin',  'lievin',   'ievin ',   'evin  ',   'vin   ',   'in    ',   'n    ',    '      ',   '       ' },
                { '       ', '      C',  '     Ch',  '    Che',  '   Chec',  '  Check',  ' Check ',  'Check T',  'heck Th',   'eck Tho',   'ck Those',  'k Those ',  ' Those C',  'Those Cl',  'hose Clo',  'ose Clou', 'se Cloud', 'e Clouds', ' Clouds!', 'Clouds! ', 'louds!  ', 'ouds!   ', 'uds!    ', 'ds!     ', 's!      ', '!       ', '       ' },
                { '       ', '      W',  '     We',  '    Wer',  '   Were',  '  Were ',  ' Were n',  'Were ne',  'ere nev',   're neve',   'e never',   ' never ',   'never g',   'ever go',   'ver gon',   'er gonn',  'r gonna',  ' gonna ',  'gonna g',  'onna gi',  'nna giv',  'na give',  'a give ',  ' give y',  'give yo',  'ive you',  've you ', 'e you u',  ' you up',  'you up ',  'ou up  ', 'u up   ', ' up    ', 'up     ', 'p      ', '       ', '       ', '      N', '     Ne', '    Nev', '   Neve', '  Never', ' Never ', 'Never g', 'Never go', 'ever gon', 'ver gonn', 'er gonna', 'r gonna ', ' gonna l', 'gonna le', 'onna let', 'nna let ', 'na let ', 'a let y', ' let yo', 'let you', 'et you ', 't you d', ' you do', 'you dow', 'ou down', 'u down ', ' down  ', 'down   ', 'own    ', 'wn     ', 'n      ', '       ' },
            }

            local textIndex = 1
            local subIndex = 1
            local cachedPlateText = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(vehicle)
            local function LicensePlateLooper()
                if not feat:IsToggled() then
                    return false
                end

                local currentText = customlicTexts[textIndex][subIndex]
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, currentText)

                subIndex = subIndex + 1
                if subIndex > #customlicTexts[textIndex] then
                    subIndex = 1
                    textIndex = (textIndex % #customlicTexts) + 1
                end

                Script.Yield(200)
                return true
            end
            if feat:IsToggled() then 
                Script.RegisterLooped(LicensePlateLooper)
            else
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, cachedPlateText)
            end
        end
    )

    
    FeatAdd(joaat("flyingBroomstick"), "Spawn Flying Broomstick", eFeatureType.Button, "Press to spawn a flying broomstick.", function()
        local playerPed = GTA.PointerToHandle(GTA.GetLocalPed())
        local playerPos = V3.New(ENTITY.GET_ENTITY_COORDS(playerPed, true))
        
        local Broomstick = GTA.CreateObject(joaat("prop_tool_broom"), playerPos.x, playerPos.y, playerPos.z + 1, true, false)
        local mk2 = GTA.SpawnVehicle(joaat("oppressor2"), playerPos.x, playerPos.y, playerPos.z + 1, 9, true, false)
        PED.SET_PED_INTO_VEHICLE(playerPed, mk2, -1)
        ENTITY.SET_ENTITY_VISIBLE(mk2, 0, false)

        ENTITY.ATTACH_ENTITY_TO_ENTITY(
            Broomstick,
            mk2,0, 
            2.980232e-08, 
            -0.1599999, 
            0.12000008, 
            -80.0, 0.0, 0.0,  
            false, false, false, 
            false, 0, true, false 
        )
    end)

    drawmarker = FeatAdd(joaat("DrawCone"), "Draw Marker", eFeatureType.Toggle,
        "Toggles whether or not you show the things below the waypoint line")
    randomwpcolor = FeatAdd(joaat("RandomColorwp"), "Random Colors?", eFeatureType.Toggle,
        "Toggles whether or not you have Random Colors on the cones under the waypoint line")

    linesforwp = FeatAdd(joaat("linesforwp"), "How many lines?", eFeatureType.SliderInt,
        "how many lines are shown in the waypoint line (WIP)")
    linesforwp:SetMinValue(1)
    linesforwp:SetMaxValue(10)
    linesforwp:SetValue(1)
    WPColor = FeatAdd(joaat("WPColor"), "Waypoint Line Color", eFeatureType.InputColor4,
        "Sets the color of the waypoint line")
    WPColor:SetColor(0, 0, 255, 255)

    FeatAdd(joaat("waypointline"), "Waypoint Line", eFeatureType.Toggle, "Draws a direct line to the waypoint.",
        function(feat)
            if feat:IsToggled() then
                GetFname("Auto Teleport To Waypoint"):SetBoolValue(false)
            else
                GetFname("Auto Teleport To Waypoint"):SetBoolValue(true)
            end
        end)
    zvall = FeatAdd(joaat("zvaluee"), "z Offset from Ground", eFeatureType.SliderInt, "sets the z Offset from Ground")
    zvall:SetMinValue(1)
    zvall:SetMaxValue(10)
    zvall:SetIntValue(1)
    markeroffset = FeatAdd(joaat("markeroffset"), "marker offset", eFeatureType.SliderFloat,
        "set the offset of the marker to the waypoint line")
    markeroffset:SetMinValue(1.0)
    markeroffset:SetMaxValue(10.0)
    markeroffset:SetFloatValue(3.180)

    xrott = FeatAdd(joaat("xrott"), "X rot", eFeatureType.SliderFloat, "Set the x rotation of marker")
    xrott:SetMinValue(1.0)
    xrott:SetMaxValue(360.0)
    xrott:SetFloatValue(0.0)

    yrott = FeatAdd(joaat("yrott"), "Y Rot", eFeatureType.SliderFloat, "change the y rotation of the marker")
    yrott:SetMinValue(1.0)
    yrott:SetMaxValue(360.0)
    yrott:SetFloatValue(180)

    scalex = FeatAdd(joaat("scalex"), "scale X", eFeatureType.SliderFloat, "change the scale of the marker")
    scalex:SetMinValue(1.0)
    scalex:SetMaxValue(10.0)
    scalex:SetFloatValue(1.0)

    scaley = FeatAdd(joaat("scaley"), "scale Y", eFeatureType.SliderFloat, "change the scale of the marker")
    scaley:SetMinValue(1.0)
    scaley:SetMaxValue(10.0)
    scaley:SetFloatValue(1.0)
    scalez = FeatAdd(joaat("scalez"), "scale Z", eFeatureType.SliderFloat, "change the scale of the marker")
    scalez:SetMinValue(1.0)
    scalez:SetMaxValue(10.0)
    scalez:SetFloatValue(1.0)
    MarkerColor = FeatAdd(joaat("MarkerColor"), "Marker Color", eFeatureType.InputColor4, "change the Marker Color")
    MarkerColor:SetColor(0, 0, 255, 255)
    bobupndown = FeatAdd(joaat("bobchecker"), "bob up and down", eFeatureType.Toggle,
        "toggle wether the marker bob up and down")

    markerTypes = {
        { name = "Upside Down Cone",               value = 0 },
        { name = "Vertical Cylinder",              value = 1 },
        { name = "Thick Chevron Up",               value = 2 },
        { name = "Thin Chevron Up",                value = 3 },
        { name = "Checkered Flag Rect",            value = 4 },
        { name = "Checkered Flag Circle",          value = 5 },
        { name = "Vertical Circle",                value = 6 },
        { name = "Plane Model",                    value = 7 },
        { name = "Lost MC Dark",                   value = 8 },
        { name = "Lost MC Light",                  value = 9 },
        { name = "Number 0",                       value = 10 },
        { name = "Number 1",                       value = 11 },
        { name = "Number 2",                       value = 12 },
        { name = "Number 3",                       value = 13 },
        { name = "Number 4",                       value = 14 },
        { name = "Number 5",                       value = 15 },
        { name = "Number 6",                       value = 16 },
        { name = "Number 7",                       value = 17 },
        { name = "Number 8",                       value = 18 },
        { name = "Number 9",                       value = 19 },
        { name = "Chevron Up x1",                  value = 20 },
        { name = "Chevron Up x2",                  value = 21 },
        { name = "Chevron Up x3",                  value = 22 },
        { name = "Horizontal Circle Fat",          value = 23 },
        { name = "Replay Icon",                    value = 24 },
        { name = "Horizontal Circle Skinny",       value = 25 },
        { name = "Horizontal Circle Skinny Arrow", value = 26 },
        { name = "Horizontal Split Arrow Circle",  value = 27 },
        { name = "Debug Sphere",                   value = 28 },
        { name = "Dollar Sign",                    value = 29 },
        { name = "Horizontal Bars",                value = 30 },
        { name = "Wolf Head",                      value = 31 }
    }

    markerNames = {}
    for i, marker in ipairs(markerTypes) do
        table.insert(markerNames, marker.name)
    end

    selectedMarkerType = markerTypes[1].value

    markerTypeCombo = FeatAdd(joaat("MarkerType"), "Marker Type", eFeatureType.Combo,
        "Choose the marker type to render below the waypoint line")
    markerTypeCombo:SetList(markerNames)
    markerTypeCombo:SetListIndex(0)

    markerTypeCombo:TriggerCallback(function(feat)
        selectedMarkerType = markerTypes[feat:GetValue() + 1].value
    end)

    lastColorChange = 0
    headerColor = { 0, 255, 0, 255 }

    function onPresent1()
        if not FeatureMgr.IsFeatureEnabled(joaat("waypointline")) or not CMiniMap__GetWaypointData then
            return
        end

        local points = Memory.ReadLong(CMiniMap__GetWaypointData)
        local count = Memory.ReadUInt(CMiniMap__GetWaypointData + 68)

        if not points or count <= 1 then
            return
        end

        local currentTime = Time.GetEpocheMs()

        if currentTime - lastColorChange > 400 then
            headerColor = { math.random(1, 255), math.random(1, 255), math.random(1, 255), 255 }
            lastColorChange = currentTime
        end

        local bob = bobupndown:GetBoolValue()
        local numlines = linesforwp:GetIntValue()
        local zval = zvall:GetIntValue()
        local selectedIndex = markerTypeCombo:GetListIndex() + 1
        local markerType    = markerTypes[selectedIndex] and markerTypes[selectedIndex].value or 0
        local markerColor   = randomwpcolor:IsToggled() and headerColor or { MarkerColor:GetColor() }
        local markeroffset  = markeroffset:GetFloatValue()
        local xrot, yrot    = xrott:GetFloatValue(), yrott:GetFloatValue()
        local scx, scy, scz = scalex:GetFloatValue(), scaley:GetFloatValue(), scalez:GetFloatValue()

        for i = 1, count - 1 do
            local point = Memory.ReadV3(points + i * 16)
            local nextPoint = Memory.ReadV3(points + (i + 1) * 16)

            if point and nextPoint then
                local lineColor = FeatureMgr.IsFeatureEnabled(joaat("RandomColorwp")) and headerColor or { WPColor:GetColor() }

                for j = -numlines, numlines do
                    if j ~= 0 then
                        local offset = j * 0.05
                        GRAPHICS.DRAW_LINE(
                            point.x + offset, point.y + offset, point.z + zval,
                            nextPoint.x + offset, nextPoint.y + offset, nextPoint.z + zval,
                            lineColor[1], lineColor[2], lineColor[3], lineColor[4]
                        )
                    end
                end

                if drawmarker:IsToggled() then
                    GRAPHICS.DRAW_MARKER(
                        markerType, point.x, point.y, point.z + zval + markeroffset - 2.5,
                        0, 0, 0, xrot, yrot, 0,
                        scx, scy, scz,
                        markerColor[1], markerColor[2], markerColor[3], markerColor[4],
                        bob, true, false, false, 0, 0, 0
                    )
                end
            end
        end
    end
    Script.RegisterLooped(onPresent1)


    FeatAdd(
        joaat("patriottoggle"),
        "Set Vehicle for Patriotic Tire Smoke",
        eFeatureType.Toggle,
        "Applies or removes patriotic smoke from your current vehicle.",
        function(feat)
            if not PED.IS_PED_IN_ANY_VEHICLE(getPlayerPed(), false) then
                ShowGlowNotification("Feature disabled. Get in a vehicle to use this feature", 5000)
                return FeatureMgr.ResetFeature(joaat("patriottoggle"))
            end
            if feat:IsToggled() then
                if GetVehicle() and GetVehicle() ~= 0 then
                    if not VEHICLE.GET_VEHICLE_MOD_KIT(GetVehicle()) then
                        VEHICLE.SET_VEHICLE_MOD_KIT(GetVehicle(), 0)
                    end
                    VEHICLE.TOGGLE_VEHICLE_MOD(GetVehicle(), 20, true)

                    while feat:IsToggled() do
                        Script.Yield(500)
                        VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(GetVehicle(), 0, 0, 0)
                        Script.Yield(500)
                    end
                end
            else
                if GetVehicle() and GetVehicle() ~= 0 then
                    VEHICLE.TOGGLE_VEHICLE_MOD(GetVehicle(), 20, false)
                    VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(GetVehicle(), 255, 255, 255)
                end
            end
        end
    )

    FeatAdd(
        joaat("patriotbutton"),
        "Give Vehicle Patriotic Tire Smoke",
        eFeatureType.Button,
        "Applies patriotic smoke to your current vehicle permanently.",
        function(feat)
            local vehicle = GetVehicle()
            if not VEHICLE.GET_VEHICLE_MOD_KIT(vehicle) then
                VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
            end
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 20, true)
            if vehicle and vehicle ~= 0 then
                VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, 0, 0, 0)
            end

            if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), false) then
                ShowGlowNotification("Feature disabled. Get in a vehicle to use this feature", 5000)
                return FeatureMgr.ResetFeature(joaat("patriottoggle"))
            end
        end
    )

    selectedRID = FeatAdd(joaat("AddModderRID"), "RID or Name", eFeatureType.InputText, "Your selected RID or Name")
    selectedReason = FeatAdd(joaat("ReasonModderRID"), "Reason", eFeatureType.InputText, "Your Selected Reasoning")
    FeatAdd(joaat("ChangeModderRID"), "Change Modder Reason", eFeatureType.Button, "Changes your selected person's reason for modding.", function()
        local playerRID = selectedRID:GetStringValue()
        local PlayerReason = selectedReason:GetStringValue()
        if ModderDB.GetModderDetections(playerRID) and PlayerReason ~= "" and playerRID ~= "" then
            ShowGlowNotification("Successfully changed " .. playerRID .. " Modder Reason to " .. PlayerReason, 5000)
            ModderDB.AddModder(playerRID, PlayerReason)
        else
            if PlayerReason ~= "" and playerRID ~= "" then
                ShowGlowNotification("You'll need to add " .. playerRID .. " to the ModderDB before changing their reason" .. PlayerReason, 5000)
            else
                ShowGlowNotification("Invalid arguments" .. PlayerReason, 5000)
            end
        end
    end)

    FeatAdd(joaat("RemoveModderRID"), "Remove Modder Reason", eFeatureType.Button, "Removes the selected player's modder reason from the database.", function()
        local playerRID = selectedRID:GetStringValue()
        local PlayerReason = selectedReason:GetStringValue()
        if ModderDB.GetModderDetections(playerRID) then
            ModderDB.RemoveModder(playerRID)
            ShowGlowNotification("Successfully removed " .. playerRID .. " from ModderDB" .. PlayerReason, 5000)
        else
            ShowGlowNotification("Player " .. playerRID .. " is not in the ModderDB" ..
            PlayerReason, 5000)
        end
    end)
    
FeatAdd(
    joaat("FlashTime"),
    "Flash time",
    eFeatureType.Toggle,
    "You are now the fastest man alive when you use this feature\n(not literally its a reference to the flash obviously :P)",
    function(feat)          
        local particleDict = "scr_rcbarry2"
        local particleName = "sp_clown_appear_trails"
        local function flash()
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(GTA.GetLocalPlayerId())
  

            local bones = {
                { name = "SKEL_ROOT", offset = {0.0, 0.0, 0.0} },
                { name = "SKEL_L_Foot", offset = {0.1, 0.0, -0.6} },
                { name = "SKEL_R_Foot", offset = {-0.1, 0.0, -0.6} },
                { name = "SKEL_Spine_Root", offset = {0.0, 0.0, 0.2} },
                { name = "SKEL_L_Hand", offset = {0.35, 0.0, 0.0} },
                { name = "SKEL_R_Hand", offset = {-0.35, 0.0, 0.0} },
                { name = "MH_R_Elbow", offset = {0.0, 0.0, 0.0} },
                { name = "SKEL_Head", offset = {0.0, 0.0, 0.7} }
            }

            local lastPlayTime = 0

            while feat:IsToggled() do
                STREAMING.REQUEST_NAMED_PTFX_ASSET(particleDict)
                FeatureMgr.GetFeatureByName("Run Speed"):SetBoolValue(true):SetFloatValue(6.000)
                FeatureMgr.GetFeatureByName("No Ragdoll"):SetBoolValue(true)
                FeatureMgr.GetFeatureByName("Super Jump"):SetBoolValue(true)
                GRAPHICS.SET_TIMECYCLE_MODIFIER("RaceTurboDark")
                GRAPHICS.SET_TIMECYCLE_MODIFIER_STRENGTH(0.25)
                MISC.SET_GRAVITY_LEVEL(0.0)

                local currentTime = Time.GetEpocheMs()
                if currentTime - lastPlayTime >= 150 then 
                    local pedcoordsx, pedcoordsy, pedcoordsz = ENTITY.GET_ENTITY_COORDS(playerPed, true)
                    local pedHeading = ENTITY.GET_ENTITY_HEADING(playerPed)
                    for _, boneData in ipairs(bones) do
                        local boneIndex = PED.GET_PED_BONE_INDEX(playerPed, joaat(boneData.name))

                        GRAPHICS.USE_PARTICLE_FX_ASSET(particleDict)
                        GRAPHICS.START_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(
                            particleName,
                            playerPed,
                            boneData.offset[1], boneData.offset[2], boneData.offset[3],
                            0.0, 0.0, 0.0,
                            boneIndex,
                            2,
                            false, false, false
                        )
                    end
                    lastPlayTime = currentTime
                end

                Script.Yield()
            end

            GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
            MISC.SET_GRAVITY_LEVEL(1.0)
            FeatureMgr.GetFeatureByName("Run Speed"):SetBoolValue(false):Reset()
            FeatureMgr.GetFeatureByName("No Ragdoll"):SetBoolValue(false)
            FeatureMgr.GetFeatureByName("Super Jump"):SetBoolValue(false)
            TASK.CLEAR_PED_TASKS(playerPed)
        end
        flash()
    end) 

    function loadModel(hash)
        Script.QueueJob(function()
            if not STREAMING.HAS_MODEL_LOADED(hash) then
                STREAMING.REQUEST_MODEL(hash)
                while not STREAMING.HAS_MODEL_LOADED(hash) do
                    STREAMING.REQUEST_MODEL(hash)
                    Script.Yield(10)
                end
            end
        end)
    end

    spawnedPeds = {}
    PlayerFeatAdd(
        joaat("Chaos_Crash"),
        "Chaos crash",
        eFeatureType.Toggle,
        "Spawns 30 chaos filled peds, making them the most unpredictable AI in the game.",
        function(feat)
            local pedHash = joaat("MP_M_Freemode_01")
            loadModel(pedHash) 
            local playercoords = V3.New(ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(Utils.GetSelectedPlayer()), true))

            for i = 1, 30 do
                local spawn = V3.New(playercoords.x + math.random(-5, 5), playercoords.y + math.random(-5, 5), playercoords.z + 1)
                local ped = GTA.CreatePed(pedHash, 4, spawn.x, spawn.y, spawn.z, math.random(0, 360), true, true)

                if ped ~= 0 then
                    table.insert(spawnedPeds, ped)
                    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(ped), true)
                    PED.SET_PED_COMPONENT_VARIATION(ped, 11, 555, 0, math.random(1, 1000))
                    ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
                    Script.QueueJob(function()
                        while feat:IsToggled() do
                            PED.SET_PED_COMPONENT_VARIATION(ped, 11, 555, 0, math.random(1, 1000))
                            if math.random(1, 4) == 1 then
                                ENTITY.SET_ENTITY_MAX_SPEED(ped, math.random(10, 100))
                                ENTITY.SET_ENTITY_INVINCIBLE(ped, false)
                                ENTITY.SET_ENTITY_VISIBLE(ped, true, false)
                                ENTITY.SET_ENTITY_COLLISION(ped, true, true)
                                ENTITY.FREEZE_ENTITY_POSITION(ped, false)
                            end

                            if math.random(1, 6) == 1 then
                                local newPosx, newPosy, newPosz = ENTITY.GET_ENTITY_COORDS(
                                PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(Utils.GetSelectedPlayer()), false)
                                ENTITY.SET_ENTITY_COORDS(ped, newPosx + math.random(-5, 5), newPosy + math.random(-5, 5),
                                    newPosz, false, false, false, true)
                            end
                            Script.Yield(3000)
                        end
                    end)

                    Script.QueueJob(function()
                        while feat:IsToggled() do
                            PED.SET_PED_COMPONENT_VARIATION(ped, 11, 555, 0, math.random(1, 1000))
                            local newPos = V3.New(ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(Utils.GetSelectedPlayer()), false))
                            local new = V3.New(newPosx + math.random(-5, 5), newPosy + math.random(-5, 5), newPosz)
                            ENTITY.SET_ENTITY_COORDS(ped, new.x, new.y, new.z, false, false, false, true)
                            ENTITY.SET_ENTITY_HEADING(ped, math.random(0, 360))
                            if math.random(1, 4) == 1 then
                                TASK.TASK_START_SCENARIO_IN_PLACE(ped, "WORLD_HUMAN_PARTYING", 0, true)
                            end
                            Script.Yield(10)
                        end
                    end)
                end
                Script.Yield(100)
            end
            if not feat:IsToggled() then
                for _, ped in ipairs(spawnedPeds) do
                    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ped) do
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
                        Script.Yield()
                    end
                    local mem = Memory.AllocInt()
                    Memory.WriteInt(mem, ped)
                    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mem)
                    PED.DELETE_PED(mem)
                    Memory.Free(mem)
                    spawnedPeds = {}
                end
            end
        end, true
    )

    UID = Cherax.GetUID()
    username = PLAYER.GET_PLAYER_NAME(GTA.GetLocalPlayerId())
    
    -- File: ./Features/Cages.lua
    ---------------------------------------------------------------------------------------

    PlayerFeatAdd(
        joaat("TPALLTOPLAYER"), 
        "Teleport Everything To Player", 
        eFeatureType.Button, 
        "", 
        function(f)
            local playerCoords = V3.New(ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(Utils.GetSelectedPlayer()), true))
            for _, vehicle in pairs(PoolMgr.GetRenderedVehicles()) do 
                local handle = GTA.PointerToHandle(vehicle)       
                ENTITY.SET_ENTITY_COORDS(handle, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false, true)
            end
            for _, object in pairs(PoolMgr.GetRenderedObjects()) do 
                local handle = GTA.PointerToHandle(object)       
                ENTITY.SET_ENTITY_COORDS(handle, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false, true)
            end
            for _, ped in pairs(PoolMgr.GetRenderedPeds()) do
                if ped == GTA.GetLocalPed() then return end  
                local handle = GTA.PointerToHandle(ped)       
                ENTITY.SET_ENTITY_COORDS(handle, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false, true)
            end 
        end
    )
    PlayerFeatAdd(
        joaat("CouchCage"),
        "Get off the couch",
        eFeatureType.Button,
        "Spawn couches around the player in a circle",
        function(feat)
            local playerID = Utils.GetSelectedPlayer()
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerID)
            local pos = V3.New(ENTITY.GET_ENTITY_COORDS(ped, true))

            local objectHash = 3353576388

            loadModel(objectHash)
            

            local radius = 1.3
            local numCouches = 12
            local angleStep = 360.0 / numCouches

            for i = 1, numCouches do
                local angle = math.rad(angleStep * i)
                local xOffset = math.cos(angle) * radius
                local yOffset = math.sin(angle) * radius

                local couch = GTA.CreateObject(objectHash, pos.x + xOffset, pos.y + yOffset, pos.z - 0.3, false, true)
                table.insert(AllThingsForScriptCleanup, couch)
                ENTITY.SET_ENTITY_ROTATION(couch, 0.0, 0.0, angleStep * i, 2, true)

                if i % 3 == 0 then
                    Script.Yield()
                end
            end
            ShowGlowNotification("Couches spawned", 5000)
        end, true
    )

    PlayerFeatAdd(
        joaat("CageSelectedPlayer"),
        "Cage Selected Player",
        eFeatureType.Button,
        "Spawns a cage around the selected player. Will not work if they have anti-cage enabled.",
        function(feat)
            local hash = 1137700900
            local targetPlayerId = Utils.GetSelectedPlayer()
            if not targetPlayerId or not NETWORK.NETWORK_IS_PLAYER_ACTIVE(targetPlayerId) then
                GradientLogger("Invalid or inactive player selected.")
                return
            end
            loadModel(hash)

            local ped = PLAYER.GET_PLAYER_PED(targetPlayerId)
            if ped then
                local coords = V3.New(ENTITY.GET_ENTITY_COORDS(ped, true))
                local cage1 = GTA.CreateObject(hash, coords.x, coords.y, coords.z, true, true)
                ENTITY.SET_ENTITY_ROTATION(cage1, 0.0, -90.0, 0.0, true)
                local cage2 = GTA.CreateObject(hash, coords.x, coords.y, coords.z - 10,true, true)
                ENTITY.SET_ENTITY_ROTATION(cage2, 0.0, 90.0, 0.0, 2, true)
                local cage3 = GTA.CreateObject(hash, coords.x, coords.y, coords.z - 10, true, true)
                ENTITY.SET_ENTITY_ROTATION(cage3, 90.0, 0.0, 0.0, 2, true)
                table.insert(AllThingsForScriptCleanup, cage1)
                table.insert(AllThingsForScriptCleanup, cage2)
                table.insert(AllThingsForScriptCleanup, cage3)
                ShowGlowNotification("Cage spawned around the selected player.", 5000)
            end
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        end, true
    )

    -- File: ./Features/trolling.lua
    --CODE TO BUILD
    --run CMD prompt in folder
    --type in CMD this command
    --lua C:\Users\elfis\OneDrive\Documents\Cherax\Lua\Pubbuild\build.lua

    PlayerFeatAdd(
        joaat("vehiclespam"),
        "Spawn Jumpy vehicles",
        eFeatureType.Button,
        "Spawn 20 vehicles and have them jump around the player",
        function(feat)
            if not isDev then
                if isFeatureOnCooldown() then
                    ShowGlowNotification("Feature is on cooldown. Please wait.", 5000)
                    return
                end
            end
            startFeatureCooldown()
            ShowGlowNotification("Vehicle spam started..", 5000)
            targetPlayer = Utils.GetSelectedPlayer()
            playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetPlayer)
            targetCoordsx, targetCoordsy, targetCoordsz = ENTITY.GET_ENTITY_COORDS(playerPed, false)
            centerX, centerY, centerZ = targetCoordsx, targetCoordsy, targetCoordsz
            radius = 15
            numVehicles = 20
            modelHash = 2272483501
            vehicles = {}

            loadModel(modelHash) 
            for i = 1, numVehicles do
                theta = math.random() * (2 * math.pi)
                phi = math.acos(2 * math.random() - 1)

                x = centerX + radius * math.sin(phi) * math.cos(theta)
                y = centerY + radius * math.sin(phi) * math.sin(theta)
                z = centerZ + radius * math.cos(phi)

                vehicle = GTA.SpawnVehicle(modelHash, x, y, z, 0, true, true)
                ped = GTA.CreatePed(joaat("cs_nigel"), 26, x, y, z, 0, true, true)
                table.insert(AllThingsForScriptCleanup, vehicle)
                table.insert(AllThingsForScriptCleanup, ped)
                if vehicle then
                    table.insert(vehicles, vehicle)
                    ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 0, 0, 0, 1000, 0, 0, 0, 1, true, true, true, true, true)
                    ENTITY.SET_ENTITY_ROTATION(vehicle, 0, 0, 0, 2, true)
                    ENTITY.SET_ENTITY_VELOCITY(vehicle, 0, 0, 0)
                    ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(ped, vehicle, 0, 0, 0, 0, 5 + (2 * i), 0, 0, 0, 0, 0, 0, 1000, true, true, true, true, 2)
                    Script.Yield(25)
                end
            end
            ShowGlowNotification("20 jumpy vehicles spawned around the player.", 5000)
        end, true
    )

    PlayerFeatAdd(
        joaat("fatspam"),
        "spam the fat people",
        eFeatureType.Button,
        "Put the player in the oven",
        function(feat)
            if not isDev then
                if isFeatureOnCooldown() then
                    ShowGlowNotification("Feature is on cooldown. Please wait.", 5000)
                    return
                end
            end
            ShowGlowNotification("Fat dude spam started.", 5000)
            startFeatureCooldown()

            local targetPlayer = Utils.GetSelectedPlayer()
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetPlayer)
            local targetCoordsx, targetCoordsy, targetCoordsz = ENTITY.GET_ENTITY_COORDS(playerPed, false)
            local centerX, centerY, centerZ = targetCoordsx, targetCoordsy, targetCoordsz
            local radius = 10
            local spawned_peds = {}
            local numPeds = 30
            local angleStep = (2 * math.pi) / numPeds
            local modelHash = 3050275044
            local peds = {}

            loadModel(modelHash)

            local object = GTA.CreateObject(878813842, centerX, centerY, centerZ - 0.5, true, true)
            ENTITY.FREEZE_ENTITY_POSITION(object, true)
            ENTITY.SET_ENTITY_ROTATION(object, 0, 0, 90, 0, false)
            local object1 = GTA.CreateObject(878813842, centerX, centerY, centerZ - 0.5, true, true)
            table.insert(AllThingsForScriptCleanup, object1)
            table.insert(AllThingsForScriptCleanup, object)
            ENTITY.FREEZE_ENTITY_POSITION(object1, true)
            Script.Yield(500)
            for i = 1, numPeds do
                local angle = angleStep * (i - 1)
                local x = centerX + radius * math.cos(angle)
                local y = centerY + radius * math.sin(angle)
                local ped = GTA.CreatePed(modelHash, 26, x, y, centerZ, 0)
                if ped then
                    table.insert(peds, ped)
                    table.insert(AllThingsForScriptCleanup, ped)
                    Script.Yield(50)
                    WEAPON.GIVE_WEAPON_TO_PED(ped, 0x63AB0442, 1337, true, true)
                    ENTITY.DETACH_ENTITY(WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(ped), true, true)
                    PED.SET_PED_SHOOTS_AT_COORD(ped, centerX, centerY, centerZ - 1.0, true)
                    PED.SET_PED_SHOOTS_AT_COORD(ped, centerX, centerY, centerZ - 1.0, true)
                end
                table.insert(spawned_peds, ped)
            end
            Script.Yield(50)
            Script.Yield(3000)
            for i = 1, #peds do
                local ped = peds[i]
                while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ped) do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
                    Script.Yield()
                end
                local mem = Memory.AllocInt()
                Memory.WriteInt(mem, ped)
                PED.DELETE_PED(mem)
                Memory.Free(mem)
                Script.Yield()
            end
            ShowGlowNotification("spam ended, area cleared.", 5000)
        end, true
    )

    PlayerFeatAdd(
        joaat("vehiclenuke"),
        "Spawn a nuke",
        eFeatureType.Button,
        "Spawn 20 vehicles in a sphere around the player",
        function(feat)

            if not isDev then
                if isFeatureOnCooldown() then
                    ShowGlowNotification("Feature is on cooldown. Please wait.", 5000)
                    return
                end
            end
            startFeatureCooldown()
            ShowGlowNotification("Vehicle nuke started.", 5000)

            local targetPlayer = Utils.GetSelectedPlayer()
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetPlayer)
            local targetCoords = ENTITY.GET_ENTITY_COORDS(playerPed, false)
            local radius, numVehicles = 5, 20
            local modelHash, towtruck = joaat("comet3"), joaat("metrotrain")

            loadModel(modelHash) 
            loadModel(towtruck)

            for i = 1, numVehicles do
                local theta, phi = math.random() * (2 * math.pi), math.acos(2 * math.random() - 1)
                local x = targetCoords + radius * math.sin(phi) * math.cos(theta)
                local y = targetCoords + radius * math.sin(phi) * math.sin(theta)
                local z = targetCoords + radius * math.cos(phi)

                local vehicle = GTA.SpawnVehicle(modelHash, x, y, z, 0, true, true)
                local vehicle2 = GTA.SpawnVehicle(towtruck, x, y, z, 0, true, true)
                table.insert(AllThingsForScriptCleanup, vehicle)
                table.insert(AllThingsForScriptCleanup, vehicle2)
                if vehicle then
                    ENTITY.SET_ENTITY_COLLISION(vehicle, true, true)
                    ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 0, 0, 0, 1000, 0, 0, 0, 1, true, true, true, true, true)
                    ENTITY.SET_ENTITY_ROTATION(vehicle, 0, 0, 0, 2, true)


                    ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(
                        vehicle2, vehicle, 0, 0, 0, 0, 5 + (2 * i), 0, 0, 0, 0, 0, 0, 1000, true, true, true, true, 2
                    )

                    local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(vehicle)
                    NETWORK.NETWORK_EXPLODE_VEHICLE(vehicle, true, false, netId)

                    Script.Yield()
                end
            end
            ShowGlowNotification("Player has been sucessfully fucked", 5000)
        end, true
    )
    local vehicleModels = { joaat("adder"), joaat("zentorno"), joaat("t20"), joaat("rhino"), joaat("buzzard") }

    PlayerFeatAdd(
        joaat("Chaosnuke"),
        "Spawn a CHAOS NUKE",
        eFeatureType.Button,
        "Spawns 50 crazy vehicles with random explosions and chaos!",
        function(feat)

            if not isDev then
                if isFeatureOnCooldown() then
                    ShowGlowNotification("Feature is on cooldown. Please wait.", 5000)
                    return
                end
            end
            startFeatureCooldown()
            ShowGlowNotification("CHAOS NUKE DEPLOYED", 5000)

            local targetPlayer = Utils.GetSelectedPlayer()
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetPlayer)
            local targetCoords = ENTITY.GET_ENTITY_COORDS(playerPed, false)
            local radius = 10
            local numVehicles = 50
            for i = 1, numVehicles do
                local randomModel = vehicleModels[math.random(#vehicleModels)]
                STREAMING.REQUEST_MODEL(randomModel)
                Script.Yield(0)

                local theta, phi = math.random() * (2 * math.pi), math.acos(2 * math.random() - 1)
                local x = targetCoords + radius * math.sin(phi) * math.cos(theta)
                local y = targetCoords + radius * math.sin(phi) * math.sin(theta)
                local z = targetCoords + radius * math.cos(phi)

                local vehicle = GTA.SpawnVehicle(randomModel, x, y, z, math.random(0, 360), true, true)
                table.insert(AllThingsForScriptCleanup, vehicle)
                if vehicle then
                    local forceX, forceY, forceZ = math.random(-50, 50), math.random(-50, 50), math.random(0, 100)
                    ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, forceX, forceY, forceZ, 0, 0, 0, 1, true, true, true, true, true)

                    local c4 = GTA.CreateObject(joaat("prop_ld_bomb_01"), x, y, z, false, true)
                    table.insert(AllThingsForScriptCleanup, c4)
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(c4, vehicle, 0, 0, 0, 0.5, 0, 0, 0, false, false, true, false, 0, true)

                    Script.QueueJob(function()
                        Script.Yield(math.random(2000, 8000))
                        local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(vehicle)
                        NETWORK.NETWORK_EXPLODE_VEHICLE(vehicle, true, false, netId)
                    end)

                    local pedModel = joaat("a_m_y_skater_01")
                    STREAMING.REQUEST_MODEL(pedModel)
                    local ped = GTA.CreatePed(pedModel, 26, x, y, z, 0, true, true)
                    table.insert(AllThingsForScriptCleanup, ped)
                    PED.SET_PED_INTO_VEHICLE(ped, vehicle, -1)
                    TASK.TASK_VEHICLE_DRIVE_WANDER(ped, vehicle, 100, 786603)
                end
                Script.Yield()
            end
            ShowGlowNotification("? Total Chaos Activated! ?", 5000)
        end, true
    )

    PlayerFeatAdd(
        joaat("aggroRc"),
        "Spawn Aggressive RC Car",
        eFeatureType.Button,
        "Spawns an RC car that aggressively follows and collides with the selected player.",
        function(feat)
            local targetPlayer = Utils.GetSelectedPlayer()
            if not targetPlayer then
                ShowGlowNotification("No player selected!", 5000)
                return
            end

            local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetPlayer)
            local targetCoords = ENTITY.GET_ENTITY_COORDS(targetPed, true)
            local targetHeading = ENTITY.GET_ENTITY_HEADING(targetPed)
            local rcCarHash = joaat("rcbandito")
            local driverHash = joaat("a_m_m_acult_01")

            STREAMING.REQUEST_MODEL(rcCarHash)
            STREAMING.REQUEST_MODEL(driverHash)
            loadModel(rcCarHash) 
            loadModel(driverHash) 

            local rcCar = GTA.SpawnVehicle(rcCarHash, targetCoords + math.random(-3, 3), targetCoords + math.random(-3, 3),
                targetCoords + 1.0, targetHeading, true, true)

            if not ENTITY.DOES_ENTITY_EXIST(rcCar) then
                ShowGlowNotification("Failed to spawn RC car!", 5000)
                return
            end


            ENTITY.SET_ENTITY_INVINCIBLE(rcCar, true)
            VEHICLE.SET_VEHICLE_ENGINE_ON(rcCar, true, true, false)
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(rcCar, true, true)

            local driver = GTA.CreatePed(driverHash, 26, targetCoords, targetCoords, targetCoords, targetHeading, true, true)

            table.insert(AllThingsForScriptCleanup, rcCar)
            table.insert(AllThingsForScriptCleanup, driver)
            if ENTITY.DOES_ENTITY_EXIST(driver) then
                PED.SET_PED_INTO_VEHICLE(driver, rcCar, -1)
                PED.SET_PED_COMBAT_ATTRIBUTES(driver, 5, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(driver, 46, true)
                PED.SET_PED_KEEP_TASK(driver, true)
                PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver, true)
                TASK.SET_DRIVE_TASK_DRIVING_STYLE(driver, 524859)
                PED.SET_DRIVER_ABILITY(driver, 1.0)
                PED.SET_DRIVER_AGGRESSIVENESS(driver, 1.0)
                TASK.TASK_VEHICLE_MISSION_PED_TARGET(driver, rcCar, targetPed, 6, 100.0, 786469, 5.0, 5.0, true)

                Script.QueueJob(function()
                    while ENTITY.DOES_ENTITY_EXIST(rcCar) and ENTITY.DOES_ENTITY_EXIST(driver) and ENTITY.DOES_ENTITY_EXIST(targetPed) do
                        TASK.TASK_VEHICLE_MISSION_PED_TARGET(driver, rcCar, targetPed, 6, 100.0, 786469, 5.0, 5.0, true)
                        Script.Yield(1000)
                    end
                end)
                ShowGlowNotification("Aggressive RC Car deployed!", 5000)
            else
                ShowGlowNotification("Failed to create driver!", 5000)
                ENTITY.DELETE_ENTITY(rcCar)
            end

            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(rcCarHash)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(driverHash)
        end, true
    )

    PlayerFeatAdd(
        joaat("SpawnRCCar"),
        "Spawn Pet RC",
        eFeatureType.Button,
        "Spawns an RC car that follows the player ",
        function(feat)
            local targetPed = PLAYER.GET_PLAYER_PED(Utils.GetSelectedPlayer())
            local targetCoords = ENTITY.GET_ENTITY_COORDS(targetPed, true)
            local targetHeading = ENTITY.GET_ENTITY_HEADING(targetPed)
            local rcCarHash = joaat("rcbandito")
            loadModel(rcCarHash)
            local rcCar = GTA.SpawnVehicle(rcCarHash, targetCoords + math.random(-3, 3), targetCoords + math.random(-3, 3), targetCoords + 1.0, targetHeading, true, false)
            if not ENTITY.DOES_ENTITY_EXIST(rcCar) then
                ShowGlowNotification("Failed to spawn RC car!", 5000)
                return
            end
            ENTITY.SET_ENTITY_INVINCIBLE(rcCar, true)
            VEHICLE.SET_VEHICLE_ENGINE_ON(rcCar, true, true, false)
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(rcCar, true, true)
            local driverHash = joaat("a_m_m_acult_01")
            loadModel(driverHash) 
            local driver = GTA.CreatePed(driverHash, 26, targetCoords, targetCoords, targetCoords, targetHeading, true, false)
            table.insert(AllThingsForScriptCleanup, driver)
            table.insert(AllThingsForScriptCleanup, rcCar)
            
            if ENTITY.DOES_ENTITY_EXIST(driver) then
                PED.SET_PED_INTO_VEHICLE(driver, rcCar, -1)
                PED.SET_PED_COMBAT_ATTRIBUTES(driver, 5, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(driver, 46, true)
                ENTITY.SET_ENTITY_HEALTH(driver, 20000, 1, 1)
                PED.SET_DRIVER_AGGRESSIVENESS(driver, 1.0)
                TASK.TASK_VEHICLE_DRIVE_WANDER(driver, rcCar, 100.0, 786468)
                while true do
                    targetCoords = ENTITY.GET_ENTITY_COORDS(targetPed, true)
                    TASK.TASK_VEHICLE_FOLLOW(driver, rcCar, targetPed, 100, 2, 1)

                    Script.Yield(500)
                end
            else
                ShowGlowNotification("Failed to create driver for RC car!", 5000)
                GradientLogger("Error: Failed to create driver for RC car!")
                ENTITY.DELETE_ENTITY(rcCar)
            end
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(rcCarHash)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(driverHash)
            ShowGlowNotification("pet Rc Spawned", 5000)
            GradientLogger("friendly Rc Spawned ")
        end, true
    )

    FeatAdd(
        joaat("npcAttackSquad"),
        "Send Attack Squad",
        eFeatureType.Button,
        "Send armed NPCs in selected vehicles to attack a player.",
        function(feat)
            local targetPlayer = Utils.GetSelectedPlayer()
            if not targetPlayer then
                ShowGlowNotification("No player selected!", 5000)
                return
            end
            if not isDev then
                if isFeatureOnCooldown() then
                    ShowGlowNotification("Feature is on cooldown. Please wait.", 5000)
                    return
                end
            end
            startFeatureCooldown()

            local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetPlayer)
            local targetCoords = V3.New(ENTITY.GET_ENTITY_COORDS(targetPed, false))
            local vehicleHash = joaat("insurgent2")
            local pedHash = joaat("s_m_y_blackops_01")
            local weaponHash = joaat("WEAPON_CARBINERIFLE")
            local numNPCs = 7
            local activeNPCs = {}

            loadModel(vehicleHash)
            loadModel(pedHash)

            local spawnOffset = 2
            local vehicle = GTA.SpawnVehicle(vehicleHash, targetCoords.x + spawnOffset, targetCoords.y, targetCoords.z, 0, true, true)
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(vehicle, 1.0)

            local function allNPCsDead()
                for _, npc in ipairs(activeNPCs) do
                    if ENTITY.DOES_ENTITY_EXIST(npc) and not PED.IS_PED_DEAD_OR_DYING(npc, true) then
                        return false
                    end
                end
                return true
            end

            for i = 0, numNPCs - 1 do
                local ped = GTA.CreatePed(pedHash, 26, targetCoordsx + spawnOffset, targetCoordsy, targetCoordsz, 0.0, true, true)
                if ped then
                    table.insert(activeNPCs, ped)
                    PED.SET_PED_INTO_VEHICLE(ped, vehicle, i)
                    WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, 9999, true, true)

                    PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, joaat("ARMY"))

                    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)
                    PED.SET_PED_ACCURACY(ped, 100)
                    PED.SET_PED_COMBAT_ABILITY(ped, 2)
                    PED.SET_PED_COMBAT_MOVEMENT(ped, 2)
                    PED.SET_PED_COMBAT_RANGE(ped, 2)

                    TASK.TASK_COMBAT_PED(ped, targetPed, 0, 16)
                end
            end

            Script.QueueJob(function()
                while true do
                    if allNPCsDead() then
                        activeNPCs = {}
                        for i = 0, numNPCs - 1 do
                            coords = ENTITY.GET_ENTITY_COORDS(vehicle, false)
                            local ped = GTA.CreatePed(pedHash, 26, coords.x, coords.y, coords.z + 2.0, 0.0, true, true)
                            if ped then
                                table.insert(activeNPCs, ped)
                                PED.SET_PED_INTO_VEHICLE(ped, vehicle, i)
                                WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, 9999, true, true)
                                PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, joaat("ARMY"))
                                TASK.TASK_COMBAT_PED(ped, targetPed, 0, 16)
                            end
                            Script.Yield(500)
                        end
                    end
                    Script.Yield(1000)
                end
            end)
            ShowGlowNotification("Attack squad deployed!", 5000)
        end
    )

    FeatAdd(joaat("anim_crash"), "Animation Crash", eFeatureType.Button, "Plays a animation on a ped around the selected target to cwash them.", function(feat)
        local targetPlayer = Utils.GetSelectedPlayer()
        local handle = NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(targetPlayer)
        Script.ExecuteAsScript("freemode", function()
            GTA.TriggerScriptEvent((1 << playerID), -1604421397, GTA.GetLocalPlayerId(), 9, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        end)
        ShowGlowNotification("Crash animation played on selected player.", 5000)
    end)

    FeatAdd(joaat("Clearthem"), "Clear them?", eFeatureType.Toggle, "Clear the area after 25 seconds")

    jetSlider = FeatAdd(
        joaat("jetSlider"),
        "How many jets?",
        eFeatureType.SliderInt,
        "Set how many jets you want to attack the player"
    )
    jetSlider:SetMinValue(1)
    jetSlider:SetMaxValue(50)
    jetSlider:SetValue(10)

    PlayerFeatAdd(
        joaat("airattack"),
        "Send Air Attackers",
        eFeatureType.Button,
        "Send jets to fly around and attack the player., nothing flagged on the receiving end, and they are deadly accurate.",
        function(feat)
            if not isDev then
                if isFeatureOnCooldown() then
                    ShowGlowNotification("Feature is on cooldown. Please wait.", 5000)
                    return
                end
            end
            startFeatureCooldown()
            local targetPlayer = Utils.GetSelectedPlayer()
            local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetPlayer)
            if not targetPed then
                ShowGlowNotification("Selected player ped not found.", 5000)
                return
            end
            local targetCoordsx, targetCoordsy, targetCoordsz = ENTITY.GET_ENTITY_COORDS(targetPed, true)

            local pilotHash = joaat("s_m_y_blackops_01")
            local jetHash = joaat("lazer")
            STREAMING.REQUEST_MODEL(pilotHash)
            STREAMING.REQUEST_MODEL(jetHash)

            loadModel(pilotHash) 
            loadModel(jetHash) 

            local numJets = jetSlider:GetIntValue()

            for i = 1, numJets do
                local angle = math.random() * math.pi * 2
                local offsetX = math.cos(angle) * 1500.0
                local offsetY = math.sin(angle) * 1500.0
                local offsetZ = math.random(500, 700)
                local spawnCoordsx = targetCoordsx + offsetX
                local spawnCoordsy = targetCoordsy + offsetY
                local spawnCoordsz = targetCoordsz + offsetZ
                local heading = math.random(0, 360)

                local pilot = GTA.CreatePed(pilotHash, 1, spawnCoordsx, spawnCoordsy, spawnCoordsz, heading, true, false)
                local jet = GTA.SpawnVehicle(jetHash, spawnCoordsx, spawnCoordsy, spawnCoordsz, heading, true, false)
                table.insert(AllThingsForScriptCleanup, jet)
                table.insert(AllThingsForScriptCleanup, pilot)
                while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(jet) do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(jet)
                    Script.Yield()
                end

                VEHICLE.CONTROL_LANDING_GEAR(jet, 3)
                VEHICLE.SET_VEHICLE_ENGINE_ON(jet, true, true, false)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(jet, 250)
                VEHICLE.SET_HELI_BLADES_FULL_SPEED(jet)
                VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(jet, 0.0)
                VEHICLE.SET_VEHICLE_GRAVITY(jet, true)

                PED.SET_PED_INTO_VEHICLE(pilot, jet, -1)

                PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 5, true)
                PED.SET_PED_COMBAT_ATTRIBUTES(pilot, 46, true)
                PED.SET_PED_ACCURACY(pilot, 100)
                PED.SET_PED_COMBAT_ABILITY(pilot, 2)
                PED.SET_PED_COMBAT_MOVEMENT(pilot, 2)
                PED.SET_PED_COMBAT_RANGE(pilot, 2)

                TASK.TASK_PLANE_MISSION(pilot, jet, 0, targetPed, targetCoordsx, targetCoordsy, targetCoordsz + 100, 6, 600.0, 0.0, 90.0, 3000.0, 100.0, true)
            end
            if FeatureMgr.IsFeatureEnabled(joaat("Clearthem")) then
                Script.Yield(5000)
                Script.Yield(5000)
                Script.Yield(5000)
                Script.Yield(5000)
                Script.Yield(5000)
                GetFname("Clear Distance"):SetValue(10000)
                GetFname("Clear Area"):TriggerCallback()
                ShowGlowNotification("Jets Cleared", 5000)
            end

            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pilotHash)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(jetHash)
        end, true
    )

    spawnedObjects = {}

    PlayerFeatAdd(
        joaat("VEHICLE_FUCKER"),
        "Woah now",
        eFeatureType.Toggle,
        "Spawns some BS and really fucks the players car works on all menus so far",
        function(feat)
            local player = Utils.GetSelectedPlayer()

            if not player then
                return
            end
            local objectHash = joaat("xm_prop_x17_osphatch_40m")
            STREAMING.REQUEST_MODEL(objectHash)
            loadModel(objectHash)

            local posx, posy, posz = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(player), false)
            if feat:IsToggled() then
                local handles = {}
                for i = 1, 10 do
                    local randX = posx + math.random(-10, 10)
                    local randY = posy + math.random(-10, 10)
                    local randZ = posz + math.random(1, 5)
                    local randPitch = math.random(-180, 180)
                    local randYaw = math.random(-180, 180)
                    local randRoll = math.random(-180, 180)
                    local handle = GTA.CreateObject(objectHash, randX, randY, randZ, true, true)

                    if handle ~= 0 then
                        local objPtr = (handle)
                        if objPtr and objPtr ~= 0 then
                            ENTITY.SET_ENTITY_COLLISION(handle, true, true)
                            ENTITY.SET_ENTITY_ROTATION(handle, randPitch, randRoll, randYaw, 2, true)
                            ENTITY.SET_ENTITY_VISIBLE(handle, false, false)
                            table.insert(handles, handle)
                        end
                    else
                        GradientLogger("[Elf Script] Failed to spawn object #" .. i)
                    end
                end
                for _, handle in ipairs(handles) do
                    table.insert(spawnedObjects, handle)
                end
                Script.QueueJob(function()
                    while feat:IsToggled() do
                        local posx, posy, posz = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(player), false)
                        for _, handle in ipairs(spawnedObjects) do
                            if ENTITY.DOES_ENTITY_EXIST(handle) then
                                local newX = posx + math.random(-10, 10)
                                local newY = posy + math.random(-10, 10)
                                local newZ = posz + math.random(1, 5)
                                local newPitch = math.random(-180, 180)
                                local newYaw = math.random(-180, 180)
                                local newRoll = math.random(-180, 180)

                                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(handle, newX, newY, newZ, false, false, false)
                                ENTITY.SET_ENTITY_VELOCITY(handle, 0, 0, 0)
                                ENTITY.SET_ENTITY_ROTATION(handle, newPitch, newRoll, newYaw, 2, true)
                            end
                        end
                        Script.Yield(20)
                    end
                end)
            else
                for i = 1, #spawnedObjects do
                    local handle = spawnedObjects[i]
                    if ENTITY.DOES_ENTITY_EXIST(handle) then
                        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(handle) do
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(handle)
                            Script.Yield(10)
                        end
                        ENTITY.SET_ENTITY_COLLISION(handle, false, false)
                        local mem = Memory.AllocInt()
                        Memory.WriteInt(mem, handle)
                        ENTITY.DELETE_ENTITY(mem)
                        Memory.Free(mem)
                    end
                    Script.Yield()
                end
                spawnedObjects = {}
            end
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(objectHash)
        end,
        true
    )


    PlayerFeatAdd(
        joaat("FlyingMonkeys"),
        "Flying Monkeys Attack",
        eFeatureType.Toggle,
        "Spawn flying monkeys attached to alien eggs to attack the selected player",
        function(feat)
            if not Utils.GetSelectedPlayer() then
                ShowGlowNotification("Elf Script No player selected!", 5000)
                return
            end
            if Utils.GetSelectedPlayer() == getPlayerPed() then
                ShowGlowNotification("Cannot target yourself", 5000)
                return
            end
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(Utils.GetSelectedPlayer())
            local playerCoords = ENTITY.GET_ENTITY_COORDS(playerPed, false)
            local eggHash = joaat("prop_alien_egg_01")
            local pedHash = joaat("u_m_y_pogo_01")
            local pedTable = {}
            local eggTable = {}
            local numberOfEntities = 20

            loadModel(eggHash) 
            loadModel(pedHash)

            for i = 1, numberOfEntities do
                local egg = GTA.CreateObject(eggHash, playerCoords.x, playerCoords.y, playerCoords.z, true, true)
                local monkey = GTA.CreatePed(pedHash, 26, playerCoords.x, playerCoords.y, playerCoords.z, 0.0, true, false)
                table.insert(eggTable, egg)
                table.insert(pedTable, monkey)
                Script.Yield()
            end
            for i = 1, #pedTable do
                ENTITY.ATTACH_ENTITY_TO_ENTITY(pedTable[i], eggTable[i], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 0, false, false)
                Script.Yield()
            end
            for i = 1, #pedTable do
                ENTITY.SET_ENTITY_INVINCIBLE(pedTable[i], true)
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(pedTable[i], 2138347493, 0, true)
                Script.Yield()
            end
            ShowGlowNotification("Flying monkeys deployed", 5000)
            while FeatureMgr.IsFeatureEnabled(joaat("FlyingMonkeys")) do
                local targetCoords = ENTITY.GET_ENTITY_COORDS(playerPed, false)
                for i = 1, #pedTable do
                    WEAPON.REFILL_AMMO_INSTANTLY(pedTable[i])
                    TASK.TASK_COMBAT_PED(pedTable[i], playerPed, 0, 16)
                end
                for i = 1, #eggTable do
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(
                        eggTable[i],
                        targetCoords.x + math.random(-7, 7),
                        targetCoords.y + math.random(-7, 7),
                        targetCoords.z + math.random(-7, 7),
                        false, false, false
                    )
                end
                Script.Yield(0)
            end
            for i = 1, #eggTable do
                local egg = eggTable[i]
                local mem = Memory.AllocInt()
                Memory.WriteInt(mem, egg)
                ENTITY.DELETE_ENTITY(mem)
                Memory.Free(mem)
                Script.Yield()
            end
            for i = 1, #pedTable do
                local ped = pedTable[i]
                local mem = Memory.AllocInt()
                Memory.WriteInt(mem, ped)
                PED.DELETE_PED(mem)
                Memory.Free(mem)
                Script.Yield()
            end
            ShowGlowNotification("Flying monkeys removed!", 5000)
        end,
        true
    ) 
    
    PlayerFeatAdd(Utils.Joaat("SetMaxWanted"), "Set Wanted Level To Max", eFeatureType.Toggle, "Sets the players wanted level to the max.", function(feature)
        while feature:IsToggled() and not ShouldUnload() do
            local playerID = feature:GetPlayerIndex()
            local wantedLevel = 5
            local CNetGamePlayer = Players.GetById(playerID)
            if not PLAYER.IS_PLAYER_WANTED_LEVEL_GREATER(playerID, wantedLevel -1) then
                Memory.LuaCallCFunction(CAlterWantedLevelEvent__Trigger, CNetGamePlayer, wantedLevel, 0, -1)
            end
            Script.Yield(250)
        end
    end)


    -- File: ./Features/Session.lua

    messageSpacingFeature = GUIFeatAdd(joaat("AltChatMessageSpacing"), "Message Spacing",
        eFeatureType.SliderInt, "Adjust spacing between chat messages.")
    messageSpacingFeature:SetMinValue(0)
    messageSpacingFeature:SetMaxValue(10)
    messageSpacingFeature:SetIntValue(2)

    altChatEnabled = GUIFeatAdd(joaat("AltChat"), "Alternative Chat", eFeatureType.Toggle,
        "Enable or disable the alternative chat system.", function(feat)
            local renderevent
            if feat:IsToggled() then
                renderevent = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, onPresentChat)
                if version == "EE" then 
                    GUI.AddToast("Elf Script", "Disabled in enhanced cuz ther is no chat", 5000, eToastPos.TOP_RIGHT) 
                    EventMgr.RemoveHandler(renderevent)
                    return
                end
            else
                EventMgr.RemoveHandler(renderevent)
            end
        end)
    autoScroll = GUIFeatAdd(joaat("AltChatAutoScroll"), "Auto Scroll", eFeatureType.Toggle,
        "Toggle auto-scrolling when new messages appear.")

    textColor = GUIFeatAdd(joaat("AltChatTextColor"), "Text Color", eFeatureType.InputColor4,
        "Set chat message text color.")
    textColor:SetColor(1.0, 1.0, 1.0, 1.0)
    useRandomColors = GUIFeatAdd(joaat("AltChatRandomColors"), "Use Random Colors(disabled)",
        eFeatureType.Toggle, "Toggle random chat colors.", function(feat)
            while feat:IsToggled() do
                Script.QueueJob(function()
                    textColor:SetColor(math.random(1, 255), math.random(1, 255), math.random(1, 255), 255)
                    Script.Yield(100)
                end)
                Script.Yield(100)
            end
        end)


    fontScale = GUIFeatAdd(joaat("AltChatFontScale"), "Font Scale", eFeatureType.SliderFloat,
        "Adjust font size.")
    fontScale:SetMinValue(0.0)
    fontScale:SetMaxValue(2.0)
    fontScale:SetFloatValue(1.0)

    flagNoTitleBar = GUIFeatAdd(joaat("AltChatNoTitleBar"), "No Title Bar", eFeatureType.Toggle,
        "Remove the window title bar.")
    flagNoTitleBar:TriggerCallback()
    flagNoResize = GUIFeatAdd(joaat("AltChatNoResize"), "No Resize", eFeatureType.Toggle,
        "Disable window resizing.")
    flagNoMove = GUIFeatAdd(joaat("AltChatNoMove"), "No Move", eFeatureType.Toggle,
        "Prevent the window from being moved.")
    flagNoScrollbar = GUIFeatAdd(joaat("AltChatNoScrollbar"), "No Scrollbar", eFeatureType.Toggle,
        "Disable the window scrollbar.")
    flagAutoResize = GUIFeatAdd(joaat("AltChatAutoResize"), "Always Auto Resize", eFeatureType.Toggle,
        "Automatically resize the window.")
    BGColor = GUIFeatAdd(joaat("AltChatBGColor"), "Background Color", eFeatureType.InputColor4,
        "Set chat window background color.")

    themeFolder = menuRootPath .. "\\Themes"
    themes = {}

    function LoadThemes()
        themes = {}
        local files = FileMgr.FindFiles(themeFolder)
        for _, file in ipairs(files) do
            table.insert(themes, file)
        end
        local altchatthemes = {}
        if #themes == 0 then
            table.insert(themes, "No Themes Found")
        end
    end
    
    LoadThemes()
        function makeDefaultConfig()
            local filepath = menuRootPath .. "\\" .. "DefaultConfig.json"
            local configTable = {}
            local configTable1 = {}

            GradientLogger("Starting to save config: " .. filepath)
            if Features and Features.HashNameMap then
                for hash, label in pairs(Features.HashNameMap) do
                    local feature = FeatureMgr.GetFeature(hash)
                    if feature then
                        local t = feature:GetType()
                        local value = nil

                        if t == eFeatureType.Toggle then
                            value = feature:IsToggled()
                        elseif t == eFeatureType.Combo then
                            value = feature:GetListIndex()
                        elseif t == eFeatureType.SliderInt then
                            value = feature:GetIntValue()
                        elseif t == eFeatureType.SliderFloat then
                            value = feature:GetFloatValue()
                        elseif t == eFeatureType.InputText then
                            value = feature:GetStringValue()
                        elseif t == eFeatureType.InputColor4 then
                            local c = { feature:GetColor() }
                            value = { c[1], c[2], c[3], c[4] }
                        end

                        if value ~= nil then
                            configTable[tostring(hash)] = {
                                value = value,
                                description = label
                            }
                        end
                    else
                        GradientLogger("Feature not found for hash: " .. tostring(hash))
                    end
                end
            else
                GradientLogger("Features.HashNameMap not found!")
            end

            local jsonData
            local success, err = pcall(function()
                jsonData = json.encode({
                    features = configTable,
                }, { indent = true })
            end)

            if not success then
                GradientLogger("Error: JSON encoding failed: " .. tostring(err))
                return
            end

            local ok = FileMgr.WriteFileContent(filepath, jsonData)
            if ok then
                GradientLogger("Config saved to : " .. filepath)
            else
                GradientLogger("Failed to write config to file: " .. filepath)
            end
        end
        
    configsave = FeatAdd(joaat("configsave"), "Save Default Config", eFeatureType.Button,
        "Save the current configuration", function()
        makeDefaultConfig()
    end)

    KEYWORDS_FILE = menuRootPath .. "\\assets.ini"
    keywords = {}
    selectedKeywordIndex = 1

    function SaveKeywordsToINI()
        local content = table.concat(keywords, "\n")
        GradientLogger("[Elf Script] Saving keywords to: " .. KEYWORDS_FILE)
        local success = FileMgr.WriteFileContent(KEYWORDS_FILE, content)
        if success then
            GradientLogger("[Elf Script] Successfully saved keywords.")
        else
            GradientLogger("[Elf Script] Failed to save keywords!")
        end
    end

    function LoadKeywordsFromINI()
        keywords = {}
        if FileMgr.DoesFileExist(KEYWORDS_FILE) then
            local content = FileMgr.ReadFileContent(KEYWORDS_FILE)
            if content and content ~= "" then
                for line in content:gmatch("[^\r\n]+") do
                    local sanitizedKeyword = line:match("^%s*(.-)%s*$")
                    if sanitizedKeyword ~= "" then
                        table.insert(keywords, sanitizedKeyword:lower())
                    end
                end
            else
                GradientLogger("[Elf Script] Keyword file exists but is empty!")
            end
        else
            GradientLogger("[Elf Script] No keyword file found. Creating new one...")
            SaveKeywordsToINI()
        end
    end

    LoadKeywordsFromINI()
    
    function StartGarageVehicleExport()
        Script.QueueJob(function()
            local garageSelector = FeatureMgr.GetFeatureByName("Garages")
            local vehicleList = FeatureMgr.GetFeatureByName("Vehicles")
            local vehiclename = FeatureMgr.GetFeatureByName("Vehicle Name")
            local saveFeature = FeatureMgr.GetFeatureByName("Save Current Vehicle")
            local requestVehicle = FeatureMgr.GetFeatureByName("Request Personal Vehicle")

            local garages = garageSelector:GetList()

            GUI.AddToast("Elf Script", "Starting garage vehicle export...", 4000, eToastPos.TOP_RIGHT)

            for i = 1, #garages do
                local garageName = garages[i]
                if garageName then
                    garageSelector:SetListIndex(i - 1)
                    Script.Yield(1500)

                    GradientLogger("Switched to: " .. garageName)

                    local vehicleCount = #vehicleList:GetList()

                    for j = 0, vehicleCount - 1 do
                        vehicleList:SetListIndex(j)
                        Script.Yield(500)

                        requestVehicle:TriggerCallback()
                        GUI.AddToast("Elf Script", "Requested Vehicle at: " .. j, 4000, eToastPos.TOP_RIGHT)
                        GradientLogger("Requested vehicle at index: " .. j)
                        Script.Yield(4000)  

                        local currentIndex = vehicleList:GetListIndex()
                        local currentVehicle = vehicleList:GetList()[currentIndex + 1]

                        if currentVehicle then
                            local filename = currentVehicle

                            vehiclename:SetValue(filename)
                            Script.Yield(250)

                            saveFeature:TriggerCallback()
                            GUI.AddToast("Elf Script", "Saved: " .. currentVehicle, 5000, eToastPos.TOP_RIGHT)
                            GradientLogger("Saved: " .. currentVehicle)
                            Script.Yield(1000)
                        else
                            GUI.AddToast("Elf Script", "Failed to get vehicle name at index: " .. j, 5000, eToastPos.TOP_RIGHT)
                            GradientLogger("Failed to get vehicle name at index: " .. j)
                        end
                    end

                    Script.Yield(2000)
                else
                    GUI.AddToast("Elf Script", "Skipped nil garage at index: " .. tostring(i), 5000, eToastPos.TOP_RIGHT)
                    Logger.LogError("Skipped nil garage at index: " .. tostring(i))
                end
            end
            GradientLogger("All garages exported")
            GUI.AddToast("Elf Script", "All garages exported.", 5000, eToastPos.TOP_RIGHT)
        end)
    end       

    FeatAdd(joaat("savegarage"), "Start Garage export", eFeatureType.Button,
        "Save all vehicles in the selected garage", function()
        StartGarageVehicleExport()
    end)

    local keywordCombo = FeatAdd(joaat("KeywordCombo"), "Keywords", eFeatureType.Combo, "Select a keyword for detection")

    function UpdateKeywordCombo()
        keywordCombo:SetList(keywords)
        keywordCombo:SetListIndex(math.max(0, math.min(selectedKeywordIndex, #keywords - 1)))
    end

    FeatAdd(joaat("deletekeyword"), "Delete Keyword", eFeatureType.Button, "Deletes the selected keyword", function()
        local selectedIndex = keywordCombo:GetListIndex()
        if selectedIndex >= 0 and selectedIndex < #keywords then
            table.remove(keywords, selectedIndex + 1)
            SaveKeywordsToINI()
            UpdateKeywordCombo()
            selectedKeywordIndex = math.max(0, selectedIndex - 1)
            keywordCombo:SetListIndex(selectedKeywordIndex)
        end
    end)

    local keywordInput = FeatAdd(joaat("KeywordInput"), "Add Keyword", eFeatureType.InputText,
        "Enter a new keyword for detection")

    keywordInput:TriggerCallback(function()
        local enteredText = keywordInput:GetStringValue()
        local sanitizedText = enteredText:lower():match("^%s*(.-)%s*$")

        local exists = false
        for _, keyword in ipairs(keywords) do
            if keyword == sanitizedText then
                exists = true
                break
            end
        end

        if sanitizedText ~= "" and not exists then
            table.insert(keywords, sanitizedText)
            SaveKeywordsToINI()
            UpdateKeywordCombo()
            keywordInput:SetStringValue("")
        else
            GradientLogger("[Elf Script] Duplicate or empty keyword ignored.")
        end
    end)

    function handleKeyworddetection()
        if ImGui.IsKeyPressed(13) then
            local enteredText = keywordInput:GetStringValue()
            local sanitizedText = enteredText:lower():match("^%s*(.-)%s*$")
            local exists = false
            for _, keyword in ipairs(keywords) do
                if keyword == sanitizedText then
                    exists = true
                    break
                end
            end
            if sanitizedText ~= "" and not exists then
                table.insert(keywords, sanitizedText)
                UpdateKeywordCombo()
                keywordInput:SetStringValue("")
            end
        end
    end

    FeatAdd(joaat("savekeyword"), "Save Keyword", eFeatureType.Button, "", function()
        SaveKeywordsToINI()
    end)

    UpdateKeywordCombo()

    local message = { 
        logMessages = {},
        detectedMessages = {},
        messageColors = {},
        shouldScrollToBottom = false,
        inputText = "",
        lastColorChange = Time.GetEpocheMs(),
        colorChangeInterval = 100
    }


    function handleKeywordDetection(keyword, playerName, msg)
        GradientLogger("[ALERT] Detected keyword: '" .. keyword .. "' from player: " .. playerName)

        local playerId = nil
        for i = 0, 31 do
            local p = Players.GetById(i)
            if p and p:GetName():lower() == playerName:lower() then
                playerId = p.PlayerId
                break
            end
        end

        if playerId then
            local crashFeature = GetFname("ATF Crash", playerId) and
                GetFname("Host Kick", playerId) and GetFname("Drop Kick", playerId)
            if crashFeature then
                crashFeature:TriggerCallback()
                GradientLogger("[ACTION] Sent crash to player: " .. playerName)
            else
                GradientLogger("[ERROR] ATF Crash feature not found!")
            end

            table.insert(message.detectedMessages, string.format("[DETECTED] [%s] said: %s", playerName, msg))
        else
            GradientLogger("[ERROR] Player '" .. playerName .. "' not found!")
        end
    end

    function containsKeyword(msg)
        local lowerMessage = msg:lower()

        for _, keyword in ipairs(keywords) do
            if lowerMessage:find("%f[%a]" .. keyword .. "%f[%A]") then
                return true, keyword
            end
        end

        return false, nil
    end

    function updateMessageColors()
        for msg, _ in pairs(message.messageColors) do
            if useRandomColors:IsToggled() then
                message.messageColors[msg] = getRandomColor()
            else
                local defaultR, defaultG, defaultB, defaultA = textColor:GetColorFloats()
                message.messageColors[msg] = { defaultR, defaultG, defaultB, defaultA }
            end
        end
    end
    FeatAdd(joaat("UseChatCommands"), "Use Chat Commands", eFeatureType.Toggle, "Enable or disable chat command handling.", function(f)
        if f:IsToggled() then
            if version == "LE" then
                GUI.AddToast("Elf Script", "Chat commands enabled. Use !help for a list of commands.", 5000, eToastPos.TOP_RIGHT)
            else
                GUI.AddToast("Elf Script", "Chat commands disabled in enhanced cuz ther is no chat", 5000, eToastPos.TOP_RIGHT)
                f:Reset()
            end
        end
    end)
        
    function HandleChatCommand(sender, message)
        if not FeatureMgr.IsFeatureEnabled(joaat("UseChatCommands")) then return end
        if not message or not message:lower():find("^!") then return end
        local args = {}
        for word in message:gmatch("%S+") do
            table.insert(args, word)
        end
        local function GetPlayerIdByName(name)
            for i = 0, 31 do
                local pname = Players.GetName(i)
                if pname and pname:lower() == name:lower() then
                    return i
                end
            end
            return nil
        end

        local command = args[1] and args[1]:sub(2):lower() or nil
        local isSelf = sender == GTA.GetLocalPlayerId()
        local ped = GTA.GetLocalPed()
        local playerID = sender.PlayerId or sender

        if command == "help" then
            Script.QueueJob(function()
                GUI.AddToast("Chat Commands", "Available: !help, !spawn <vehicle>, !couchcage (all) or 'PlayerName'", 5000, eToastPos.TOP_RIGHT)
            end)
        elseif command == "spawn" and isSelf and args[2] then
            local vehicleHash = Utils.Joaat(args[2])
            Script.QueueJob(function()
                local ok, err = pcall(function()
                    GTA.SpawnVehicleForPlayer(vehicleHash, playerID, 5.0)
                end)
                if not ok then
                    GradientLogger("error spawning vehicle: " .. tostring(err))
                end
                GUI.AddToast("Elf Script", "Spawned vehicle: " .. args[2], 4000, eToastPos.TOP_RIGHT)
            end)
        elseif command == "spawn" and not isSelf and args[2] then
            local vehicleHash = Utils.Joaat(args[2])
            Script.QueueJob(function()
                local ok, vehicle = pcall(function()
                    return GTA.SpawnVehicleForPlayer(vehicleHash, playerID, 5.0)
                end)
                if not ok then
                    GradientLogger("[DEBUG] error spawning vehicle: " .. tostring(vehicle))
                elseif vehicle then
                    GUI.AddToast("Elf Script", "Spawned vehicle: " .. args[2], 4000, eToastPos.TOP_RIGHT)
                else
                    GUI.AddToast("Elf Script", "Failed to spawn vehicle: " .. args[2], 4000, eToastPos.TOP_RIGHT)
                end
            end)
        elseif command == "couchcage" and args[2] then
            if args[2]:lower() == "all" then
                for i = 0, 32 do
                    local ok, err = pcall(function()
                        FeatureMgr.GetFeature(joaat("CouchCage"), i):TriggerCallback()
                    end)
                    if not ok then
                        GradientLogger("[DEBUG] error couchcaging player " .. tostring(i) .. ": " .. tostring(err))
                    end
                end
                GUI.AddToast("Elf Script", "Couch caged all players!", 4000, eToastPos.TOP_RIGHT)
            else
                local targetId = GetPlayerIdByName(args[2])
                if targetId then
                    local ok, err = pcall(function()
                        FeatureMgr.GetFeature(joaat("CouchCage"), targetId):TriggerCallback()
                    end)    
                    if not ok then
                        GradientLogger("[DEBUG] error couchcaging player " .. tostring(targetId) .. ": " .. tostring(err))
                    end
                    GUI.AddToast("Elf Script", "Caged " .. args[2], 4000, eToastPos.TOP_RIGHT)
                else
                    GUI.AddToast("Elf Script", "No player found with name: " .. args[2], 4000, eToastPos.TOP_RIGHT)
                end
            end
        else
            GUI.AddToast("Elf Script", "Unknown or bad command: " .. (command or ""), 4000, eToastPos.TOP_RIGHT)
        end
    end

    function logMessage(playerObject, msg)

        if not playerObject or not msg then return end

        local playerName = playerObject:GetName() or "Unknown Player"
        local formattedMessage = ("[%s]: %s"):format(playerName, msg)

        local isDetected, keyword = containsKeyword(msg)
        if isDetected then
            handleKeywordDetection(keyword, playerName, msg)
        end

        table.insert(message.logMessages, formattedMessage)
        updateMessageColors()

        if #message.logMessages > 500 then
            table.remove(message.logMessages, 1)
        end
        message.shouldScrollToBottom = true
        HandleChatCommand(playerObject, msg)
        if altChatEnabled:IsToggled() then
            if playerObject and msg and msg.Message then
                logMessage(playerObject, msg.Message)
                if LogChatEnabled:IsToggled() then
                    local logFile = menuRootPath .. "chatLog.txt"
                    FileMgr.WriteFileContent(logFile, msg .. "\n")
                end
            end

            Script.RegisterLooped(function()
                NIGGER.MP_TEXT_CHAT_DISABLE(true)
                Script.Yield()
            end)
        end
    end
    
    function onPresentChat()
        if version == "EE" then 
            GUI.AddToast("Elf Script", "Disabled in enhanced cuz ther is no chat", 5000, eToastPos.TOP_RIGHT) 
            return
        end
        if not FeatureMgr.IsFeatureEnabled(joaat("AltChat")) then
            return
        end
        useRandomColors = FeatureMgr.IsFeatureEnabled(joaat("AltChatRandomColors"))

        local currentTime = Time.GetEpocheMs()
        if currentTime - message.lastColorChange > message.colorChangeInterval then
            for msg, _ in pairs(message.messageColors) do
                if useRandomColors then
                    message.messageColors[msg] = getRandomColor()
                else
                    message.messageColors[msg] = {0.0, 0.0, 0.0, 1.0}
                end
            end
            message.lastColorChange = currentTime
        end

        stylePushCountAlternativeChat = 0

            colors = {
                { ImGuiCol.WindowBg,             BGColor:GetColor() },
                { ImGuiCol.ScrollbarGrab,        ButtonColor:GetColor() },
                { ImGuiCol.ScrollbarGrabActive,  ButtonActiveColor:GetColor() },
                { ImGuiCol.ScrollbarGrabHovered, ButtonHoverColor:GetColor() },
                { ImGuiCol.Header,               HeaderColor:GetColor() },
                { ImGuiCol.HeaderActive,         HeaderActiveC:GetColor() },
                { ImGuiCol.HeaderHovered,        HeaderHovered:GetColor() },
                { ImGuiCol.FrameBg,              ComboBgColor:GetColor() },
                { ImGuiCol.FrameBgHovered,       ComboBgColor:GetColor() },
                { ImGuiCol.FrameBgActive,        ComboBgColor:GetColor() },
                { ImGuiCol.Border,               ComboBorderColor:GetColor() },
                { ImGuiCol.PopupBg,              ComboBgColor:GetColor() },
                { ImGuiCol.Separator,            ComboBorderColor:GetColor() },
                { ImGuiCol.Button,               ButtonColor:GetColor() },
                { ImGuiCol.ButtonHovered,        ButtonHoverColor:GetColor() },
                { ImGuiCol.ButtonActive,         ButtonActiveColor:GetColor() },
                { ImGuiCol.Text,                 TextColor1:GetColor() },
                { ImGuiCol.ChildBg,              ChildBgColor:GetColor() },
                { ImGuiCol.CheckMark,            CheckMarkcolor:GetColor() },
                { ImGuiCol.ResizeGrip,           CheckMarkcolor:GetColor() },
                { ImGuiCol.SliderGrab,           SliderGrab:GetColor() },
                { ImGuiCol.SliderGrabActive,     SliderGrabActive:GetColor() },
                { ImGuiCol.TitleBg,            255, 0, 0, 255},
                { ImGuiCol.TitleBgActive,            225, 0, 0, 255},
                { ImGuiCol.TitleBgCollapsed,            225, 0, 0, 255}
            }

        for _, color in ipairs(colors) do
            local col, r, g, b, a = table.unpack(color)
            ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, (a or 255))
            stylePushCountAlternativeChat = stylePushCountAlternativeChat + 1
        end

        ImGui.Begin("Alternative Chat", true, ImGuiWindowFlags.None
            + (flagNoTitleBar:IsToggled() and ImGuiWindowFlags.NoTitleBar or 0)
            + (flagNoResize:IsToggled() and ImGuiWindowFlags.NoResize or 0)
            + (flagNoMove:IsToggled() and ImGuiWindowFlags.NoMove or 0)
            + (flagNoScrollbar:IsToggled() and ImGuiWindowFlags.NoScrollbar or 0)
            + (flagAutoResize:IsToggled() and ImGuiWindowFlags.AlwaysAutoResize or 0))
        ImGui.SetWindowFontScale(1.2)
        ImGui.PushTextWrapPos(0.0)
    
        for _, msg in ipairs(message.logMessages) do
            local isDetected, _ = containsKeyword(msg)
    
            if isDetected then
                ImGui.TextColored(1.0, 0.0, 0.0, 1.0, msg) 
            else
                local r, g, b, a = table.unpack(message.messageColors[msg] or {0.0, 0.0, 0.0, 1.0})
                ImGui.TextColored(r, g, b, a, msg)
            end
        end
    
        ImGui.PopTextWrapPos()
    
        if shouldScrollToBottom then
            ImGui.SetScrollHereY(1.0)
            shouldScrollToBottom = false
        end
    
        ImGui.Spacing()
        ImGui.PopStyleColor(stylePushCountAlternativeChat)
        ImGui.End()
    end

    

    BGColorelf = GUIFeatAdd(joaat("colorBGelf"), "Window Background", eFeatureType.InputColor4,
        "Sets the window background color")
    BGColorelf:SetColor(30, 30, 30, 0)

    ButtonColor = GUIFeatAdd(joaat("ButtonColor"), "Button", eFeatureType.InputColor4, "Sets the button color")
    ButtonColor:SetColor(2, 0, 0, 255)

    ButtonHoverColor = GUIFeatAdd(joaat("ButtonHoverColor"), "Button Hover", eFeatureType.InputColor4,
        "Sets the button hover color")
    ButtonHoverColor:SetColor(100, 100, 100, 255)

    TextColor1 = GUIFeatAdd(joaat("TextColor11"), "Text", eFeatureType.InputColor4, "Sets the text color")
    TextColor1:SetColor(255, 255, 255, 255)

    ButtonActiveColor = GUIFeatAdd(joaat("ButtonActiveColor"), "Active Button Color", eFeatureType.InputColor4,
        "Sets the active button color")
    ButtonActiveColor:SetColor(255, 255, 255, 255)

    ChildBgColor = GUIFeatAdd(joaat("ChildBgColor"), "Child BG", eFeatureType.InputColor4, "Sets the child background color")
    ChildBgColor:SetColor(0, 0, 0, 40)

    ComboBgColor = GUIFeatAdd(joaat("ComboBgColor"), "Combo Background", eFeatureType.InputColor4,
        "Sets the combo box background color")
    ComboBgColor:SetColor(30, 30, 30, 255)

    ComboBorderColor = GUIFeatAdd(joaat("ComboBorderColor"), "Border", eFeatureType.InputColor4,
        "Sets the combo box border color")
    ComboBorderColor:SetColor(200, 200, 200, 255)

    HeaderColor = GUIFeatAdd(joaat("Comboselected"), "Combo Active", eFeatureType.InputColor4, "Sets the Combo Active Color")
    HeaderColor:SetColor(210, 10, 10, 255)

    HeaderActiveC = GUIFeatAdd(joaat("ComboActive"), "Combo  Selected", eFeatureType.InputColor4,
        "Sets the Combo  Selected Color")
    HeaderActiveC:SetColor(200, 200, 200, 255)

    HeaderHovered = GUIFeatAdd(joaat("ComboHovered"), "Combo Hovered", eFeatureType.InputColor4, "Sets the Combo Hovered Color")
    HeaderHovered:SetColor(200, 200, 200, 255)

    CheckMarkcolor = GUIFeatAdd(joaat("CheckMarkcolor"), "Check Mark", eFeatureType.InputColor4, "Sets the Check Mark Color")
    CheckMarkcolor:SetColor(200, 200, 200, 255)

    ScrollbarBgColor = GUIFeatAdd(joaat("ScrollbarBgColor"), "Scroll bar Bg", eFeatureType.InputColor4,
        "Sets the Scroll bar Bg Color")
    ScrollbarBgColor:SetColor(200, 0, 0, 255)

    ScrollbarGrab = GUIFeatAdd(joaat("Scrollbarcolor"), "Scroll bar", eFeatureType.InputColor4, "Sets the Scroll bar Color")
    ScrollbarGrab:SetColor(0, 0, 0, 255)

    ScrollbarGrabActive = GUIFeatAdd(joaat("ScrollbarActive"), "Scroll bar Active", eFeatureType.InputColor4,
        "Sets the Scroll bar Active Color")
    ScrollbarGrabActive:SetColor(200, 200, 200, 255)

    ScrollbarGrabHovered = GUIFeatAdd(joaat("ScrollbarGrabHovered"), "Scroll bar Hovered", eFeatureType.InputColor4,
        "Sets the Scroll bar Bg Color")
    ScrollbarGrabHovered:SetColor(200, 200, 200, 255)

    SliderGrab = GUIFeatAdd(joaat("SliderGrab"), "Slider Grab", eFeatureType.InputColor4, "Sets the Slider Grab Color")
    SliderGrab:SetColor(200, 0, 0, 255)

    SliderGrabActive = GUIFeatAdd(joaat("SliderGrabActive"), "Slider Grab Active", eFeatureType.InputColor4,
        "Sets the Slider Grab Active Color")
    SliderGrabActive:SetColor(0, 0, 0, 255)

    function RenderAltChatSettings()
        if not GUI.IsOpen() then
            return
        end

        local stylePushCount = 0

        local colors = {
            { ImGuiCol.WindowBg,             BGColorelf:GetColor() },
            { ImGuiCol.ScrollbarGrab,        ButtonColor:GetColor() },
            { ImGuiCol.ScrollbarGrabActive,  ButtonActiveColor:GetColor() },
            { ImGuiCol.ScrollbarGrabHovered, ButtonHoverColor:GetColor() },
            { ImGuiCol.Header,               HeaderColor:GetColor() },
            { ImGuiCol.HeaderActive,         HeaderActiveC:GetColor() },
            { ImGuiCol.HeaderHovered,        HeaderHovered:GetColor() },
            { ImGuiCol.FrameBg,              ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgHovered,       ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgActive,        ComboBgColor:GetColor() },
            { ImGuiCol.PopupBg,              ComboBgColor:GetColor() },
            { ImGuiCol.Separator,            ComboBorderColor:GetColor() },
            { ImGuiCol.Button,               ButtonColor:GetColor() },
            { ImGuiCol.ButtonHovered,        ButtonHoverColor:GetColor() },
            { ImGuiCol.ButtonActive,         ButtonActiveColor:GetColor() },
            { ImGuiCol.Text,                 TextColor1:GetColor() },
            { ImGuiCol.ChildBg,              ChildBgColor:GetColor() },
            { ImGuiCol.CheckMark,            CheckMarkcolor:GetColor() },
            { ImGuiCol.ResizeGrip,           CheckMarkcolor:GetColor() },
            { ImGuiCol.SliderGrab,           SliderGrab:GetColor() },
            { ImGuiCol.SliderGrabActive,     SliderGrabActive:GetColor() }
        }

        for _, color in ipairs(colors) do
            local col, r, g, b, a = table.unpack(color)
            ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, a / 255)
            stylePushCount = stylePushCount + 1
        end

        if ImGui.Begin("Alternative Chat Settings", true) then
            ImGui.SetWindowSize(400, 600)

            local features = {
                "AltChatMessageSpacing",
                "AltChatNoScrollbar", "AltChatAutoResize", "AltChatRandomColors",
                "AltChatNoTitleBar", "AltChatNoResize", "AltChatNoMove",
                "AltChatAutoScroll", "AltChatFontScale", "AltChatBGColor",
                "AltChatTextColor"
            }
            for _, feature in ipairs(features) do
                RendF(joaat(feature))
            end
        end
        ImGui.End()

        ImGui.PopStyleColor(stylePushCount)
    end

    function ShowModdersSettings()
        if not GUI.IsOpen() then
            return
        end

        local stylePushCount = 0

        local bgelfr, bgelfg, bgelfb, bgelfa = BGColorelf:GetColor()
        if bgelfr == nil then bgelfr, bgelfg, bgelfb, bgelfa = 255, 255, 255, 255 end
        ImGui.PushStyleColor(ImGuiCol.WindowBg, bgelfr / 255, bgelfg / 255, bgelfb / 255, bgelfa / 255)
        stylePushCount = stylePushCount + 1

        local colors = {
            { ImGuiCol.WindowBg,             BGColorelf:GetColor() },
            { ImGuiCol.ScrollbarGrab,        ButtonColor:GetColor() },
            { ImGuiCol.ScrollbarGrabActive,  ButtonActiveColor:GetColor() },
            { ImGuiCol.ScrollbarGrabHovered, ButtonHoverColor:GetColor() },
            { ImGuiCol.Header,               HeaderColor:GetColor() },
            { ImGuiCol.HeaderActive,         HeaderActiveC:GetColor() },
            { ImGuiCol.HeaderHovered,        HeaderHovered:GetColor() },
            { ImGuiCol.FrameBg,              ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgHovered,       ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgActive,        ComboBgColor:GetColor() },
            { ImGuiCol.Border,               ComboBorderColor:GetColor() },
            { ImGuiCol.PopupBg,              ComboBgColor:GetColor() },
            { ImGuiCol.Separator,            ComboBorderColor:GetColor() },
            { ImGuiCol.Button,               ButtonColor:GetColor() },
            { ImGuiCol.ButtonHovered,        ButtonHoverColor:GetColor() },
            { ImGuiCol.ButtonActive,         ButtonActiveColor:GetColor() },
            { ImGuiCol.Text,                 TextColor1:GetColor() },
            { ImGuiCol.ChildBg,              ChildBgColor:GetColor() },
            { ImGuiCol.CheckMark,            CheckMarkcolor:GetColor() },
            { ImGuiCol.ResizeGrip,           CheckMarkcolor:GetColor() },
            { ImGuiCol.SliderGrab,           SliderGrab:GetColor() },
            { ImGuiCol.SliderGrabActive,     SliderGrabActive:GetColor() }
        }

        for _, color in ipairs(colors) do
            local col, r, g, b, a = table.unpack(color)
            ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, a / 255)
            stylePushCount = stylePushCount + 1
        end

        ImGui.Begin("Draw Modders Settings", true, ImGuiWindowFlags.AlwaysAutoResize)
        ImGui.Text("This contains Customizability for the Draw Modder Settings")

        RendF(joaat("flagAutoResizeMD"))
        RendF(joaat("flagNoMoveMD"))
        RendF(joaat("flagNoResizeMD"))
        RendF(joaat("flagNoTitleBarMD"))
        RendF(joaat("colorBGelf1"))
        RendF(joaat("TextColor111"))
        RendF(joaat("DMFontScale"))
        ImGui.End()

        ImGui.PopStyleColor(stylePushCount)
    end

    local altChatSettings = FeatAdd(
        joaat("altChatSettings"),
        "Alternative Chat Settings",
        eFeatureType.Toggle,
        "Enable or disable alternative chat settings."
    )

    function onPresent2()
        if altChatSettings:IsToggled() then
            RenderAltChatSettings()
        end
    end
    local ShowModdersSettingsrenderEvent
    local ShowModderSettings = FeatAdd(joaat("ShowModderSettings"), "Draw Modders Settings", eFeatureType.Toggle,
        "Enable or disable the Draw Modders Settings", function(feat)
            if feat:IsToggled() then 
                ShowModdersSettingsrenderEvent = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, onPresent4)
            else
                EventMgr.RemoveHandler(ShowModdersSettingsrenderEvent)
            end
        end)

    function onPresent4()
        if ShowModderSettings:IsToggled() then
            ShowModdersSettings()
        end
    end
    
    Script.RegisterLooped(handleKeyworddetection)
    logmessagesevent = EventMgr.RegisterHandler(eLuaEvent.ON_CHAT_MESSAGE, logMessage)
    altchatsettingsrenderevent = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, onPresent2)
    keywordaddingevent =  EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, handleKeyworddetection)
    if version == "EE" then 
        EventMgr.RemoveHandler(altchatsettingsrenderevent)
        EventMgr.RemoveHandler(logmessagesevent)
        EventMgr.RemoveHandler(logChatMessageforaltchat)
        EventMgr.RemoveHandler(keywordaddingevent)
    end

    local detectedPlayers = detectedPlayers or {}
    local nameColors = {}
    local modderFeatureIds = {}

    function getRandomColor()
        Script.QueueJob(function()
            Script.Yield(100)
            return { math.random(), math.random(), math.random(), 1.0 }
        end)
    end

    local function onPlayerLeave(playerId)
        if type(playerId) ~= "number" or playerId < 0 then
            return
        end
        local NetGamePlayer = Players.GetById(playerId)
        if NetGamePlayer then
            local GamerInfo = NetGamePlayer:GetGamerInfo() or {}
            local rid = GamerInfo.RockstarId or "Invalid"
            if detectedPlayers[rid] then
                detectedPlayers[rid] = nil
            end
            if modderFeatureIds[rid] then
                RemFeat(modderFeatureIds[rid])
                modderFeatureIds[rid] = nil
            end
        end
    end

    local function detectPlayers()
        for playerId = 0, 31 do
            if playerId ~= localPlayerId then
                local NetGamePlayer = Players.GetById(playerId)
                if NetGamePlayer then
                    local rid = NetGamePlayer:GetGamerInfo().RockstarId or "Invalid"
                    if rid ~= "Invalid" then
                        local modderDetections = ModderDB.GetModderDetections(rid)
                        if type(modderDetections) == "table" and #modderDetections > 0 then
                            local reasons = {}
                            for _, detection in ipairs(modderDetections) do
                                if type(detection) == "string" and detection ~= "" then
                                    table.insert(reasons, detection)
                                end
                            end
                            if #reasons > 0 then
                                local name = NetGamePlayer:GetName() or "Unknown"
                                local tags = Players.GetTags(playerId) or ""
                                local hasFTag = tags:find("F") ~= nil
                                detectedPlayers[rid] = {
                                    name = hasFTag and ("[F] " .. name) or name,
                                    reason = table.concat(reasons, ", "),
                                    hasFTag = hasFTag,
                                    notified = detectedPlayers[rid] and detectedPlayers[rid].notified or false
                                }
                                if hasFTag and not nameColors[rid] then
                                    nameColors[rid] = { 10, 10, 10 }
                                end
                                if not detectedPlayers[rid].notified then
                                    detectedPlayers[rid].notified = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local function clearDetectedPlayers()
        detectedPlayers = {}
        nameColors = {}
        modderFeatureIds = {}
    end

    EventMgr.RegisterHandler(eLuaEvent.ON_SESSION_CHANGE, function()
        clearDetectedPlayers()
        local mem = Memory.AllocInt()
        for i=1, #AllThingsForScriptCleanup do 
            local thing = AllThingsForScriptCleanup[i]
            Memory.WriteInt(mem, thing)
            ENTITY.DELETE_ENTITY(mem)
        end
        Memory.Free(mem)
    end)
    EventMgr.RegisterHandler(eLuaEvent.ON_PLAYER_LEFT, function(playerId)
        if playerId == GTA.GetLocalPlayerId() then
            clearDetectedPlayers()
        else
            onPlayerLeave(playerId)
        end
    end)

    -- File: ./gui/gui.lua

    BGColorelfdm = GUIFeatAdd(joaat("colorBGelf1"), "Window Background for modder display", eFeatureType.InputColor4,
        "Sets the window background color for modder display")
    BGColorelfdm:SetColor(30, 30, 30, 255)

    TextColor1dm = GUIFeatAdd(joaat("TextColor111"), "Text for modder display", eFeatureType.InputColor4,
        "Sets the text color for modder display")
    TextColor1dm:SetColor(255, 255, 255, 255)

    ComboBorderColordm = GUIFeatAdd(joaat("ComboBorderColordm"), "Border Color for modder Display", eFeatureType.InputColor4,
        "Sets the border color for modder Display")
    ComboBorderColordm:SetColor(255, 0, 0, 255)

    Resizegrip = GUIFeatAdd(joaat("Resizegrip"), "Resize Grip Color for modder Display", eFeatureType.InputColor4,
        "Sets the Resize Grip Color for modder Display")
    Resizegrip:SetColor(255, 0, 0, 255)

    ResizegripActive = GUIFeatAdd(joaat("ResizegripActive"), "Resize Grip Active Color for modder Display",
        eFeatureType.InputColor4, "Sets the Resize Grip Active Color for modder Display")
    ResizegripActive:SetColor(255, 255, 255, 255)

    ResizeGripHovered = GUIFeatAdd(joaat("ResizeGripHovered"), "Resize Grip Hovered Color for modder Display",
        eFeatureType.InputColor4, "Sets the Resize Grip Hovered Color for modder Display")
    ResizeGripHovered:SetColor(0, 0, 0, 255)

    MdFontScale = GUIFeatAdd(joaat("DMFontScale"), "Font scale for modder display", eFeatureType.SliderFloat,
        "Sets the font scale for the modder display")
    MdFontScale:SetMinValue(1.0)
    MdFontScale:SetMaxValue(10.0)
    MdFontScale:SetFloatValue(1.0)

    flagAutoResizeMD = GUIFeatAdd(joaat("flagAutoResizeMD"), "flag Auto Resize toggle", eFeatureType.Toggle,
        "sets the flag Auto Resize for modder display")
    flagNoMoveMD = GUIFeatAdd(joaat("flagNoMoveMD"), "flag No Move toggle", eFeatureType.Toggle,
        "sets the flag No Move for modder display")
    flagNoResizeMD = GUIFeatAdd(joaat("flagNoResizeMD"), "flag No Resize toggle", eFeatureType.Toggle,
        "sets the flag No Resize for modder display")
    flagNoTitleBarMD = GUIFeatAdd(joaat("flagNoTitleBarMD"), "flag No Title Bar toggle", eFeatureType.Toggle,
        "sets the No Title Bar for modder display")


    local RIDs = {
        retard = { 267637605, 265469367, 252800664 },
        admin = { 257977874, 254035041, 268613635, 271663576 },
        developer = { 266234520, 229330955 }
    }

    local detected = {
        retard = {},
        admin = {},
        developer = {}
    }

    local monitoringActive = true

    local function DetectPlayers()
        if not monitoringActive then return end
        detected = { retard = {}, admin = {}, developer = {} }

        for i = 0, 31 do
            local NetGamePlayer = Players.GetById(i)
            if NetGamePlayer then
                local rid = tonumber(NetGamePlayer:GetGamerInfo().RockstarId or "Invalid")
                if rid then
                    for role, rids in pairs(RIDs) do
                        for _, roleRID in ipairs(rids) do
                            if rid == roleRID then
                                detected[role][rid] = NetGamePlayer:GetName() or "Unknown"
                                GUI.AddToast("Elf Script",
                                    role:sub(1, 1):upper() .. role:sub(2) .. " detected: " .. detected[role][rid], 5000,
                                    eToastPos.TOP_RIGHT)
                                break
                            end
                        end
                    end
                end
            end
        end
        monitoringActive = not (next(detected.retard) or next(detected.developer))
    end



    local function DetectPlayerLeave()
        if not (next(detected.retard) or next(detected.developer)) then return end

        local activePlayers = {}
        for i = 0, 31 do
            local NetGamePlayer = Players.GetById(i)
            if NetGamePlayer then
                local rid = tonumber(NetGamePlayer:GetGamerInfo().RockstarId or "Invalid")
                activePlayers[rid] = true
            end
        end

        for role, players in pairs(detected) do
            for rid in pairs(players) do
                if not activePlayers[rid] then
                    detected[role][rid] = nil
                end
            end
        end
        monitoringActive = not (next(detected.retard) or next(detected.developer))
    end
    local function DrawDetectedWindow()
        if not (next(detected.retard) or next(detected.developer)) then return end
        if not GUI.IsOpen() then return end

        local colors = {
            { ImGuiCol.WindowBg,       BGColorelf:GetColor() },
            { ImGuiCol.Header,         HeaderColor:GetColor() },
            { ImGuiCol.FrameBg,        ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgHovered, ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgActive,  ComboBgColor:GetColor() },
            { ImGuiCol.Border,         ComboBorderColordm:GetColor() },
            { ImGuiCol.PopupBg,        ComboBgColor:GetColor() },
            { ImGuiCol.Text,           TextColor1:GetColor() },
            { ImGuiCol.ChildBg,        ChildBgColor:GetColor() }
        }

        for _, color in ipairs(colors) do
            local col, r, g, b, a = table.unpack(color)
            ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, a / 255)
        end

        if ImGui.Begin("Detected", true, ImGuiWindowFlags.AlwaysAutoResize) then
            for role, players in pairs(detected) do
                if next(players) then
                    ImGui.TextColored(1.0, 1.0, 1.0, 1.0, role:sub(1, 1):upper() .. role:sub(2) .. " Detected:")
                    for _, name in pairs(players) do
                        ImGui.TextColored(1.0, 1.0, 1.0, 1.0, "Name: " .. name)
                    end
                end
            end
            ImGui.End()
        end

        ImGui.PopStyleColor(#colors)
    end

    local function MonitorPlayers()
        if monitoringActive and NETWORK.NETWORK_IS_SESSION_STARTED() then
            DetectPlayers()
        else
            DetectPlayerLeave()
        end
    end

    Script.RegisterLooped(MonitorPlayers)
    EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, DrawDetectedWindow)
    EventMgr.RegisterHandler(eLuaEvent.ON_PLAYER_JOIN, DetectPlayers)
    EventMgr.RegisterHandler(eLuaEvent.ON_PLAYER_LEFT, DetectPlayerLeave)

    local bgR, bgG, bgB, bgA = BGColor:GetColorFloats()

    function ShowModderDisplay()
        detectedPlayers = detectedPlayers or {}

        local stylePushCount = 0

        local colors = {
            { ImGuiCol.WindowBg,          BGColorelfdm:GetColor() },
            { ImGuiCol.Text,              TextColor1dm:GetColor() },
            { ImGuiCol.ResizeGrip,        Resizegrip:GetColor() },
            { ImGuiCol.ResizeGripActive,  ResizegripActive:GetColor() },
            { ImGuiCol.ResizeGripHovered, ResizeGripHovered:GetColor() },
            { ImGuiCol.Separator,         ComboBorderColordm:GetColor() }
        }

        for _, color in ipairs(colors) do
            local col, r, g, b, a = table.unpack(color)
            ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, a / 255)
            stylePushCount = stylePushCount + 1
        end

        local scale1 = MdFontScale:GetFloatValue()
        local windowFlags = 0
        if flagNoTitleBarMD:IsToggled() then windowFlags = windowFlags + ImGuiWindowFlags.NoTitleBar end
        if flagNoResizeMD:IsToggled() then windowFlags = windowFlags + ImGuiWindowFlags.NoResize end
        if flagNoMoveMD:IsToggled() then windowFlags = windowFlags + ImGuiWindowFlags.NoMove end
        if flagAutoResizeMD:IsToggled() then windowFlags = windowFlags + ImGuiWindowFlags.AlwaysAutoResize end

        if ImGui.Begin("Detected Modders", true, windowFlags) then
            ImGui.SetWindowFontScale(scale1)
            if next(detectedPlayers) == nil then
                ImGui.Text("No modders detected.")
            else
                for rid, playerData in pairs(detectedPlayers) do
                    local name = playerData.name or "Unknown"
                    local reasons = playerData.reason or "No reason provided"
                    local hasFTag = playerData.hasFTag or false
                    local color = hasFTag and { 0.0, 0.5, 1.0, 1.0 } or { 1.0, 0.0, 0.0, 1.0 }

                    ImGui.TextColored(color[1], color[2], color[3], color[4], name)

                    if ImGui.IsItemHovered() then
                        ImGui.BeginTooltip()
                        ImGui.Text("Detections:")
                        ImGui.Separator()
                        for reason in reasons:gmatch("[^,]+") do
                            ImGui.Text(reason:match("^%s*(.-)%s*$"))
                            ImGui.Dummy(0, spacingmd)
                        end
                        ImGui.Separator()
                        ImGui.Text("Rockstar ID: " .. rid)
                        ImGui.Text(("Average Ping %s"):format(NETWORK.NETWORK_GET_AVERAGE_PING(PlayerData.Id)))
                        ImGui.Text("Has F Tag: " .. (hasFTag and "Yes" or "No"))
                        ImGui.Text("Player ID: " .. PlayerData.Id)
                        ImGui.Text("Player Name: " .. PlayerData.Name)
                        ImGui.Text("Player Tags: " .. (Players.GetTags(PlayerData.Id) or "No Tags"))
                        ImGui.EndTooltip()
                    end

                    ImGui.Separator()
                end
            end
        end
        ImGui.End()
        ImGui.PopStyleColor(stylePushCount)
    end

    Script.QueueJob(function()
        while true do
            detectPlayers()
            Script.Yield(5000)
        end
    end)

    local ShowModdersEvent = nil
    FeatAdd(joaat("ShowModders"), "Draw Modders", eFeatureType.Toggle, "Draw Modders", function(feature)
        if feature:IsToggled() then
            if not ShowModdersEvent then
                ShowModdersEvent = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, ShowModderDisplay)
                GradientLogger("Draw Modders enabled.")
            end
        else
            if ShowModdersEvent then
                EventMgr.RemoveHandler(ShowModdersEvent)
                ShowModdersEvent = nil
                GradientLogger("Draw Modders disabled.")
            end
        end
    end)


    local currentGUIMode = 1
    if not FileMgr.DoesFileExist(themeFolder) then
        FileMgr.CreateDir(themeFolder)
    end
    local function LoadThemeFromJson(filename)
        local filepath = themeFolder .. "\\" .. filename .. ".json"
        GradientLogger("Loading theme from: " .. filepath)

        local file = io.open(filepath, "r")
        if not file then
            GradientLogger("Failed to open theme file: " .. filename)
            return
        end

        local content = file:read("*a")
        file:close()

        local theme = json.decode(content)
        if not theme then
            GradientLogger("Failed to decode json for: " .. tostring(theme))
            return
        end

        for hashStr, data in pairs(theme) do
            local hash = tonumber(hashStr)
            local feat = FeatureMgr.GetFeature(hash)
            if feat and data.value then
                local t = feat:GetType()
                if t == eFeatureType.InputColor4 then
                    if type(data.value) == "table" then
                        feat:SetColor(table.unpack(data.value))
                    end
                elseif t == eFeatureType.Toggle then
                    feat:SetBoolValue(data.value == true)
                elseif t == eFeatureType.SliderInt then
                    feat:SetIntValue(data.value)
                elseif t == eFeatureType.SliderFloat then
                    feat:SetFloatValue(data.value)
                end
            end
        end

        GradientLogger("Theme loaded successfully: " .. filename)
    end
    local defaultpath1 = themeFolder .. "\\DefaultTheme1.lua" 
    local defaultpathold = themeFolder .. "\\DefaultTheme.lua"

    local defaultpath2 = themeFolder .. "\\DefaultTheme.json"
    local bgColor = BGColorelf:GetColor()

    function makeDefaultTheme(filepath)
        local theme = {
            BGColorelf = {30, 30, 30, 255},
            ButtonColor = {2, 0, 0, 41},
            ButtonHoverColor = {100, 100, 100, 41},
            TextColor1 = {255, 255, 255, 255},
            ButtonActiveColor = {255, 255, 255, 41},
            ChildBgColor = {0, 0, 0, 40},
            ComboBgColor = {30, 30, 30, 255},
            ComboBorderColor = {255, 0, 0, 255},
            HeaderColor = {200, 0, 0, 255},
            HeaderHovered = {200, 200, 200, 255},
            HeaderActiveC = {0, 0, 0, 255},
            SliderGrab = {200, 0, 0, 255},
            CheckMarkcolor = {200, 200, 200, 255},
            SliderGrabActive = {255, 255, 255, 255},
            
        }

        local jsonData = json.encode(theme, { indent = true })
        local success = FileMgr.WriteFileContent(filepath, jsonData)

        if success then
            GradientLogger("Default Theme saved successfully: " .. filepath)
        else
            GradientLogger("Failed to save Default Theme: " .. filepath)
        end
    end

    if FileMgr.DoesFileExist(defaultpath1) or FileMgr.DoesFileExist(defaultpathold) then
        FileMgr.DeleteFile(defaultpath1 or defaultpathold)
    end

    if not FileMgr.DoesFileExist(defaultpath2) then
        makeDefaultTheme(defaultpath2)
    end

    if FileMgr.DoesFileExist(defaultpath2) then
        local content = FileMgr.ReadFileContent(defaultpath2)
        local theme = json.decode(content)

        if not theme then
            GradientLogger("Error loading theme: invalid JSON format")
            return
        end

        local function safeUnpack(tbl)
            if not tbl then
                return 0, 0, 0, 255
            end
            return table.unpack(tbl)
        end

        BGColorelf:SetColor(safeUnpack(theme.BGColorelf))
        ButtonColor:SetColor(safeUnpack(theme.ButtonColor))
        ButtonHoverColor:SetColor(safeUnpack(theme.ButtonHoverColor))
        TextColor1:SetColor(safeUnpack(theme.TextColor1))
        ButtonActiveColor:SetColor(safeUnpack(theme.ButtonActiveColor))
        ChildBgColor:SetColor(safeUnpack(theme.ChildBgColor))
        ComboBgColor:SetColor(safeUnpack(theme.ComboBgColor))
        ComboBorderColor:SetColor(safeUnpack(theme.ComboBorderColor))
        HeaderColor:SetColor(safeUnpack(theme.HeaderColor))
        HeaderHovered:SetColor(safeUnpack(theme.HeaderHovered))
        HeaderActiveC:SetColor(safeUnpack(theme.HeaderActiveC))
        CheckMarkcolor:SetColor(safeUnpack(theme.CheckMarkcolor))
        SliderGrab:SetColor(safeUnpack(theme.SliderGrab))
        SliderGrabActive:SetColor(safeUnpack(theme.SliderGrabActive))

        local themeFiles = FileMgr.FindFiles(themeFolder, ".json")
        for i, file in ipairs(themeFiles) do
            themeFiles[i] = file:match("([^\\]+)%.json$")
        end
        GradientLogger("Theme Files Found: " .. table.concat(themeFiles, ", "))
    end

    themeCombo = FeatAdd(joaat("themeCombo11"), "Select Theme", eFeatureType.Combo, "Select a saved theme")

    local selectedThemeFile = nil

    function UpdateThemeCombo()
        local themeFiles = FileMgr.FindFiles(themeFolder, ".json")
        for i, file in ipairs(themeFiles) do
            themeFiles[i] = file:match("([^\\]+)%.json$")
        end
        themeCombo:SetList(themeFiles)
        if #themeFiles > 0 then
            themeCombo:SetListIndex(0)
            selectedThemeFile = themeFiles[1]
        else
            selectedThemeFile = nil
        end
    end

    function OnThemeComboChange()
        local selectedIndex = themeCombo:GetListIndex()
        if selectedIndex and selectedIndex >= 0 then
            selectedThemeFile = themeCombo:GetList()[selectedIndex + 1]
        end
    end

    themeCombo:TriggerCallback(OnThemeComboChange)

    UpdateThemeCombo()

    FeatAdd(joaat("themeload1"), "Load Theme", eFeatureType.Button, "Loads the selected theme",
        function(feat)
            local selectedIndex = themeCombo:GetListIndex()

            if selectedIndex and selectedIndex >= 0 then
                local selectedTheme = themeCombo:GetList()[selectedIndex + 1]
                if selectedTheme then
                    GradientLogger("Loading selected theme: " .. selectedTheme)
                    LoadThemeFromJson(selectedTheme)
                else
                    GradientLogger("No valid theme selected!")
                end
            end
        end)

    local function SaveThemeToJson(filename)
        local filepath = themeFolder .. "\\" .. filename .. ".json"
        if FileMgr.DoesFileExist(filepath) then
            FileMgr.DeleteFile(filepath)
        end

        local themeTable = {}

        for i, feat in ipairs(Features.GuiFeatures) do
            if feat then
                local hash = feat:GetHash()
                local name = feat:GetName()
                local featureType = feat:GetType()
                local value

                if featureType == eFeatureType.InputColor4 then
                    local ok, r, g, b, a = pcall(feat.GetColor, feat)
                    if ok and r and g and b and a then
                        value = { r, g, b, a }
                    end
                elseif featureType == eFeatureType.Toggle then
                    value = feat:IsToggled()
                elseif featureType == eFeatureType.Combo then
                    value = feat:GetListIndex()
                elseif featureType == eFeatureType.SliderInt then
                    value = feat:GetIntValue()
                elseif featureType == eFeatureType.SliderFloat then
                    value = feat:GetFloatValue()
                elseif featureType == eFeatureType.InputText then
                    value = feat:GetStringValue()
                end

                if value ~= nil then
                    themeTable[tostring(hash)] = {
                        value = value,
                        description = name
                    }
                end
            end
        end

        local ok, jsonData = pcall(function()
            return json.encode(themeTable, { indent = true })
        end)

        if not ok or not jsonData then
            GradientLogger("Error encoding theme to JSON")
            return
        end

        local success = FileMgr.WriteFileContent(filepath, jsonData)
        if success then
            GradientLogger("Theme saved successfully: " .. filename)
        else
            GradientLogger("Failed to write theme file.")
        end

        UpdateThemeCombo()
    end

    themename1 = FeatAdd(joaat("themename1"), "File Name", eFeatureType.InputText, "Name the theme")

    SaveTheme = FeatAdd(joaat("themesave1"), "Save Theme", eFeatureType.Button, "Saves the theme to a Lua file", function(feat)
        local filename = themename1:GetStringValue()
        if filename and filename ~= "" then
            SaveThemeToJson(filename)
        end
    end)


    particlesval = GUIFeatAdd(joaat("particlevalue"), "How many particles", eFeatureType.SliderInt,"Change how many lines will show up in the background(lower if fps gets too bad)")
    particleval = GUIFeatAdd(joaat("ParticleVal"), "Particle Effect", eFeatureType.Toggle, "if toggled it enables the particle effect"):SetBoolValue(true)
    draggingToggle = GUIFeatAdd(joaat("draggingToggle"), "Dragging Toggle", eFeatureType.Toggle, "Toggle wether or not you can drag and manipulate the lines in the particle effect")
    curosrcontrol = GUIFeatAdd(joaat("curosrcontrol"), "Cursor Control", eFeatureType.Toggle, "Toggle wether or not you can move the lines in the particle effect with the mouse")
    baseColor = GUIFeatAdd(joaat("PrismBaseColor"), "Prism Base Color", eFeatureType.InputColor4,"Color of the prismatic background")
    prismenabled = GUIFeatAdd(joaat("drawPrism"), "Prismatic background", eFeatureType.Toggle,"Toggle wether or not the prismatic background is enabled")
    vaporwave = GUIFeatAdd(joaat("vaporwave"), "Vapor Wave", eFeatureType.Toggle, "Toggle Vapor Wave")
    windowsizee = GUIFeatAdd(joaat("windowsizexy"), "Window Size", eFeatureType.SliderFloat, "Set the size of the window")
    hexglow = GUIFeatAdd(joaat("hexGlow"), "Hex Glow Grid", eFeatureType.Toggle, "Cyberpunk grid overlay")
    playpong = GUIFeatAdd(joaat("playpong"), "Play Pong(WIP)", eFeatureType.Toggle, "Play a simple pong game")
    closeGUI = FeatAdd(joaat("CloseGUI"), "Close GUI with cherax", eFeatureType.Toggle, "if toggled it Closes the GUI when the menu is closed")
    LineColor = GUIFeatAdd(joaat("LineColor"), "Line Color", eFeatureType.InputColor4, "Sets the color of the lines")
    toline = GUIFeatAdd(joaat("toLine"), "To cursor line color", eFeatureType.InputColor4, "Sets the color of the lines coming to the cursor")
    snowflakesToggle = GUIFeatAdd(joaat("background_snowflakes"), "Enable Snowflakes", eFeatureType.Toggle, "Toggle falling snowflakes")
    gridToggle = GUIFeatAdd(joaat("background_grid"), "Enable Grid", eFeatureType.Toggle, "Toggle cyber grid background")
    neonPrismToggle = GUIFeatAdd(joaat("background_neonprism"), "Enable Neon Prism", eFeatureType.Toggle, "Toggle neon prism background")
    snowflakeColor = GUIFeatAdd(joaat("snowflake_color"), "Snowflake Color", eFeatureType.InputColor4, "Color of snowflakes")
    gridLineColor = GUIFeatAdd(joaat("grid_line_color"), "Grid Line Color", eFeatureType.InputColor4, "Color of grid lines")
    prismColorTop = GUIFeatAdd(joaat("prism_color_top"), "Prism Top Color", eFeatureType.InputColor4, "Top color of neon prism lines")
    prismColorBottom = GUIFeatAdd(joaat("prism_color_bottom"), "Prism Bottom Color", eFeatureType.InputColor4, "Bottom color of neon prism lines")
    prismTriangleColor = GUIFeatAdd(joaat("prism_triangle_color"), "Prism Triangle Color", eFeatureType.InputColor4, "Triangle color in neon prism")
    circleval = GUIFeatAdd(joaat("circleval"), "Spinny Circle", eFeatureType.Toggle, "Toggle wether or not the spinny circle shows up")
    circlecolor = GUIFeatAdd(joaat("circleColor"), "Spinny Circle color", eFeatureType.InputColor4, "Change the color of the spinny circle")
    
    snowflakeColor:SetColor(255, 255, 255, 200)
    gridLineColor:SetColor(255, 255, 255, 20)
    prismColorTop:SetColor(204, 51, 255, 180)
    prismColorBottom:SetColor(51, 153, 255, 180)
    prismTriangleColor:SetColor(100, 200, 255, 150)
    toline:SetColor(200, 55, 55, 255)
    LineColor:SetColor(255, 0, 0, 255)
    baseColor:SetColor(255, 0, 0, 0)
    particlesval:SetMinValue(45)
    particlesval:SetMaxValue(250)
    particlesval:SetValue(90)
    windowsizee:SetMinValue(0.4)
    windowsizee:SetMaxValue(1.8)
    windowsizee:SetFloatValue(0.4)
    circlecolor:SetColor(255, 0, 0, 255)


    SnowflakesArray = {}

    lastTime = os.clock()


    spinnycircle = {}

    function RenderSpinnyCircle()
        if not circleval:IsToggled() then return end

        spinnycircle.windowPosX, spinnycircle.windowPosY = ImGui.GetWindowPos()
        spinnycircle.windowSizeX, spinnycircle.windowSizeY = ImGui.GetWindowSize()
        spinnycircle.centerX = spinnycircle.windowPosX + spinnycircle.windowSizeX * 0.5
        spinnycircle.centerY = spinnycircle.windowPosY + spinnycircle.windowSizeY * 0.5

        spinnycircle.t = os.clock()
        spinnycircle.segments = 36
        spinnycircle.baseRadius = 30.0                                 
        spinnycircle.pulse = math.sin(spinnycircle.t * 4.0) * 20.0    
        spinnycircle.spinnerRadius = spinnycircle.baseRadius + spinnycircle.pulse

        spinnycircle.rf, spinnycircle.gf, spinnycircle.bf, spinnycircle.af = circlecolor:GetColor()
        spinnycircle.r = math.floor(spinnycircle.rf)
        spinnycircle.g = math.floor(spinnycircle.gf)
        spinnycircle.b = math.floor(spinnycircle.bf)

        for i = 0, spinnycircle.segments - 1 do
            spinnycircle.angle = (2 * math.pi * i / spinnycircle.segments) + spinnycircle.t * 2.0
            spinnycircle.x = spinnycircle.centerX + math.cos(spinnycircle.angle) * spinnycircle.spinnerRadius
            spinnycircle.y = spinnycircle.centerY + math.sin(spinnycircle.angle) * spinnycircle.spinnerRadius

            spinnycircle.fade = i / spinnycircle.segments
            spinnycircle.alpha = math.floor(255 *
            (0.3 + 0.7 * spinnycircle.fade * (0.6 + 0.4 * math.sin(spinnycircle.t * 3.0 + i))))
            spinnycircle.size = 3.0 + 3.0 * spinnycircle.fade    

            ImGui.AddCircleFilled(spinnycircle.x, spinnycircle.y, spinnycircle.size, spinnycircle.r, spinnycircle.g,
                spinnycircle.b, spinnycircle.alpha, 10)
        end
    end

    function InitSnowflakes(snowflakes, count, screenSize)
        for i = 1, count do
            table.insert(snowflakes, {
                pos = {
                    x = math.random() * screenSize.x,
                    y = math.random() * screenSize.y
                },
                radius = math.random(1, 3)
            })
        end
    end

    function RenderSnowflakesBackground(snowflakes, deltaTime)
        if not snowflakesToggle:GetBoolValue() then return end

        local snowflake = {}
        snowflake.originX, snowflake.originY = ImGui.GetWindowPos()
        snowflake.sizeX, snowflake.sizeY = ImGui.GetWindowSize()

        if #snowflakes == 0 then
            InitSnowflakes(snowflakes, 100, { x = snowflake.sizeX, y = snowflake.sizeY })
        end

        snowflake.t = os.clock()
        snowflake.r, snowflake.g, snowflake.b, snowflake.a = snowflakeColor:GetColor()

        for i, flake in ipairs(snowflakes) do
            flake.pos.y = flake.pos.y + 2

            if flake.pos.y > snowflake.sizeY then
                flake.pos.y = -flake.radius
                flake.pos.x = math.random() * snowflake.sizeX
            end

            snowflake.drawX = snowflake.originX + flake.pos.x
            snowflake.drawY = snowflake.originY + flake.pos.y

            snowflake.shimmer = 0.6 + 0.4 * math.sin(snowflake.t * 4.0 + flake.pos.y * 0.05)
            snowflake.adjustedAlpha = math.floor(snowflake.a * snowflake.shimmer)
            snowflake.glowAlpha = math.floor(snowflake.adjustedAlpha * 0.5)

            ImGui.AddCircleFilled(snowflake.drawX, snowflake.drawY, flake.radius, snowflake.r, snowflake.g, snowflake.b,
                snowflake.adjustedAlpha, 10)
            ImGui.AddCircleFilled(snowflake.drawX, snowflake.drawY, flake.radius + 1.5, snowflake.r, snowflake.g, snowflake
            .b, snowflake.glowAlpha, 10)
        end
    end

    gridBG = {}

    function RenderGridBackground()
        if not gridToggle:GetBoolValue() then return end

        gridBG.originX, gridBG.originY = ImGui.GetWindowPos()
        gridBG.sizeX, gridBG.sizeY = ImGui.GetWindowSize()

        gridBG.t = ImGui.GetTime()
        gridBG.spacing = 20.0
        gridBG.scroll = (gridBG.t * -30.0) % gridBG.spacing

        gridBG.r, gridBG.g, gridBG.b, gridBG.a = gridLineColor:GetColor()

        for x = 0, gridBG.sizeX, gridBG.spacing do
            ImGui.AddLine(
                gridBG.originX + x, gridBG.originY,
                gridBG.originX + x, gridBG.originY + gridBG.sizeY,
                gridBG.r, gridBG.g, gridBG.b, gridBG.a
            )
        end

        for y = 0, gridBG.sizeY + gridBG.spacing, gridBG.spacing do
            ImGui.AddLine(
                gridBG.originX, gridBG.originY + y - gridBG.scroll,
                gridBG.originX + gridBG.sizeX, gridBG.originY + y - gridBG.scroll,
                gridBG.r, gridBG.g, gridBG.b, gridBG.a
            )
        end
    end

    NeonPrism = {}

    function RenderNeonPrism()
        if not neonPrismToggle:GetBoolValue() then return end

        NeonPrism.OriginX, NeonPrism.OriginY = ImGui.GetWindowPos()
        NeonPrism.SizeX, NeonPrism.SizeY = ImGui.GetWindowSize()
        NeonPrism.Time = ImGui.GetTime()

        NeonPrism.CenterX, NeonPrism.CenterY = NeonPrism.OriginX + NeonPrism.SizeX * 0.5,
            NeonPrism.OriginY + NeonPrism.SizeY * 0.5
        NeonPrism.PrismHeight, NeonPrism.MaxWidth, NeonPrism.LineCount = NeonPrism.SizeY, NeonPrism.SizeX * 0.6, 30

        NeonPrism.TopR, NeonPrism.TopG, NeonPrism.TopB, NeonPrism.TopA = prismColorTop:GetColor()
        NeonPrism.BottomR, NeonPrism.BottomG, NeonPrism.BottomB, NeonPrism.BottomA = prismColorBottom:GetColor()
        NeonPrism.TriR, NeonPrism.TriG, NeonPrism.TriB, NeonPrism.TriA = prismTriangleColor:GetColor()

        for i = 0, NeonPrism.LineCount - 1 do
            NeonPrism.Ratio = i / (NeonPrism.LineCount - 1)
            NeonPrism.Y = NeonPrism.CenterY - NeonPrism.PrismHeight * 0.5 + NeonPrism.Ratio * NeonPrism.PrismHeight
            NeonPrism.Width = NeonPrism.MaxWidth * NeonPrism.Ratio
            NeonPrism.Pulse = 0.5 + 0.5 * math.sin(NeonPrism.Time * 2.0 + NeonPrism.Ratio * 5.0)

            ImGui.AddLine(
                NeonPrism.CenterX - NeonPrism.Width * 0.3, NeonPrism.Y,
                NeonPrism.CenterX + NeonPrism.Width * 0.3, NeonPrism.Y,
                NeonPrism.TopR, NeonPrism.TopG, NeonPrism.TopB, math.floor(NeonPrism.TopA * (0.7 * NeonPrism.Pulse)),
                math.floor(1.5 + NeonPrism.Ratio * 2.0)
)

            ImGui.AddLine(
                NeonPrism.CenterX - NeonPrism.Width * 0.5, NeonPrism.Y + 2.0,
                NeonPrism.CenterX + NeonPrism.Width * 0.5, NeonPrism.Y + 2.0,
                NeonPrism.BottomR, NeonPrism.BottomG, NeonPrism.BottomB,
                math.floor(NeonPrism.BottomA * (0.7 * NeonPrism.Pulse)), math.floor(0.8 + NeonPrism.Ratio * 1.5)
            )
        end

        ImGui.AddTriangle(
            NeonPrism.CenterX, NeonPrism.CenterY - NeonPrism.PrismHeight * 0.5,
            NeonPrism.CenterX - NeonPrism.MaxWidth * 0.5, NeonPrism.CenterY + NeonPrism.PrismHeight * 0.5,
            NeonPrism.CenterX + NeonPrism.MaxWidth * 0.5, NeonPrism.CenterY + NeonPrism.PrismHeight * 0.5,
            NeonPrism.TriR, NeonPrism.TriG, NeonPrism.TriB, math.floor(NeonPrism.TriA), 2.5
        )
    end

    local particle = {
        lastFrameTime = os.clock(),
        init_particle = false,
        numParticles = 90,
        PARTICLE_CONNECTION_DISTANCE = 100,
        CURSOR_CONNECTION_DISTANCE = 150,
        particlePositions = {},
        particleVelocities = {}
    }

    function DrawParticles(deltaTime)
        if not FeatureMgr.IsFeatureEnabled(joaat("ParticleVal")) then return end

        local windowPosX, windowPosY = ImGui.GetWindowPos()
        local windowWidth, windowHeight = ImGui.GetWindowSize()

        local newCount = particlesval:GetIntValue()
        if newCount ~= particle.numParticles then
            particle.numParticles = newCount
            particle.init_particle = false
        end

        if not particle.init_particle then
            particle.particlePositions = {}
            particle.particleVelocities = {}

            for i = 1, particle.numParticles do
                particle.particlePositions[i] = {
                    x = windowPosX + math.random() * windowWidth,
                    y = windowPosY + math.random() * windowHeight
                }
                particle.particleVelocities[i] = {
                    x = (math.random() - 0.5) * 100,
                    y = (math.random() - 0.5) * 100
                }
            end
            particle.init_particle = true
        end

        local cursorPosX, cursorPosY = ImGui.GetMousePos()

        for i = 1, particle.numParticles do
            local pi = particle.particlePositions[i]

            for j = i + 1, particle.numParticles do
                local pj = particle.particlePositions[j]
                local dx, dy = pj.x - pi.x, pj.y - pi.y
                local dist = math.sqrt(dx * dx + dy * dy)
                local opacity = math.max(0, 1.0 - (dist / particle.PARTICLE_CONNECTION_DISTANCE))
                local r, g, b = LineColor:GetColor()
                if opacity > 0.0 then
                    ImGui.AddLine(pi.x, pi.y, pj.x, pj.y, r, g, b, math.floor(opacity * 255), 1.0)
                end
            end

            local dx, dy = cursorPosX - pi.x, cursorPosY - pi.y
            local distToCursor = math.sqrt(dx * dx + dy * dy)
            local opacityCursor = math.max(0, 1.0 - (distToCursor / particle.CURSOR_CONNECTION_DISTANCE))
            local tolineR, tolineG, tolineB = toline:GetColor()
            if opacityCursor > 0.0 then
                ImGui.AddLine(cursorPosX, cursorPosY, pi.x, pi.y, tolineR, tolineG, tolineB, math.floor(opacityCursor * 255),
                    1.2)
            end

            pi.x = pi.x + particle.particleVelocities[i].x * deltaTime
            pi.y = pi.y + particle.particleVelocities[i].y * deltaTime

            if pi.x < windowPosX then
                pi.x = windowPosX + windowWidth
            elseif pi.x > windowPosX + windowWidth then
                pi.x = windowPosX
            end

            if pi.y < windowPosY then
                pi.y = windowPosY + windowHeight
            elseif pi.y > windowPosY + windowHeight then
                pi.y = windowPosY
            end
        end
    end

    function UpdateParticles()
        local now = os.clock()
        local deltaTime = now - particle.lastFrameTime
        particle.lastFrameTime = now

        DrawParticles(deltaTime)
    end


    prismgrid = {
        facets = {},
        facetCount = 100,
        resolution = 60,
        lightDir = { x = 0.6, y = -0.8 }
    }



    function generatePrismGrid(w, h)
        prismgrid.facets = {}
        for y = 0, h, prismgrid.resolution do
            for x = 0, w, prismgrid.resolution do
                local x1, y1 = x, y
                local x2, y2 = x + prismgrid.resolution, y
                local x3, y3 = x, y + prismgrid.resolution
                local x4, y4 = x + prismgrid.resolution, y + prismgrid.resolution

                if ((x + y) / prismgrid.resolution) % 2 == 0 then
                    table.insert(prismgrid.facets, { x1 = x1, y1 = y1, x2 = x2, y2 = y2, x3 = x4, y3 = y4 })
                    table.insert(prismgrid.facets, { x1 = x1, y1 = y1, x2 = x4, y2 = y4, x3 = x3, y3 = y3 })
                else
                    table.insert(prismgrid.facets, { x1 = x1, y1 = y1, x2 = x2, y2 = y2, x3 = x3, y3 = y3 })
                    table.insert(prismgrid.facets, { x1 = x2, y1 = y2, x2 = x4, y2 = y4, x3 = x3, y3 = y3 })
                end
            end
        end
    end

    function DrawPrismBackground()
        if not prismenabled:IsToggled() then return end

        prismgrid.winX, prismgrid.winY = ImGui.GetWindowPos()
        prismgrid.winW, prismgrid.winH = ImGui.GetWindowSize()

        if #prismgrid.facets == 0 then generatePrismGrid(prismgrid.winW, prismgrid.winH) end

        prismgrid.r, prismgrid.g, prismgrid.b = baseColor:GetColor()
        prismgrid.mx, prismgrid.my = ImGui.GetMousePos()

        for _, tri in ipairs(prismgrid.facets) do
            prismgrid.x1 = prismgrid.winX + tri.x1
            prismgrid.y1 = prismgrid.winY + tri.y1
            prismgrid.x2 = prismgrid.winX + tri.x2
            prismgrid.y2 = prismgrid.winY + tri.y2
            prismgrid.x3 = prismgrid.winX + tri.x3
            prismgrid.y3 = prismgrid.winY + tri.y3

            prismgrid.cx = (prismgrid.x1 + prismgrid.x2 + prismgrid.x3) / 3
            prismgrid.cy = (prismgrid.y1 + prismgrid.y2 + prismgrid.y3) / 3

            prismgrid.dx = (prismgrid.x2 - prismgrid.x1 + prismgrid.x3 - prismgrid.x1) / 2
            prismgrid.dy = (prismgrid.y2 - prismgrid.y1 + prismgrid.y3 - prismgrid.y1) / 2
            prismgrid.len = math.sqrt(prismgrid.dx * prismgrid.dx + prismgrid.dy * prismgrid.dy)
            prismgrid.nx, prismgrid.ny = prismgrid.dx / prismgrid.len, prismgrid.dy / prismgrid.len

            prismgrid.dot = prismgrid.nx * prismgrid.lightDir.x + prismgrid.ny * prismgrid.lightDir.y
            prismgrid.intensity = math.max(0.25, prismgrid.dot)

            prismgrid.dist = math.sqrt((prismgrid.mx - prismgrid.cx) ^ 2 + (prismgrid.my - prismgrid.cy) ^ 2)
            prismgrid.hoverBoost = 1.0 + math.max(0, 0.15 - prismgrid.dist / 500)

            prismgrid.rr = math.min(255, prismgrid.r * prismgrid.intensity * prismgrid.hoverBoost)
            prismgrid.gg = math.min(255, prismgrid.g * prismgrid.intensity * prismgrid.hoverBoost)
            prismgrid.bb = math.min(255, prismgrid.b * prismgrid.intensity * prismgrid.hoverBoost)

            ImGui.AddTriangleFilled(prismgrid.x1, prismgrid.y1, prismgrid.x2, prismgrid.y2, prismgrid.x3, prismgrid.y3,
                prismgrid.rr, prismgrid.gg, prismgrid.bb, 255)
        end
    end
    function RenderVaporwaveGradient()
        if not vaporwave:IsToggled() then return end
        local posX, posY = ImGui.GetWindowPos()
        local sizeX, sizeY = ImGui.GetWindowSize()

        for i = 0, sizeY do
            local fade = i / sizeY
            local r = math.floor(255 * (0.5 + 0.5 * math.sin(fade * math.pi * 2 + os.clock())))
            local g = math.floor(255 * (0.5 + 0.5 * math.sin(fade * math.pi * 2 + os.clock() + 2 * math.pi / 3)))
            local b = math.floor(255 * (0.5 + 0.5 * math.sin(fade * math.pi * 2 + os.clock() + 4 * math.pi / 3)))
            ImGui.AddRectFilled(posX, posY + i, posX + sizeX, posY + i + 1, r, g, b, 40)
        end
    end

    function RenderHexGlow()
        if not hexglow:IsToggled() then return end
        local x, y = ImGui.GetWindowPos()
        local w, h = ImGui.GetWindowSize()
        local spacing = 20
        local time = os.clock()
        for gx = 0, w, spacing do
            for gy = 0, h, spacing do
                local alpha = math.floor(60 + 40 * math.sin((gx + gy) * 0.1 + time * 2))
                ImGui.AddRectFilled(x + gx, y + gy, x + gx + 4, y + gy + 4, 0, 255, 100, alpha)
                
            end
        end
    end  

    ball = { x = 200, y = 200, dx = 2, dy = 2, size = 10, speed = 2 }
    paddle1 = { y = 200 }
    paddle2 = { y = 200 }
    paddleHeight = 60
    score1 = 0
    score2 = 0
    
    Script.RegisterLooped(function()
        ball.x = ball.x + ball.dx
        ball.y = ball.y + ball.dy
    
        if ball.y < 0 or ball.y + ball.size > 400 then
            ball.dy = -ball.dy
        end
    
        if ball.x < 0 then
            score2 = score2 + 1
            ball.x, ball.y = 240, 200
            ball.speed = 2
            ball.dx = ball.speed
            ball.dy = ball.speed * (math.random() > 0.5 and 1 or -1)
        end
    
        if ball.x + ball.size > 500 then
            score1 = score1 + 1
            ball.x, ball.y = 240, 200
            ball.speed = 2
            ball.dx = -ball.speed
            ball.dy = ball.speed * (math.random() > 0.5 and 1 or -1)
        end

        if ball.x < 40 and ball.y + ball.size > paddle1.y and ball.y < paddle1.y + paddleHeight then
            ball.dx = math.abs(ball.dx) 
            ball.speed = ball.speed + 0.2
            ball.dx = ball.speed
        end
    
        if ball.x + ball.size > 460 and ball.y + ball.size > paddle2.y and ball.y < paddle2.y + paddleHeight then
            ball.dx = -math.abs(ball.dx)
            ball.speed = ball.speed + 0.2
            ball.dx = -ball.speed
        end
    
        Script.Yield(10)
    end)
    
    function RenderPong()
        if not playpong:IsToggled() then return end 
        if ImGui.Begin("Pong", true, ImGuiWindowFlags.NoTitleBar) then
            local winX, winY = ImGui.GetWindowPos()
    
            ImGui.AddRectFilled(winX + ball.x, winY + ball.y, winX + ball.x + ball.size, winY + ball.y + ball.size, 255, 255, 255, 255)
    
            ImGui.AddRectFilled(winX + 20, winY + paddle1.y, winX + 30, winY + paddle1.y + paddleHeight, 255, 255, 255, 255)
            ImGui.AddRectFilled(winX + 470, winY + paddle2.y, winX + 480, winY + paddle2.y + paddleHeight, 255, 255, 255, 255)
    
            local _, my = ImGui.GetMousePos()
            paddle1.y = my - paddleHeight / 2
    
            paddle2.y = ball.y - paddleHeight / 2
    
            ImGui.SetCursorPos(200, 10)
            ImGui.Text(string.format("Score: %d  -  %d", score1, score2))
    
            ImGui.End()
        end
    end

    lastMainTab = mainMenuTab
    elfTab = 1
    lastElfTab = elfTab
    lastInxTab = inxTab
    mainMenuTab = 1
    currentTime = os.clock()
    deltaTime = currentTime - lastTime
    lastTime = currentTime
    
    if mainMenuTab ~= lastMainTab then
        lastMainTab = mainMenuTab
    elseif mainMenuTab == 1 and elfTab ~= lastElfTab then
        lastElfTab = elfTab
    elseif mainMenuTab == 2 and inxTab ~= lastInxTab then
        lastInxTab = inxTab
    end
    
    function RenderMainGUI()   -- fucking dumb nigger function cuz EventMgr is gay 
        if closeGUI:IsToggled() then
            if not GUI.IsOpen() then
                return
            end
        end
        local windowX, windowY = ImGui.GetWindowPos()
        ImGui.SetWindowPos(windowX - 600, windowY, ImGuiCond.Always)
        local windowSizex, windowSizey = ImGui.GetDisplaySize()
        local nextWindowX = windowSizex * windowsizee:GetFloatValue()
        local nextWindowY = windowSizey * windowsizee:GetFloatValue()
        ImGui.SetNextWindowSize(nextWindowX, nextWindowY)

        local stylePushCount = 0 
        local stylePushCount1 = 0
        if mainMenuTab == 2 then
            local colors = {
                { ImGuiCol.Text,                0, 0, 0, 255 }, 
                { ImGuiCol.TextDisabled,        128, 128, 128, 255 }, 
                { ImGuiCol.WindowBg,            255, 182, 193, 255 },
                { ImGuiCol.ChildBg,             255, 228, 225, 40 },
                { ImGuiCol.PopupBg,             255, 240, 245, 255 }, 
                { ImGuiCol.Border,              255, 182, 193, 255 },
                { ImGuiCol.BorderShadow,        255, 192, 203, 255 }, 
                { ImGuiCol.FrameBg,             255, 182, 193, 255 }, 
                { ImGuiCol.FrameBgHovered,      255, 192, 203, 255 },
                { ImGuiCol.FrameBgActive,       255, 105, 180, 255 }, 
                { ImGuiCol.TitleBg,             221, 160, 221, 255 }, 
                { ImGuiCol.TitleBgActive,       186, 85, 211, 255 }, 
                { ImGuiCol.TitleBgCollapsed,    255, 182, 193, 255 },
                { ImGuiCol.MenuBarBg,           255, 228, 225, 255 },
                { ImGuiCol.ScrollbarBg,         255, 240, 245, 255 },
                { ImGuiCol.ScrollbarGrab,       255, 105, 180, 255 },
                { ImGuiCol.ScrollbarGrabHovered,255, 140, 186, 255 },
                { ImGuiCol.ScrollbarGrabActive, 255, 20, 147, 255 }, 
                { ImGuiCol.CheckMark,           186, 85, 211, 255 }, 
                { ImGuiCol.SliderGrab,          255, 182, 193, 255 }, 
                { ImGuiCol.SliderGrabActive,    255, 20, 147, 255 }, 
                { ImGuiCol.Button,              255, 105, 180, 255 }, 
                { ImGuiCol.ButtonHovered,       255, 20, 147, 255 }, 
                { ImGuiCol.ButtonActive,        255, 140, 186, 255 }, 
                { ImGuiCol.Header,              186, 85, 211, 255 }, 
                { ImGuiCol.HeaderHovered,       221, 160, 221, 255 }, 
                { ImGuiCol.HeaderActive,        148, 0, 211, 255 }, 
                { ImGuiCol.Separator,           255, 182, 193, 255 }, 
                { ImGuiCol.SeparatorHovered,    255, 105, 180, 255 }, 
                { ImGuiCol.SeparatorActive,     255, 20, 147, 255 }, 
                { ImGuiCol.ResizeGrip,          255, 105, 180, 255 },
                { ImGuiCol.ResizeGripHovered,   255, 20, 147, 255 }, 
                { ImGuiCol.ResizeGripActive,    255, 140, 186, 255 }, 
                { ImGuiCol.Tab,                 221, 160, 221, 255 }, 
                { ImGuiCol.TabHovered,          255, 182, 193, 255 }, 
                { ImGuiCol.TabActive,           186, 85, 211, 255 }, 
                { ImGuiCol.TabUnfocused,        255, 228, 225, 255 },
                { ImGuiCol.TabUnfocusedActive,  255, 192, 203, 255 }, 
                { ImGuiCol.PlotLines,           186, 85, 211, 255 }, 
                { ImGuiCol.PlotLinesHovered,    255, 20, 147, 255 }, 
                { ImGuiCol.PlotHistogram,       255, 105, 180, 255 },
                { ImGuiCol.PlotHistogramHovered,255, 20, 147, 255 }, 
                { ImGuiCol.TextSelectedBg,      255, 182, 193, 128 }, 
                { ImGuiCol.DragDropTarget,      255, 20, 147, 128 },
                { ImGuiCol.NavHighlight,        255, 105, 180, 255 },
                { ImGuiCol.NavWindowingHighlight,255, 182, 193, 255 }, 
                { ImGuiCol.NavWindowingDimBg,   255, 240, 245, 192 }, 
                { ImGuiCol.ModalWindowDimBg,    255, 240, 245, 192 }, 
            }
                for _, color in ipairs(colors) do
                    local col, r, g, b, a = table.unpack(color)
                    ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, (a or 255) / 255)
                    stylePushCount = stylePushCount + 1
                end
            elseif mainMenuTab == 0 or 1 then
                colors = {
                    { ImGuiCol.WindowBg,             BGColorelf:GetColor() },
                    { ImGuiCol.ScrollbarGrab,        ButtonColor:GetColor() },
                    { ImGuiCol.ScrollbarGrabActive,  ButtonActiveColor:GetColor() },
                    { ImGuiCol.ScrollbarGrabHovered, ButtonHoverColor:GetColor() },
                    { ImGuiCol.Header,               HeaderColor:GetColor() },
                    { ImGuiCol.HeaderActive,         HeaderActiveC:GetColor() },
                    { ImGuiCol.HeaderHovered,        HeaderHovered:GetColor() },
                    { ImGuiCol.FrameBg,              ComboBgColor:GetColor() },
                    { ImGuiCol.FrameBgHovered,       ComboBgColor:GetColor() },
                    { ImGuiCol.FrameBgActive,        ComboBgColor:GetColor() },
                    { ImGuiCol.Border,               ComboBorderColor:GetColor() },
                    { ImGuiCol.PopupBg,              ComboBgColor:GetColor() },
                    { ImGuiCol.Separator,            ComboBorderColor:GetColor() },
                    { ImGuiCol.Button,               ButtonColor:GetColor() },
                    { ImGuiCol.ButtonHovered,        ButtonHoverColor:GetColor() },
                    { ImGuiCol.ButtonActive,         ButtonActiveColor:GetColor() },
                    { ImGuiCol.Text,                 TextColor1:GetColor() },
                    { ImGuiCol.ChildBg,              ChildBgColor:GetColor() },
                    { ImGuiCol.CheckMark,            CheckMarkcolor:GetColor() },
                    { ImGuiCol.ResizeGrip,           CheckMarkcolor:GetColor() },
                    { ImGuiCol.SliderGrab,           SliderGrab:GetColor() },
                    { ImGuiCol.SliderGrabActive,     SliderGrabActive:GetColor() }
                }
                for _, color in ipairs(colors) do
                    local col, r, g, b, a = table.unpack(color)
                    ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, (a or 255) / 255)
                    stylePushCount1 = stylePushCount1 + 1
                end
            end
            if ImGui.Begin("Elf Menu", true, ImGuiWindowFlags.NoCollapse | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoTitleBar + (draggingToggle:IsToggled() and ImGuiWindowFlags.NoMove or 0)) then
                if ImGui.BeginChild("Header", 0, 45, true, ImGuiWindowFlags.NoScrollbar) then
                    ImGui.PushStyleColor(ImGuiCol.ChildBg, HeaderColor:GetColor())
                    ImGui.PushStyleColor(ImGuiCol.Text, TextColor1:GetColor())
                    ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Elf Menu")) / 2)
                    ImGui.SetCursorPosY(15)
                    ImGui.Text("Elf Menu")
                    ImGui.PopStyleColor(2)
                end
            ImGui.EndChild()            
        
            local windowWidth = ImGui.GetWindowWidth()
            local windowHeight = ImGui.GetWindowHeight()
            local windowPosX, windowPosY = ImGui.GetWindowPos()
            local currentTime = os.clock()
            local deltaTime = currentTime - lastTime
            lastTime = currentTime

            if not particle.init_particle or #particle.particlePositions ~= particle.numParticles then
                particle.particlePositions = {}
                particle.particleVelocities = {}
                for i = 1, particle.numParticles do
                    particle.particlePositions[i] = {
                        x = windowPosX + math.random() * windowWidth,
                        y = windowPosY + math.random() * windowHeight
                    }
                    particle.particleVelocities[i] = {
                        x = (math.random() - 0.5) * 100,
                        y = (math.random() - 0.5) * 100
                    }
                end
                particle.init_particle = true
            end

            for i = 1, particle.numParticles do
                if not particle.particlePositions[i] or not particle.particleVelocities[i] then
                    particle.particlePositions[i] = {
                        x = windowPosX + math.random() * windowWidth,
                        y = windowPosY + math.random() * windowHeight
                    }
                    particle.particleVelocities[i] = {
                        x = (math.random() - 0.5) * 100,
                        y = (math.random() - 0.5) * 100
                    }
                end
            end

            local mouseX, mouseY = ImGui.GetMousePos()
            local mouseOver = mouseX >= windowPosX and mouseX <= windowPosX + windowWidth and mouseY >= windowPosY and mouseY <= windowPosY + windowHeight

            _lastMouseX = _lastMouseX or mouseX
            _lastMouseY = _lastMouseY or mouseY
            local mouseDX = mouseX - _lastMouseX
            local mouseDY = mouseY - _lastMouseY
            local mouseSpeed = math.sqrt(mouseDX * mouseDX + mouseDY * mouseDY)
            _lastMouseX = mouseX
            _lastMouseY = mouseY

            local dragging = mouseOver and ImGui.IsMouseDown(0)
            local dragRadius = 60

            local baseSpeed = 45
            local damping = 0.98

            for i = 1, particle.numParticles do
                local pos = particle.particlePositions[i]
                local vel = particle.particleVelocities[i]
                pos.x = pos.x + vel.x * deltaTime
                pos.y = pos.y + vel.y * deltaTime

                vel.x = vel.x * damping
                vel.y = vel.y * damping

                local speed = math.sqrt(vel.x * vel.x + vel.y * vel.y)
                if speed < 20 then
                    if speed == 0 then
                        vel.x = baseSpeed
                        vel.y = 0
                    else
                        vel.x = vel.x / speed * baseSpeed
                        vel.y = vel.y / speed * baseSpeed
                    end
                end

                local dx = mouseX - pos.x
                local dy = mouseY - pos.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if draggingToggle:IsToggled() then 
                    if dragging and dist < dragRadius then
                        pos.x = pos.x + (dx) * 0.35
                        pos.y = pos.y + (dy) * 0.35
                        vel.x = vel.x * 0.7
                        vel.y = vel.y * 0.7
                    end
                end
            
                if curosrcontrol:IsToggled() then 
                    if mouseOver then
                        if mouseSpeed > 2 and dist < 120 then
                            local dirX = -dx / dist 
                            local dirY = -dy / dist 

                            vel.x = vel.x + dirX * mouseSpeed * 2
                            vel.y = vel.y + dirY * mouseSpeed * 2
                        end
                    end
                end

                if pos.x < windowPosX then
                    pos.x = windowPosX
                    vel.x = math.abs(vel.x)
                elseif pos.x > windowPosX + windowWidth then
                    pos.x = windowPosX + windowWidth
                    vel.x = -math.abs(vel.x)
                end

                if pos.y < windowPosY then
                    pos.y = windowPosY
                    vel.y = math.abs(vel.y)
                elseif pos.y > windowPosY + windowHeight then
                    pos.y = windowPosY + windowHeight
                    vel.y = -math.abs(vel.y)
                end
            end

            for i = #particle.particlePositions + 1, particle.numParticles do
                particle.particlePositions[i] = {
                    x = windowPosX + math.random() * windowWidth,
                    y = windowPosY + math.random() * windowHeight
                }
                particle.particleVelocities[i] = {
                    x = (math.random() - 0.5) * 100,
                    y = (math.random() - 0.5) * 100
                }
            end

            local currentTime = os.clock()
            local deltaTime = currentTime - lastTime
            lastTime = currentTime

            for y = 1, gridHeight do
                grid[y] = {}
                for x = 1, gridWidth do
                    grid[y][x] = 0
                end
            end

            DrawPrismBackground()
            RenderSpinnyCircle()
            UpdateParticles()
            RenderVaporwaveGradient()
            RenderSnowflakesBackground(SnowflakesArray, deltaTime)
            RenderGridBackground()
            RenderNeonPrism()
            RenderHexGlow()
            RenderPong()

           if ImGui.BeginChild("TopBar", 0, 34, true, ImGuiWindowFlags.NoNav) then
                ImGui.SetCursorPosY(8) 
                local totalButtonWidth = 60 * 2 + 9  
                ImGui.SetCursorPosX((ImGui.GetWindowWidth() - totalButtonWidth) * 0.5)

                if ImGui.Button("Elf", 60, 20) then mainMenuTab = 1 end
                ImGui.SameLine()
                if ImGui.Button("Inx", 60, 20) then mainMenuTab = 2 end

            end
            ImGui.EndChild()


            ImGui.BeginChild("LeftBar", 100, 0, true)
            if mainMenuTab == 1 then
                if ImGui.Button("Session", 90, 30) then elfTab = 1 end
                if ImGui.Button("Self", 90, 30) then elfTab = 2 end
                if ImGui.Button("Vehicle", 90, 30) then elfTab = 3 end
                if ImGui.Button("Colors/settings", 90, 30) then elfTab = 4 end
            elseif mainMenuTab == 2 then

                if ImGui.Button("Vehicle", 90, 30) then inxTab = 1 end
                if ImGui.Button("UI", 90, 30) then inxTab = 2 end
                if ImGui.Button("Stats", 90, 30) then inxTab = 3 end
                if ImGui.Button("Debug", 90, 30) then inxTab = 4 end

            end
            ImGui.EndChild()

            ImGui.SameLine()
            ImGui.BeginChild("MainContent", 0, 0, true)
            if mainMenuTab == 2 then
                ImGui.TextColored(0,0,0,1,"This GUI color was requested to do by inxaneDev :)")
            end
          
            if mainMenuTab == 1 then
                ImGui.Separator()
                if elfTab == 1 then   
                    if ImGui.BeginChild("Quality of life", 0, 45, true, ImGuiWindowFlags.NoScrollbar) then
                        ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Quality of life")) / 2)
                        ImGui.SetCursorPosY(15)
                        ImGui.Text("Quality of life")
                    end
                    ImGui.EndChild() 
                    RendF(joaat("OSKTEST"))
                    RendF(joaat("savegarage"))
                    RendF(joaat("SHSTEAL"))
                    RendF(joaat("Forcequit"))
                    RendF(joaat("ShowModders"))
                    RendF(joaat("AltChat"))
                    ImGui.SameLine()
                    RendF(joaat("altChatSettings"))
                    RendF(joaat("UseChatCommands"))
                    RendF(joaat("LogChatEnabled"))
                    RendF(joaat("KeywordCombo"))
                    ImGui.SameLine()
                    RendF(joaat("KeywordInput"))
                    RendF(joaat("deletekeyword"))
                    RendF(joaat("ChangeModderRID"))
                    ImGui.SameLine()
                    RendF(joaat("RemoveModderRID"))
                    RendF(joaat("ReasonModderRID"))
                    RendF(joaat("AddModderRID"))

                elseif elfTab == 2 then
                    ImGui.BeginChild("selfouter")
                        if ImGui.BeginChild("Selffeatures", 0, 45, true, ImGuiWindowFlags.NoScrollbar) then
                            ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Self Features")) / 2)
                            ImGui.SetCursorPosY(15)
                            ImGui.Text("Self Features")
                        end
                    ImGui.EndChild()  
                    ImGui.Columns(3, "SelfFeaturesColumns", false)
                    RendF(joaat("JoinDiscordInvite"))
                    RendF(joaat("Stats to change Combo"))
                    RendF(joaat("Stats Int input"))
                    RendF(joaat("Change Stat Value"))
                    RendF(joaat("SnowEnable"))
                    RendF(joaat("SightSeerRig"))
                    RendF(joaat("YachtAttackRig"))
                    RendF(joaat("FlashTime"))
                    ImGui.NextColumn()
                    RendF(joaat("EnableGXTMod"))
                    RendF(joaat("GXTLabelToggles"))
                    RendF(joaat("SelectedLabel"))
                    RendF(joaat("GXTLabelText"))
                    RendF(joaat("SavePresetName"))
                    RendF(joaat("SaveGXT"))
                    RendF(joaat("LoadGXT"))
                    ImGui.EndChild()
                elseif elfTab == 3 then  
                    ImGui.Columns(3, "VehicleFeaturesColumns", true)
                   --ImGui.PushStyleColor(ImGuiCol.Border, 1, 0, 0, 1)
                    ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 6)
                    ImGui.BeginChild("wplineouter")
                    if ImGui.BeginChild("wpline", 0, 45, true, ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoInputs) then
                        ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Waypoint Line")) / 2)
                        ImGui.SetCursorPosY(15)
                        ImGui.Text("Waypoint Line")
                    end
                    ImGui.EndChild()    
                    ImGui.SetCursorPosX(15)
                    ImGui.Separator()
                    RendF(joaat("waypointline"))
                    RendF(joaat("WPColor"))
                    RendF(joaat("RandomColorwp"))
                    RendF(joaat("zvaluee"))
                    RendF(joaat("linesforwp"))
                    RendF(joaat("MarkerType"))
                    ImGui.EndChild()
                    ImGui.NextColumn()
                    ImGui.BeginChild("wplineouter2")
                    if ImGui.BeginChild("wpline", 0, 45, true, ImGuiWindowFlags.NoScrollbar) then
                        ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Waypoint Line again")) / 2)
                        ImGui.SetCursorPosY(15)
                        ImGui.Text("Waypoint Line again")
                    end
                    ImGui.EndChild()    
                    RendF(joaat("bobchecker"))
                    ImGui.SameLine()
                    RendF(joaat("DrawCone"))
                    RendF(joaat("MarkerColor"))
                    RendF(joaat("markeroffset"))
                    RendF(joaat("xrott"))
                    RendF(joaat("yrott"))
                    RendF(joaat("scalex"))
                    RendF(joaat("scaley"))
                    RendF(joaat("scalez"))
                    ImGui.EndChild()
                    ImGui.NextColumn()
                    ImGui.BeginChild("vehiclestuffouter")
                    if ImGui.BeginChild("Vehiclestuff", 0, 47, true, ImGuiWindowFlags.NoScrollbar) then
                        ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Vehicle Stuff")) / 2)
                        ImGui.SetCursorPosY(15)
                        ImGui.Text("Vehicle Stuff")
                    end
                    ImGui.EndChild()    
                    RendF(joaat("patriotbutton"))
                    RendF(joaat("patriottoggle"))
                    RendF(joaat("fakeDisconnect"))
                    RendF(joaat("SpeedPlateKMH"))
                    RendF(joaat("SpeedPlateUnits"))
                    RendF(joaat("LicensePlateScroller"))
                    RendF(joaat("BurnoutLimiter"))
                    RendF(joaat("ManualTrans"))
                    RendF(joaat("SpeedUnits"))
                    ImGui.PopStyleVar(1)
                   -- ImGui.PopStyleColor(1)
                    ImGui.EndChild()
                elseif elfTab == 4 then
                    if ClickGUI.BeginCustomChildWindow("Color Management") then
                        RendF(joaat("welcometxtclr"))
                        ImGui.SameLine()
                        RendF(joaat("ComboBorderColor"))
                        ImGui.SameLine()
                        RendF(joaat("ChildBGcolor"))
                        ImGui.SameLine()
                        RendF(joaat("colorBGelf"))
                        ImGui.SameLine()
                        RendF(joaat("TextColor11"))
                        ImGui.SameLine()
                        RendF(joaat("ButtonColor"))
                        RendF(joaat("ButtonActiveColor"))
                        ImGui.SameLine()
                        RendF(joaat("ButtonHoverColor"))
                        ImGui.SameLine()
                        RendF(joaat("CheckMarkcolor"))
                        ImGui.SameLine()
                        RendF(joaat("ComboBgColor"))
                        ImGui.SameLine()
                        RendF(joaat("Comboselected"))
                        RendF(joaat("ComboActive"))
                        ImGui.SameLine()
                        RendF(joaat("ComboHovered"))
                        ImGui.SameLine()
                        RendF(joaat("ScrollbarGrabHovered"))
                        ImGui.SameLine()
                        RendF(joaat("SliderGrab"))
                        ImGui.SameLine()
                        RendF(joaat("SliderGrabActive"))
                        RendF(joaat("windowsizexy"))
                        ClickGUI.EndCustomChildWindow()
                    end
                    ImGui.Separator()
                    ImGui.Columns(2, "dumbass", false)
                    if ClickGUI.BeginCustomChildWindow("Background management") then
                        RendF(joaat("ParticleVal"))
                        ImGui.SameLine()
                        RendF(joaat("LineColor"))
                        ImGui.SameLine()
                        RendF(joaat("toLine"))
                        RendF(joaat("draggingToggle"))
                        ImGui.SameLine()
                        RendF(joaat("curosrcontrol"))
                        RendF(joaat("particlevalue"))
                        ImGui.Separator()
                        RendF(joaat("PrismBaseColor"))
                        ImGui.SameLine()
                        RendF(joaat("drawPrism"))
                        ImGui.Separator()
                        RendF(joaat("circleval"))
                        ImGui.SameLine()
                        RendF(joaat("circleColor"))
                        ImGui.Separator()
                        RendF(joaat("vaporwave"))
                        ImGui.Separator()
                        RendF(joaat("background_snowflakes"))
                        ImGui.SameLine()
                        RendF(joaat("snowflake_color"))
                        ImGui.Separator()
                        RendF(joaat("background_grid"))
                        ImGui.SameLine()
                        RendF(joaat("grid_line_color"))
                        ImGui.Separator()
                        RendF(joaat("background_neonprism"))
                        ImGui.SameLine()
                        RendF(joaat("prism_color_top"))
                        ImGui.SameLine()
                        RendF(joaat("prism_color_bottom"))
                        ImGui.SameLine()
                        RendF(joaat("prism_triangle_color"))
                        ImGui.Separator()
                        RendF(joaat("hexGlow"))
                        ClickGUI.EndCustomChildWindow()
                    end
                    ImGui.NextColumn()
                    ClickGUI.BeginCustomChildWindow("Settings##234242342345235234234235634nigger")
                    ImGui.Separator()
                    RendF(joaat("guiModeCombo"))
                    ImGui.Separator()
                    RendF(joaat("ShowModderSettings"))
                    --RendF(joaat("Tetris"))
                    RendF(joaat("playpong"))
                    --RendF(joaat("rendercuppong"))
                    RendF(joaat("CloseGUI"))
                    RendF(joaat("configsave"))
                    RendF(joaat("themename1"))
                    RendF(joaat("themesave1"))
                    RendF(joaat("themeload1"))
                    RendF(joaat("themeCombo11"))            
                    ClickGUI.EndCustomChildWindow()   
                end
            elseif mainMenuTab == 2 then
                if inxTab == 1 then
                    
                    ImGui.Columns(2, "", false)

                    ClickGUI.BeginCustomChildWindow("Copy Vehicles to Clipboard")
                    ImGui.TextWrapped(
                    "You can copy your current car as a code, which you can share anywhere. Then, anyone can spawn the car by copying the code you sent.")
                    RendF(joaat("VehicleStealerCopyCode"))
                    ImGui.TextWrapped("Before using this feature, copy the entire vehicle code to your clipboard!")
                    RendF(joaat("VehicleStealerSpawnFromCode"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Save/Load Vehicle Configs")
                    RendF(joaat("Saved Vehicle Configs"))
                    RendF(joaat("Config Name"))
                    RendF(joaat("Refresh Vehicle Configs"))
                    RendF(joaat("Save Vehicle Config"))
                    RendF(joaat("Apply Vehicle Config"))
                    RendF(joaat("VehicleConfigSpawnUpgraded"))
                    RendF(joaat("VehicleFullyUpgraded"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Car Saving Walkthrough")
                    ImGui.TextWrapped("1. First, spawn the car you want. Press below to open the Spawner tab.")
                    if ImGui.Button("Open Spawner Tab") then
                        ClickGUI.SetActiveMenuTab(ClickTab.Spawner)
                    end
                    ImGui.Separator()
                    ImGui.TextWrapped(
                    "2. Now, mod the car in Cherax. There is an LSC tab, where you can apply any mods you want.")
                    if ImGui.Button("Open Vehicle Tab") then
                        ClickGUI.SetActiveMenuTab(ClickTab.Vehicle)
                    end
                    ImGui.Separator()
                    ImGui.TextWrapped(
                    "3. Once you've made your modifications, you can now claim the car as a personal vehicle.")
                    RendF(2816017279)
                    ImGui.Separator()
                    ImGui.TextWrapped("4. You're done! You now own the vehicle, with all the modifications saved.")
                    ClickGUI.EndCustomChildWindow()

                    ImGui.NextColumn()


                    ClickGUI.BeginCustomChildWindow("Random Vehicles")
                    RendF(joaat("Spawn Random Saved Vehicle"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Forge Model")
                    RendF(joaat("ForgeModelName"))
                    RendF(joaat("ForgeModelSpoof"))
                    RendF(joaat("ForgeModelUnspoof"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Breathing Neon Kit")
                    RendF(joaat("BreathingNeon"))
                    RendF(joaat("BreathingNeonSlider"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Toggles")
                    RendF(joaat("EnableFestiveHorns"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Vehicle Stealer")
                    ImGui.TextWrapped(
                    "You can use the feature below to clone any vehicle, for example from the LS Car Meet.")
                    RendF(joaat("VehicleStealer"))
                    ImGui.TextWrapped("Currently copied: " ..
                    (copied_vehicle ~= nil and HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(copied_vehicle["model"])) or "None"))
                    RendF(joaat("VehicleStealerSpawn"))
                    RendF(joaat("ClearCopiedVehicleCode"))
                    ClickGUI.EndCustomChildWindow()

                    ImGui.Columns()
                elseif inxTab == 2 then
                    ImGui.Columns(2, "", false)
                    ClickGUI.BeginCustomChildWindow("Custom Crosshair")
                    ImGui.TextWrapped("Copy/Paste Crosshair Settings")
                    RendF(joaat("CustomCrosshairCopy"))
                    RendF(joaat("CustomCrosshairApply"))
                    ImGui.Separator()
                    ImGui.TextWrapped("Crosshair settings")
                    RendF(joaat("CustomCrosshair"))
                    RendF(joaat("CrosshairSize"))
                    RendF(joaat("CrosshairColor"))
                    RendF(joaat("CrosshairShape"))
                    local shape = FeatureMgr.GetFeatureListIndex(joaat("CrosshairShape"))
                    if shape == 1 then
                        RendF(joaat("CrosshairRectangleWidth"))
                        RendF(joaat("CrosshairRectangleHeight"))
                        RendF(joaat("CrosshairRectangleRounding"))
                    elseif shape == 2 or shape == 3 or shape == 4 or shape == 5 or shape == 6 or shape == 7 then
                        RendF(joaat("CrosshairLineThickness"))
                    end
                    ClickGUI.EndCustomChildWindow()
                    ImGui.Columns()
                elseif inxTab == 3 then
                    ImGui.Columns(2, "", false)
                    ClickGUI.BeginCustomChildWindow("Stat Editor")
                    RendF(joaat("OpenStatsWebsite"))
                    ImGui.Text("Stat name:")
                    RendF(joaat("StatName"))
                    local type = FeatureMgr.GetFeatureListIndex(joaat("StatType"))
                    RendF(joaat("StatType"))
                    if type == 0 then
                        ImGui.Text("Current value: " .. read_stat(0))
                        RendF(joaat("StatValueInt"))
                        RendF(joaat("SetStatInt"))
                    elseif type == 1 then
                        ImGui.Text("Current value: " .. read_stat(1))
                        RendF(joaat("StatValueFloat"))
                        RendF(joaat("SetStatFloat"))
                    elseif type == 2 then
                        ImGui.Text("Current value: " .. read_stat(2))
                        ImGui.Text("Bool value:")
                        ImGui.SameLine()
                        RendF(joaat("StatValueBool"))
                        RendF(joaat("SetStatBool"))
                    elseif type == 3 then
                        ImGui.Text("Current value: " .. read_stat(3))
                        ImGui.Text("String value:")
                        ImGui.SameLine()
                        RendF(joaat("StatValueString"))
                        RendF(joaat("SetStatString"))
                    end

                    ClickGUI.EndCustomChildWindow()
                    ClickGUI.BeginCustomChildWindow("Unlocks")
                    RendF(joaat("UnlockChameleonPaints"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Hasher")
                    RendF(joaat("HasherInput"))
                    if hasher_output ~= nil then
                        ImGui.Text("Hash: " .. hasher_output)
                    else
                        ImGui.Text("Hash: no input yet")
                    end
                    RendF(joaat("HasherCopy"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Bypass Int Limit")
                    ImGui.TextWrapped(
                    "Setting integer stats with the above methods only works up to the 32 bit integer limit. This feature bypasses the limit by using increments.")
                    ImGui.Spacing()
                    RendF(joaat("StatLimitBypassStatName"))
                    RendF(joaat("StatLimitBypassValue"))
                    RendF(joaat("StatLimitSetStat"))
                    ClickGUI.EndCustomChildWindow()

                    ImGui.NextColumn()

                    ClickGUI.BeginCustomChildWindow("Packed Bool Stat Editor (single)")
                    RendF(joaat("PackedBoolSingleIndex"))
                    RendF(joaat("PackedBoolSingleValue"))
                    RendF(joaat("SetPackedBoolStatSingle"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Packed Bool Stat Editor (range)")
                    RendF(joaat("PackedBoolRangeIndexStart"))
                    RendF(joaat("PackedBoolRangeIndexEnd"))
                    RendF(joaat("PackedBoolRangeValue"))
                    RendF(joaat("SetPackedBoolStatRange"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Packed Int Stat Editor")
                    RendF(joaat("PackedIntIndex"))
                    RendF(joaat("PackedIntValue"))
                    RendF(joaat("SetPackedInt"))
                    ClickGUI.EndCustomChildWindow()

                    ClickGUI.BeginCustomChildWindow("Global Editor")
                    RendF(joaat("GlobalEditorInput"))
                    ImGui.Separator()
                    RendF(joaat("GlobalEditorType"))
                    local type = FeatureMgr.GetFeatureListIndex(joaat("GlobalEditorType"))
                    if type == 0 then
                        RendF(joaat("GlobalEditorValueInt"))
                    elseif type == 1 then
                        ImGui.Text("Bool value")
                        ImGui.SameLine()
                        RendF(joaat("GlobalEditorValueBool"))
                    elseif type == 2 then
                        RendF(joaat("GlobalEditorValueFloat"))
                    elseif type == 3 then
                        ImGui.Text("String value")
                        RendF(joaat("GlobalEditorValueString"))
                    end
                    ImGui.Separator()

                    RendF(joaat("GlobalEditorSet"))
                    ClickGUI.EndCustomChildWindow()

                    ImGui.Columns()
                elseif inxTab == 4 then
                    RendF(joaat("print hovered feature info"))
                end
                
            end
            ImGui.EndChild()    
        end
        
        ImGui.PopStyleColor(stylePushCount1)  
        ImGui.PopStyleColor(stylePushCount)
        ImGui.End()
    end 

    local stylePushCountcherax = 0
    function RenderCheraxGUI()
        if not GUI.IsOpen() then return end
            colors = {
                { ImGuiCol.WindowBg,             BGColorelf:GetColor() },
                { ImGuiCol.ScrollbarGrab,        ButtonColor:GetColor() },
                { ImGuiCol.ScrollbarGrabActive,  ButtonActiveColor:GetColor() },
                { ImGuiCol.ScrollbarGrabHovered, ButtonHoverColor:GetColor() },
                { ImGuiCol.Header,               HeaderColor:GetColor() },
                { ImGuiCol.HeaderActive,         HeaderActiveC:GetColor() },
                { ImGuiCol.HeaderHovered,        HeaderHovered:GetColor() },
                { ImGuiCol.FrameBg,              ComboBgColor:GetColor() },
                { ImGuiCol.FrameBgHovered,       ComboBgColor:GetColor() },
                { ImGuiCol.FrameBgActive,        ComboBgColor:GetColor() },
                { ImGuiCol.Border,               ComboBorderColor:GetColor() },
                { ImGuiCol.PopupBg,              ComboBgColor:GetColor() },
                { ImGuiCol.Separator,            ComboBorderColor:GetColor() },
                { ImGuiCol.Button,               ButtonColor:GetColor() },
                { ImGuiCol.ButtonHovered,        ButtonHoverColor:GetColor() },
                { ImGuiCol.ButtonActive,         ButtonActiveColor:GetColor() },
                { ImGuiCol.Text,                 TextColor1:GetColor() },
                { ImGuiCol.ChildBg,              ChildBgColor:GetColor() },
                { ImGuiCol.CheckMark,            CheckMarkcolor:GetColor() },
                { ImGuiCol.ResizeGrip,           CheckMarkcolor:GetColor() },
                { ImGuiCol.SliderGrab,           SliderGrab:GetColor() },
                { ImGuiCol.SliderGrabActive,     SliderGrabActive:GetColor() }
            }
            for _, color in ipairs(colors) do
                local col, r, g, b, a = table.unpack(color)
                ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, (a or 255) / 255)
                stylePushCountcherax = stylePushCountcherax + 1
            end

        if ImGui.BeginTabBar("MainTabs") then
            if ImGui.BeginTabItem("Elf") then
                if ImGui.BeginTabBar("ElfSubTabs") then
                    ImGui.BeginChild("testchild")
                    if ImGui.BeginTabItem("Session") then

                        ImGui.EndTabItem()
                    end
                        
                    if ImGui.BeginTabItem("Self") then

                        ImGui.EndTabItem()
                    end

                    if ImGui.BeginTabItem("Vehicle") then

                        ImGui.EndTabItem()
                    end 
                        
                    if ImGui.BeginTabItem("Settings") then

                    end
                    ImGui.EndTabBar()
                    ImGui.EndChild()
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Inx") then
                if ImGui.BeginTabBar("InxSubTabs") then
                    if ImGui.BeginTabItem("Vehicle") then

                        ImGui.EndTabItem()
                    end
                        
                    if ImGui.BeginTabItem("UI") then

                        ImGui.EndTabItem()
                    end
                
                    if ImGui.BeginTabItem("Stats") then
                        ImGui.EndTabItem()
                    end
                        
                    if ImGui.BeginTabItem("Debug") then
                        
                        ImGui.EndTabItem()
                    end
                        
                    ImGui.EndTabBar()
                end
                ImGui.EndTabItem()
            end
            ImGui.PopStyleColor(stylePushCountcherax)
            ImGui.EndTabBar()
        end
    end

    local stylePushCountcherax = 0
    function RenderCheraxGUI()
        if not GUI.IsOpen() then return end

        -- === Style setup ===
        local colors = {
            { ImGuiCol.WindowBg,             BGColorelf:GetColor() },
            { ImGuiCol.ScrollbarGrab,        ButtonColor:GetColor() },
            { ImGuiCol.ScrollbarGrabActive,  ButtonActiveColor:GetColor() },
            { ImGuiCol.ScrollbarGrabHovered, ButtonHoverColor:GetColor() },
            { ImGuiCol.Header,               HeaderColor:GetColor() },
            { ImGuiCol.HeaderActive,         HeaderActiveC:GetColor() },
            { ImGuiCol.HeaderHovered,        HeaderHovered:GetColor() },
            { ImGuiCol.FrameBg,              ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgHovered,       ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgActive,        ComboBgColor:GetColor() },
            { ImGuiCol.Border,               ComboBorderColor:GetColor() },
            { ImGuiCol.PopupBg,              ComboBgColor:GetColor() },
            { ImGuiCol.Separator,            ComboBorderColor:GetColor() },
            { ImGuiCol.Button,               ButtonColor:GetColor() },
            { ImGuiCol.ButtonHovered,        ButtonHoverColor:GetColor() },
            { ImGuiCol.ButtonActive,         ButtonActiveColor:GetColor() },
            { ImGuiCol.Text,                 TextColor1:GetColor() },
            { ImGuiCol.ChildBg,              ChildBgColor:GetColor() },
            { ImGuiCol.CheckMark,            CheckMarkcolor:GetColor() },
            { ImGuiCol.ResizeGrip,           CheckMarkcolor:GetColor() },
            { ImGuiCol.SliderGrab,           SliderGrab:GetColor() },
            { ImGuiCol.SliderGrabActive,     SliderGrabActive:GetColor() }
        }
        for _, color in ipairs(colors) do
            local col, r, g, b, a = table.unpack(color)
            ImGui.PushStyleColor(col, r/255, g/255, b/255, (a or 255)/255)
            stylePushCountcherax = stylePushCountcherax + 1
        end

        if ImGui.BeginTabBar("MainTabs") then

            if ImGui.BeginTabItem("Elf") then
                if ImGui.BeginTabBar("ElfSubTabs") then
                    if ImGui.BeginTabItem("Session") then
                        if ImGui.BeginChild("Quality of life", 0, 45, true, ImGuiWindowFlags.NoScrollbar) then
                            ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Quality of life")) / 2)
                            ImGui.SetCursorPosY(15)
                            ImGui.Text("Quality of life")
                        end
                        ImGui.EndChild() 
                        RendF(joaat("savegarage"))
                        RendF(joaat("SHSTEAL"))
                        RendF(joaat("Forcequit"))
                        RendF(joaat("ShowModders"))
                        if version == "LE" then 
                            RendF(joaat("AltChat"))
                            RendF(joaat("altChatSettings"))
                            RendF(joaat("UseChatCommands"))
                            RendF(joaat("LogChatEnabled"))
                            RendF(joaat("KeywordCombo"))
                            ImGui.SameLine()
                            RendF(joaat("KeywordInput"))
                            RendF(joaat("deletekeyword"))
                        end
                        RendF(joaat("ChangeModderRID"))
                        ImGui.SameLine()
                        RendF(joaat("RemoveModderRID"))
                        RendF(joaat("ReasonModderRID"))
                        RendF(joaat("AddModderRID"))
                        ImGui.EndTabItem()
                    end

                    if ImGui.BeginTabItem("Self") then
                        ImGui.BeginChild("selfouter")
                        if ImGui.BeginChild("Selffeatures", 0, 45, true, ImGuiWindowFlags.NoScrollbar) then
                            ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Self Features")) / 2)
                            ImGui.SetCursorPosY(15)
                            ImGui.Text("Self Features")
                        end
                        ImGui.EndChild()  
                        ImGui.Columns(3, "SelfFeaturesColumns", false)
                        RendF(joaat("Stats to change Combo"))
                        RendF(joaat("Stats Int input"))
                        RendF(joaat("Change Stat Value"))
                        RendF(joaat("SightSeerRig"))
                        RendF(joaat("YachtAttackRig"))
                        RendF(joaat("FlashTime"))
                        ImGui.NextColumn()
                        ImGui.Text("Notifications")
                        RendF(joaat("EnableGXTMod"))
                        RendF(joaat("GXTLabelToggles"))
                        RendF(joaat("SelectedLabel"))
                        RendF(joaat("GXTLabelText"))
                        RendF(joaat("SavePresetName"))
                        RendF(joaat("SaveGXT"))
                        RendF(joaat("LoadGXT"))
                        ImGui.EndChild()
                        ImGui.EndTabItem()
                    end

                    if ImGui.BeginTabItem("Vehicle") then
                        ImGui.Columns(3, "", false) 
                        ImGui.BeginChild("wplineouter")
                        if ImGui.BeginChild("wpline", 0, 45, true, ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoInputs) then
                            ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Waypoint Line")) / 2)
                            ImGui.SetCursorPosY(15)
                            ImGui.Text("Waypoint Line")
                        end
                        ImGui.EndChild()    
                        ImGui.SetCursorPosX(15)
                        ImGui.Separator()
                        RendF(joaat("waypointline"))
                        RendF(joaat("WPColor"))
                        RendF(joaat("RandomColorwp"))
                        RendF(joaat("zvaluee"))
                        RendF(joaat("linesforwp"))
                        RendF(joaat("MarkerType"))
                        ImGui.EndChild()
                        ImGui.NextColumn()
                        ImGui.BeginChild("wplineouter2")
                        if ImGui.BeginChild("wpline##12312", 0, 45, true, ImGuiWindowFlags.NoScrollbar) then
                            ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Waypoint Line again")) / 2)
                            ImGui.SetCursorPosY(15)
                            ImGui.Text("Waypoint Line again")
                        end
                        ImGui.EndChild()    
                        RendF(joaat("bobchecker"))
                        ImGui.SameLine()
                        RendF(joaat("DrawCone"))
                        RendF(joaat("MarkerColor"))
                        RendF(joaat("markeroffset"))
                        RendF(joaat("xrott"))
                        RendF(joaat("yrott"))
                        RendF(joaat("scalex"))
                        RendF(joaat("scaley"))
                        RendF(joaat("scalez"))
                        ImGui.EndChild()
                        ImGui.NextColumn()
                        ImGui.BeginChild("vehiclestuffouter")
                        if ImGui.BeginChild("Vehiclestuff", 0, 47, true, ImGuiWindowFlags.NoScrollbar) then
                            ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Vehicle Stuff")) / 2)
                            ImGui.SetCursorPosY(15)
                            ImGui.Text("Vehicle Stuff")
                        end
                        ImGui.EndChild()    
                        RendF(joaat("patriotbutton"))
                        RendF(joaat("patriottoggle"))
                        RendF(joaat("fakeDisconnect"))
                        RendF(joaat("SpeedPlateKMH"))
                        RendF(joaat("SpeedPlateUnits"))
                        RendF(joaat("LicensePlateScroller"))
                        RendF(joaat("BurnoutLimiter"))
                        RendF(joaat("ManualTrans"))
                        RendF(joaat("SpeedUnits"))
                        ImGui.EndChild()
                        ImGui.Columns()
                        ImGui.EndTabItem()
                    end

                    if ImGui.BeginTabItem("Settings") then
                        ImGui.BeginChild("Settings", 0, 400)
                        if ImGui.BeginChild("Vehiclestuff", 0, 47, true, ImGuiWindowFlags.NoScrollbar) then
                            ImGui.SetCursorPosX((ImGui.GetWindowWidth() - ImGui.CalcTextSize("Settings")) / 2)
                            ImGui.SetCursorPosY(15)
                            ImGui.Text("Settings")
                        end
                        ImGui.EndChild()
                        ImGui.Separator()
                        RendF(joaat("guiModeCombo"))
                        ImGui.Separator()
                        RendF(joaat("ShowModderSettings"))
                        RendF(joaat("playpong"))
                        RendF(joaat("configsave"))          
                        ImGui.EndChild()   
                        ImGui.EndTabItem()
                    end

                    ImGui.EndTabBar()
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Inx") then
                if ImGui.BeginTabBar("InxSubTabs") then
                    if ImGui.BeginTabItem("Vehicle") then
                        ImGui.BeginChild("##21231")
                        ImGui.Columns(2, "", false)
                        ClickGUI.BeginCustomChildWindow("Copy Vehicles to Clipboard")
                        ImGui.TextWrapped(
                        "You can copy your current car as a code, which you can share anywhere. Then, anyone can spawn the car by copying the code you sent.")
                        RendF(joaat("VehicleStealerCopyCode"))
                        ImGui.TextWrapped("Before using this feature, copy the entire vehicle code to your clipboard!")
                        RendF(joaat("VehicleStealerSpawnFromCode"))
                        ClickGUI.EndCustomChildWindow()
                        ClickGUI.BeginCustomChildWindow("Save/Load Vehicle Configs")
                        RendF(joaat("Saved Vehicle Configs"))
                        RendF(joaat("Config Name"))
                        RendF(joaat("Refresh Vehicle Configs"))
                        RendF(joaat("Save Vehicle Config"))
                        RendF(joaat("Apply Vehicle Config"))
                        RendF(joaat("VehicleConfigSpawnUpgraded"))
                        RendF(joaat("VehicleFullyUpgraded"))
                        ClickGUI.EndCustomChildWindow()
                        ClickGUI.BeginCustomChildWindow("Car Saving Walkthrough")
                        ImGui.TextWrapped("1. First, spawn the car you want. Press below to open the Spawner tab.")
                        if ImGui.Button("Open Spawner Tab") then
                            ClickGUI.SetActiveMenuTab(ClickTab.Spawner)
                        end
                        ImGui.Separator()
                        ImGui.TextWrapped(
                        "2. Now, mod the car in Cherax. There is an LSC tab, where you can apply any mods you want.")
                        if ImGui.Button("Open Vehicle Tab") then
                            ClickGUI.SetActiveMenuTab(ClickTab.Vehicle)
                        end
                        ImGui.Separator()
                        ImGui.TextWrapped(
                        "3. Once you've made your modifications, you can now claim the car as a personal vehicle.")
                        RendF(2816017279)
                        ImGui.Separator()
                        ImGui.TextWrapped("4. You're done! You now own the vehicle, with all the modifications saved.")
                        ClickGUI.EndCustomChildWindow()
                        ImGui.NextColumn()
                        ClickGUI.BeginCustomChildWindow("Random Vehicles")
                        RendF(joaat("Spawn Random Saved Vehicle"))
                        ClickGUI.EndCustomChildWindow()
                        ClickGUI.BeginCustomChildWindow("Forge Model")
                        RendF(joaat("ForgeModelName"))
                        RendF(joaat("ForgeModelSpoof"))
                        RendF(joaat("ForgeModelUnspoof"))
                        ClickGUI.EndCustomChildWindow()
                        ClickGUI.BeginCustomChildWindow("Breathing Neon Kit")
                        RendF(joaat("BreathingNeon"))
                        RendF(joaat("BreathingNeonSlider"))
                        ClickGUI.EndCustomChildWindow()
                        ClickGUI.BeginCustomChildWindow("Vehicle Stealer")
                        ImGui.TextWrapped(
                        "You can use the feature below to clone any vehicle, for example from the LS Car Meet.")
                        RendF(joaat("VehicleStealer"))
                        ImGui.TextWrapped("Currently copied: " ..
                        (copied_vehicle ~= nil and HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(copied_vehicle["model"])) or "None"))
                        RendF(joaat("VehicleStealerSpawn"))
                        RendF(joaat("ClearCopiedVehicleCode"))
                            
                        ClickGUI.EndCustomChildWindow()
                        ImGui.Columns()
                        ImGui.EndChild()
                        ImGui.EndTabItem()
                    end

                    if ImGui.BeginTabItem("UI") then
                        ImGui.Columns(2, "", false)
                        ClickGUI.BeginCustomChildWindow("Custom Crosshair")
                        ImGui.TextWrapped("Copy/Paste Crosshair Settings")
                        RendF(joaat("CustomCrosshairCopy"))
                        RendF(joaat("CustomCrosshairApply"))
                        ImGui.Separator()
                        ImGui.TextWrapped("Crosshair settings")
                        RendF(joaat("CustomCrosshair"))
                        RendF(joaat("CrosshairSize"))
                        RendF(joaat("CrosshairColor"))
                        RendF(joaat("CrosshairShape"))
                        local shape = FeatureMgr.GetFeatureListIndex(joaat("CrosshairShape"))
                        if shape == 1 then
                            RendF(joaat("CrosshairRectangleWidth"))
                            RendF(joaat("CrosshairRectangleHeight"))
                            RendF(joaat("CrosshairRectangleRounding"))
                        elseif shape == 2 or shape == 3 or shape == 4 or shape == 5 or shape == 6 or shape == 7 then
                            RendF(joaat("CrosshairLineThickness"))
                        end
                        ClickGUI.EndCustomChildWindow()
                        ImGui.Columns()
                        ImGui.EndTabItem()
                    end

                    -- Stats SubTab
                    if ImGui.BeginTabItem("Stats") then
                        ImGui.Columns(2, "", false)
                        ClickGUI.BeginCustomChildWindow("Stat Editor")
                        RendF(joaat("OpenStatsWebsite"))
                        ImGui.Text("Stat name:")
                        RendF(joaat("StatName"))
                        local type = FeatureMgr.GetFeatureListIndex(joaat("StatType"))
                        RendF(joaat("StatType"))
                        if type == 0 then
                            ImGui.Text("Current value: " .. read_stat(0))
                            RendF(joaat("StatValueInt"))
                            RendF(joaat("SetStatInt"))
                        elseif type == 1 then
                            ImGui.Text("Current value: " .. read_stat(1))
                            RendF(joaat("StatValueFloat"))
                            RendF(joaat("SetStatFloat"))
                        elseif type == 2 then
                            ImGui.Text("Current value: " .. read_stat(2))
                            ImGui.Text("Bool value:")
                            ImGui.SameLine()
                            RendF(joaat("StatValueBool"))
                            RendF(joaat("SetStatBool"))
                        elseif type == 3 then
                            ImGui.Text("Current value: " .. read_stat(3))
                            ImGui.Text("String value:")
                            ImGui.SameLine()
                            RendF(joaat("StatValueString"))
                            RendF(joaat("SetStatString"))
                        end

                        ClickGUI.EndCustomChildWindow()
                        ClickGUI.BeginCustomChildWindow("Unlocks")
                        RendF(joaat("UnlockChameleonPaints"))
                        ClickGUI.EndCustomChildWindow()

                        ClickGUI.BeginCustomChildWindow("Hasher")
                        RendF(joaat("HasherInput"))
                        if hasher_output ~= nil then
                            ImGui.Text("Hash: " .. hasher_output)
                        else
                            ImGui.Text("Hash: no input yet")
                        end
                        RendF(joaat("HasherCopy"))
                        ClickGUI.EndCustomChildWindow()

                        ClickGUI.BeginCustomChildWindow("Bypass Int Limit")
                        ImGui.TextWrapped(
                        "Setting integer stats with the above methods only works up to the 32 bit integer limit. This feature bypasses the limit by using increments.")
                        ImGui.Spacing()
                        RendF(joaat("StatLimitBypassStatName"))
                        RendF(joaat("StatLimitBypassValue"))
                        RendF(joaat("StatLimitSetStat"))
                        ClickGUI.EndCustomChildWindow()

                        ImGui.NextColumn()

                        ClickGUI.BeginCustomChildWindow("Packed Bool Stat Editor (single)")
                        RendF(joaat("PackedBoolSingleIndex"))
                        RendF(joaat("PackedBoolSingleValue"))
                        RendF(joaat("SetPackedBoolStatSingle"))
                        ClickGUI.EndCustomChildWindow()

                        ClickGUI.BeginCustomChildWindow("Packed Bool Stat Editor (range)")
                        RendF(joaat("PackedBoolRangeIndexStart"))
                        RendF(joaat("PackedBoolRangeIndexEnd"))
                        RendF(joaat("PackedBoolRangeValue"))
                        RendF(joaat("SetPackedBoolStatRange"))
                        ClickGUI.EndCustomChildWindow()

                        ClickGUI.BeginCustomChildWindow("Packed Int Stat Editor")
                        RendF(joaat("PackedIntIndex"))
                        RendF(joaat("PackedIntValue"))
                        RendF(joaat("SetPackedInt"))
                        ClickGUI.EndCustomChildWindow()

                        ClickGUI.BeginCustomChildWindow("Global Editor")
                        RendF(joaat("GlobalEditorInput"))
                        ImGui.Separator()
                        RendF(joaat("GlobalEditorType"))
                        local type = FeatureMgr.GetFeatureListIndex(joaat("GlobalEditorType"))
                        if type == 0 then
                            RendF(joaat("GlobalEditorValueInt"))
                        elseif type == 1 then
                            ImGui.Text("Bool value")
                            ImGui.SameLine()
                            RendF(joaat("GlobalEditorValueBool"))
                        elseif type == 2 then
                            RendF(joaat("GlobalEditorValueFloat"))
                        elseif type == 3 then
                            ImGui.Text("String value")
                            RendF(joaat("GlobalEditorValueString"))
                        end
                        ImGui.Separator()

                        RendF(joaat("GlobalEditorSet"))
                        ClickGUI.EndCustomChildWindow()

                        ImGui.Columns()
                        ImGui.EndTabItem()
                    end

                    -- Debug SubTab
                    if ImGui.BeginTabItem("Debug") then
                        ImGui.BeginChild("InxDebugChild", 0, 0, true)
                        RendF(joaat("print hovered feature info"))
                        ImGui.EndChild()
                        ImGui.EndTabItem()
                    end

                    ImGui.EndTabBar()
                end
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end

        -- === Cleanup ===
        ImGui.PopStyleColor(stylePushCountcherax)
        stylePushCountcherax = 0
    end

    

    function RenderPlayerTab()
        if not GUI.IsOpen() then
            return
        end

        local totalStylePushes = 0

        ImGui.PushStyleColor(ImGuiCol.WindowBg, BGColorelf:GetColor())
        totalStylePushes = totalStylePushes + 1

        local bgelfr, bgelfg, bgelfb, bgelfa = BGColorelf:GetColor()
        if bgelfr == nil then bgelfr, bgelfg, bgelfb, bgelfa = 255, 255, 255, 255 end

        ImGui.PushStyleColor(ImGuiCol.WindowBg, bgelfr / 255, bgelfg / 255, bgelfb / 255, bgelfa / 255)
        totalStylePushes = totalStylePushes + 1

        local colors = {
            { ImGuiCol.ScrollbarGrab,        ButtonColor:GetColor() },
            { ImGuiCol.ScrollbarGrabActive,  ButtonActiveColor:GetColor() },
            { ImGuiCol.ScrollbarGrabHovered, ButtonHoverColor:GetColor() },
            { ImGuiCol.Header,               HeaderColor:GetColor() },
            { ImGuiCol.HeaderActive,         HeaderActiveC:GetColor() },
            { ImGuiCol.HeaderHovered,        HeaderHovered:GetColor() },
            { ImGuiCol.FrameBg,              ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgHovered,       ComboBgColor:GetColor() },
            { ImGuiCol.FrameBgActive,        ComboBgColor:GetColor() },
            { ImGuiCol.Border,               ComboBorderColor:GetColor() },
            { ImGuiCol.PopupBg,              ComboBgColor:GetColor() },
            { ImGuiCol.Separator,            ComboBorderColor:GetColor() },
            { ImGuiCol.Button,               ButtonColor:GetColor() },
            { ImGuiCol.ButtonHovered,        ButtonHoverColor:GetColor() },
            { ImGuiCol.ButtonActive,         ButtonActiveColor:GetColor() },
            { ImGuiCol.Text,                 TextColor1:GetColor() },
            { ImGuiCol.ChildBg,              ChildBgColor:GetColor() },
            { ImGuiCol.WindowBg,             BGColorelf:GetColor() },
            { ImGuiCol.CheckMark,            CheckMarkcolor:GetColor() },
            { ImGuiCol.ResizeGrip,           CheckMarkcolor:GetColor() },
            { ImGuiCol.SliderGrab,           SliderGrab:GetColor() },
            { ImGuiCol.SliderGrabActive,     SliderGrabActive:GetColor() }
        }

        for _, color in ipairs(colors) do
            local col, r, g, b, a = table.unpack(color)
            ImGui.PushStyleColor(col, r / 255, g / 255, b / 255, a / 255)
            totalStylePushes = totalStylePushes + 1
        end

        local menuItems = { "Trolling", "Cages", "Protections"}

        if selectedTab == nil then
            for i, item in ipairs(menuItems) do
                if ImGui.Button(item, 370, 30) then
                    selectedTab = item
                end
            end
        else
            if selectedTab == "Trolling" then
                ClickGUI.BeginCustomChildWindow("Trolling")
                    RendF(joaat("explodeveh"), Utils.GetSelectedPlayer())
                    RendF(joaat("npcAttackSquad"), Utils.GetSelectedPlayer())
                    RendF(joaat("vehiclespam"), Utils.GetSelectedPlayer())
                    RendF(joaat("FlyingMonkeys"), Utils.GetSelectedPlayer())
                    RendF(joaat("SetMaxWanted"), Utils.GetSelectedPlayer())
                    RendF(joaat("SpawnRCCar"), Utils.GetSelectedPlayer())
                    RendF(joaat("aggroRc"), Utils.GetSelectedPlayer())
                    RendF(joaat("TPALLTOPLAYER"), Utils.GetSelectedPlayer())
                    ImGui.Separator()
                    ImGui.Text("These are the supporter features below")
                    ClickGUI.BeginCustomChildWindow("##1213")
                    ClickGUI.RenderCustomTitleBar("Air Attack Section")
                    RendF(joaat("Clearthem"))
                    RendF(joaat("jetSlider"))
                    RendF(joaat("airattack"), Utils.GetSelectedPlayer())
                    ClickGUI.EndCustomChildWindow()
                    RendF(joaat("sendTP"), Utils.GetSelectedPlayer())
                    RendF(joaat("Event19"), Utils.GetSelectedPlayer())
                    RendF(joaat("VEHICLE_FUCKER"), Utils.GetSelectedPlayer())
                    RendF(joaat("anim_crash"), Utils.GetSelectedPlayer())
                    RendF(joaat("Chaos_crash"), Utils.GetSelectedPlayer())
                    RendF(joaat("vehiclenuke"), Utils.GetSelectedPlayer())
                    RendF(joaat("Chaosnuke"), Utils.GetSelectedPlayer())
                    ClickGUI.EndCustomChildWindow() 
            end

            if selectedTab == "Cages" then
                ClickGUI.BeginCustomChildWindow("Cages")
                RendF(joaat("CageSelectedPlayer"), Utils.GetSelectedPlayer())
                RendF(joaat("CouchCage"), Utils.GetSelectedPlayer())
                RendF(joaat("fatspam"), Utils.GetSelectedPlayer())
                ClickGUI.EndCustomChildWindow()
            end
            if selectedTab == "Protections" then 
                RendF(joaat("LogPlayerSEs"), Utils.GetSelectedPlayer())
                RendF(joaat("BlockPlayerSEs"), Utils.GetSelectedPlayer())
                RendF(joaat("LogAllSEs"))
                RendF(joaat("LogModderSEs"))
                RendF(joaat("NotifyPlayerTimeout"), Utils.GetSelectedPlayer())
            
                ImGui.Separator()
                RendF(joaat("LogPlayerNEs"), Utils.GetSelectedPlayer())
                RendF(joaat("BlockPlayerNEs"), Utils.GetSelectedPlayer())
                RendF(joaat("LogAllNEs"))
                RendF(joaat("LogModderNEs")) 
            end

            if ImGui.Button("Back", 330, 30) then
                selectedTab = nil
            end
        end

        ImGui.PopStyleColor(totalStylePushes)
    end

    function renderListUI()
        local root = ListGUI.GetRootTab()
        if root then
            local ElfScriptTab = root:AddSubTab("Elf Script", "")
            if ElfScriptTab then
                local inxTab = ElfScriptTab:AddSubTab("InxLua", "Contains stuff from the now banned script 'InxLua' ")
                if inxTab then 
                    local inxVehicleTab = inxTab:AddSubTab("Vehicles", "Contains vehicle features for InxLua")
                    if inxVehicleTab then 
                        local inxVehicleCopyTab = inxVehicleTab:AddSubTab("Vehicle Copy", "Contains vehicle copy stuff from InxLua")
                        if inxVehicleCopyTab then 
                            inxVehicleCopyTab:AddSeperator("Copy Vehicles to clipboard")
                            inxVehicleCopyTab:AddSeperator("You can copy your car as a code which you can share anywhere.")
                            inxVehicleCopyTab:AddSeperator("then anyone can spawn the car by copying the code you send")
                            inxVehicleCopyTab:AddFeature(joaat("VehicleStealerCopyCode"))
                            inxVehicleCopyTab:AddSeperator("Before using this feature copy the entire vehicle code")
                            inxVehicleCopyTab:AddFeature(joaat("VehicleStealerSpawnFromCode"))
                            inxVehicleCopyTab:AddSeperator("End of vehicle copy")
                        end
                        local inxVehicleConfigTab = inxVehicleTab:AddSubTab("Save/Load vehicle configs")
                        if inxVehicleConfigTab then
                            inxVehicleConfigTab:AddFeature(joaat("Saved Vehicle Configs"))
                            inxVehicleConfigTab:AddFeature(joaat("Config Name"))
                            inxVehicleConfigTab:AddFeature(joaat("Refresh Vehicle Configs"))
                            inxVehicleConfigTab:AddFeature(joaat("Save Vehicle Config"))
                            inxVehicleConfigTab:AddFeature(joaat("Apply Vehicle Config"))
                            inxVehicleConfigTab:AddFeature(joaat("VehicleConfigSpawnUpgraded"))
                            inxVehicleConfigTab:AddFeature(joaat("VehicleFullyUpgraded"))
                        end
                        inxVehicleTab:AddFeature(joaat("Spawn Random Saved Vehicle"))

                        inxVehicleTab:AddFeature(joaat("ForgeModelName"))
                        inxVehicleTab:AddFeature(joaat("ForgeModelSpoof"))
                        inxVehicleTab:AddFeature(joaat("ForgeModelUnspoof"))

                        inxVehicleTab:AddFeature(joaat("BreathingNeon"))
                        inxVehicleTab:AddFeature(joaat("BreathingNeonSlider"))

                        inxVehicleTab:AddSeperator("Currently Copied: " .. (copied_vehicle ~= nil and HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(copied_vehicle["model"])) or "None"))
                        inxVehicleTab:AddFeature(joaat("VehicleStealerSpawn"))
                        inxVehicleTab:AddFeature(joaat("ClearCopiedVehicleCode"))
                    end
                    inxTab:AddSeperator("Unlocks")
                    inxTab:AddFeature(joaat("UnlockChameleonPaints"))
                end
                local Pstuff = ElfScriptTab:AddSubTab("Session", "contains all the stuff")
                if Pstuff then
                    Pstuff:AddFeature(joaat("SHSTEAL"))
                    Pstuff:AddFeature(joaat("Forcequit"))
                    Pstuff:AddFeature(joaat("ShowModders"))
                    if version == "LE" then 
                        Pstuff:AddFeature(joaat("AltChat"))
                        Pstuff:AddFeature(joaat("KeywordCombo"))
                        Pstuff:AddFeature(joaat("KeywordInput"))
                        Pstuff:AddFeature(joaat("deletekeyword"))
                    end
                    Pstuff:AddFeature(joaat("ChangeModderRID"))
                    Pstuff:AddFeature(joaat("ReasonModderRID"))
                    Pstuff:AddFeature(joaat("AddModderRID"))
                    Pstuff:AddFeature(joaat("RemoveModderRID"))

                    local Csettings = Pstuff:AddSubTab("Chat Settings",
                        "Contains all the chat settings needed for the alternative chat")
                    if Csettings then
                        local features = {
                            "AltChatMessageSpacing", "AltChatNoScrollbar",
                            "AltChatAutoResize", "AltChatRandomColors", "AltChatNoTitleBar",
                            "AltChatNoResize", "AltChatNoMove", "AltChatAutoScroll",
                            "AltChatFontScale", "AltChatBGColor", "AltChatTextColor"
                        }
                        for _, feature in ipairs(features) do
                            Csettings:AddFeature(joaat(feature))
                        end
                    end
                    local msettings = Pstuff:AddSubTab("Modder Settings", "Contains all the modder settings")
                    if msettings then
                        msettings:AddFeature(joaat("flagAutoResizeMD"))
                        msettings:AddFeature(joaat("flagNoMoveMD"))
                        msettings:AddFeature(joaat("flagNoResizeMD"))
                        msettings:AddFeature(joaat("flagNoTitleBarMD"))
                        msettings:AddFeature(joaat("colorBGelf1"))
                        msettings:AddFeature(joaat("TextColor111"))
                        msettings:AddFeature(joaat("DMFontScale"))
                    end
                end
                local SelfTab = ElfScriptTab:AddSubTab("Self", "Fun Self Features")
                if SelfTab then
                    SelfTab:AddFeature(joaat("FlashTime"))
                    SelfTab:AddFeature(joaat("Stats to change Combo"))
                    SelfTab:AddFeature(joaat("Stats Int input"))
                    SelfTab:AddFeature(joaat("Change Stat Value"))
                    SelfTab:AddFeature(joaat("SightSeerRig"))
                    SelfTab:AddFeature(joaat("YachtAttackRig"))
                end
                local vehicleTab = ElfScriptTab:AddSubTab("Vehicle", "Fun Vehicle Features")
                if vehicleTab then
                    local WPStuff = vehicleTab:AddSubTab("Waypoint Line", "Waypoint Line Features")
                    if WPStuff then
                        WPStuff:AddFeature(joaat("waypointline"))
                        WPStuff:AddFeature(joaat("WPColor"))
                        WPStuff:AddFeature(joaat("DrawCone"))
                        WPStuff:AddFeature(joaat("MarkerColor"))
                        WPStuff:AddFeature(joaat("xrott"))
                        WPStuff:AddFeature(joaat("yrott"))
                        WPStuff:AddFeature(joaat("scalex"))
                        WPStuff:AddFeature(joaat("scaley"))
                        WPStuff:AddFeature(joaat("scalez"))
                        WPStuff:AddFeature(joaat("MarkerType"))
                        WPStuff:AddFeature(joaat("RandomColorwp"))
                        WPStuff:AddFeature(joaat("bobchecker"))
                        WPStuff:AddFeature(joaat("zvaluee"))
                        WPStuff:AddFeature(joaat("linesforwp"))
                        WPStuff:AddFeature(joaat("markeroffset"))
                    end

                    vehicleTab:AddFeature(joaat("patriotbutton"))
                    vehicleTab:AddFeature(joaat("patriottoggle"))
                    vehicleTab:AddFeature(joaat("SpeedPlateKMH"))
                    vehicleTab:AddFeature(joaat("SpeedPlateUnits"))
                    vehicleTab:AddFeature(joaat("LicensePlateScroller"))
                end

                local SettingsTab = ElfScriptTab:AddSubTab("Settings", "Contains Settings for Elf Script")
                if SettingsTab then
                    SettingsTab:AddFeature(joaat("guiModeCombo"))
                    SettingsTab:AddFeature(joaat("configsave"))
                end
            end
        end

        for index = 0, 31 do
            local playerRoot = ListGUI.GetPlayerTab(index)
            if playerRoot then
                playerRoot:AddSeperator("Elf Script")
                local CageTab = playerRoot:AddSubTab("Cages", "Cage Features for Elf Script")
                CageTab:AddFeature(joaat("CageSelectedPlayer"), index)
                CageTab:AddFeature(joaat("CouchCage"), index)
                CageTab:AddFeature(joaat("fatspam"), index)

                local TrollTab = playerRoot:AddSubTab("Trolling", "Trolling Features for Elf Script")
                if TrollTab then
                        TrollTab:AddFeature(joaat("explodeveh"), index)
                        TrollTab:AddFeature(joaat("npcAttackSquad"), index)
                        TrollTab:AddFeature(joaat("vehiclespam"), index)
                        TrollTab:AddFeature(joaat("vehiclenuke"), index)
                        TrollTab:AddFeature(joaat("FlyingMonkeys"), index)
                        TrollTab:AddFeature(joaat("SpawnRCCar"), index)
                        TrollTab:AddFeature(joaat("aggroRc"), index)
                        TrollTab:AddFeature(joaat("Clearthem"))
                        TrollTab:AddFeature(joaat("jetSlider"))
                        TrollTab:AddFeature(joaat("airattack"), index)
                        TrollTab:AddFeature(joaat("sendTP"), index)
                        TrollTab:AddFeature(joaat("Event19"), index)
                        TrollTab:AddFeature(joaat("VEHICLE_FUCKER"), index)
                        TrollTab:AddFeature(joaat("Chaos_crash"), index)
                        TrollTab:AddFeature(joaat("vehiclenuke"), index)
                        TrollTab:AddFeature(joaat("Chaosnuke"), index)
                end
            end
        end
    end
    guiModeCombo = FeatAdd(joaat("guiModeCombo"), "GUI Mode", eFeatureType.Combo, "Select GUI Mode")
    guiModeCombo:SetList({ "MenUI", "Internal GUI", "List GUI" })
    guiModeCombo:SetListIndex(0)


    RunScans()

    renderevent = nil
    cachedMode = GUI.GetMode()
    lastSelectedIndex = guiModeCombo:GetListIndex()

    local listGuiInitialized = false

    function OnGuiModeChange()
        local selectedIndex = guiModeCombo:GetListIndex()

        if renderevent then
            EventMgr.RemoveHandler(renderevent)
            renderevent = nil
        end

        if selectedIndex == 0 then
            GUI.SetMode(eGuiMode.ClickGUI)
            renderevent = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, RenderMainGUI)
            ClickGUI.RemoveTab("Elf Script")
            listGuiInitialized = false

        elseif selectedIndex == 1 then
            GUI.SetMode(eGuiMode.ClickGUI)
            ClickGUI.AddTab("Elf Script", RenderCheraxGUI)
            listGuiInitialized = false

        elseif selectedIndex == 2 then
            GUI.SetMode(eGuiMode.ListGUI)
            if not listGuiInitialized then
                renderListUI()
                listGuiInitialized = true
            end
        end

        cachedMode = GUI.GetMode()
        lastSelectedIndex = selectedIndex
    end
    function CheckGuiMode()
        local selectedIndex = guiModeCombo:GetListIndex()
        if selectedIndex ~= lastSelectedIndex then
            OnGuiModeChange()
        end
    end

    function RenderModeWatcher()
        if not ShouldUnload() then
            local currentMode = GUI.GetMode()
            if currentMode ~= cachedMode then
                if currentMode == eGuiMode.ClickGUI then
                    guiModeCombo:SetListIndex(0)
                elseif currentMode == eGuiMode.ListGUI then
                    guiModeCombo:SetListIndex(2)
                end
                cachedMode = currentMode
            end
        end
    end

    Script.RegisterLooped(CheckGuiMode)
    Script.RegisterLooped(RenderModeWatcher)
    function InitializeGuiMode()
        local currentMode = GUI.GetMode()

        if currentMode == eGuiMode.ClickGUI then
            guiModeCombo:SetListIndex(0)
        elseif currentMode == eGuiMode.ListGUI then
            guiModeCombo:SetListIndex(2)
        end

        OnGuiModeChange()
    end

    InitializeGuiMode()

function loadDefaultConfig()
    local filepath = menuRootPath .. "\\" .. "DefaultConfig.json"

    if FileMgr.DoesFileExist(filepath) then
        local raw = FileMgr.ReadFileContent(filepath)
        local settings = json.decode(raw)

        if type(settings) == "table" and type(settings.features) == "table" then
            for hashStr, data in pairs(settings.features) do
                local hash = tonumber(hashStr)

                if hash and type(data) == "table" and data.value ~= nil then
                    local feature = FeatureMgr.GetFeature(hash)
                    if feature then
                        local t = feature:GetType()

                        if t == eFeatureType.Toggle then
                            feature:SetBoolValue(data.value == true)
                        elseif t == eFeatureType.Combo then
                            feature:SetListIndex(tonumber(data.value) or 0)
                            if hash == joaat("guiModeCombo") then
                                OnGuiModeChange()
                            end
                        elseif t == eFeatureType.SliderInt then
                            feature:SetIntValue(tonumber(data.value) or 0)
                        elseif t == eFeatureType.SliderFloat then
                            feature:SetFloatValue(tonumber(data.value) or 0.0)
                        elseif t == eFeatureType.InputText then
                            feature:SetStringValue(tostring(data.value))
                        elseif t == eFeatureType.InputColor4 and type(data.value) == "table" then
                            feature:SetColor(
                                tonumber(data.value[1]) or 0,
                                tonumber(data.value[2]) or 0,
                                tonumber(data.value[3]) or 0,
                                tonumber(data.value[4]) or 255
                            )
                        end
                    else
                        GradientLogger("Feature not found for hash: " .. tostring(hash))
                    end
                end
            end

      
            GradientLogger("Default config loaded successfully.")
        else
            GradientLogger("Invalid JSON format.")
        end
    else
        GradientLogger("Config file not found create one or dont" )
    end
end

    loadDefaultConfig()
    ClickGUI.AddPlayerTab("Elf Script", RenderPlayerTab)

    if Cherax.GetUID() == 26949 then
        AddToast("inx + elf fusion loaded.", "hi there elf <3                   ")
    elseif Cherax.GetUID() == 29089 then
        AddToast("inx + elf fusion loaded.", "hi to myself ig hehe                     ")
    else
        AddToast("inx + elf fusion loaded.", "join the discord <3 elf the goat                 ")
    end

    Script.QueueJob(function()
        local lasttime = Time.GetEpocheMs()
        local time = math.abs(scriptloadtime - lasttime)
        GradientLogger("Elf Script loaded in " .. time .. " ms.")
        Script.Yield(2000)
        GradientLogger("Loaded " .. #Features .. " features from Elf Script.")
        GradientLogger("Loaded " .. #Features.PlayerFeatures .. " Player Features from Elf Script")
        GradientLogger("Loaded " .. #Features.GuiFeatures .. " GUI Features from Elf Script")
    end)
    
    --[[ to do self radio multiplayer??
        entity gun that can shoot cars, animals, or objects 
        buy all clothes with one button?
    ]]
