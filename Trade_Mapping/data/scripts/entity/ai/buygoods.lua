-- include("utility")  -- only needed for 'printTable'

if onServer() then
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
end
