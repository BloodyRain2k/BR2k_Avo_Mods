function Scrapyard.buyLicense(duration)
    if not CheckFactionInteraction(callingPlayer, Scrapyard.interactionThreshold) then return end

    duration = duration or 0
    if duration <= 0 then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    local price = Scrapyard.getLicensePrice(buyer, duration / 60) -- minutes!

    local station = Entity()

    local canPay, msg, args = buyer:canPay(price)
    if not canPay then
        player:sendChatMessage(station, 1, msg, unpack(args));
        return;
    end

    buyer:pay("Paid %1% credits for a scrapyard license."%_T, price)

    -- register player's license
    licenses[buyer.index] = math.max(0, licenses[buyer.index] or 0) + duration

    -- send a message as response
    local minutes = (duration / 60)
    player:sendChatMessage(station, 0, "You bought a %s minutes salvaging license."%_t, minutes);
    player:sendChatMessage(station, 0, "%s cannot be held reliable for any damage to ships or deaths caused by salvaging."%_t, Faction().name);

    Scrapyard.sendLicenseDuration()
end
callable(Scrapyard, "buyLicense")
