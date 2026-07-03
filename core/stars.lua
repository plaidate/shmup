-- shmup core: parallax starfield. Two layers of white points on solid black.
-- Direction is set at init: "down" (vertical shooter) or "left" (horizontal).

import "CoreLibs/graphics"
local gfx <const> = playdate.graphics

Stars = {}
local layers = {}

local function makeLayer(count, speed, size)
    local pts = {}
    for i = 1, count do
        pts[i] = { x = math.random(0, SCREEN_W - 1), y = math.random(0, SCREEN_H - 1) }
    end
    return { pts = pts, speed = speed, size = size }
end

function Stars.init(dir)
    Stars.dir = dir or "down"
    layers = { makeLayer(48, 22, 1), makeLayer(24, 60, 2) }
end

function Stars.update(dt)
    local horiz = Stars.dir == "left"
    for _, L in ipairs(layers) do
        local d = L.speed * dt
        for _, p in ipairs(L.pts) do
            if horiz then
                p.x = p.x - d
                if p.x < 0 then p.x = p.x + SCREEN_W; p.y = math.random(0, SCREEN_H - 1) end
            else
                p.y = p.y + d
                if p.y >= SCREEN_H then p.y = p.y - SCREEN_H; p.x = math.random(0, SCREEN_W - 1) end
            end
        end
    end
end

function Stars.draw()
    gfx.clear(gfx.kColorBlack)
    gfx.setColor(gfx.kColorWhite)
    for _, L in ipairs(layers) do
        local s = L.size
        if s == 1 then
            for _, p in ipairs(L.pts) do gfx.drawPixel(p.x, p.y) end
        else
            for _, p in ipairs(L.pts) do gfx.fillRect(p.x, p.y, s, s) end
        end
    end
end
