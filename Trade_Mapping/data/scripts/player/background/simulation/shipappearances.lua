--[[ 
ShipAppearances.br2k_spawnShips = ShipAppearances.spawnShips
function ShipAppearances.spawnShips(x, y)
    ShipAppearances.br2k_spawnShips(x, y)
    print(string.format("Ship appearance in %s, %s", x, y))
end
]]

ShipAppearances.tm_addToVisible = ShipAppearances.addToVisible
function ShipAppearances.addToVisible(ownerIndex, visualizedShip, x, y)
    ShipAppearances.tm_addToVisible(ownerIndex, visualizedShip, x, y)
    print(string.format("addToVisible: %s in %s, %s", visualizedShip.name, x, y))
    
    local entry = ShipDatabaseEntry(ownerIndex, visualizedShip.name)
    local systems = entry:getSystems()
    for k,v in pairs(systems) do
        local script = string.lower(string.gmatch(k.script, "/(%w+)%.lua")())
        if script == "tradingoverview" then
            print(string.format("%s [%s] - %s", k.name, k.rarity, script))
        end
    end
end
