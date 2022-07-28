--[[
local tm_onInstalled = onInstalled
function onInstalled(seed, rarity, permanent)
	tm_onInstalled(seed, rarity, permanent)
end

local tm_onUninstalled = onUninstalled
function onUninstalled(seed, rarity, permanent)
	tm_onUninstalled(seed, rarity, permanent)
end
--]]


function collectSectorData()
	local sector = Sector()

	-- don't run while the server is still starting up
    if not tradingData or not Galaxy().sectorLoaded or
		not Galaxy():sectorLoaded(sector:getCoordinates()) then
			return
	end

    local sellable, buyable = TradingUtility.detectBuyableAndSellableGoods(_, _, true, sector)
	local debug = false

	-- local sellable, buyable = TradingUtility.detectBuyableAndSellableGoods(_, _, true) -- only get station goods
	local sellkeys, buykeys = {}, {} -- indices for sorting the goods
	local selling,  buying  = {}, {}
	-- { good = {
	--		stations = station_count,
	-- 		avg_price = avg_price,
	-- 		best_price = best_price,
	-- 	 }
	-- }
	
	local coords = vec2(sector:getCoordinates())
	-- print(Entity().name.." is collecting TradeMapping data in "..coords)
	
    for i, good in pairs(buyable) do
		-- good.good.price holds the base price
		local goodId = good.good.name
		local goodName = good.good:displayName(2)
		local data = selling[goodId]
		
		if (not data) then
			sellkeys[#sellkeys + 1] = goodId
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

    for i, good in pairs(sellable) do
		local goodId = good.good.name
		local goodName = good.good:displayName(2)
		local data = buying[goodId]
		
		if (not data) then
			buykeys[#buykeys + 1] = goodId
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
	
	local goods_data = {
		entity  = Entity().name, -- name of the ship which collected the data
		sector  = coords, -- sector where it collected the data
		buying  = buying,
		selling = selling,
	}
	
	-- multiplayer fix done by thakyZ
	local pilots = Entity():getPilotIndices()
	local player = Player(callingPlayer)
	
	if debug then
		-- printTable(sellable)
		-- printTable(buyable)
		printTable(goods_data)
		print(callingPlayer, player)
	end
	
	if player then
		invokeFactionFunction(player.index, true, "data/scripts/player/trade_mapping.lua", "setData", goods_data)
	elseif pilots ~= nil then
		if pilots == 1 then
			invokeFactionFunction(Player(pilots).index, true, "data/scripts/player/trade_mapping.lua", "setData", goods_data)
		elseif pilots > 1 then
			for i = 1,pilots.length do
				invokeFactionFunction(Player(pilots[i]).index, true, "data/scripts/player/trade_mapping.lua", "setData", goods_data)
			end
		end
	else
		print("[TM]: ok, who owns "..Entity().name.."? Because I don't know...")
	end
	
	if #buykeys > 0 or #sellkeys > 0 then
		tradingData:insert({ sellable = sellable, buyable = buyable })
	-- else
		-- print("No TradeMapping data to save for "..coords)
	end
	
	updateTradingRoutes()
end
