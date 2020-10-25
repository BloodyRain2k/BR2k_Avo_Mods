local Azimuth = include("azimuthlib-basic")
local exported = false


local cargo_updateOwnSupply = Factory.updateOwnSupply
function Factory.updateOwnSupply()
    cargo_updateOwnSupply()
    updateStorageDistribution()
end


function Factory.sync(data)
    if onClient() then
        if not data then
            invokeServerFunction("sync")
        else
            maxDuration = data.maxDuration
            Factory.maxNumProductions = data.maxNumProductions
            factorySize = data.maxNumProductions - 1
            production = data.production
            Factory.trader.cargo = data.cargo

            InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())

            Factory.onShowWindow()
        end
    else
        local data = {}
        data.maxDuration = maxDuration
        data.maxNumProductions = Factory.maxNumProductions
        data.factorySize = factorySize
        data.production = production
        data.cargo = Factory.trader.cargo

        invokeClientFunction(Player(callingPlayer), "sync", data)
    end
end


function updateStorageDistribution()
    if not production then
        Factory.trader.cargo = nil
        return
    end
    -- if not exported then print("updating storage space:", Entity().name) end

    local cargo = {
        productPercent = (#Factory.trader.boughtGoods == 0) and 1 or 1/3,
        input = {
            volNeeded = 0,
            costNeeded = 0,
            volTotal = 0,
            costTotal = 0,
        },
        output = {
            volTotal = 0,
            costTotal = 0,
        }
    }

    local what = { ingredients = "input", results = "output", garbages = "output" }
    for k,v in pairs(what) do
        for i,ing in ipairs(production[k]) do
            local name = ing.name
            local good = goods[name]
            
            local dats = {
                amount = ing.amount,
                price = good.price,
                size = good.size,
            }
            dats.vol  = dats.amount * dats.size
            dats.cost = dats.amount * dats.price

            if k == "input" then
                dats.needed = (ing.optional == 0)
            end
            
            cargo[v][name] = dats
            
            if k == "input" and dats.needed then
                cargo[v].volNeeded  = cargo[v].volNeeded  + dats.vol
                cargo[v].costNeeded = cargo[v].costNeeded + dats.cost
            end
            
            cargo[v].volTotal  = cargo[v].volTotal  + dats.vol
            cargo[v].costTotal = cargo[v].costTotal + dats.cost
        end
    end

    Factory.trader.cargo = cargo
    
    if exported then return end
    exported = true

    if Faction() and Faction().isAIFaction then return end

    local debugData = { stocks = {}, production = production }
    if debugData then
        for k,v in pairs(Factory.trader.ownSupplyTypes) do
            local needed, optional
            local good = goods[k]
            
            local data = {
                max = Factory.getMaxGoods(k),
                size = good.size,
                price = good.price,
                needed = needed,
                optional = optional,
            }
            
            data.vol = data.max * data.size
            
            debugData.stocks[k] = data
        end

        debugData.maxStock = Factory.getMaxStock(cargo.input.volNeeded + cargo.output.volTotal)

        Azimuth.saveConfig("FC_"..Entity().name, debugData)
    end
end


function Factory.updateProduction(timeStep)
    -- if the result isn't there yet, don't produce
    if not production then return end
    if not Factory.trader.cargo then updateStorageDistribution() end

    -- if not yet fully used, start producing
    local numProductions = tablelength(currentProductions)
    local canProduce = true

    if numProductions >= Factory.maxNumProductions then
        canProduce = false
        -- print("can't produce as there are no more slots free for production")
    end

    -- only start if there are actually enough ingredients for producing
    for i, ingredient in pairs(production.ingredients) do
        if ingredient.optional == 0 and Factory.getNumGoods(ingredient.name) < ingredient.amount then
            canProduce = false
            newProductionError = "Factory can't produce because ingredients are missing!"%_T
            -- print("can't produce due to missing ingredients: " .. ingredient.amount .. " " .. ingredient.name .. ", have: " .. Factory.getNumGoods(ingredient.name))
            break
        end
    end

    local station = Entity()
    for i, garbage in pairs(production.garbages) do
        local newAmount = Factory.getNumGoods(garbage.name) + garbage.amount
        local size = Factory.getGoodSize(garbage.name)

        if newAmount > Factory.getMaxGoods(garbage.name) or station.freeCargoSpace < garbage.amount * size then
            canProduce = false
            newProductionError = "Factory can't produce because there is not enough cargo space for garbage!"%_T
            -- print("can't produce due to missing room for garbage")
            break
        end
    end

    for _, result in pairs(production.results) do
        local newAmount = Factory.getNumGoods(result.name) + result.amount
        local size = Factory.getGoodSize(result.name)

        if newAmount > Factory.getMaxGoods(result.name) or station.freeCargoSpace < result.amount * size then
            canProduce = false
            newProductionError = "Factory can't produce because there is not enough cargo space for products!"%_T
            -- print("can't produce due to missing room for result")
            break
        end
    end

    if canProduce then
        local boosted

        for i, ingredient in pairs(production.ingredients) do
            local removed = Factory.decreaseGoods(ingredient.name, ingredient.amount)

            if ingredient.optional == 1 and removed then
                boosted = true
            end
        end

        newProductionError = ""
        -- print("start production")

        -- start production
        Factory.startProduction(timeStep, boosted)
    end
end
