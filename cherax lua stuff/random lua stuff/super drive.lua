local driveToggle = FeatureMgr.AddFeature(Utils.Joaat("SuperDrive"), "SuperDrive", eFeatureType.Toggle, "Accelerates vehicle in the direction you're aiming")
local speedSlider = FeatureMgr.AddFeature(Utils.Joaat("SuperDriveSpeed"), "Drive Speed", eFeatureType.SliderFloat, "Controls SuperDrive thrust speed")
speedSlider:SetMinValue(1.0)
speedSlider:SetMaxValue(1800.0)
speedSlider:SetFloatValue(25.0)

PLAYER = {
	PLAYER_PED_ID=function()return Natives.InvokeInt(0xD80958FC74E988A6)end;---@return integer
}

PED = {
    IS_PED_IN_ANY_VEHICLE=function(ped--[[@param ped integer]],atGetIn--[[@param atGetIn boolean]])return Natives.InvokeBool(0x997ABD671D25CA0B,ped,atGetIn)end;---@return boolean
    GET_VEHICLE_PED_IS_IN=function(ped--[[@param ped integer]],includeEntering--[[@param includeEntering boolean]])return Natives.InvokeInt(0x9A9112A0FE9A4713,ped,includeEntering)end;---@return integer
}

ENTITY = { 
    DOES_ENTITY_EXIST=function(entity--[[@param entity integer]])return Natives.InvokeBool(0x7239B21A38F536BA,entity)end;---@return boolean
    SET_ENTITY_VELOCITY=function(entity--[[@param entity integer]],x--[[@param x number]],y--[[@param y number]],z--[[@param z number]])return Natives.InvokeVoid(0x1C99BB7B6E96D16F,entity,x+.0,y+.0,z+.0)end;
	APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS=function(entity--[[@param entity integer]],forceType--[[@param forceType integer]],x--[[@param x number]],y--[[@param y number]],z--[[@param z number]],p5--[[@param p5 boolean]],isDirectionRel--[[@param isDirectionRel boolean]],isForceRel--[[@param isForceRel boolean]],p8--[[@param p8 boolean]])return Natives.InvokeVoid(0x18FF00FC7EFF559E,entity,forceType,x+.0,y+.0,z+.0,p5,isDirectionRel,isForceRel,p8)end;
	GET_ENTITY_FORWARD_VECTOR=function(entity--[[@param entity integer]])return Natives.InvokeV3(0x0A794A5A57F8DF91,entity)end;---@return V3

}

CAM = {
	GET_FINAL_RENDERED_CAM_ROT=function(rotationOrder--[[@param rotationOrder integer]])return Natives.InvokeV3(0x5B4E4C817FCC2DFB,rotationOrder)end;---@return V3
}

VEHICLE = {
    SET_VEHICLE_REDUCE_GRIP=function(vehicle--[[@param vehicle integer]],toggle--[[@param toggle boolean]])return Natives.InvokeVoid(0x222FF6A823D122E2,vehicle,toggle)end;
	SET_VEHICLE_REDUCE_GRIP_LEVEL=function(vehicle--[[@param vehicle integer]],val--[[@param val integer]])return Natives.InvokeVoid(0x6DEE944E1EE90CFB,vehicle,val)end;
}

function rotationToDirection(rotX, rotY, rotZ)
    local radX = math.rad(rotX)
    local radZ = math.rad(rotZ)

    local cosX = math.cos(radX)
    local sinX = math.sin(radX)
    local cosZ = math.cos(radZ)
    local sinZ = math.sin(radZ)

    local dirX = -sinZ * cosX
    local dirY =  cosZ * cosX
    local dirZ = sinX

    return dirX, dirY, dirZ
end


Script.RegisterLooped(function()

    local ped = PLAYER.PLAYER_PED_ID()
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if not driveToggle:IsToggled() then 
        FeatureMgr.GetFeatureByName("Hulk Vehicle"):SetBoolValue(false)
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(vehicle, false)
        return 
    end
    FeatureMgr.GetFeatureByName("Hulk Vehicle"):SetBoolValue(true)

    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return end

    VEHICLE.SET_VEHICLE_REDUCE_GRIP(vehicle, true)
    VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(vehicle, 2)
    if not ENTITY.DOES_ENTITY_EXIST(vehicle) then return end

    local camRotX, camRotY, camRotZ = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
    local dirX, dirY, dirZ = rotationToDirection(camRotX, camRotY, camRotZ)

    local mag = math.sqrt(dirX^2 + dirY^2 + dirZ^2)
    if mag == 0 then return end
    dirX, dirY, dirZ = dirX / mag, dirY / mag, dirZ / mag

    local rawForce = speedSlider:GetFloatValue() / 100.0 
    local force = math.min(math.max(rawForce, 1.0), 20.0) / 10.0
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle, 1, dirX * force, dirY * force, dirZ * force, true, false, true, true)
end)


ClickGUI.AddTab("superdrive", function()
    ClickGUI.RenderFeature(Utils.Joaat("SuperDrive"))
    ClickGUI.RenderFeature(Utils.Joaat("SuperDriveSpeed"))
end)