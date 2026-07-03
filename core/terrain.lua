-- shmup core: a scrolling cavern for horizontal (Scramble-style) games. Ground
-- and ceiling are smooth procedural profiles drawn as solid white silhouettes;
-- the ship flies the black gap between them. Provides collision and a ground
-- height query so games can ride enemies along the surface.

import "CoreLibs/graphics"
local gfx <const> = playdate.graphics

Terrain = { active = false }

local scroll, speed = 0, 70
local gBase, gAmp, cBase, cAmp

local function groundY(wx) -- top of the ground band
    return gBase - gAmp * (0.6 * math.sin(wx * 0.020) + 0.4 * math.sin(wx * 0.052 + 1.3))
end

local function ceilY(wx) -- bottom of the ceiling band
    return cBase + cAmp * (0.6 * math.sin(wx * 0.017 + 2.0) + 0.4 * math.sin(wx * 0.061))
end

function Terrain.init(cfg)
    cfg = type(cfg) == "table" and cfg or {}
    speed = cfg.speed or 70
    gBase = cfg.groundBase or (SCREEN_H - 32)
    gAmp = cfg.groundAmp or 22
    cBase = cfg.ceilBase or 26
    cAmp = cfg.ceilAmp or 16
    scroll = 0
    Terrain.active = true
end

function Terrain.reset() scroll = 0 end
function Terrain.speed() return speed end
function Terrain.update(dt) scroll = scroll + speed * dt end
function Terrain.groundY(sx) return groundY(scroll + sx) end
function Terrain.ceilY(sx) return ceilY(scroll + sx) end

function Terrain.hits(x, y, r)
    return (y + r >= groundY(scroll + x)) or (y - r <= ceilY(scroll + x))
end

function Terrain.draw()
    gfx.setColor(gfx.kColorWhite)
    local g = {}
    for sx = 0, SCREEN_W, 16 do g[#g + 1] = sx; g[#g + 1] = groundY(scroll + sx) end
    g[#g + 1] = SCREEN_W; g[#g + 1] = SCREEN_H
    g[#g + 1] = 0; g[#g + 1] = SCREEN_H
    gfx.fillPolygon(table.unpack(g))

    local c = {}
    for sx = 0, SCREEN_W, 16 do c[#c + 1] = sx; c[#c + 1] = ceilY(scroll + sx) end
    c[#c + 1] = SCREEN_W; c[#c + 1] = 0
    c[#c + 1] = 0; c[#c + 1] = 0
    gfx.fillPolygon(table.unpack(c))
end
