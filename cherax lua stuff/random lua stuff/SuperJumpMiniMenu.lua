-- Mini Menu for Super Jump in Cherax
local superJumpEnabled = false

-- Constants for Super Jump configuration
local JUMP_FORCE = 15.0  -- Vertical force applied to make player jump higher

-- Define native functions needed for Super Jump
PLAYER = {
    PLAYER_PED_ID = function() return Natives.InvokeInt(0xD80958FC74E988A6) end
}

PED = {
    IS_PED_JUMPING = function(ped) return Natives.InvokeBool(0xCEDABC5900A0BF97, ped) end
}

ENTITY = {
    -- Native: APPLY_FORCE_TO_ENTITY
    -- Parameters: entity, forceType, x, y, z, offX, offY, offZ, boneIndex, isDirectionRel, ignoreUpVec, isForceRel, p12 (unused), p13 (unused)
    APPLY_FORCE_TO_ENTITY = function(entity, forceType, x, y, z, offX, offY, offZ, boneIndex, isDirectionRel, ignoreUpVec, isForceRel, p12, p13)
        return Natives.InvokeVoid(0xC5F68BE9613E2D18, entity, forceType, x + .0, y + .0, z + .0, offX + .0, offY + .0, offZ + .0, boneIndex, isDirectionRel, ignoreUpVec, isForceRel, p12, p13)
    end
}

-- Create the Super Jump toggle feature
local superJumpFeature = FeatureMgr.AddFeature(
    Utils.Joaat("SuperJump"),
    "Super Jump",
    eFeatureType.Toggle,
    "Enable super jump for player",
    function(feat)
        superJumpEnabled = feat:IsToggled()
        if superJumpEnabled then
            GUI.AddToast("Super Jump", "Super Jump Activated!", 3000, eToastPos.TOP_RIGHT)
        else
            GUI.AddToast("Super Jump", "Super Jump Deactivated!", 3000, eToastPos.TOP_RIGHT)
        end
    end
)

-- Handler to modify jump mechanics
Script.RegisterLooped(function()
    if superJumpEnabled then
        local playerPed = PLAYER.PLAYER_PED_ID()
        if PED.IS_PED_JUMPING(playerPed) then
            -- Apply upward force when player jumps
            -- forceType: 1 (apply force), force: (0, 0, JUMP_FORCE) for upward push
            -- offset: (0, 0, 0), boneIndex: true, isDirectionRel: true, ignoreUpVec: true, isForceRel: true
            ENTITY.APPLY_FORCE_TO_ENTITY(playerPed, 1, 0, 0, JUMP_FORCE, 0, 0, 0, true, true, true, true, false, true)
        end
    end
    Script.Yield(0)
end)

-- Adding Tab for Mini Menu
ClickGUI.AddTab("Mini Menu", function()
    if ClickGUI.BeginCustomChildWindow("Super Jump Features") then
        ClickGUI.RenderFeature(Utils.Joaat("SuperJump"))
        ClickGUI.EndCustomChildWindow()
    end
end)
