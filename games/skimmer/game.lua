-- Skimmer: a Uridium-style demo of horizontal *back-and-forth* scrolling. You
-- pilot a fast skimmer over the hull of a long dreadnought; fly left or right
-- and the camera follows, so the world scrolls whichever way you go. Weave the
-- girders (crashing costs a life), shoot the defenders in your facing
-- direction, and reach the far end. Self-contained on the engine's reusable
-- pieces: Pool, Sprites, Lib, Camera, Harness.

import "CoreLibs/graphics"
local gfx <const> = playdate.graphics

Sk = {}

local LEVEL_W <const> = 2400
local HULL_T <const> = 20
local HULL_B <const> = SCREEN_H - 20
local SPEED <const> = 150

local state, score, lives, t
local player, bullets, enemies, booms, pillars, stars

--------------------------------------------------------------------------------
local function defineSprites()
    Sprites.init()
    Sprites.define("manta", 20, 10, function(w, h)
        gfx.fillTriangle(w, h / 2, 0, 0, 0, h) -- rightward wedge
        gfx.setColor(gfx.kColorBlack); gfx.fillRect(3, h / 2 - 1, 6, 2)
        gfx.setColor(gfx.kColorWhite)
    end)
    Sprites.define("defender", 12, 12, function(w, h)
        gfx.fillTriangle(0, h / 2, w, 1, w, h - 1)
        gfx.setColor(gfx.kColorBlack); gfx.fillRect(w - 5, h / 2 - 1, 3, 2)
        gfx.setColor(gfx.kColorWhite)
    end)
    Sprites.define("mshot", 8, 3, function(w, h) gfx.fillRect(0, 0, w, h) end)
end

