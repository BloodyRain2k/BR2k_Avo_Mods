function AIHarvest:fightersRecall()
    local controller = FighterController()
    if not controller or not self.squads or #self.squads < 1 then return end

    local fighters = { controller:getDeployedFighters() }
    for i,f in ipairs(fighters) do
        local ai = FighterAI(f.id)
        ai.ignoreMothershipOrders = false
        ai:setOrders(FighterOrders.Return, ai.mothershipId)
    end

    -- [[
    for k,v in ipairs(self.squads) do
        controller:setSquadOrders(v, FighterOrders.Return, Uuid())
    end
    --]]
end


function AIHarvest:fightersHarvest()
    local controller = FighterController()
    if not controller or not self.squads or #self.squads < 1 then return end

    for k,v in ipairs(self.squads) do
        controller:setSquadOrders(v, FighterOrders.Harvest, Uuid())
    end

    local fighters = { controller:getDeployedFighters() }
    for i,f in ipairs(fighters) do
        FighterAI(f.id).ignoreMothershipOrders = true
    end
end


function AIHarvest:checkIfAbleToHarvest()
    if onServer() then
        local ship = Entity()
        self.hasRawLasers = false
        
        for _, turret in pairs({ship:getTurrets()}) do
            local weapons = Weapons(turret)
            
            if self.getHasRawLasers(weapons) then self.hasRawLasers = true end
            
            local harvestMaterial = self.getHarvestMaterial(weapons)
            if harvestMaterial and (self.harvestMaterial == nil or harvestMaterial > self.harvestMaterial) then
                self.harvestMaterial = harvestMaterial
            end
        end
        
        local hangar = Hangar()
        local squads = {hangar:getSquads()}
        self.squads = {}
        
        for _, index in pairs(squads) do
            local category = hangar:getSquadMainWeaponCategory(index)
            if self.weaponCategoryMatches(category) then
                self.squads[#self.squads + 1] = index

                if self.harvestMaterial == nil or hangar:getHighestMaterialInSquadMainCategory(index).value > self.harvestMaterial then
                    self.harvestMaterial = hangar:getHighestMaterialInSquadMainCategory(index).value
                end
                
                self.hasRawLasers = self.hasRawLasers or hangar:getSquadHasRawMinersOrSalvagers(index)
            end
        end

        if not self.harvestMaterial then
            self.harvestMaterial = self.getSecondaryHarvestMaterial(ship)
        end
        
        if not self.harvestMaterial then
            local faction = Faction(Entity().factionIndex)
            
            if faction then
                faction:sendChatMessage("", ChatMessageType.Error, self.getNoWeaponsError())
            end
            
            self:fightersRecall()
            -- print("no adequate turrets")
            ShipAI():setPassive()
            terminate()
        end
    end
end

-- this function will be executed every frame on the server only
function AIHarvest:updateServer(timeStep)
    local ship = Entity()
    
    if self.harvestMaterial == nil then
        self:checkIfAbleToHarvest()
        
        if self.harvestMaterial == nil then
            self:fightersRecall()
            ShipAI():setPassive()
            terminate()
            return
        end
    end
    
    if ship.hasPilot or ((ship.playerOwned or ship.allianceOwned) and ship:getCrewMembers(CrewProfessionType.Captain) == 0) then
        --        print("no captain")
        self:fightersRecall()
        ShipAI():setPassive()
        terminate()
        return
    end
    
    -- find an object that can be harvested
    self:updateHarvesting(timeStep)
    
    if self.noTargetsLeft == true then
        self.noTargetsLeftTimer = self.noTargetsLeftTimer - timeStep
    end
end


-- check the immediate region around the ship for loot that can be collected
-- and if there is some, assign harvestLoot
function AIHarvest:findHarvestLoot()
    local loots = {Sector():getEntitiesByType(EntityType.Loot)}
    local ship = Entity()

    self.harvestLoot = nil
    for _, loot in pairs(loots) do
        if loot:isCollectable(ship) and distance2(loot.translationf, ship.translationf) < 1500 * 1500 then
            if self.stuckLoot[loot.index.string] ~= true then
                local goodToCollect = true

                -- don't collect tiny loot amounts
                if loot:hasComponent(ComponentType.MoneyLoot) then
                    if loot:getMoneyLootAmount() < 10 then goodToCollect = false end
                end

                if loot:hasComponent(ComponentType.ResourceLoot) then
                    if loot:getResourceLootAmount() < 10 then goodToCollect = false end
                end

                if goodToCollect then
                    self.harvestLoot = loot
                    return
                end
            end
        end
    end
end


-- check the sector for an object that can be mined
-- if there is one, assign objectToHarvest
function AIHarvest:findObjectToHarvest()
    local ship = Entity()
    local sector = Sector()
    
    local higherMaterialPresent
    self.objectToHarvest, higherMaterialPresent = self.findObject(ship, sector, self.harvestMaterial)
    
    if self.objectToHarvest then
        self.noTargetsLeft = false
        self.noTargetsLeftTimer = 1
        broadcastInvokeClientFunction("setObjectToHarvest", self.objectToHarvest.index)
    else
        if self.noTargetsLeft == false or self.noTargetsLeftTimer <= 0 then
            self.noTargetsLeft = true
            self.noTargetsLeftTimer = 10 * 60 -- ten minutes
            
            local faction = Faction(Entity().factionIndex)
            if faction then
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)
                
                if higherMaterialPresent then
                    local materialName = Material(self.harvestMaterial + 1).name
                    faction:sendChatMessage(ship.name or "", ChatMessageType.Error, self.getMaterialTooLowError(), coords, materialName)
                    faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, self.getMaterialTooLowMessage(), coords, materialName)
                else
                    faction:sendChatMessage(ship.name or "", ChatMessageType.Error, self.getSectorEmptyError(), coords)
                    faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, self.getSectorEmptyMessage(), coords)
                end
            end
            
            self:fightersRecall()
            ShipAI():setPassive()
        end
    end
