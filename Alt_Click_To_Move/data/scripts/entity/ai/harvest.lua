
package.path = package.path .. ";data/scripts/lib/?.lua"

include ("stringutility")
include ("refineutility")

AIHarvest = {}

AIHarvest.objectToHarvest = nil
AIHarvest.harvestLoot = nil
AIHarvest.collectCounter = 0
AIHarvest.harvestMaterial = nil
AIHarvest.hasRawLasers = false
AIHarvest.noCargoSpace = false

AIHarvest.noTargetsLeft = false
AIHarvest.noTargetsLeftTimer = 1

AIHarvest.stuckLoot = {}

function AIHarvest:getUpdateInterval()
    if self.noTargetsLeft or self.noCargoSpace then return 15 end

    return 1
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

        for _, index in pairs(squads) do
            local category = hangar:getSquadMainWeaponCategory(index)
            if self.weaponCategoryMatches(category) then
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

--            print("no adequate turrets")
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
            ShipAI():setPassive()
            terminate()
            return
        end
    end

    if ship.hasPilot or ((ship.playerOwned or ship.allianceOwned) and ship:getCrewMembers(CrewProfessionType.Captain) == 0) then
--        print("no captain")
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
                self.harvestLoot = loot
                return
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

            ShipAI():setPassive()
        end
    end
end

function AIHarvest:canContinueHarvesting()
    -- prevent terminating script before it even started
    if not self.harvestMaterial then return true end

    return valid(self.harvestLoot) or valid(self.objectToHarvest) or not self.noTargetsLeft
end

function AIHarvest:updateHarvesting(timeStep)
    local ship = Entity()

    if self.hasRawLasers == true then
        if ship.freeCargoSpace < 1 then
            if self.noCargoSpace == false then
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
            end
        end

    elseif valid(self.objectToHarvest) then
        ai:setStatus(self.getNormalStatus(), {})

        -- if there is an object, harvest it
        if ship.selectedObject == nil
            or ship.selectedObject.index ~= self.objectToHarvest.index
            or ai.state ~= AIState.Harvest then

            ai:setHarvest(self.objectToHarvest)
            self.stuckLoot = {}
        end
    else
        ai:setStatus(self.getAllHarvestedStatus(), {})
    end

end

function AIHarvest:setObjectToHarvest(index)
    self.objectToHarvest = Sector():getEntity(index)
end

---- this function will be executed every frame on the client only
--function AIHarvest:updateClient(timeStep)
--    if valid(self.objectToHarvest) then
--        drawDebugSphere(self.objectToHarvest:getBoundingSphere(), ColorRGB(1, 0, 0))
--    end
--end


function AIHarvest:new()
    local object = {}
    setmetatable(object, self)
    self.__index = self

    return object
end

function AIHarvest.CreateNamespace()
    local instance = AIHarvest:new()
    local result = {instance = instance}

    result.getUpdateInterval = function(...) return instance:getUpdateInterval(...) end
    result.checkIfAbleToHarvest = function(...) return instance:checkIfAbleToHarvest(...) end
    result.updateServer = function(...) return instance:updateServer(...) end
    result.findHarvestLoot = function(...) return instance:findHarvestLoot(...) end
    result.findObjectToHarvest = function(...) return instance:findObjectToHarvest(...) end
    result.canContinueHarvesting = function(...) return instance:canContinueHarvesting(...) end
    result.updateHarvesting = function(...) return instance:updateHarvesting(...) end
    result.setObjectToHarvest = function(...) return instance:setObjectToHarvest(...) end
    result.fighters = FighterController()

    return result
end


return AIHarvest
