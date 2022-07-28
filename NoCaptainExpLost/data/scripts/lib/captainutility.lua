-- print("captains extended")

function CaptainUtility.applyLeveling(captain, minutesAway)
    print(string.format("leveling up a captain '%s' with %s min", captain.name, minutesAway))
    -- adds some robustness to the leveling process
    CaptainUtility.setRequiredLevelUpExperience(captain)

    local gain = math.max(0, minutesAway) / 2
    if captain:hasPerk(CaptainUtility.PerkType.Educated) then gain = gain * 1.2 end
    if captain:hasPerk(CaptainUtility.PerkType.Uneducated) then gain = gain * 0.9 end

    local factor = minutesAway / gain
    local experience = captain.experience + gain

    if experience >= captain.requiredLevelUpExperience then
        if captain.level < 5 then
            local excess = experience - captain.requiredLevelUpExperience

            captain.level = captain.level + 1
            captain.experience = 0
            CaptainUtility.setRequiredLevelUpExperience(captain)

            if excess > 0 then
                CaptainUtility.applyLeveling(captain, excess * factor)
            end
        else
            captain.experience = captain.requiredLevelUpExperience - 1
        end
    else
        captain.experience = experience
    end

    return captain
end

--[[
    function levelUp(minutesAway)
	print("level", level, "exp", exp, "min", minutesAway)
	
	local gain = math.max(0, minutesAway) / 2
	gain = gain * 0.75
	--if captain:hasPerk(CaptainUtility.PerkType.Educated) then gain = gain * 1.2 end
	--if captain:hasPerk(CaptainUtility.PerkType.Uneducated) then gain = gain * 0.9 end
	
	local factor = minutesAway / gain
	local experience = exp + gain
	
	if experience >= expNeeded then
	    local excess = experience - expNeeded
	    print("excess", excess)
	    
	    level = level + 1
	    exp = 0
	    expNeeded = expNeeded + 50
	    
	    experience = levelUp(excess * factor)
    else
    	exp = experience
	end
	
	return experience, level
end
]]