local function buildLevel()
    pillars = {}
    local x, top = 300, true
    while x < LEVEL_W - 240 do
        pillars[#pillars + 1] = { x = x, w = 22, top = top, h = math.random(34, 82) }
        top = not top
        x = x + math.random(150, 250)
    end
    -- defenders guarding positions along the level
    enemies:clear()
    x = 380
    while x < LEVEL_W - 120 do
        local e = enemies:spawn()
        if e then
            e.x = x
            e.baseY = math.random(HULL_T + 28, HULL_B - 28)
            e.y = e.baseY
            e.amp = math.random(16, 40)
            e.phase = math.random() * 6.28
            e.r = 6
        end
        x = x + math.random(200, 320)
    end
    stars = {}
    for i = 1, 40 do
        stars[i] = { bx = math.random(0, SCREEN_W - 1),
                     by = math.random(HULL_T, HULL_B), d = math.random(2, 5) / 10 }
    end
end

--------------------------------------------------------------------------------
local function rectsOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function hitsPillar(px, py)
    for _, p in ipairs(pillars) do
        if math.abs(p.x - px) < 40 then
            local ry, rh = (p.top and HULL_T or HULL_B - p.h), p.h
            if rectsOverlap(px - 7, py - 3, 14, 6, p.x - p.w / 2, ry, p.w, rh) then
                return true
            end
        end
    end
    return false
end

local function spawnBoom(x, y)
    local b = booms:spawn(); if b then b.x, b.y, b.t = x, y, 0 end
end

local function crash()
    spawnBoom(player.x, player.y)
    lives = lives - 1
    player.invuln = 1.5
    if lives <= 0 then player.alive = false; state = "over" end
end

--------------------------------------------------------------------------------
function Sk.init()
    bullets = Pool.new(24)
    enemies = Pool.new(40)
    booms = Pool.new(16)
    defineSprites()
    Camera.init(LEVEL_W)
    state = "title"
    score = 0
end

function Sk.start()
    score, lives, t = 0, 3, 0
    player = { x = 120, y = SCREEN_H / 2, facing = 1, fireT = 0, invuln = 0, alive = true }
    bullets:clear(); booms:clear()
    buildLevel()
    Camera.follow(player.x)
    state = "play"
end

function Sk.update(dt, input)
    if state == "title" then
        if input.start then Sk.start() end
        return
    elseif state == "over" or state == "win" then
        booms:update(function(b) b.t = b.t + dt; if 1 + b.t // 0.05 > #Sprites.boom then b.dead = true end end)
        if input.start then state = "title" end
        return
    end

    t = t + dt
    if player.alive then
        local dx, dy = 0, 0
        if input.left then dx = -1; player.facing = -1 end
        if input.right then dx = 1; player.facing = 1 end
        if input.up then dy = -1 end
        if input.down then dy = 1 end
        player.x = Lib.clamp(player.x + dx * SPEED * dt, 12, LEVEL_W - 12)
        player.y = Lib.clamp(player.y + dy * SPEED * dt, HULL_T + 6, HULL_B - 6)

        player.fireT = player.fireT - dt
        if input.fire and player.fireT <= 0 then
            player.fireT = 0.16
            local b = bullets:spawn()
            if b then b.x = player.x + player.facing * 11; b.y = player.y; b.vx = player.facing * 560 end
        end

        if player.invuln > 0 then player.invuln = player.invuln - dt
        elseif hitsPillar(player.x, player.y) then crash() end

        if player.x >= LEVEL_W - 24 then state = "win" end
    end

    Camera.follow(player.x)

    bullets:update(function(b)
        b.x = b.x + b.vx * dt
        if b.x < Camera.x - 40 or b.x > Camera.x + SCREEN_W + 40 then b.dead = true end
    end)

    enemies:update(function(e)
        e.y = e.baseY + math.sin(t * 2.2 + e.phase) * e.amp
        -- vs player bullets
        bullets:each(function(b)
            if not b.dead and not e.dead and Lib.circlesHit(b.x, b.y, 3, e.x, e.y, e.r) then
                b.dead = true; e.dead = true; score = score + 200; spawnBoom(e.x, e.y)
            end
        end)
        -- vs player
        if not e.dead and player.alive and player.invuln <= 0
            and Lib.circlesHit(e.x, e.y, e.r, player.x, player.y, 5) then
            e.dead = true; crash()
        end
    end)

    booms:update(function(b) b.t = b.t + dt; if 1 + b.t // 0.05 > #Sprites.boom then b.dead = true end end)

    Harness.set("score", score); Harness.set("lives", lives)
    Harness.set("progress", math.floor(Camera.progress() * 100)); Harness.set("state", state == "play" and 2 or 3)
end

--------------------------------------------------------------------------------
local function textCentered(str, y)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local w = gfx.getTextSize(str)
    gfx.drawText(str, (SCREEN_W - w) // 2, y)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function Sk.draw()
    gfx.clear(gfx.kColorBlack)

    if state == "title" then
        textCentered("SKIMMER", 82); textCentered("PRESS A", 128)
        return
    end

    -- parallax stars (scroll slower than the hull -> depth + scroll direction)
    gfx.setColor(gfx.kColorWhite)
    for _, s in ipairs(stars) do gfx.drawPixel((s.bx - Camera.x * s.d) % SCREEN_W, s.by) end

    -- dreadnought hull bands + panel seams
    gfx.fillRect(0, 0, SCREEN_W, HULL_T)
    gfx.fillRect(0, HULL_B, SCREEN_W, SCREEN_H - HULL_B)
    gfx.setColor(gfx.kColorBlack)
    for sx = -(Camera.x % 24), SCREEN_W, 24 do
        gfx.drawLine(sx, 0, sx, HULL_T); gfx.drawLine(sx, HULL_B, sx, SCREEN_H)
    end
    gfx.setColor(gfx.kColorWhite)

    -- girders
    for _, p in ipairs(pillars) do
        local sx = p.x - Camera.x
        if sx > -20 and sx < SCREEN_W + 20 then
            local y = p.top and HULL_T or HULL_B - p.h
            gfx.fillRect(sx - p.w / 2, y, p.w, p.h)
        end
    end

    enemies:each(function(e)
        local sx = e.x - Camera.x
        if not e.dead and sx > -12 and sx < SCREEN_W + 12 then Sprites.draw("defender", sx, e.y) end
    end)
    bullets:each(function(b) Sprites.draw("mshot", b.x - Camera.x, b.y) end)

    if player.alive and not (player.invuln > 0 and math.floor(player.invuln * 12) % 2 == 0) then
        local img = Sprites.imgs.manta.img
        local sx = player.x - Camera.x
        img:draw(sx - 10, player.y - 5, player.facing < 0 and gfx.kImageFlippedX or gfx.kImageUnflipped)
    end

    booms:each(function(b) Sprites.drawBoom(1 + math.floor(b.t / 0.05), b.x - Camera.x, b.y) end)

    -- HUD in a black strip (over the white top hull)
    gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, SCREEN_W, 15)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(string.format("%06d", score), 6, 3)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    for i = 1, lives do gfx.fillTriangle(SCREEN_W - 6 - i * 14, 4, SCREEN_W - 6 - i * 14, 12, SCREEN_W - 18 - i * 14, 8) end
    -- level-position bar shows the back-and-forth scroll
    local bw = 120; local bx = (SCREEN_W - bw) // 2
    gfx.setColor(gfx.kColorWhite); gfx.drawRect(bx, 5, bw, 5)
    gfx.fillRect(bx + math.floor((bw - 6) * Camera.progress()), 4, 6, 7)

    if state == "over" then
        textCentered("GAME OVER", 96); textCentered("PRESS A", 128)
    elseif state == "win" then
        textCentered("HULL CLEARED", 96); textCentered("PRESS A", 128)
    end
end
