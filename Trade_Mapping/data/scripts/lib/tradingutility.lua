table.insert(scripts, "/basefactory.lua")
table.insert(scripts, "/lowfactory.lua")
table.insert(scripts, "/midfactory.lua")
table.insert(scripts, "/highfactory.lua")

function TradingUtility.detectBuyableAndSellableGoods(sellable, buyable, stations_only, sector)
	sellable = sellable or {}
	buyable = buyable or {}
	sector = sector or Sector()
	
	local entities = { sector:getEntitiesByType(EntityType.Station) }
	if not stations_only then
		for _, entity in pairs({ sector:getEntitiesByType(EntityType.Ship) }) do
			table.insert(entities, entity)
		end
	end
	
	for _, station in pairs(entities) do
		TradingUtility.getBuyableAndSellableGoods(station, sellable, buyable)
	end
	
	return sellable, buyable
end


function TradingUtility.summarizeSector(sellable, buyable, sector)
	local sector = sector or Sector()
	local coords = vec2(sector:getCoordinates())

	-- local sellable, buyable = TradingUtility.detectBuyableAndSellableGoods(_, _, true) -- only get station goods
	local sellkeys, buykeys = {}, {} -- indices for sorting the goods
	local selling,  buying  = {}, {}
	-- { good = {
	--		stations = station_count,
	-- 		avg_price = avg_price,
	-- 		best_price = best_price,
	-- 	 }
	-- }
	
	-- print(Entity().name.." is collecting TradeMapping data in "..coords)
	
	for i, good in pairs(buyable) do -- iterate the goods we can buy
		local goodId = good.good.name
		local goodName = good.good:displayName(2)
		local data = selling[goodId] -- "selling" because the station is selling to us
		
		if (not data) then
			table.insert(sellkeys, goodId)
			data = {
				name = goodName,
				stations = 0,
				avg_price = 0,
				best_price = 9999999999,
			}
		end
		
		local avg = data.avg_price * data.stations
		data.stations = data.stations + 1
		data.avg_price = (avg + good.price) / data.stations
		data.best_price = math.min(good.price, data.best_price)
		selling[goodId] = data
	end
	
	if debug and false then
		if #sellkeys > 0 then
			table.sort(sellkeys)
			local sell_str = "Selling >> "..#sellkeys.." goods: "
			for i,v in ipairs(sellkeys) do
				sell_str = sell_str..(i > 1 and ", " or "")..(i % 10 == 0 and "\n" or "")..v.." x "..selling[v]
			end
			print(string.rep("-", 40))
			print(sell_str)
		end
	end

	for i, good in pairs(sellable) do -- iterate the goods that we can sell
		local goodId = good.good.name
		local goodName = good.good:displayName(2)
		local data = buying[goodId] -- "buying" because the station is buying from us
		
		if (not data) then
			table.insert(buykeys, goodId)
			data = {
				name = goodName,
				stations = 0,
				avg_price = 0,
				best_price = 0,
			}
		end
		
		local avg = data.avg_price * data.stations
		data.stations = data.stations + 1
		data.avg_price = (avg + good.price) / data.stations
		data.best_price = math.max(good.price, data.best_price)
		buying[goodId] = data
	end
	
	if debug and false then
		if #buykeys > 0 then
			table.sort(buykeys)
			local buy_str = "Buying << "..#buykeys.." goods: "
			for i,v in ipairs(buykeys) do
				buy_str = buy_str..(i > 1 and ", " or "")..(i % 10 == 0 and "\n" or "")
				..v.." x "..buying[v].stations.." @ "..buying[v].avg_price
			end
			print(string.rep("-", 40))
			print(buy_str.."\n")
		end
	end
	
	return {
		entity  = Entity().name, -- name of the ship which collected the data
		sector  = coords, -- sector where it collected the data
		buying  = buying,
		selling = selling,
	}, #sellkeys, #buykeys
end


function TradingUtility.saveTradeMapping(goods_data, entity, player)
	local pilots = { entity:getPilotIndices() }

	if player then
		invokeFactionFunction(player.index, true, "data/scripts/player/trade_mapping.lua", "setData", goods_data)
	elseif pilots ~= nil then
		-- if pilots == 1 then
		-- 	invokeFactionFunction(Player(pilots).index, true, "data/scripts/player/trade_mapping.lua", "setData", goods_data)
		-- elseif pilots > 1 then
		for i = 1, #pilots do
			invokeFactionFunction(Player(pilots[i]).index, true, "data/scripts/player/trade_mapping.lua", "setData", goods_data)
		end
		-- end
	else
		local faction = Faction(entity.factionIndex) or { name = "no faction" }
		print(string.format("[TM]: ok, who owns '%s'? Because I don't know... maybe '%s'?", entity.name, faction.name))
	end
end
