
package.path = package.path .. ";data/scripts/?.lua"

local HarvestAI = include("entity/ai/harvest")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MineAI
MineAI = HarvestAI.CreateNamespace()

function MineAI.instance.getHasRawLasers(weapons)
    return weapons.stoneRawEfficiency > 0
end

function MineAI.instance.getHarvestMaterial(weapons)
    if weapons.category == WeaponCategory.Mining then
        return weapons.material.value
    end
end

function MineAI.instance.weaponCategoryMatches(category)
    return category == WeaponCategory.Mining
end

function MineAI.instance.getSecondaryHarvestMaterial(ship)
    -- this is for salvaging with armed turrets, not used for mining
end


function MineAI.instance.getNoWeaponsError()
    return "We need mining turrets or fighters to mine."%_T
end

function MineAI.instance.findObject(ship, sector, harvestMaterial)
    local objectToHarvest
    local higherMaterialPresent

    local mineables = {sector:getEntitiesByComponent(ComponentType.MineableMaterial)}
    local nearest = math.huge
    local hasMiningSystem = ship:hasScript("systems/miningsystem.lua")
    for _, a in pairs(mineables) do
        if a.type == EntityType.Asteroid and (a.isObviouslyMineable or hasMiningSystem) then
            local material = a:getLowestMineableMaterial()
            local resources = a:getMineableResources()

            if resources ~= nil and resources > 0 and material ~= nil then
                -- only try to mine objects that are mineable by the available mining lasers
                if material.value <= harvestMaterial + 1 then
                    local dist = distance2(a.translationf, ship.translationf)
                    if dist < nearest then
                        nearest = dist
                        objectToHarvest = a
                    end
                else
                    higherMaterialPresent = true
                end
            end
        end
    end

    return objectToHarvest, higherMaterialPresent
end

-- ShipAI status
function MineAI.instance.getNoSpaceStatus()
    return "Mining - No Cargo Space"%_T
end

function MineAI.instance.getCollectLootStatus()
    return "Collecting Mined Loot /* ship AI status*/"%_T
end

function MineAI.instance.getNormalStatus()
    return "Mining /* ship AI status*/"%_T
end

function MineAI.instance.getAllHarvestedStatus()
    return "Mining - No Asteroids Left /* ship AI status*/"%_T
end


-- chat messages
function MineAI.instance.getMaterialTooLowError()
    return "Your mining ship in sector %1% can't find any more asteroids made of %2% or lower."%_T
end

function MineAI.instance.getMaterialTooLowMessage()
    return "Commander, we can't find any more asteroids in \\s(%1%) made of %2% or lower!"%_T
end

function MineAI.instance.getSectorEmptyError()
    return "Your mining ship in sector %s can't find any more asteroids."%_T
end

function MineAI.instance.getSectorEmptyMessage()
    return "Commander, we can't find any more asteroids in \\s(%s)!"%_T
end


function MineAI.instance.getNoSpaceMessage()
    return "Commander, we can't mine in \\s(%s) - we have no space in our cargo bay!"%_T
end

function MineAI.instance.getNoMoreSpaceMessage()
    return "Commander, we can't continue mining in \\s(%s) - we have no more space left in our cargo bay!"%_T
end

function MineAI.instance.getNoMoreSpaceError()
    return "Your ship's cargo bay in sector %s is full."%_T
end
