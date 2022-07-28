function AIHarvest:setShipStatusMessage(msg, arguments)
    -- only set AI state if auto pilot inactive
    -- if not ControlUnit().autoPilotEnabled then
        local ai = ShipAI()
        ai:setStatusMessage(msg, arguments)
        -- print(msg)
    -- end
end
