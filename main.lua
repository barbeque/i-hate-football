
local TEAM_NAMES = {"BLUE", "RED"}
local TEAM_COLORS = {{0,0,255}, {255,0,0}}
local PLAYER_RADIUS = 16
local PLAYERS_PER_TEAM = 5

-- mouse states
local STATE_NONE = 0
local STATE_DRAG_PLAYER = 1
local STATE_DRAG_DIR = 2

local background
local players = {}

local mouse_state = STATE_NONE
local cur_player = nil
-- 1 or 2
local cur_team = 1

function love.load()
	love.graphics.setCaption("I HATE FOOTBALL")

	background = love.graphics.newImage("background.png")
end

function love.update(dt)
	local x, y = love.mouse.getPosition()	
	if mouse_state == STATE_DRAG_PLAYER then
		-- don't allow dragging into the other team's half of the field
		if cur_team == 1  then
			x = math.min(x, 1280/2 - PLAYER_RADIUS)
		else -- 2
			x = math.max(x, 1280/2 + PLAYER_RADIUS)
		end
		cur_player.x = x
		cur_player.y = y
	elseif mouse_state == STATE_DRAG_DIR then
		cur_player.dx = x - cur_player.x
		cur_player.dy = y - cur_player.y
	end
end

function love.draw()
	love.graphics.draw(background, 0, 0)

	for n, player in ipairs(players) do
		draw_player(player)
	end

	love.graphics.print("fps: "..love.timer.getFPS(), 10, 10)
	local team_1_prefix = "      "
	local team_2_prefix = team_1_prefix
	if cur_team == 1 then
		team_1_prefix = "--> "
	else
		team_2_prefix = "--> "
	end
	love.graphics.print(team_1_prefix..TEAM_NAMES[1] .. ": "..players_on_team(1).."/"..PLAYERS_PER_TEAM, 10, 10+12*1)
	love.graphics.print(team_2_prefix..TEAM_NAMES[2] .. ": "..players_on_team(2).."/"..PLAYERS_PER_TEAM, 10, 10+12*2)
	love.graphics.print("T to swap teams", 10, 10+12*3)
end

function draw_player(player)
	-- draw direction line
	love.graphics.setColor(255,255,255)
	love.graphics.line(player.x, player.y, player.x+player.dx, player.y+player.dy)

	-- draw player circle fill
	love.graphics.setColor(unpack(TEAM_COLORS[player.team]))
	love.graphics.circle("fill", player.x, player.y, PLAYER_RADIUS)

	-- draw circle outline
	love.graphics.setLineWidth(2)
	love.graphics.setColor(255,255,255)
	love.graphics.circle("line", player.x, player.y, PLAYER_RADIUS, 30)

	-- draw the point the player runs towards
	love.graphics.setColor(255,255,255)
	love.graphics.circle("fill", player.x + player.dx, player.y + player.dy, 4)
end

function distance(x1, y1, x2, y2)
	return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end

function hit_test(x, y, team)
	for n, player in ipairs(players) do
		if player.team == team then
			local d

			d = distance(player.x+player.dx, player.y+player.dy, x, y)
			if d < PLAYER_RADIUS*0.5 then
				return player, true
			end

			d = distance(player.x, player.y, x, y)
			if d < PLAYER_RADIUS then
				return player, false
			end

		end
	end
end

function love.mousepressed(x, y, button)
	if mouse_state ~= STATE_NONE then
		return
	end

	if button == "l" then
		local over_player, hit_dir_handle = hit_test(x,y,cur_team)
		if over_player ~= nil then
			cur_player = over_player
			if hit_dir_handle then
				mouse_state = STATE_DRAG_DIR
			else
				mouse_state = STATE_DRAG_PLAYER
			end
		else
			place_new_player(x,y)
		end
	elseif button == "r" then
		local over_player, hit_dir_handle = hit_test(x,y,cur_team)
		if not hit_dir_handle and over_player ~= nil then
			remove_player(over_player)
		end
	end
end

function place_new_player(x,y)
	if players_on_team(cur_team) >= PLAYERS_PER_TEAM then
		return
	end
	if cur_team == 1 and x > (1280/2 - PLAYER_RADIUS) then
		return
	end
	if cur_team == 2 and x < (1280/2 + PLAYER_RADIUS) then
		return
	end
	cur_player = {
		x=x,
		y=y,
		dx=0,
		dy=0,
		team=cur_team
	}
	table.insert(players, cur_player)
	mouse_state = STATE_DRAG_DIR
end

function remove_player(p)
	for n, player in ipairs(players) do 
		if player == p then
			print ("Removing player "..n)
			table.remove(players, n)
			return
		end
	end
end

function players_on_team(team)
	local count = 0
	for n, player in ipairs(players) do
		if player.team == team then
			count = count + 1
		end
	end
	return count
end

function love.mousereleased(x, y, button)
	if button == "l" then
		cur_player = nil
		mouse_state = STATE_NONE
	end
end

function love.keypressed(key, unicode)
	-- switch teams when "T" is pressed
	if mouse_state == STATE_NONE and key == "t" then
		if cur_team == 1 then
			cur_team = 2
		else
			cur_team = 1
		end
	end
end