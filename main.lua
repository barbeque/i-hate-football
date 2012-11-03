local mapWidth, mapHeight
local map
local tilesDisplayWidth, tilesDisplayHeight

local tileSize = 32
local mapX, mapY
local zoomX, zoomY

local tileSetImage
local tileQuads = {}
local tileSetSprite
local dudeBatch
local tileSetBatch

function love.load()
	mapWidth = math.floor(love.graphics.getWidth() / tileSize + 0.5)
	mapHeight = math.floor(love.graphics.getHeight() / tileSize + 0.5)

	print('map width '.. mapWidth)
	print('map height '.. mapHeight)

	-- put random crap in the map
	map = {}
	for x = 1, mapWidth do
		map[x] = {}
		for y = 1, mapHeight do
			map[x][y] = 0--math.random(0, 3)
		end
	end

	-- set up the tile batch
	mapX = 1
	mapY = 1
	tilesDisplayWidth = math.floor(love.graphics.getWidth() / tileSize + 0.5)
	tilesDisplayHeight = math.floor(love.graphics.getHeight() / tileSize + 0.5)

	zoomX = 1
	zoomY = 1

	tileSetImage = love.graphics.newImage("tileset.png")
	tileSetImage:setFilter("nearest", "linear") -- linear filtering

	-- grass
	tileQuads[0] = love.graphics.newQuad(0 * tileSize, 20 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())
	-- kitchen floor tile
	tileQuads[1] = love.graphics.newQuad(2 * tileSize, 0 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())
	-- parquet flooring
	tileQuads[2] = love.graphics.newQuad(4 * tileSize, 0 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())
	-- middle of red carpet
	tileQuads[3] = love.graphics.newQuad(3 * tileSize, 9 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())

	-- top wall
	tileQuads[4] = love.graphics.newQuad(10 * tileSize, 1 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())
	-- down wall
	tileQuads[5] = love.graphics.newQuad(10 * tileSize, 2 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())

	-- top left corner
	-- top wall
	tileQuads[6] = love.graphics.newQuad(8 * tileSize, 1 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())
	-- top right corner
	tileQuads[7] = love.graphics.newQuad(9 * tileSize, 1 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())
	-- bottom left corner
	tileQuads[8] = love.graphics.newQuad(8 * tileSize, 2 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())
	-- bottom right corner
	tileQuads[9] = love.graphics.newQuad(9 * tileSize, 2 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())

	-- wall front
	tileQuads[10] = love.graphics.newQuad(8 * tileSize, 0 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())

	-- man hair
	tileQuads[11] = love.graphics.newQuad(14 * tileSize, 13 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())
	-- man body
	tileQuads[12] = love.graphics.newQuad(14 * tileSize, 14 * tileSize, tileSize, tileSize, tileSetImage:getWidth(), tileSetImage:getHeight())

	for x = 1, mapWidth do
		map[x][1] = 4
		map[x][mapHeight] = 4
	end

	for y = 1, mapHeight do
		map[1][y] = 5
		map[mapWidth][y] = 5
	end

	map[1][1] = 6
	map[mapWidth][1] = 7
	map[1][mapHeight] = 8
	map[mapWidth][mapHeight] = 9

	for x = 2, mapWidth - 1 do
		map[x][2] = 10
	end

	tileSetBatch = love.graphics.newSpriteBatch(tileSetImage, tilesDisplayHeight * tilesDisplayWidth)
	updateVisibleBatch()

	dudeBatch = love.graphics.newSpriteBatch(tileSetImage, 2)
	dudeBatch:addq(tileQuads[11], 0, 0)
	dudeBatch:addq(tileQuads[12], 0, tileSize)
end

function updateVisibleBatch()
	tileSetBatch:clear()
	for x = 0, tilesDisplayWidth - 1 do
		for y = 0, tilesDisplayHeight - 1 do
			q = tileQuads[map[mapX + x][mapY + y]]
			tileSetBatch:addq(q, x * tileSize, y * tileSize)
		end
	end
end

function scrollMap(dx, dy)
	oldMapX = mapX
	oldMapY = mapY
	mapX = math.max(math.min(mapX + dx, mapWidth - tilesDisplayWidth), 1)
	mapY = math.max(math.min(mapY + dy, mapHeight - tilesDisplayHeight), 1)

	-- only update if we moved
	if math.floor(mapX) ~= math.floor(oldMapX) or math.floor(mapY) ~= math.floor(oldMapY) then
		updateVisibleBatch()
	end
end

function love.draw()
	xPos = math.floor(-zoomX * (mapX % 1) * tileSize)
	yPos = math.floor(-zoomY * (mapY % 1) * tileSize)
	love.graphics.draw(tileSetBatch, xPos, yPos)

	-- draw the fat chinese computer science student on the field
	love.graphics.draw(dudeBatch, 80, 200)

	love.graphics.print("fps: "..love.timer.getFPS(), 10, 10)
end