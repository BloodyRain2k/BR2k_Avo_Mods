local Azimuth = include("azimuthlib-basic")
local loadedData
local exported
local maxCargoVol = 25000


local cargo_restoreTradingGoods = TradingManager.restoreTradingGoods
function TradingManager:restoreTradingGoods(data)
    -- Azimuth.saveConfig("FC_"..Entity().name, data)
    loadedData = data or {}
    cargo_restoreTradingGoods(self, loadedData)
end


--[[
function TradingManager:secureTradingGoods()
    return loadedData
end
--]]


function TradingManager:getMaxGoods(name)
    for i, good in pairs(self.soldGoods) do
        if good.name == name then
            return self:getMaxStock(good.name)
        end
    end

    for i, good in pairs(self.boughtGoods) do
        if good.name == name then
            return self:getMaxStock(good.name)
        end
    end

    return 0
end


function TradingManager:calcMaxStock(name)
    local space = Entity().maxCargoSpace
    local spaceOut = space * self.cargo.productPercent
    local spaceIn = space - spaceOut
    local stack = 25

    local cyclesIn = (spaceIn > 1) and spaceIn / self.cargo.input.volNeeded or 0
    local cyclesOut = spaceOut / self.cargo.output.volTotal
    local debugPrint = not exported and (not Faction() or Faction() and not Faction().isAIFaction)
    
    if debugPrint == true then
        printTable({
            {name = Entity().name},
            {ware = name},
            {cyclesIn = cyclesIn},
            {cyclesOut = cyclesOut},
            {spaceIn = spaceIn},
            {spaceOut = spaceOut},
            {cargo = self.cargo},
        })
    end
    
    local ware = self.cargo.input[name]
    if ware then
        local max = round(maxCargoVol / (ware.size < 1 and ware.size or 1))
        local norm = round(cyclesIn * ware.amount / stack) * stack

        if debugPrint == true then
            print(norm, max)
        end

        exported = true
        return math.min(max, norm)
    end
    
    ware = self.cargo.output[name]
    if ware then
        local max = round(maxCargoVol / (ware.size < 1 and ware.size or 1))
        local norm = round(cyclesOut * ware.amount / stack) * stack

        if debugPrint == true then
            print(norm, max)
        end

        exported = true
        return math.min(max, norm)
    end

    return 0
end


function TradingManager:getMaxStock(goodNameSize)
    local space = Entity().maxCargoSpace
    local original = goodNameSize

    if self.cargo then
        if not exported then
            -- exported = true
            Azimuth.saveConfig("FC/"..Entity().name, self)
        end

        return self:calcMaxStock(goodNameSize)
    end

    exported = true
    
    -- fallback vanilla method
    for i, good in pairs(self.soldGoods) do
        if good.name == goodNameSize then
            goodNameSize = good.size
            -- print("sell", good.name, good.size)
        end
    end

    for i, good in pairs(self.boughtGoods) do
        if good.name == goodNameSize then
            goodNameSize = good.size
            -- print("buy", good.name, good.size)
        end
    end

    if type(goodNameSize) == "number" then
        local slots = self.numBought + self.numSold
        if slots > 0 then space = space / slots end

        if space / goodNameSize > 100 then
            local factor = (goodNameSize < 1 and goodNameSize or 1)
            -- round to 100
            return math.min(
                round(maxCargoVol / factor / 250) * 250,
                round(space / goodNameSize / 100) * 100
            )
        else
            -- not very much space already, don't round
            return math.floor(space / goodNameSize)
        end
    end

    print(original.." fucked up: "..goodNameSize)
    return 0
end


function TradingManager:getInitialGoods(boughtGoodsIn, soldGoodsIn)
    local resourceAmount = math.random(1, 5)

    local boughtStockByGood = {}
    local soldStockByGood = {}

    for _, v in ipairs(boughtGoodsIn) do
        local maxStock = self:getMaxStock(v.name)
        if maxStock > 0 then

            local amount
            if resourceAmount == 1 then
                -- station has few resources available
                amount = math.random(0, maxStock * 0.15)
            else
                -- normal amount of resources available
                amount = math.random(maxStock * 0.1, maxStock * 0.5)
            end

            -- limit by value
            local maxValue = 300 * 1000 * Balancing_GetSectorRichnessFactor(Sector():getCoordinates())
            amount = math.min(amount, math.floor(maxValue / v.price))

            boughtStockByGood[v] = amount
        end
    end

    for _, v in ipairs(soldGoodsIn) do
        local maxStock = self:getMaxStock(v.name)
        if maxStock > 0 then

            local amount
            if resourceAmount == 1 then
                -- resources are used up -> more products
                amount = math.random(maxStock * 0.4, maxStock)
            else
                amount = math.random(0, maxStock * 0.6)
            end

            -- limit to 500k value at max
            local maxValue = 500 * 1000 * Balancing_GetSectorRichnessFactor(Sector():getCoordinates())
            amount = math.min(amount, math.floor(maxValue / v.price))

            soldStockByGood[v] = amount
        end
    end

    return boughtStockByGood, soldStockByGood
