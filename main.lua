
-- teams
local TEAM_BLUE = {
	name="BLUE",
	color={0,0,255},
	score=0
}
local TEAM_RED = {
	name="RED",
	color={255,0,0},
	score=0
}

local PLAYER_COLLIDE_RADIUS = 12
local PLAYERS_PER_TEAM = 5
local PLAYER_SPEED = 500
-- whether players keep running in original direction (true) or run to the point
-- specified by player.{x,y} + player.{dx,dy}
local PLAYER_RUN_FOREVER
local PLAYER_BOUNCE
local PLAYER_TOP_BUFFER = 40
local PLAYER_LEFT_BUFFER = 20
local PLAYER_RIGHT_BUFFER = 20
local PLAYER_BOTTOM_BUFFER = 0

local TARGET_DRAW_RADIUS = 4
local TARGET_HIT_RADIUS = 8

local FIELD_W = 1280
local FIELD_H = 720

local TURN_TIME

-- game states
local GSTATE_PLACEMENT = 0 -- putting dudes down AND giving them directions
local GSTATE_COACHING = 1 -- pointing them in a direction, molesting them a little
local GSTATE_RUNNING = 2 -- the game is running. you can't do anything but cry

-- mouse states
local STATE_NONE = 0
local STATE_DRAG_PLAYER = 1
local STATE_DRAG_DIR = 2

-- are we running in SHILBERT MODE? (long turns, keep running in same direction forever)
if love.filesystem.exists("hax.lua") then
	love.filesystem.load("hax.lua")()
end

if SHILBERT_MODE then
	PLAYER_RUN_FOREVER = true
	PLAYER_BOUNCE = true
	TURN_TIME = 30
else -- ravuya mode
	PLAYER_RUN_FOREVER = false
	PLAYER_BOUNCE = false
	TURN_TIME = 0.25
end

local background
local football_image
local player_blue_image
local player_red_image
local small_font
local score_font
local players = {}

local game_state = GSTATE_PLACEMENT
local mouse_state = STATE_NONE
local cur_player = nil
local drag_x_offset = 0
local drag_y_offset = 0
local t = 0
local turn_time_remaining = 0
local cur_team = TEAM_BLUE

require "utils"

function love.load()
	background = love.graphics.newImage("images/background.png")
	football_image = love.graphics.newImage("images/football.png")
	player_blue_image = love.graphics.newImage("images/player_blue.png")
	player_red_image = love.graphics.newImage("images/player_red.png")
	small_font = love.graphics.newFont(12)
	score_font = love.graphics.newFont(48)
end

function love.update(dt)
	dt = clamp(dt,0,0.1)
	t = t + dt

	if game_state == GSTATE_RUNNING then
		-- move each player towards their "goal"
		for n, player in ipairs(players) do
			local dist_left = length(player.dx, player.dy)
			if dist_left > 0.001 then
				local travel = math.min(PLAYER_SPEED * dt, dist_left)
				local nx, ny = normalize(player.dx, player.dy)

				player.x = player.x + nx * travel
				player.y = player.y + ny * travel

				if not PLAYER_RUN_FOREVER then
					if travel == dist_left then
						player.dx = 0
						player.dy = 0
					else
						player.dx = player.dx - nx * travel
						player.dy = player.dy - ny * travel
					end
				end

				if player.x < PLAYER_LEFT_BUFFER then
					player.x = PLAYER_LEFT_BUFFER
					if PLAYER_BOUNCE then
						player.dx = math.abs(player.dx)
					end
				elseif player.x > FIELD_W-PLAYER_RIGHT_BUFFER then
					player.x = FIELD_W-PLAYER_RIGHT_BUFFER
					if PLAYER_BOUNCE then
						player.dx = -math.abs(player.dx)
					end
				end

				if player.y < PLAYER_TOP_BUFFER then
					player.y = PLAYER_TOP_BUFFER
					if PLAYER_BOUNCE then
						player.dy = math.abs(player.dy)
					end
				elseif player.y > FIELD_H-PLAYER_BOTTOM_BUFFER then
					player.y = FIELD_H-PLAYER_BOTTOM_BUFFER
					if PLAYER_BOUNCE then
						player.dy = -math.abs(player.dy)
					end
				end
			end
		end

		player_player_collisions()

		-- when the timer runs out we're done
		turn_time_remaining = turn_time_remaining - dt
		if turn_time_remaining <= 0 then
			stop_running()
		end
	else
		local x, y = love.mouse.getPosition()
		if mouse_state == STATE_DRAG_PLAYER then
			cur_player.x, cur_player.y = restrict_to_team_area(x - drag_x_offset,
																y - drag_y_offset,
																cur_player.team)
		elseif mouse_state == STATE_DRAG_DIR then
			cur_player.dx = x - cur_player.x - drag_x_offset
			cur_player.dy = y - cur_player.y - drag_y_offset
		end
	end
