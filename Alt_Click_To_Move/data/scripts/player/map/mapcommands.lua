--[[
function MapCommands.onGalaxyMapMouseDown(button, mx, my, cx, cy)
    if button == MouseButton.Right and #MapCommands.filterPortraits{selected = true} > 0
    and (Keyboard().altPressed or Keyboard().shiftPressed) then
        -- consume right click if at least one craft is selected to prevent opening the context menu
        return true
    end
    
    if button == MouseButton.Left then
        rectSelection = {mouseStart = {x = mx, y = my}, sectorStart = {x = cx, y = cy}}
    end
    
    return false
end
--]]

MapCommands.altclick_onGalaxyMapKeyboardDown = MapCommands.onGalaxyMapKeyboardDown
function MapCommands.onGalaxyMapKeyboardDown(key, repeating)
    if MapCommands.altclick_onGalaxyMapKeyboardDown(key, repeating) then
        return true
    end

    if key == KeyboardKey._U then
        -- if MapCommands.hasCommandToUndo() then
            MapCommands.onUndoPressed()
        -- else
            -- MapCommands.clearOrders()
        -- end
        return true
    end
end

function MapCommands.onGalaxyMapMouseUp(button, mx, my, cx, cy, mapMoved)
    if areaSelection and areaSelection.cancelling then
        if not mapMoved then
            -- the user didn't move the map - stop area selection
            MapCommands.stopAreaSelection()
        else
            -- moving the map should not interfere with area selection - don't cancel
            areaSelection.cancelling = false
        end

        -- eat up one mouse up
        -- otherwise cancelling area selection by right click also issues a jump order
        return
    end

    if not shipList.frame.mouseOver and (Keyboard().altPressed or Keyboard().shiftPressed) then
        if button == MouseButton.Right and #shipList.selectedPortraits > 0 and not mapMoved then
            MapCommands.enqueueJump(cx, cy)
            return
        end
    end

    if button == MouseButton.Left and not MapCommands.isCommandWindowVisible() then
        if rectSelection then
            if math.abs(rectSelection.mouseStart.x - mx) > 1 or math.abs(rectSelection.mouseStart.y - my) > 1 then
                MapCommands.selectCraftsInRect(rectSelection.sectorStart.x, rectSelection.sectorStart.y, cx, cy)
                rectSelection = nil
                return
            end

            rectSelection = nil

            -- left mouse up on the map -> clear selection
            for _, portrait in pairs(shipList.craftPortraits) do
                portrait.portrait.selected = false
            end
        end
    end
end