end


function TradingManager:updateBoughtGoodGui(index, good, price)
    if not self.guiInitialized then return end

    local maxAmount = self:getMaxStock(good.name)
    local amount = self:getNumGoods(good.name)

    if not index then
        for i, g in pairs(self.boughtGoods) do
            if g.name == good.name then
                index = i
                break
            end
        end
    end

    if not index then return end

    local line = self.boughtLines[index]
    if not line then return end

    line.name.caption = good:displayName(100)
    line.name.color = good.color
    local tagDescription = good.tagDescription
    if tagDescription == "" then
        line.name.tooltip = nil
    else
        line.name.tooltip = tagDescription
    end
    line.stock.caption = amount .. "/" .. maxAmount
    line.price.caption = createMonetaryString(price)
    line.size.caption = round(good.size, 2)
    line.icon.picture = good.icon

    local ownCargo = 0
    local ship = Entity(Player().craftIndex)
    if ship then
        ownCargo = ship:getCargoAmount(good) or 0
    end
    if ownCargo == 0 then ownCargo = "-" end
    line.you.caption = tostring(ownCargo)

    line:show()
end


function TradingManager:updateSoldGoodGui(index, good, price)

    if not self.guiInitialized then return end

    local maxAmount = self:getMaxStock(good.name)
    local amount = self:getNumGoods(good.name)

    if not index then
        for i, g in pairs(self.soldGoods) do
            if g.name == good.name then
                index = i
                break
            end
        end
    end

    if not index then return end

    local line = self.soldLines[index]
    if not line then return end

    line.icon.picture = good.icon
    line.name.caption = good:displayName(100)
    line.name.color = good.color
    local tagDescription = good.tagDescription
    if tagDescription == "" then
        line.name.tooltip = nil
    else
        line.name.tooltip = tagDescription
    end
    line.stock.caption = amount .. "/" .. maxAmount
    line.price.caption = createMonetaryString(price)
    line.size.caption = round(good.size, 2)

    for i, good in pairs(self.soldGoods) do
        local line = self.soldLines[i]

        local ownCargo = 0
        local ship = Entity(Player().craftIndex)
        if ship then
            ownCargo = math.floor((ship.freeCargoSpace or 0) / good.size)
        end

        if ownCargo == 0 then ownCargo = "-" end
        line.you.caption = tostring(ownCargo)
    end

    line:show()

end


function TradingManager:onSellTextEntered(textBox)

    local enteredNumber = tonumber(textBox.text)
    if enteredNumber == nil then
        enteredNumber = 0
    end

    local newNumber = enteredNumber

    local goodIndex = nil
    for i, line in pairs(self.boughtLines) do
        if line.number.index == textBox.index then
            goodIndex = i
            break
        end
    end
    if goodIndex == nil then return end

    local good = self.boughtGoods[goodIndex]
    if not good then
        -- no error reporting necessary, it's possible the goods got reset while waiting for sync
        -- self:reportError("Good with index " .. goodIndex .. " isn't bought");
        return
    end

    local stock = self:getNumGoods(good.name)

    local maxAmountPlaceable = self:getMaxStock(good.name) - stock;
    if maxAmountPlaceable < newNumber then
        newNumber = maxAmountPlaceable
    end


    local ship = Player().craft

    local msg

    -- make sure the player does not sell more than he has in his cargo bay
    local amountOnPlayerShip = ship:getCargoAmount(good)
    if amountOnPlayerShip == nil then return end --> no cargo bay

    if amountOnPlayerShip < newNumber then
        newNumber = amountOnPlayerShip
        if newNumber == 0 then
            msg = "You don't have any of this!"%_t
        end
    end

    if msg then
        self:sendError(nil, msg)
    end

    -- maximum number of sellable things is the amount the player has on his ship
    if newNumber ~= enteredNumber then
        textBox.text = newNumber
    end
end


