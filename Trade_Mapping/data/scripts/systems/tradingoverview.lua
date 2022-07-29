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
	
	-- local coords = vec2(sector:getCoordinates())
	local debug = false
	
	local sellable, buyable = TradingUtility.detectBuyableAndSellableGoods(_, _, true, sector)

	local goods_data, sellingCount, buyingCount = TradingUtility.summarizeSector(sellable, buyable)
	
	-- multiplayer fix done by thakyZ
	local player = Player(callingPlayer)
	
	if debug then
		-- printTable(sellable)
		-- printTable(buyable)
		printTable(goods_data)
		print(callingPlayer, player)
	end
	
	if buyingCount > 0 or sellingCount > 0 then -- don't track sectors that don't trade
		local entity = Entity()
		TradingUtility.saveTradeMapping(goods_data, entity, player)
		
		tradingData:insert({ sellable = sellable, buyable = buyable })
	-- else
		-- print("No TradeMapping data to save for "..coords)
	end
	
	updateTradingRoutes()
end