end

function love.draw()
	draw_bg()

	for n, player in ipairs(players) do
		draw_player_ground_stuff(player)
	end

	local players_sorted = {}
	for n, player in ipairs(players) do
		players_sorted[n] = player
	end

	table.sort(players_sorted, function(a,b) return a.y < b.y end)

	for n, player in ipairs(players_sorted) do
		draw_player_sprite(player)
	end

	for n, player in ipairs(players) do
		draw_player_target(player)
	end

	draw_scores()
	draw_hud()
end

function draw_bg()
	local offsetX, offsetY = 0
	if game_state == GSTATE_RUNNING then
		-- vibrate that bitch but just softly
		local alpha = 1.6
		local beta = 0.7
		offsetX = 6 * math.sin(15 * t + alpha)
		offsetY = 2.5 * math.cos(41.1 * t + beta)
	end

	love.graphics.draw(background, offsetX, offsetY)
end

function draw_hud()
	love.graphics.setFont(small_font)
	love.graphics.print("fps: "..love.timer.getFPS(), 10, 10)

	-- tell us whose turn it is
	local team_r_prefix = "      "
	local team_b_prefix = team_r_prefix
	if cur_team == TEAM_BLUE then
		team_b_prefix = "--> "
	else
		team_r_prefix = "--> "
	end
	love.graphics.print(string.format("%s%s: %d/%d", team_b_prefix, TEAM_BLUE.name, players_on_team(TEAM_BLUE), PLAYERS_PER_TEAM), 10, 10+12*1)
	love.graphics.print(string.format("%s%s: %d/%d", team_r_prefix, TEAM_RED.name, players_on_team(TEAM_RED), PLAYERS_PER_TEAM), 10, 10+12*2)
	love.graphics.print("T to swap teams", 10, 10+12*3)

	-- tell us what game state we're in
	local hudText = "";
	if game_state == GSTATE_PLACEMENT then
		hudText = "Placing players..."
	elseif game_state == GSTATE_COACHING then
		hudText = "Directing players..."
	elseif game_state == GSTATE_RUNNING then
		hudText = "Players are playing the game (idiots)"
	else
		hudText = "Unknown game state (".. game_state ..")"
	end
	love.graphics.print(hudText, 10, 10 + 12 * 4)
end

function draw_single_score(val, x,y)
	love.graphics.setFont(score_font)
	love.graphics.setColor(0,0,0)
	love.graphics.print(val, x, y+2)
	love.graphics.setColor(255,255,255)
	love.graphics.print(val, x, y)
end

function draw_scores()
	draw_single_score(TEAM_BLUE.score, 10, 720-60)
	draw_single_score(TEAM_RED.score, 1280-75, 720-60)
end

function draw_player_ground_stuff(player)


	if game_state ~= GSTATE_RUNNING then
		-- draw direction line
		love.graphics.setLineWidth(1)
		love.graphics.setColor(255,255,255)
		love.graphics.line(player.x, player.y, player.x+player.dx, player.y+player.dy)
	end

	-- -- draw circle outline
	-- love.graphics.setLineWidth(1)
	-- love.graphics.setColor(255,255,255)
	-- love.graphics.circle("line", player.x, player.y, PLAYER_COLLIDE_RADIUS, 30)
end

function draw_player_sprite(player)

	local img = player_blue_image
	if player.team == TEAM_RED then
		img = player_red_image
	end
	love.graphics.draw(img, round(player.x - 32), round(player.y - 52))

	-- draw FOOTBALL
	if player.has_football then
		local fbx = round(player.x + 13 - football_image:getWidth()*0.5)
		local fby = round(player.y - 17 - football_image:getHeight()*0.5)
		love.graphics.draw(football_image, fbx, fby)
	end
end

function draw_player_target(player)
	if game_state ~= GSTATE_RUNNING then
		-- draw the point the player runs towards
		love.graphics.setColor(255,255,255)
		love.graphics.circle("fill", player.x + player.dx, player.y + player.dy, TARGET_DRAW_RADIUS)

		love.graphics.setColor(0,0,0)
		love.graphics.setLineWidth(1)
		love.graphics.circle("line", player.x + player.dx, player.y + player.dy, TARGET_DRAW_RADIUS)
	end
end

function hit_test(x, y, team)
	for n, player in ipairs(players) do
		if player.team == team then
			local d

			-- target handle
			d = distance(player.x+player.dx, player.y+player.dy, x, y)
			if d < TARGET_HIT_RADIUS then
				return player, true
			end

			-- player itself
			if get_player_hit_rect(player):contains(x,y) then
				return player, false
			end

		end
	end
