
package.path = package.path .. ";data/scripts/?.lua"

local HarvestAI = include("entity/ai/harvest")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace SalvageAI
SalvageAI = HarvestAI.CreateNamespace()

function SalvageAI.instance.getHasRawLasers(weapons)
    return weapons.metalRawEfficiency > 0
end

function SalvageAI.instance.getHarvestMaterial(weapons)
    if weapons.category == WeaponCategory.Salvaging then
        return weapons.material.value
    end
end

function SalvageAI.instance.weaponCategoryMatches(category)
    return category == WeaponCategory.Salvaging or category == WeaponCategory.Armed
end

function SalvageAI.instance.getSecondaryHarvestMaterial(ship)
    -- use armed weapons only if no salvaging weapons are available
    for _, turret in pairs({ship:getTurrets()}) do
        local weapons = Weapons(turret)

        if weapons.category == WeaponCategory.Armed then
            return MaterialType.Avorion
        end
    end
end


function SalvageAI.instance.getNoWeaponsError()
    return "We need turrets or combat or salvaging fighters to salvage."%_T
end

function SalvageAI.instance.findObject(ship, sector, harvestMaterial)
    local objectToHarvest
    local higherMaterialPresent

    local nearest = math.huge
    local nearestResources = 0
    local nearestSize = 0
    for _, a in pairs({sector:getEntitiesByComponent(ComponentType.MineableMaterial)}) do
        if a.type == EntityType.Wreckage then
            local material = a:getLowestMineableMaterial()
            if not material then goto continue end

            local resources = 0
            for _, value in pairs({a:getMineableResources()}) do
                resources = resources + value
            end

            if resources < 10 then goto continue end

            if material.value > harvestMaterial + 1 then
                higherMaterialPresent = true
                goto continue
            end

            local dist2 = distance2(a.translationf, ship.translationf)
            local sphere = a:getBoundingSphere()
            local size = sphere and sphere.radius * 2 or 0

            if resources > nearestResources then
                if dist2 < nearest then
                    -- wreckage has more resources and is closer
                    nearest = dist2
                    nearestResources = resources
                    nearestSize = size
                    objectToHarvest = a
                else
                    if math.sqrt(dist2) < math.sqrt(nearest) + 2 * size then
                        -- wreckage has more resources and is only one diameter farther away
                        nearest = dist2
                        nearestResources = resources
                        nearestSize = size
                        objectToHarvest = a
                    end
                end
            else
                if math.sqrt(dist2) < math.sqrt(nearest) - nearestSize then
                    -- wreckage is closer
                    nearest = dist2
                    nearestResources = resources
                    nearestSize = size
                    objectToHarvest = a
                end
            end

            ::continue::
        end
    end

    return objectToHarvest, higherMaterialPresent
end

-- ShipAI status
function SalvageAI.instance.getNoSpaceStatus()
    return "Salvaging - No Cargo Space"%_T
end

function SalvageAI.instance.getCollectLootStatus()
    return "Collecting Salvaged Loot /* ship AI status*/"%_T
end

function SalvageAI.instance.getNormalStatus()
    return "Salvaging /* ship AI status*/"%_T
end

function SalvageAI.instance.getAllHarvestedStatus()
    return "Salvaging - No Wreckages Left /* ship AI status*/"%_T
end


-- chat messages
function SalvageAI.instance.getMaterialTooLowError()
    return "Your ship in sector %1% can't find any more wreckages made of %2% or lower."%_T
end

function SalvageAI.instance.getMaterialTooLowMessage()
    return "Commander, we can't find any more wreckages in \\s(%1%) made of %2% or lower!"%_T
end

function SalvageAI.instance.getSectorEmptyError()
    return "Your ship in sector %s can't find any more wreckages."%_T
end

function SalvageAI.instance.getSectorEmptyMessage()
    return "Commander, we can't find any more wreckages in \\s(%s)!"%_T
end


function SalvageAI.instance.getNoSpaceMessage()
    return "Commander, we can't salvage in \\s(%s) - we have no space in our cargo bay!"%_T
end

function SalvageAI.instance.getNoMoreSpaceMessage()
    return "Commander, we can't continue salvaging in \\s(%s) - we have no more space left in our cargo bay!"%_T
end

function SalvageAI.instance.getNoMoreSpaceError()
    return "Your ship's cargo bay in sector %s is full."%_T
end