function TradingManager:buyFromShip(shipIndex, goodName, amount, noDockCheck)
    local shipFaction, ship = getInteractingFactionByShip(shipIndex, callingPlayer, AlliancePrivilege.SpendResources)
    if not shipFaction then return end

    if callingPlayer then noDockCheck = nil end

    local stationFaction = Faction()

    -- check if it even buys
    if self.buyFromOthers == false and stationFaction.index ~= shipFaction.index then
        self:sendError(shipFaction, "This object doesn't buy goods from others."%_t)
        return
    end

    -- check if the good can be bought
    if not self:getBoughtGoodByName(goodName) == nil then
        self:sendError(shipFaction, "%s isn't bought."%_t, goodName)
        return
    end

    if ship.freeCargoSpace == nil then
        self:sendError(shipFaction, "Your ship has no cargo bay!"%_t)
        return
    end

    local station = Entity()

    -- check if the relations are ok
    if self.relationsThreshold then
        local relations = stationFaction:getRelations(shipFaction.index)
        if relations < self.relationsThreshold then
            self:sendError(shipFaction, "Relations aren't good enough to trade!"%_t)
            return
        end
    end

    -- check if the specific good from the player can be bought (ie. it's not illegal or something like that)
    local cargos = ship:findCargos(goodName)
    local good = nil
    local msg = "You don't have any %s to sell!"%_t
    local args = {goodName}

    for g, amount in pairs(cargos) do
        local ok
        ok, msg = self:isBoughtBySelf(g)
        args = {}
        if ok then
            good = g
            break
        end
    end

    if not good then
        self:sendError(shipFaction, msg, unpack(args))
        return
    end

    -- make sure the ship can not sell more than the station can have in stock
    local maxAmountPlaceable = self:getMaxStock(good.name) - self:getNumGoods(good.name);

    if maxAmountPlaceable < amount then
        amount = maxAmountPlaceable

        if maxAmountPlaceable == 0 then
            self:sendError(shipFaction, "This station is not able to take any more %s."%_t, good:pluralForm(0))
        end
    end

    -- make sure the player does not sell more than he has in his cargo bay
    local amountOnShip = ship:getCargoAmount(good)

    if amountOnShip < amount then
        amount = amountOnShip

        if amountOnShip == 0 then
            self:sendError(shipFaction, "You don't have any %s on your ship."%_t, good:pluralForm(0))
        end
    end

    if amount <= 0 then
        return
    end

    -- begin transaction
    -- calculate price. if the seller is the owner of the station, the price is 0
    local price = self:getBuyPrice(good.name, shipFaction.index) * amount

    local canPay, msg, args = stationFaction:canPay(price * self.factionPaymentFactor);
    if not canPay then
        self:sendError(shipFaction, "This station's faction doesn't have enough money."%_t)
        return
    end

    if not noDockCheck then
        -- test the docking last so the player can know what he can buy from afar already
        local errors = {}
        errors[EntityType.Station] = "You must be docked to the station to trade."%_T
        errors[EntityType.Ship] = "You must be closer to the ship to trade."%_T
        if not CheckShipDocked(shipFaction, ship, station, errors) then
            return
        end
    end

    local x, y = Sector():getCoordinates()
    local fromDescription = Format("\\s(%1%:%2%) %3% bought %4% %5% for ¢%6%."%_T, x, y, station.name, math.floor(amount), good:pluralForm(math.floor(amount)), createMonetaryString(price))
    local toDescription = Format("\\s(%1%:%2%) %3% sold %4% %5% for ¢%6%."%_T, x, y, ship.name, math.floor(amount), good:pluralForm(math.floor(amount)), createMonetaryString(price))

    -- give money to ship faction
    self:transferMoney(stationFaction, stationFaction, shipFaction, price, fromDescription, toDescription)

    -- remove goods from ship
    ship:removeCargo(good, amount)

    if callingPlayer then
        Player(callingPlayer):sendCallback("onTradingmanagerBuyFromPlayer", self.soldGoods[goodIndex])
    end
    Entity():sendCallback("onTradingmanagerBuyFromPlayer", self.soldGoods[goodIndex])

    -- trading (non-military) ships get higher relation gain
    local relationsChange = GetRelationChangeFromMoney(price)
    if (ship:getNumArmedTurrets()) <= 1 then
        relationsChange = relationsChange * 1.5
    end

    changeRelations(shipFaction, stationFaction, relationsChange, RelationChangeType.GoodsTrade)

    -- add goods to station, do this last so the UI update that comes with the sync already has the new relations
    self:increaseGoods(good.name, amount)
end


function TradingManager:buyGoods(good, amount, otherFactionIndex, monetaryTransactionOnly)

    -- check if the good is even bought by the station
    if not self:getBoughtGoodByName(good.name) == nil then return 1 end

    local stationFaction = Faction()
    if not stationFaction then return 5 end

    local otherFaction = Faction(otherFactionIndex)
    if not otherFaction then return 5 end

    if self.buyFromOthers == false and stationFaction.index ~= otherFaction.index then return 4 end

    local ok = self:isBoughtBySelf(good)
    if not ok then return 4 end

    -- make sure the transaction can not sell more than the station can have in stock
    local buyable = self:getMaxStock(good.name) - self:getNumGoods(good.name);
    amount = math.min(buyable, amount)
    if amount <= 0 then return 2 end

    -- begin transaction
    -- calculate price. if the seller is the owner of the station, the price is 0
    local price = self:getBuyPrice(good.name, otherFactionIndex) * amount

    local canPay, msg, args = stationFaction:canPay(price * self.factionPaymentFactor);
    if not canPay then return 3 end

    local x, y = Sector():getCoordinates()
    local fromDescription = Format("\\s(%1%:%2%) %3% bought %4% %5% for ¢%6%."%_T, x, y, Entity().name, math.floor(amount), good:pluralForm(math.floor(amount)), createMonetaryString(price))
    local toDescription = Format("\\s(%1%:%2%): Sold %3% %4% for ¢%5%."%_T, x, y, math.floor(amount), good:pluralForm(math.floor(amount)), createMonetaryString(price))

    -- give money to other faction
    self:transferMoney(stationFaction, stationFaction, otherFaction, price, fromDescription, toDescription)

    local relationsChange = GetRelationChangeFromMoney(price)
    changeRelations(otherFaction, stationFaction, relationsChange, RelationChangeType.GoodsTrade)

    if not monetaryTransactionOnly then
        -- add goods to station, do this last so the UI update that comes with the sync already has the new relations
        self:increaseGoods(good.name, amount)
    end

    return 0
end


function TradingManager:increaseGoods(name, delta)

    local entity = Entity()
    local added = false

    for i, good in pairs(self.soldGoods) do
        if good.name == name then
            -- increase
            local current = entity:getCargoAmount(good)
            delta = math.min(delta, self:getMaxStock(good.name) - current)
            delta = math.max(delta, 0)

            if not added then
                entity:addCargo(good, delta)
                added = true
            end

            broadcastInvokeClientFunction("updateSoldGoodAmount", good.name)
        end
    end

    for i, good in pairs(self.boughtGoods) do
        if good.name == name then
            -- increase
            local current = entity:getCargoAmount(good)
            delta = math.min(delta, self:getMaxStock(good.name) - current)
            delta = math.max(delta, 0)

            if not added then
                entity:addCargo(good, delta)
                added = true
            end

            broadcastInvokeClientFunction("updateBoughtGoodAmount", good.name)
        end
    end

end


function TradingManager:getBuyPrice(goodName, sellingFactionIndex)

    local good = self:getBoughtGoodByName(goodName)
    if not good then return 0 end

    -- this is to ensure that goods can be "taken" from consumers via the buy sell UI
    -- instead of using transfer cargo UI
    if self.factionPaymentFactor == 0 and sellingFactionIndex then
        local stationFaction = Faction()

        if not stationFaction or stationFaction.index == sellingFactionIndex then return 0 end

        if stationFaction.isAlliance then
            -- is the selling player a member of the station alliance?
            local seller = Player(sellingFactionIndex)
            if seller and seller.allianceIndex == stationFaction.index then return 0 end
        end

        if stationFaction.isPlayer then
            -- does the station belong to a player that is a member of the ship's alliance?
            local stationPlayer = Player(stationFaction.index)
            if stationPlayer and stationPlayer.allianceIndex == sellingFactionIndex then return 0 end
        end
    end

    -- empty stock -> higher price
    local maxStock = self:getMaxStock(good.name)
    local stockFactor = 1

    if maxStock > 0 then
        stockFactor = math.min(1, math.max(0, self:getNumGoods(goodName) / maxStock)) -- 0 to 1 where 1 is 'full stock'
        stockFactor = 1 - stockFactor -- 1 to 0 where 0 is 'full stock'
        stockFactor = stockFactor * 0.2 -- 0.2 to 0
        stockFactor = stockFactor + 0.9 -- 1.1 to 0.9; 'no goods' to 'full'
    end

    stockFactor = lerp(self.stockInfluence, 0, 1, 1, stockFactor)

    -- better relations -> lower price
    -- worse relations -> (much) higher price
    local relationFactor = 1
    if sellingFactionIndex then
        local sellerIndex = nil
        if type(sellingFactionIndex) == "number" then
            sellerIndex = sellingFactionIndex
        else
            sellerIndex = sellingFactionIndex.index
        end

        if sellerIndex then
            local faction = Faction()
            if faction then
                if faction.isAIFaction then
                    local relations = faction:getRelations(sellerIndex)
                    if relations < -10000 then
                        -- bad relations: faction pays less for the goods
                        -- 10% to 100% from -100.000 to -10.000
                        relationFactor = lerp(relations, -100000, -10000, 0.1, 1.0)
                    elseif relations >= 80000 then
                        -- very good relations: factions pays MORE for the goods
                        -- 100% to 105% from 80.000 to 100.000
                        relationFactor = lerp(relations, 80000, 100000, 1.0, 1.05)
                    end
                end

                if Faction().index == sellerIndex then relationFactor = 0 end
            end
        end
    end

    -- get factor for supply/demand from supply/demand script
    local ok, supplyDemandFactor = Sector():invokeFunction("economyupdater.lua", "getSupplyDemandPriceChange", good.name, self.ownSupplyTypes[good.name])
    if ok ~= 0 then
        -- eprint("buy price: error getting supply demand factor: " .. tostring(ok))
    end

    supplyDemandFactor = supplyDemandFactor or 0
    supplyDemandFactor = 1 + (supplyDemandFactor * self.supplyDemandInfluence)

    local basePrice = round(good.price * self.buyPriceFactor)
    local price = round(good.price * supplyDemandFactor * relationFactor * stockFactor * self.buyPriceFactor)

    return price, basePrice, supplyDemandFactor, relationFactor, stockFactor, self.buyPriceFactor
end


function TradingManager:getSellPrice(goodName, buyingFaction)

    local good = self:getSoldGoodByName(goodName)
    if not good then return 0 end

    -- empty stock -> higher price
    local maxStock = self:getMaxStock(good.name)
    local stockFactor = 1

    if maxStock > 0 then
        stockFactor = math.min(1, math.max(0, self:getNumGoods(goodName) / maxStock)) -- 0 to 1 where 1 is 'full stock'
        stockFactor = 1 - stockFactor -- 1 to 0 where 0 is 'full stock'
        stockFactor = stockFactor * 0.2 -- 0.2 to 0
        stockFactor = stockFactor + 0.9 -- 1.1 to 0.9; 'no goods' to 'full'
    end

    stockFactor = lerp(self.stockInfluence, 0, 1, 1, stockFactor)


    local relationFactor = 1
    if buyingFaction then
        local sellerIndex = nil
        if type(buyingFaction) == "number" then
            sellerIndex = buyingFaction
        else
            sellerIndex = buyingFaction.index
        end

        if sellerIndex then
            local faction = Faction()
            if faction then
                if faction.isAIFaction then
                    local relations = faction:getRelations(sellerIndex)
                    if relations < -10000 then
                        -- bad relations: faction wants more for the goods
                        -- 200% to 100% from -100.000 to -10.000
                        relationFactor = lerp(relations, -100000, -10000, 2.0, 1.0)
                    elseif relations > 80000 then
                        -- good relations: factions start giving player better prices
                        -- 100% to 95% from 80.000 to 100.000
                        relationFactor = lerp(relations, 80000, 100000, 1.0, 0.95)
                    end
                end

                if faction.index == sellerIndex then relationFactor = 0 end
            end
        end
    end

    -- get factor for supply/demand from supply/demand script
    local ok, supplyDemandFactor = Sector():invokeFunction("economyupdater.lua", "getSupplyDemandPriceChange", good.name, self.ownSupplyTypes[good.name])
    if ok ~= 0 then
        -- eprint("sell price: error getting supply demand factor: " .. tostring(ok))
    end

    supplyDemandFactor = supplyDemandFactor or 0
    supplyDemandFactor = 1 + (supplyDemandFactor * self.supplyDemandInfluence)

    local basePrice = round(good.price * self.sellPriceFactor)
    local price = round(good.price * supplyDemandFactor * relationFactor * stockFactor * self.sellPriceFactor)

    return price, basePrice, supplyDemandFactor, relationFactor, stockFactor, self.sellPriceFactor
end
