-- include("utility")  -- only needed for 'printTable'

if onServer() then
    -- [[
    local tm_findSeller = findSeller
    function findSeller()
        -- print("calling base function")
        local stationId, script, empty, badMargin = tm_findSeller()
        -- printTable(self)
        if self.currentError then
            self.currentError.critical = true
            terminate()
        else
            -- print(stationId, script, empty, badMargin)
            return stationId, script, empty, badMargin
        end
    end
    --]]


    local tm_updateServer = updateServer
    function updateServer(timeStep)
        local possible = getPossibleAmountToFitOnShip() or 0
        local required = getRemainingAmountToFulfill() or 0
        local buyable = getBuyableAmountByMoney() or -1

        if required > possible then self.data.amount = possible end
        -- if required > buyable then self.data.amount = buyable end

        print("req:", required, "poss:", possible, "buy:", buyable)

        tm_updateServer(timeStep)
    end
end
