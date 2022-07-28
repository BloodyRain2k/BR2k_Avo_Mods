FighterUT.old_getProductionTime = FighterUT.getProductionTime
function FighterUT.getProductionTime(tech, material, durability)
    return FighterUT.old_getProductionTime(tech, material, durability) * 1
end