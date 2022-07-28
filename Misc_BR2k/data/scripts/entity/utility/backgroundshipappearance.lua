BackgroundShipAppearance.br2k_updateCommandBehavior = BackgroundShipAppearance.updateCommandBehavior
function BackgroundShipAppearance.updateCommandBehavior(owner, ship)
    BackgroundShipAppearance.br2k_updateCommandBehavior(owner, ship)
    local x,y Sector():getCoordinates()
    print(string.format("%s: %s, %s", ship.name, x, y))
end
