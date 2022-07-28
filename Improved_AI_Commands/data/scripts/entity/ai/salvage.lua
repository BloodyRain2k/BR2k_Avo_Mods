local CompTypes = { CargoLoot = ComponentType.CargoLoot, CrewLoot = ComponentType.CrewLoot, InventoryItemLoot = ComponentType.InventoryItemLoot, Loot = ComponentType.Loot, LootAttractor = ComponentType.LootAttractor, LootCollectionSound = ComponentType.LootCollectionSound, LootCollector = ComponentType.LootCollector, LootParticles = ComponentType.LootParticles, LootPhysics = ComponentType.LootPhysics, MoneyLoot = ComponentType.MoneyLoot, ResourceLoot = ComponentType.ResourceLoot, SystemUpgradeLoot = ComponentType.SystemUpgradeLoot, Torpedo = ComponentType.Torpedo, TorpedoAI = ComponentType.TorpedoAI, TorpedoImpact = ComponentType.TorpedoImpact, TorpedoLauncher = ComponentType.TorpedoLauncher, TorpedoMeshBuilder = ComponentType.TorpedoMeshBuilder, TurretLoot = ComponentType.TurretLoot }

function SalvageAI.instance:findHarvestLoot()
    local loots = {Sector():getEntitiesByType(EntityType.Loot)}
    local ship = Entity()
    local station = ship.isStation

    self.harvestLoot = nil
    for _, loot in pairs(loots) do
        if loot:isCollectable(ship) and ((not station and loot:hasComponent(ComponentType.SystemUpgradeLoot)) or (distance2(loot.translationf, ship.translationf) < 150 * 150)) then

            if not station and loot:hasComponent(ComponentType.SystemUpgradeLoot) then
                self.harvestLoot = loot
                return
            end

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

    if station or true then -- easier than commenting the whole end of the function
        return
    end

    local nextWreck = self:findObject(ship, Sector(), self.harvestMaterial)
    local distWreck = 99999999
    if nextWreck then
        distWreck = distance2(nextWreck.translationf, ship.translationf)
        -- print("distWreck: " ..distWreck)
    end

    for _, loot in pairs(loots) do
        if loot:isCollectable(ship) then
            if self.stuckLoot[loot.index.string] ~= true then
                local types = {}
                local index = 1
                for k,v in pairs(CompTypes) do
                    if loot:hasComponent(v) and k ~= nil then
                        types[index] = k
                    end
                    index = index + 1
                end

                -- if #types > 0 then
                --     print("%s - %s - %s - %s - [%s] - %s - %s", loot.name, loot.index.string, loot.type, loot.typename, table.concat(types, ", "), index, loot:isCollectable(ship))
                -- end

                -- if loot:hasComponent(ComponentType.SystemUpgradeLoot) then
                if loot:isCollectable(ship) and distance2(loot.translationf, ship.translationf) * 0.85 < distWreck then
                    self.harvestLoot = loot
                    return
                end
            end
        end
    end
end
