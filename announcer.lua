require "utils"

local Announcer = {}
Announcer.__index = Announcer

local STATE_HIDDEN = 0
local STATE_SHOWING = 1
local STATE_REVEALING_TEXT = 2
local STATE_HOLD = 3
local STATE_HIDING = 4

local ICON_W = 100
local ICON_H = 100
local ICON_TOP = 595
local ICON_LEFT = 140
local ICON_RIGHT = ICON_LEFT + ICON_W
local ICON_BOTTOM = ICON_TOP + ICON_H

local TEXT_BG_LEFT = ICON_RIGHT
local TEXT_BG_TOP = ICON_TOP
local TEXT_BG_RIGHT = 1280 - ICON_W
local TEXT_BG_BOTTOM = ICON_BOTTOM

local TEXT_LEFT = TEXT_BG_LEFT + 8
local TEXT_TOP = TEXT_BG_TOP + 5
local TEXT_RIGHT = TEXT_BG_RIGHT - 8

local SHADOW_OFFSET = 3

local TEXT_REVEAL_SPEED = 30

local SHOW_TIME = 0.25
local HOLD_TIME = 1
local HIDE_TIME = 0.25

local FRAME_1 = love.graphics.newQuad(0, 	  0, ICON_W, ICON_H, ICON_W*2, ICON_H)
local FRAME_2 = love.graphics.newQuad(ICON_W, 0, ICON_W, ICON_H, ICON_W*2, ICON_H)
local ANIM_TALK = {FRAME_1, FRAME_2}
local ANIM_NO_TALK = {FRAME_2}
local FRAME_TIME = 5/60.0

function Announcer:new()
	local an = {}
	setmetatable(an, Announcer)
	an.image = love.graphics.newImage("images/announcer.png")
	an.text = "LET'S PLAY SOME FOOTBALL!"
	an.state_timer = 0
	an.font = love.graphics.newFont(32)
	an.state = STATE_HIDDEN
	an.anim = ANIM_NO_TALK
	an.anim_frame = 1
	an.anim_frame_timer = 0
	return an
end

function Announcer:update(dt)
	self.state_timer = self.state_timer + dt
	--self.reveal_timer = clamp(self.reveal_timer + dt*TEXT_REVEAL_SPEED, 0, string.len(self.text))

	self.anim_frame_timer = self.anim_frame_timer + dt
	if self.anim_frame_timer >= FRAME_TIME then
		self.anim_frame_timer = 0
		self.anim_frame = self.anim_frame+1
		if self.anim_frame > #(self.anim) then
			self.anim_frame = 1
		end
	end

	if self.state == STATE_HIDDEN then
		self:_changeState(STATE_SHOWING)
		self:_startAnim(ANIM_TALK)
	elseif self.state == STATE_SHOWING then
		if self.state_timer >= SHOW_TIME then
			self:_changeState(STATE_REVEALING_TEXT)
		end
	elseif self.state == STATE_REVEALING_TEXT then
		if self:_charsToShow() >= string.len(self.text) then
			self:_changeState(STATE_HOLD)
			self:_startAnim(ANIM_NO_TALK)
		end
	elseif self.state == STATE_HOLD then
		if self.state_timer >= HOLD_TIME then
			self:_changeState(STATE_HIDING)
		end
	elseif self.state == STATE_HIDING then
		if self.state_timer >= HIDE_TIME then
			self:_changeState(STATE_HIDDEN)
		end
	end
end

function Announcer:_startAnim(anim)
	self.anim = anim
	self.anim_frame_timer = 0
	self.anim_frame = 1
end

function Announcer:_changeState(state)
	assert(state ~= nil, "nil not allowed for state, did you use an undefined constant?")
	self.state = state
	self.state_timer = 0
end

function Announcer:_charsToShow()
	if self.state == STATE_REVEALING_TEXT then
		return clamp(math.floor(self.state_timer * TEXT_REVEAL_SPEED), 0, string.len(self.text))
	elseif self.state == STATE_HOLD or self.state == STATE_HIDING then
		return string.len(self.text)
	else
		return 0
	end
end

-- return 1 if fully slid into view, or 0 if fully slid out of view
function Announcer:_showRatio()
	if self.state == STATE_HOLD or self.state == STATE_REVEALING_TEXT then
		return 1
	elseif self.state == STATE_SHOWING then
		return easeOutQuad(self.state_timer / SHOW_TIME)
	elseif self.state == STATE_HIDING then
		return easeOutQuad(1 - (self.state_timer / HIDE_TIME))
	else
		return 0
	end
end

function Announcer:draw()
	local offset = (720-ICON_TOP)*(1-self:_showRatio())

	-- announcer icon
	love.graphics.setColor(255,255,255) -- white
	love.graphics.drawq(self.image, self.anim[self.anim_frame], ICON_LEFT, ICON_TOP+offset)

	-- text BG
	love.graphics.setColor(0,0,0,255*0.5) -- semitransparent black
	love.graphics.rectangle("fill", TEXT_BG_LEFT, TEXT_BG_TOP+offset, TEXT_BG_RIGHT - TEXT_BG_LEFT, ICON_H)

	-- text itself
	local revealed_text = string.sub(self.text, 1, self:_charsToShow())
	love.graphics.setFont(self.font)
	love.graphics.setColor(0,0,0) -- black
	love.graphics.printf(revealed_text, TEXT_LEFT, TEXT_TOP+SHADOW_OFFSET+offset, TEXT_RIGHT-TEXT_LEFT, "left")
	love.graphics.setColor(255,255,0) -- yellow
	love.graphics.printf(revealed_text, TEXT_LEFT, TEXT_TOP+offset, TEXT_RIGHT-TEXT_LEFT, "left")
end

return {
	Announcer = Announcer
}
