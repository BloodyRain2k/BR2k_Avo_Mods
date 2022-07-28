--[[ 
ShipAppearances.br2k_spawnShips = ShipAppearances.spawnShips
function ShipAppearances.spawnShips(x, y)
    ShipAppearances.br2k_spawnShips(x, y)
    print(string.format("Ship appearance in %s, %s", x, y))
end
]]

--[[ 
ShipAppearances.br2k_addToVisible = ShipAppearances.addToVisible
function ShipAppearances.addToVisible(ownerIndex, visualizedShip, x, y)
    ShipAppearances.br2k_addToVisible(ownerIndex, visualizedShip, x, y)
    print(string.format("addToVisible: %s in %s, %s", visualizedShip.name, x, y))
end
]]
