local alt_pressed = false

--[[
local alt_onGalaxyMapKeyboardEvent = MapCommands.onGalaxyMapKeyboardEvent
function MapCommands.onGalaxyMapKeyboardEvent(key, pressed)
    alt_onGalaxyMapKeyboardEvent(key, pressed)
    alt_pressed = (key == KeyboardKey.LAlt or key == KeyboardKey.RAlt)
end
--]]

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

function MapCommands.onGalaxyMapMouseUp(button, mx, my, cx, cy, mapMoved)    
    if button == MouseButton.Right
    and #MapCommands.filterPortraits{selected = true} > 0
    and not mapMoved then
        
        if Keyboard().altPressed or Keyboard().shiftPressed then
            MapCommands.enqueueJump(cx, cy)
            return true
        end
    end
    
    if button == MouseButton.Left and rectSelection.mouseStart ~= nil then
        if math.abs(rectSelection.mouseStart.x - mx) > 1 or math.abs(rectSelection.mouseStart.y - my) > 1 then
            MapCommands.selectCraftsInRect(rectSelection.sectorStart.x, rectSelection.sectorStart.y, cx, cy)
            rectSelection = {}
            return true
        end
        
        rectSelection = {}
    end
    
    return false
end