end


function AIHarvest:updateHarvesting(timeStep)
    local ship = Entity()
    
    if self.hasRawLasers == true then
        if ship.freeCargoSpace < 1 then
            if self.noCargoSpace == false then
                self:fightersRecall()
                ShipAI():setPassive()
                
                local faction = Faction(ship.factionIndex)
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)
                
                local ores, totalOres = getOreAmountsOnShip(ship)
                local scraps, totalScraps = getScrapAmountsOnShip(ship)
                if totalOres + totalScraps == 0 then
                    ShipAI():setStatus(self.getNoSpaceStatus(), {})
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, self.getNoSpaceMessage(), coords) end
                    self.noCargoSpace = true
                else
                    local ret, moreOrders = ship:invokeFunction("data/scripts/entity/orderchain.lua", "hasMoreOrders")
                    if ret == 0 and moreOrders == true then
                        -- harvest order fulfilled, another order is queued
                        -- don't send a message
                        terminate()
                        return
                    end
                    
                    -- harvest order fulfilled, no other order is queued
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, self.getNoMoreSpaceMessage(), coords) end
                    terminate()
                end
                
                if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Error, self.getNoMoreSpaceError(), coords) end
            end
            
            return
        else
            self.noCargoSpace = false
        end
    end
    
    -- highest priority is collecting the resources
    if not valid(self.objectToHarvest) and not valid(self.harvestLoot) then
        
        -- first, check if there is loot to collect
        self:findHarvestLoot()
        
        -- then, if there's no loot, check if there is an object to mine
        if not valid(self.harvestLoot) then
            self:findObjectToHarvest()
        end
        
    end
    
    local ai = ShipAI()
    
    if valid(self.harvestLoot) then
        ai:setStatus(self.getCollectLootStatus(), {})
        
        -- there is loot to collect, fly there
        self.collectCounter = self.collectCounter + timeStep
        if self.collectCounter > 3 then
            self.collectCounter = self.collectCounter - 3
            
            if ai.isStuck then
                self.stuckLoot[self.harvestLoot.index.string] = true
                self:findHarvestLoot()
                self.collectCounter = self.collectCounter + 2
            end
            
            if valid(self.harvestLoot) then
                ai:setFly(self.harvestLoot.translationf, 0)
                self:fightersHarvest()
            end
        end
        
    elseif valid(self.objectToHarvest) then
        ai:setStatus(self.getNormalStatus(), {})
        
        -- if there is an object, harvest it
        if ship.selectedObject == nil
        or ship.selectedObject.index ~= self.objectToHarvest.index
        or ai.state ~= AIState.Harvest then
            
            ai:setHarvest(self.objectToHarvest)
            self:fightersHarvest()
            self.stuckLoot = {}
        end
    else
        ai:setStatus(self.getAllHarvestedStatus(), {})
    end
    
end
