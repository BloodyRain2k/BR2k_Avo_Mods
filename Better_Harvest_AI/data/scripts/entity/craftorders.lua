function CraftOrders.jump(x, y)
    if checkCaptain() then
        CraftOrders.removeSpecialOrders()

        local shipAI = ShipAI()
        shipAI:setStatus("Jumping to ${x}:${y} /* ship AI status */"%_T, {x=x, y=y})
        shipAI:setJump(x, y)

        local controller = FighterController()
        if not controller then return end
        
        local fighters = { controller:getDeployedFighters() }
        if #fighters < 1 then return end

        --[[
        for k,v in ipairs({Hangar():getSquads()}) do
            controller:setSquadOrders(v, FighterOrders.Return, Uuid())
        end
        --]]
    
        for i,f in ipairs(fighters) do
            local ai = FighterAI(f.id)
            ai:setOrders(FighterOrders.Return, ai.mothershipId)
        end
    end
end
