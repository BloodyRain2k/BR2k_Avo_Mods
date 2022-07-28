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
