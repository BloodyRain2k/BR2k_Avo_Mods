shipList.offscreenShipsVisible = true

MapCommands.altclick_initUI = MapCommands.initUI
function MapCommands.initUI()
    MapCommands.altclick_initUI()

    local commandsToChange = {
        { command = CommandType.Mine, order = "addMineOrder", parameters = { false } },
        { command = CommandType.Salvage, order = "addSalvageOrder", parameters = { false } },
        { command = CommandType.Refine, order = "addRefineOresOrder" },
    }

    for i,cmd in ipairs(commandsToChange) do
        local key = cmd.command .. "_CommandButtonPressed"
        
        local old_func = MapCommands[key]
        MapCommands[key] = function()
            if MapCommands.isEnqueueing() then
                if cmd.command == CommandType.Mine or cmd.command == CommandType.Salvage then
                    cmd.parameters[1] = Keyboard():keyPressed(KeyboardKey.LAlt)
                                        or Keyboard():keyPressed(KeyboardKey.RAlt)
                end
                MapCommands.enqueueOrder(cmd.order, unpack(cmd.parameters))
            else
                old_func()
            end
        end

        print(string.format("%s: %s", key, tostring(MapCommands[key])))
    end
end
