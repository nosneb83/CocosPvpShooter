local TileMap=class("TileMap",function()
    local tilemap="map1.tmx"
    return ccexp.TMXTiledMap:create(tilemap)
end)

function TileMap:ctor()
	-- self.pathMap={}
    -- self:init()
	-- self.astar = Astar:create()
end

return TileMap