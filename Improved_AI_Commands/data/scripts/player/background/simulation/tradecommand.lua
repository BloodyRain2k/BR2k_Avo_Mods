function TradeCommand:buildUI(startPressedCallback, changeAreaPressedCallback, recallPressedCallback, configChangedCallback)
    local ui = {}

    ui.orderName = "Trade"%_t
    ui.icon = TradeCommand:getIcon()

    local size = vec2(660, 700)

    ui.window = GalaxyMap():createWindow(Rect(size))
    ui.window.caption = "Trading Contract"%_t

    ui.commonUI = SimulationUtility.buildCommandUI(ui.window, startPressedCallback, changeAreaPressedCallback, recallPressedCallback, configChangedCallback, {areaHeight = 130, configHeight = 210, changeAreaButton = true})

    -- configurable values
    local vlist = UIVerticalLister(ui.commonUI.configRect, 5, 5)
    local rect = vlist:nextRect(15)
    rect.lower = rect.lower - vec2(0, 10)

    local hlist = UIHorizontalLister(rect, 5, 5)

    local label = ui.window:createLabel(hlist:nextRect(220), "Trade Route Contracts"%_t, 13)
    hlist:nextRect(20) -- for icon
    local label = ui.window:createLabel(hlist:nextRect(65), "¢", 13)
    label.tooltip = "Regular price for this good"%_t
    label:setRightAligned()
    local label = ui.window:createLabel(hlist:nextRect(40), "%", 13)
    label.tooltip = "Price margin of the route"%_t
    label:setRightAligned()
    local label = ui.window:createLabel(hlist:nextRect(50), "min"%_t, 12)
    label.tooltip = "Best deviation for the purchase price in the area"%_t
    label:setRightAligned()
    local label = ui.window:createLabel(hlist:nextRect(35), "max"%_t, 12)
    label.tooltip = "Best deviation for the selling price in the area"%_t
    label:setRightAligned()
    local label = ui.window:createLabel(hlist:nextRect(80), "#", 12)
    label.tooltip = "Transportable in a single flight"%_t
    label:setRightAligned()
    local label = ui.window:createLabel(hlist.inner, "¢/u", 12)
    label.tooltip = "Profit per single good"%_t
    label:setRightAligned()

    ui.routeLines = {}
    for i = 1, 4 do
        local line = {}
        local rect = vlist:nextRect(30)
        line.frame = ui.window:createFrame(rect)

        local hlist = UIHorizontalLister(rect, 5, 5)

        line.check = ui.window:createCheckBox(hlist:nextRect(220), "", "TradeCommand_onRouteChecked")
        line.check.captionLeft = false
        line.check.fontSize = 13

        local rect = hlist:nextQuadraticRect()
        rect.size = rect.size + 6
        line.icon = ui.window:createPicture(rect, "")
        line.icon.isIcon = true

        line.priceLabel = ui.window:createLabel(hlist:nextRect(65), "", 13)
        line.priceLabel:setRightAligned()
        line.marginLabel = ui.window:createLabel(hlist:nextRect(40), "", 13)
        line.marginLabel:setRightAligned()
        line.lowestLabel = ui.window:createLabel(hlist:nextRect(50), "", 12)
        line.lowestLabel:setRightAligned()
        line.lowestLabel.color = ColorRGB(0.6, 0.6, 0.6)
        line.highestLabel = ui.window:createLabel(hlist:nextRect(35), "", 12)
        line.highestLabel:setRightAligned()
        line.highestLabel.color = ColorRGB(0.6, 0.6, 0.6)
        line.carriableLabel = ui.window:createLabel(hlist:nextRect(80), "", 13)
        line.carriableLabel:setRightAligned()
        line.profitLabel = ui.window:createLabel(hlist.inner, "", 13)
        line.profitLabel:setRightAligned()
        line.totalQuantityLabel = ui.window:createLabel(hlist.inner, "", 13)
        line.totalQuantityLabel:setRightAligned()

        line.hide = function(self)
            line.frame:hide()
            line.icon:hide()
            line.check:hide()
            line.lowestLabel:hide()
            line.highestLabel:hide()
            line.carriableLabel:hide()
            line.priceLabel:hide()
            line.marginLabel:hide()
            line.profitLabel:hide()
            line.totalQuantityLabel:hide()
        end
        line.show = function(self)
            line.frame:show()
            line.icon:show()
            line.check:show()
            line.lowestLabel:show()
            line.highestLabel:show()
            line.carriableLabel:show()
            line.priceLabel:show()
            line.marginLabel:show()
            line.profitLabel:show()
            line.totalQuantityLabel:show()
        end

        table.insert(ui.routeLines, line)
    end

    self.mapCommands.TradeCommand_onRouteChecked = function(checkBox)
        local line = nil
        for _, l in pairs(ui.routeLines) do
            if l.check.index ~= checkBox.index then
                l.check:setCheckedNoCallback(false)
            else
                line = l
            end
        end

        if not line then return end

        local good = line.good

        local position = ui.depositSlider.sliderPosition
        ui.depositSlider:setValueNoCallback(0)
        ui.depositSlider.min = line.minAmount
        ui.depositSlider.max = line.maxAmount
        ui.depositSlider.segments = line.maxAmount - line.minAmount

        ui.depositSlider:setValueNoCallback(math.ceil(lerp(position, 0, 1, line.minAmount, line.maxAmount)))

        self.mapCommands[configChangedCallback]()
    end

    local rect = vlist:nextRect(50)
    local vsplit = UIVerticalMultiSplitter(rect, 20, 10, 2)
    ui.depositDescriptionLabel = ui.window:createLabel(vsplit.left, "Down Payment"%_t, 13)
    ui.depositDescriptionLabel:setRightAligned()
    ui.depositSlider = ui.window:createSlider(vsplit:partition(1), 0, 10, 10, "", configChangedCallback)
    ui.depositSlider.showValue = false
    ui.depositLabel = ui.window:createLabel(vsplit.right, "¢123.021"%_t, 13)
    ui.depositLabel:setLeftAligned()
    ui.depositLabel.tooltip = "Credits you need to give the captain in advance to buy the goods.\nThey will return everything they don't spend."%_t

    -- yields & issues
    local predictable = self:getPredictableValues()
    local vlist = UIVerticalLister(ui.commonUI.predictionRect, 5, 0)

    -- attack chance
    local tooltip = SimulationUtility.AttackChanceLabelTooltip
    local vsplit0 = UIVerticalSplitter(vlist:nextRect(20), 0, 0, 0.6)
    local label = ui.window:createLabel(vsplit0.left, predictable.attackChance.displayName .. ":", 12)
    label.tooltip = tooltip
    ui.commonUI.attackChanceLabel = ui.window:createLabel(vsplit0.right, "", 12)
    ui.commonUI.attackChanceLabel:setRightAligned()
    ui.commonUI.attackChanceLabel.tooltip = tooltip

    -- amount of goods to transport
    local tooltip = "Total quantity of goods to be transported for this contract"%_t
    local vsplit2 = UIVerticalSplitter(vlist:nextRect(15), 0, 0, 0.6)
    local label = ui.window:createLabel(vsplit2.left, predictable.maxAvailable.displayName .. ":", 12)
    label.tooltip = tooltip
    ui.totalQuantityLabel = ui.window:createLabel(vsplit2.right, "", 12)
    ui.totalQuantityLabel.tooltip = tooltip
    ui.totalQuantityLabel:setRightAligned()

    -- profit
    local tooltip = "Profit per shipment for this route"%_t
    local vsplit2 = UIVerticalSplitter(vlist:nextRect(15), 0, 0, 0.6)
    local label = ui.window:createLabel(vsplit2.left, predictable.profitPerFlight.displayName .. ":", 12)
    label.tooltip = tooltip
    ui.profitLabel = ui.window:createLabel(vsplit2.right, "", 12)
    ui.profitLabel.tooltip = tooltip
    ui.profitLabel:setRightAligned()

    -- single flight duration
    local vsplit1 = UIVerticalSplitter(vlist:nextRect(15), 0, 0, 0.6)
    local label = ui.window:createLabel(vsplit1.left, predictable.flightTime.displayName .. ":", 12)
    ui.flightTimeLabel = ui.window:createLabel(vsplit1.right, "", 12)
    ui.flightTimeLabel:setRightAligned()

    -- flights
    local tooltip = "The trade route can be flown this many times until the contract is fulfilled. If fulfillment requires too many flights, the contract may be given to someone else after a few deliveries."%_t
    local vsplit1 = UIVerticalSplitter(vlist:nextRect(15), 0, 0, 0.6)
    local label = ui.window:createLabel(vsplit1.left, predictable.flights.displayName .. ":", 12)
    label.tooltip = tooltip
    ui.flightsLabel = ui.window:createLabel(vsplit1.right, "", 12)
    ui.flightsLabel:setRightAligned()
    ui.flightsLabel.tooltip = tooltip

    -- single flight duration
    local vsplit1 = UIVerticalSplitter(vlist:nextRect(15), 0, 0, 0.6)
    local label = ui.window:createLabel(vsplit1.left, "Total flight time:", 12)
    ui.totalFlightTimeLabel = ui.window:createLabel(vsplit1.right, "", 12)
    ui.totalFlightTimeLabel:setRightAligned()

    local vsplit1 = UIVerticalSplitter(vlist:nextRect(15), 0, 0, 0.6)
    local label = ui.window:createLabel(vsplit1.left, "Total profits:", 12)
    label.tooltip = tooltip
    ui.totalLabel = ui.window:createLabel(vsplit1.right, "", 12)
    ui.totalLabel:setRightAligned()
    ui.totalLabel.tooltip = tooltip

    -- custom change area buttons
    -- make them similar to the existing button, just move them to the right
    local rect = ui.commonUI.changeAreaButton.rect
    local offset = vec2(rect.size.x + 10, 0)
    rect.lower = rect.lower + offset
    rect.upper = rect.upper + offset

    ui.changeAreaButton2 = ui.window:createButton(rect, "", "TradeCommand_reselectVertical")
    ui.changeAreaButton2.icon = "data/textures/icons/change-area-vertical.png"
    ui.changeAreaButton2.tooltip = "Choose a different area for the command"%_t

    rect.lower = rect.lower + offset
    rect.upper = rect.upper + offset

    ui.changeAreaButton3 = ui.window:createButton(rect, "", "TradeCommand_reselectHorizontal")
    ui.changeAreaButton3.icon = "data/textures/icons/change-area-horizontal.png"
    ui.changeAreaButton3.tooltip = "Choose a different area for the command"%_t

    self.mapCommands.TradeCommand_reselectVertical = function()
        self.mapCommands.nextUsedSize = 3
        self.mapCommands[changeAreaPressedCallback]()
    end

    self.mapCommands.TradeCommand_reselectHorizontal = function()
        self.mapCommands.nextUsedSize = 2
        self.mapCommands[changeAreaPressedCallback]()
    end

    ui.clear = function(self, shipName)
        self.commonUI:clear(shipName)

        for _, line in pairs(self.routeLines) do
            line.check:setCheckedNoCallback(false)
            line:hide()
        end

        self.depositDescriptionLabel:hide()
        self.depositSlider:setSliderPositionNoCallback(0.5)
        self.depositSlider:hide()
        self.depositLabel:hide()

        self.profitLabel.caption = string.format("¢%s"%_t, 0)
        self.totalQuantityLabel.caption = string.format("¢%s"%_t, 0)
        self.flightTimeLabel.caption = "0 min"

        self.commonUI.attackChanceLabel.caption = ""
    end

    -- used to fill values into the UI
    -- config == nil means fill with default values
    ui.refresh = function(self, ownerIndex, shipName, area, config)
        self.commonUI:refresh(ownerIndex, shipName, area, config)

        local entry = ShipDatabaseEntry(ownerIndex, shipName)
        local freeCargoSpace = entry:getFreeCargoSpace()

        for i = 1, math.min(#self.routeLines, #area.analysis.routes) do
            local line = self.routeLines[i]
            local route = area.analysis.routes[i]

            local good = goods[route.name]:good()
            local maxAvailable = getMaxGoodsOfRoute(route)
            local maximum = math.min(maxAvailable, math.floor(freeCargoSpace / good.size))

            line.good = good
            line.maxAmount = maximum
            line.minAmount = math.max(1, math.floor(math.min(maxAvailable * 0.1, freeCargoSpace * 0.1 / good.size)))
            line.minPrice = math.ceil(good.price * (1 + route.lowest))

            line:show()
            line.check.caption = good:displayName(100)
            line.icon.picture = good.icon
            line.lowestLabel.caption = string.format("%+d%%", round(route.lowest * 100, 1))
            line.highestLabel.caption = string.format("%+d%%", round(route.highest * 100, 1))
            line.priceLabel.caption = "¢${money}"%_t % {money = createMonetaryString(good.price)}
            line.marginLabel.caption = string.format("%+d%%", round(route.highest * 100, 1) - round(route.lowest * 100, 1))
            line.profitLabel.caption = "¢${money}"%_t % {money = createMonetaryString(route.profit)}
            line.carriableLabel.caption = maximum

            self.depositSlider:show()
            self.depositDescriptionLabel:show()
            self.depositLabel:show()

            line.check.active = maximum > 0

            if maximum == 0 then line.check:setCheckedNoCallback(false) end
        end

        if not config then
            -- no config: fill UI with default values, then build config, then use it to calculate yields
            self.depositSlider:setSliderPositionNoCallback(0.5)

            if self.routeLines[1].check.visible then
                self.routeLines[1].check.checked = true
            end

            config = self:buildConfig()
        end

        self.depositLabel.caption = "¢${money}"%_t % {money = createMonetaryString(config.deposit or 0)}

        self:refreshPredictions(ownerIndex, shipName, area, config)
    end

    -- each config option change should always be reflected in the predictions if it impacts the behavior
    ui.refreshPredictions = function(self, ownerIndex, shipName, area, config)
        local prediction = TradeCommand:calculatePrediction(ownerIndex, shipName, area, config)
        self:displayPredictionHelper(prediction, config, ownerIndex)

        self.commonUI:refreshPredictions(ownerIndex, shipName, area, config, TradeCommand, prediction)
    end

    -- this function is shared for two uses: for configuring the command and for displaying the running command (read only)
    ui.displayPredictionHelper = function(self, prediction, config, ownerIndex)
        self.depositLabel.caption = "¢${money}"%_t % {money = createMonetaryString(config.deposit or 0)}

        local flightTime = math.ceil(prediction.flightTime.value / 60) * 60
        self.flightTimeLabel.caption = createReadableShortTimeString(flightTime)

        local avgProfit = (prediction.profitPerFlight.from + prediction.profitPerFlight.to) / 2
        if prediction.flights.from == prediction.flights.to then
            self.flightsLabel.caption = toReadableNumber(prediction.flights.to, 1)
            self.totalLabel.caption = string.format("¢%s - ¢%s", toReadableNumber(prediction.profitPerFlight.from * prediction.flights.to, 1), toReadableNumber(prediction.profitPerFlight.to * prediction.flights.to, 1))
            self.totalFlightTimeLabel.caption = string.format("%s", createReadableShortTimeString(flightTime * prediction.flights.to))
        else
            self.flightsLabel.caption = string.format("%s - %s", toReadableNumber(prediction.flights.from, 1), toReadableNumber(prediction.flights.to, 1))
            self.totalLabel.caption = string.format("~¢%s - ~¢%s", toReadableNumber(avgProfit * prediction.flights.from, 1), toReadableNumber(avgProfit * prediction.flights.to, 1))
            self.totalFlightTimeLabel.caption = string.format("%s - %s", createReadableShortTimeString(flightTime * prediction.flights.from),createReadableShortTimeString(flightTime * prediction.flights.to))
        end

        self.profitLabel.caption = string.format("¢%s - ¢%s", toReadableNumber(prediction.profitPerFlight.from, 1), toReadableNumber(prediction.profitPerFlight.to, 1))
        self.totalQuantityLabel.caption = tostring(prediction.maxAvailable.value)

        self.commonUI:setAttackChance(prediction.attackChance.value)
    end

    -- fill in read only values when displaying the running command
    ui.displayPrediction = function(self, prediction, config, ownerIndex)
        self:displayPredictionHelper(prediction, config, ownerIndex)

        local good = goods[prediction.route.name]:good()
        local maximum = math.floor(prediction.freeCargoSpace / good.size)

        local line = self.routeLines[1]
        line.check.caption = good:displayName(100)
        line.icon.picture = good.icon
        line.lowestLabel.caption = string.format("%+d%%", round(prediction.route.lowest * 100, 1))
        line.highestLabel.caption = string.format("%+d%%", round(prediction.route.highest * 100, 1))
        line.priceLabel.caption = "¢${money}"%_t % {money = createMonetaryString(good.price)}
        line.marginLabel.caption = string.format("%+d%%", round(prediction.route.highest * 100, 1) - round(prediction.route.lowest * 100, 1))
        line.profitLabel.caption = "¢${money}"%_t % {money = createMonetaryString(prediction.route.profit)}
        line.carriableLabel.caption = maximum
    end

    -- used to build a config table for the command, based on values configured in the UI
    -- gut feeling says that each config option change should always be reflected in the predictions if it impacts the behavior
    ui.buildConfig = function(self)
        local config = {}

        config.escorts = self.commonUI.escortUI:buildConfig()

        local line = nil
        for _, l in pairs(self.routeLines) do
            if l.check.checked then
                line = l
            end
        end

        if line then
            config.goodName = line.good.name
            config.deposit = self.depositSlider.value * line.minPrice
            config.maxDeposit = self.depositSlider.max * line.minPrice
        end

        return config
    end

    ui.setActive = function(self, active, description)
        self.commonUI:setActive(active, description)

        self.changeAreaButton2.visible = active
        self.changeAreaButton3.visible = active

        self.depositSlider.active = active

        for i = 1, 4 do
            self.routeLines[i].check.active = active
        end
    end

    ui.displayConfig = function(self, config, ownerIndex)
        -- show only the chosen trade route contract
        self.routeLines[1]:show()
        for i = 2, 4 do
            self.routeLines[i]:hide()
        end

        self.routeLines[1].check:setCheckedNoCallback(true)

        self.depositSlider:setMaxNoCallback(config.maxDeposit)
        self.depositSlider:setValueNoCallback(config.deposit)
    end

    return ui
end