end

function get_player_hit_rect(player)
	return Rect:new(player.x - 20, player.y - 45, 40, 45):grow(5)
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
				drag_x_offset = x - (over_player.x+over_player.dx)
				drag_y_offset = y - (over_player.y+over_player.dy)
			else
				if game_state == GSTATE_PLACEMENT then
					mouse_state = STATE_DRAG_PLAYER
					drag_x_offset = x - over_player.x
					drag_y_offset = y - over_player.y
				end
			end
		else
			if game_state == GSTATE_PLACEMENT then
				place_new_player(x,y)
			end
		end
	elseif button == "r" and game_state == GSTATE_PLACEMENT then
		local over_player, hit_dir_handle = hit_test(x,y,cur_team)
		if not hit_dir_handle and over_player ~= nil then
			remove_player(over_player)
		end
	end
end

function restrict_to_team_area(x,y,team)
	local minX,minY,maxX,maxY
	minY = PLAYER_TOP_BUFFER
	maxY = FIELD_H - PLAYER_BOTTOM_BUFFER
	if team == TEAM_BLUE then
		minX = PLAYER_LEFT_BUFFER
		maxX = FIELD_W*0.5 - PLAYER_RIGHT_BUFFER
	else -- TEAM_RED
		minX = FIELD_W*0.5 + PLAYER_LEFT_BUFFER
		maxX = FIELD_W - PLAYER_RIGHT_BUFFER
	end
	return clamp(x, minX, maxX), clamp(y, minY, maxY)
end

function place_new_player(x,y)
	if players_on_team(cur_team) >= PLAYERS_PER_TEAM then
		return
	end
	if cur_team == TEAM_BLUE and x > (FIELD_W/2) then
		return
	end
	if cur_team == TEAM_RED and x < (FIELD_W/2) then
		return
	end
	cur_player = {
		x=x,
		y=y,
		dx=0,
		dy=0,
		team=cur_team,
		has_football=false
	}
	cur_player.x, cur_player.y = restrict_to_team_area(cur_player.x, cur_player.y, cur_player.team)
	if not player_with_football() and cur_team == TEAM_BLUE then
		cur_player.has_football = true
	end
	table.insert(players, cur_player)
	mouse_state = STATE_DRAG_DIR
	drag_x_offset = 0
	drag_y_offset = 0
end

function remove_player(p)
	for n, player in ipairs(players) do 
		if player == p then
			-- print ("Removing player "..n)
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

function player_with_football()
	for n, player in ipairs(players) do
		if player.has_football then
			return player
		end
	end
	return nil
end

function player_player_collide(p1, p2)
	local d = distance(p1.x, p1.y, p2.x, p2.y)
	if d < PLAYER_COLLIDE_RADIUS*2 then
		local ox, oy = p2.x-p1.x, p2.y-p1.y
		local nox, noy = normalize(ox, oy)
		local displacement = (PLAYER_COLLIDE_RADIUS*2 - d) * 0.5
		p1.x = p1.x - nox * displacement
		p1.y = p1.y - noy * displacement
		p2.x = p2.x + nox * displacement
		p2.y = p2.y + noy * displacement
		-- TODO: This doesn't account for dx/dy when in "run to spot" mode (RUN_FOREVER=0)
	end
end

function player_player_collisions()
	-- loop through all player-player combinations
	-- this is N^2 but we at least try to be smart about it
	-- ( it is precisely N(N+1)/2 )
	-- local t0 = love.timer.getMicroTime()
	for n = 1, #players do
		for m = 1, n - 1 do
			player_player_collide(players[n], players[m])
		end
	end
	-- local t1 = love.timer.getMicroTime()
	-- print((t1-t0)*1000)
end

function start_running_turn()
	game_state = GSTATE_RUNNING
	turn_time_remaining = TURN_TIME -- i dunno, that seems fair
end

function stop_running()
	game_state = GSTATE_COACHING
end

function love.mousereleased(x, y, button)
	if button == "l" then
		cur_player = nil
		mouse_state = STATE_NONE
	end
end

function love.keypressed(key, unicode)
	-- switch teams when "T" is pressed
	if mouse_state == STATE_NONE then
		if key == "t" then
			if cur_team == TEAM_BLUE then
				cur_team = TEAM_RED
			else
				cur_team = TEAM_BLUE
			end
		elseif key == "e" then
			-- eventually we'll do some real logic here. for now put the state in running
			start_running_turn()
		end
	end

	if key == "escape" then
		love.event.quit()
	end
end