function TravelCommand:getConfigurableValues(ownerIndex, shipName)
    local values = { }

    -- value names here must match with values returned in ui:buildConfig() below
    values.swiftness = {displayName = "Swiftness"%_t, from = 0, to = #swiftnessSpeedFactors, default = #swiftnessSpeedFactors}

    return values
end
