function love.load()
end

function love.draw()
	love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
end