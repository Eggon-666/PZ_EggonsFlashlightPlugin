local flashlights = {
    ["Base.Torch"] = true,
    ["Base.HandTorch"] = true
}

local function hasCharge(item)
    if item.getRemainingUses and item:getRemainingUses() > 0 then
        return true
    end
    return false
end

local function equipFlashlight()
    local player = getPlayer()
    local inv = player:getInventory()

    -- sprawdź czy latarka jest equipped as secondaryHandItem
    local HI = player:getSecondaryHandItem()
    if not HI or not flashlights[HI:getFullType()] then
        HI = player:getPrimaryHandItem()
    end
    if HI and flashlights[HI:getFullType()] then
        local isOn = HI:isActivated()
        if isOn then
            -- jeśli była włączona i ma zapisany container to spakuj do kontenera
            HI:setActivated(false)
            local srcContainer = HI:getModData().sourceContainer
            if srcContainer then
                local transferAction = ISInventoryTransferAction:new(player, HI, inv, srcContainer)
                ISTimedActionQueue.add(transferAction)
            end
        else
            if hasCharge(HI) then
                -- jeśli ma charge to switch
                HI:setActivated(true)
            else
                -- jeśli nie ma charge powiedz coś
                player:Say("I think the battery is dead.")
            end
        end
        return
    end

    -- znajdź latarkę z remaining charge spośród zdefiniowanych latarek
    local flashlight
    local flashlightFound = false
    for fullType, _ in pairs(flashlights) do
        local instances = inv:getAllTypeRecurse(fullType)
        if instances:size() > 0 then
            for i = 0, instances:size() - 1 do
                flashlight = instances:get(i)
                if hasCharge(flashlight) then
                    break
                else
                    flashlight = nil
                end
            end
            flashlightFound = true
        end
        if flashlight then
            break
        end
    end

    if flashlight then
        flashlight:getModData().sourceContainer = flashlight:getContainer()
        ISInventoryPaneContextMenu.equipWeapon(flashlight, false, false, player:getPlayerNum()) -- (weapon, primary, twoHands, player)
        flashlight:setActivated(true)
    elseif flashlightFound then -- ony uncharged found
        player:Say("All my flashlights are discharged.")
    else -- no flashlights found
        player:Say("I don't have any flashlight on me.")
    end
end

local keyConfigs = {
    flashlight = {
        action = equipFlashlight,
        keyCode = 0
    }
}
if EHK_Plugin then
    EHK_Plugin:AddConfigs(keyConfigs)
end
