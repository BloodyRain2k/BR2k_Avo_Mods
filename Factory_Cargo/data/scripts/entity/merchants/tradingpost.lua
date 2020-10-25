function TradingPost.trader:getInitialGoods(boughtGoodsIn, soldGoodsIn)
    local resourceAmount = math.random(1, 5)

    local boughtStockByGood = {}

    for _, v in ipairs(boughtGoodsIn) do
        local maxStock = self:getMaxStock(v.name)
        if maxStock > 0 then

            local amount
            if resourceAmount == 1 then
                -- station has few resources available
                amount = math.random(0, maxStock * 0.15)
            else
                -- normal amount of resources available
                amount = math.random(maxStock * 0.1, maxStock * 0.5)
            end

            -- limit by value
            local maxValue = 300 * 1000 * Balancing_GetSectorRichnessFactor(Sector():getCoordinates())
            amount = math.min(amount, math.floor(maxValue / v.price))

            boughtStockByGood[v] = amount
        end
    end

    return boughtStockByGood, boughtStockByGood
end
