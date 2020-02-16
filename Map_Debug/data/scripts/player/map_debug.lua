include("utility")

-- namespace MapDebug
MapDebug = {}
local sectorSets = {}
local pathSets = {}
	
if onClient() then
	local Azimuth = include("azimuthlib-basic")
	local str = tostring
	
	local map, player
	
	
	--== init ==--
	function MapDebug.initialize()
		map = GalaxyMap()
		cntPaths = map:createContainer()
		
		player = Player()
		player:registerCallback("onShowGalaxyMap", "onShowGalaxyMap")
		player:registerCallback("onMapRenderAfterLayers", "onMapRenderAfterLayers")
	end
	
	function MapDebug.onShowGalaxyMap()
		res = ivec2(getResolution())
	end
	
	function MapDebug.onMapRenderAfterLayers()
		local renderer = UIRenderer()
		
		for name, set in pairs(sectorSets) do
			for _, vSec in pairs(set.sectors) do
				local sx, sy = map:getCoordinatesScreenPosition(vSec)
				
				if sx >= -set.size and sy >= -set.size and sx < res.x + set.size and sy < res.y + set.size then
					renderer:renderTargeter(vec2(sx + 0.0, sy - 0.0), set.size, set.color, 1)
				end
			end
		end
		
		renderer:display()
	end
	
	
	--== general functions ==--
	function toXY(s) -- modified version of https://stackoverflow.com/a/37601779/1025177
		if type(s) ~= "string" then return s end
		local t = {}
		for m in s:gmatch("[^ ,()]+") do
			t[#t+1] = tonumber(m)
		end
		return t[1], t[2]
	end
	
	function distance(vFrom, vTo, round)
		local dx = vTo.x - vFrom.x
		local dy = vTo.y - vFrom.y
		dist = math.sqrt(dx * dx + dy * dy)
		local factor = 10
		for i = 2, (round or 0) do factor = factor * 10 end
		return round and (math.floor(dist * factor + 0.5) / factor) or dist
	end
	
	function getAngle(vFrom, vTo, round)
		-- normaly there'd be also an offset of 180 degree, but it's already added in the core, or forgotten, so this only works without it...
		local angle = math.atan2(vTo.x - vFrom.x, vTo.y - vFrom.y) / math.pi * 180
		while angle >  180 do angle = angle - 360 end
		while angle < -180 do angle = angle + 360 end
		local factor = 10
		for i = 2, (round or 0) do factor = factor * 10 end
		return round and (math.floor(angle * factor + 0.5) / factor) or angle
	end
end

function MapDebug.removeSectorSet(name)
	if onServer() then
		invokeClientFunction(Player(callingPlayer), "removeSectorSet", name)
		return
	end
	
	sectorSets[name] = nil
end

function MapDebug.addSectorSet(sectors, color, name, size)
	if not (sectors or next(sectors)) then return end
	
	if onServer() then
		invokeClientFunction(Player(callingPlayer), "addSectorSet", sectors, color, name, size)
		return
	end
	
	sectorSets[name or "unnamed"] = {
		color = color or ColorARGB(0.7, 1, 1, 1),
		size = size or 21,
		sectors = sectors,
	}
end

function MapDebug.removePathSet(name)
	if onServer() then
		invokeClientFunction(Player(callingPlayer), "removePathSet", name)
		return
	end
	
	pathSets[name]:clear()
end

function MapDebug.addPathSet(sectors, color, name)
	if not (sectors or next(sectors)) then return end
	
	if onServer() then
		invokeClientFunction(Player(callingPlayer), "addPathSet", sectors, color, name)
		return
	end
	
	name = name or "unnamed"
	
	local container = pathSets[name] or GalaxyMap():createContainer()
	pathSets[name] = container
	container:clear()
	
	local arrows = {}
	local last
	
	if next(sectors) == 1 and type(next(sectors)) == "number" then
		for i, vec in ipairs(sectors) do
			if i == 1 then
				last = vec
			else
				local arr = container:createMapArrowLine()
				arr.color = color or ColorARGB(0.5, 1, 1, 1)
				arr.from = last
				arr.to = vec
				
				last = vec
				
				arrows[#arrows + 1] = arr
			end
		end
	else
		for from, to in pairs(sectors) do
			local arr = container:createMapArrowLine()
			arr.color = color or ColorARGB(0.5, 1, 1, 1)
			arr.from = ivec2(toXY(from))
			arr.to = to
				
			arrows[#arrows + 1] = arr
		end
	end	
end

return MapDebug
