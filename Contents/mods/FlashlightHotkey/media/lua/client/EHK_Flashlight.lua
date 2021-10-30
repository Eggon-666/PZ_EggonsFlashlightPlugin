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
    local SHI = player.getSecondaryHandItem()
    if flashlights[SHI:getFullType()] then
        local isOn = SHI:getActivated()
        local srcContainer = SHI.getModData().sourceContainer
        if isOn then
            -- jeśli była włączona i ma zapisany container to spakuj do kontenera
            SHI:setActivated(false)
            if srcContainer then
                local transferAction = ISInventoryTransferAction:new(player, SHI, inv, srcContainer)
                ISTimedActionQueue.add(transferAction)
            end
        else
            if hasCharge(SHI) then
                -- jeśli ma charge to switch
                SHI:setActivated(true)
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
        flashlight.getModData().sourceContainer = flashlight:getContainer()
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