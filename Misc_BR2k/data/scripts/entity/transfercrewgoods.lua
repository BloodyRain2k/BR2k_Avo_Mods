function TransferCrewGoods.refreshCargoUI(playerShip, ship)
    -- update cargo info
    playerTotalCargoBar:clear()
    selfTotalCargoBar:clear()

    playerTotalCargoBar:setRange(0, playerShip.maxCargoSpace)
    selfTotalCargoBar:setRange(0, ship.maxCargoSpace)

    -- restore textbox values
    local playerAmountByIndex = {}
    local selfAmountByIndex = {}
    for cargoName, index in pairs(playerCargoTextBoxByIndex) do
        playerAmountByIndex[cargoName] = playerCargoTextBoxes[index].text
    end
    for cargoName, index in pairs(selfCargoTextBoxByIndex) do
        selfAmountByIndex[cargoName] = selfCargoTextBoxes[index].text
    end

    local playerCargo = {}
    local selfCargo = {}
    playerCargoTextBoxByIndex = {}
    selfCargoTextBoxByIndex = {}

    for good, amount in pairs(playerShip:getCargos()) do
        table.insert(playerCargo, { name = good.name, good = good, amount = amount })
    end
    table.sort(playerCargo, function(a,b) return a.name < b.name end)
    
    for good, amount in pairs(ship:getCargos()) do
        table.insert(selfCargo, { name = good.name, good = good, amount = amount })
    end
    table.sort(selfCargo, function(a,b) return a.name < b.name end)

    for i, _ in pairs(playerCargoBars) do
        local icon = playerCargoIcons[i]
        local bar = playerCargoBars[i]
        local button = playerCargoButtons[i]
        local box = playerCargoTextBoxes[i]

        if i > playerShip.numCargos then
            icon:hide()
            bar:hide()
            button:hide()
            box:hide()
        else
            icon:show()
            bar:show()
            button:show()

            local good = playerCargo[i].good
            local amount = playerCargo[i].amount
            local maxSpace = playerShip.maxCargoSpace
            playerCargoName[i] = good.name
            icon.picture = good.icon
            bar:setRange(0, maxSpace)
            bar.value = amount * good.size

            -- restore textbox value
            if not box.isTypingActive then
                local boxAmount = TransferCrewGoods.clampNumberString(playerAmountByIndex[good.name] or amount, amount)
                playerCargoTextBoxByIndex[good.name] = i
                box:show()
                if boxAmount == "" then
                    box.text = amount
                else
                    box.text = boxAmount
                end
            end

            local name = "${amount} ${good}"%_t % {amount = createMonetaryString(amount), good = good:displayName(amount)}
            bar.name = name
            playerTotalCargoBar:addEntry(amount * good.size, name, ColorInt(0xffa0a0a0))
        end

        local icon = selfCargoIcons[i]
        local bar = selfCargoBars[i]
        local button = selfCargoButtons[i]
        local box = selfCargoTextBoxes[i]

        if i > ship.numCargos then
            icon:hide()
            bar:hide()
            button:hide()
            box:hide()
        else
            icon:show()
            bar:show()
            button:show()

            local good, amount = ship:getCargo(i - 1)
            local maxSpace = ship.maxCargoSpace
            icon.picture = good.icon
            bar:setRange(0, maxSpace)
            bar.value = amount * good.size

            -- restore textbox value
            if not box.isTypingActive then
                local boxAmount = TransferCrewGoods.clampNumberString(selfAmountByIndex[good.name] or amount, amount)
                selfCargoTextBoxByIndex[good.name] = i
                box:show()
                if boxAmount == "" then
                    box.text = amount
                else
                    box.text = boxAmount
                end
            end

            local name = "${amount} ${good}"%_t % {amount = createMonetaryString(amount), good = good:displayName(amount)}
            bar.name = name
            selfTotalCargoBar:addEntry(amount * good.size, name, ColorInt(0xffa0a0a0))
        end
    end
end


function TransferCrewGoods.onShowWindow()
    local player = Player()
    local ship = Entity()
    local other = player.craft

    ship:registerCallback("onCrewChanged", "onCrewChanged")
    ship:registerCallback("onCaptainChanged", "onCrewChangedRefreshUI")
    ship:registerCallback("onPassengerAdded", "onCrewChangedRefreshUI")
    ship:registerCallback("onPassengerRemoved", "onCrewChangedRefreshUI")
    ship:registerCallback("onPassengersRemoved", "onCrewChangedRefreshUI")
    other:registerCallback("onCrewChanged", "onCrewChanged")
    other:registerCallback("onCaptainChanged", "onCrewChangedRefreshUI")
    other:registerCallback("onPassengerAdded", "onCrewChangedRefreshUI")
    other:registerCallback("onPassengerRemoved", "onCrewChangedRefreshUI")
    other:registerCallback("onPassengersRemoved", "onCrewChangedRefreshUI")

    -- set all textboxes to default values
    for _, box in pairs(playerCrewTextBoxes) do
        box.text = "1"
    end
    for _, box in pairs(selfCrewTextBoxes) do
        box.text = "1"
    end
    for _, box in pairs(playerCargoTextBoxes) do
        local _, playerAmount = other:getCargo(cargosByTextBox[box.index])
        box.text = playerAmount
    end
    for _, box in pairs(selfCargoTextBoxes) do
        local _, selfAmount = ship:getCargo(cargosByTextBox[box.index])
        box.text = selfAmount
    end

    TransferCrewGoods.refreshUI()
end
