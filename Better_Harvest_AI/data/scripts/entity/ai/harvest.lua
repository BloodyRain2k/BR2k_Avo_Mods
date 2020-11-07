
-- namespace AIHarvest
function AIHarvest:initialize(initialObjectId)
    Entity():registerCallback("onAIStateChanged", "onAIStateChanged")
    -- print("registered")

    if initialObjectId then
        self.objectToHarvest = Entity(initialObjectId)
    end
end


function AIHarvest.onAIStateChanged(entityId, state)
    print("new state of "..tostring(entityId).." is "..tostring(state))
    if state == AIState.Passive or state == AIState.Idle or state == AIState.Jump then
        AIHarvest:fightersRecall()
    end
end


function AIHarvest:fightersRecall()
    local controller = FighterController()
    if not controller or not self.squads or #self.squads < 1 then return 0 end

    for k,v in ipairs(self.squads) do
        controller:setSquadOrders(v, FighterOrders.Return, Uuid())
    end

    self.setHarvest = false

    local fighters = { controller:getDeployedFighters() }
    for i,f in ipairs(fighters) do
        local ai = FighterAI(f.id)
        ai:setOrders(FighterOrders.Return, ai.mothershipId)
    end

    return #fighters or 0
end


function AIHarvest:fightersHarvest()
    local controller = FighterController()
    if not controller or not self.squads or #self.squads < 1 then return end

    for i,sqd in ipairs(self.squads) do
        controller:setSquadOrders(sqd, FighterOrders.Harvest, Uuid())
    end

    self.setHarvest = true
    self:fightersIgnore()
end


function AIHarvest:fightersIgnore()
    local count = 0
    local hangar = Hangar()
    local controller = FighterController()
    if not controller or not self.squads or #self.squads < 1 then return end

    for i,sqd in ipairs(self.squads) do
        count = count + hangar:getSquadFighters(sqd)
    end

    local fighters = { controller:getDeployedFighters() }
    for i,f in ipairs(fighters) do
        local ai = FighterAI(f.id)
        if ai.ignoreMothershipOrders then
            count = count - 1
        end
        -- change the fighters to ignore further changes in the squad orders so they continue the harvest order while the ship is collecting loot etc.
        ai.ignoreMothershipOrders = true
    end

    if count < 1 then
        self.setHarvest = false
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
        local squads = { hangar:getSquads() }
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
            
            -- print("no adequate turrets")
            self:fightersRecall()
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
        -- print("no captain")
        self:fightersRecall()
        ShipAI():setPassive()
        terminate()
        return
    end
    
    if self.setHarvest then
        self:fightersIgnore()
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
    self.objectToHarvest, higherMaterialPresent = self:findObject(ship, sector, self.harvestMaterial)
    
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
            -- print("blegh?")
            ShipAI():setPassive()
        end
    end
end


function AIHarvest:updateHarvesting(timeStep)
    local ship = Entity()
    local ai = ShipAI()
    
    if self.hasRawLasers == true then
        if ship.freeCargoSpace < 1 then
            if self.noCargoSpace == false then
                self:fightersRecall()
                ai:setPassive()
                
                local faction = Faction(ship.factionIndex)
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)
                
                local ores, totalOres = getOreAmountsOnShip(ship)
                local scraps, totalScraps = getScrapAmountsOnShip(ship)
                if totalOres + totalScraps == 0 then
                    ai:setStatus(self.getNoSpaceStatus(), {})
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
    
    if valid(self.harvestLoot) then
        ai:setStatus(self.getCollectLootStatus(), {})
        
        -- there is loot to collect, fly there
        self.collectCounter = self.collectCounter + timeStep
        if self.collectCounter > 3 then
            self.collectCounter = self.collectCounter - 3
            
            if ai.isStuck then
                self.stuckLoot[self.harvestLoot.index.string] = true
                self.collectCounter = self.collectCounter + 2
                self:findHarvestLoot()
            end
            
            if valid(self.harvestLoot) then
                -- self:fightersHarvest()
                ai:setFly(self.harvestLoot.translationf, 0)
            end
        end
        
    elseif valid(self.objectToHarvest) then
        ai:setStatus(self.getNormalStatus(), {})
        
        -- if there is an object, harvest it
        if ship.selectedObject == nil
        or ship.selectedObject.index ~= self.objectToHarvest.index
        or ai.state ~= AIState.Harvest then
            
            self.stuckLoot = {}
            -- printTable({ ship, self.objectToHarvest, distance(ship.position, self.objectToHarvest.position), vec3(ship.position) })
            -- print(ship.name, distance(ship.position.position, self.objectToHarvest.position.position))
            if distance(ship.position.position, self.objectToHarvest.position.position) > 200 then
                -- print(self:fightersRecall(), ai.state, AIState.Harvest)
                if self:fightersRecall() < 1 then
                    ai:setFly(self.objectToHarvest.translationf, 0)
                end
            else
                -- print("nom")
                self:fightersHarvest()
                ai:setHarvest(self.objectToHarvest)
            end
        end

    else
        ai:setStatus(self.getAllHarvestedStatus(), {})

    end
end
