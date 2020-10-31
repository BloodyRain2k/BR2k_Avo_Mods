if onServer() then
    local alt_UpdateServer = AIRefine.updateServer
    function AIRefine.updateServer(timeStep)
        alt_UpdateServer(timeStep)

        if noRefineryFoundTimer > 0 then
            terminate()
        end
    end
end
