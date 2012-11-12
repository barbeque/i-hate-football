Rect = {}
Rect.__index = Rect

function Rect:new(x,y,w,h)
	local r = {x=x,y=y,w=w,h=h}
	setmetatable(r, Rect)
	return r
end

function Rect:contains(x,y)
	return ((x >= self.x) and
			(x < self.x+self.h) and
			(y >= self.y) and
			(y < self.y+self.h))
end

function Rect:grow(n)
	return Rect:new(self.x-n,self.y-n,self.w+n+n, self.h+n+n)
end

function length(x,y)
	return math.sqrt(x*x + y*y)
end

function distance(x1, y1, x2, y2)
	return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end

function normalize(x, y)
	local d = math.sqrt(x^2 + y^2)
	if d < 1e-6 then
		return 1,0
	else
		return x/d, y/d
	end
end

function round(x)
	return math.floor(x+0.5)
end

function clamp(x, a, b)
	if x < a then
		return a
	elseif x > b then
		return b
	else
		return x
	end
end

function seek(curr, target, step)
	if curr < target then
		curr = curr + step
		-- clamp to avoid overshoot
		return math.min(curr, target)
	elseif curr > target then
		curr = curr - step
		-- clamp to avoid undershoot
		return math.max(curr, target)
	else
		return curr
	end
end

function easeInQuad(t)
	t = clamp(t,0,1)
	return t*t
end

function easeOutQuad(t)
	t = clamp(t,0,1)
	return 1 - (1-t) * (1-t)
end