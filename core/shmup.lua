-- shmup core: the engine. Ties the subsystems together, owns the game-state
-- machine (title/play/over/win), runs collision, explosions, HUD and input.
-- Orientation-aware: content.scroll = "vertical" (default) or "horizontal".
-- Optional content.terrain (a Scramble-style cavern) and content.fuel add a
-- terrain-collision layer and a depleting fuel gauge.
--
-- content = {
--   scroll   = "vertical" | "horizontal",
--   title    = "TITLE",
--   sprites  = optional function() Sprites.define(...) end,
--   terrain  = optional cfg table for Terrain.init,
--   fuel     = optional true (depletes; refill by killing enemies with .fuel),
--   enemies  = { name = { sprite, hp, r, score, fuel, move, fire }, ... },
--   waves    = { {t, type, x, y, n, dx, dy}, ... },
--   enemyCap = optional int,
-- }

import "CoreLibs/graphics"
local gfx <const> = playdate.graphics

Shmup = { horizontal = false }

local TITLE, PLAY, OVER, WIN = 1, 2, 3, 4
local FUEL_RATE <const> = 3.4
local state, score, booms, content, useTerrain, useFuel

local function readInput()
    if Harness.enabled and Harness.autopilot then return Harness.autopilot() end
    local pd = playdate
    return {
        left  = pd.buttonIsPressed(pd.kButtonLeft),
        right = pd.buttonIsPressed(pd.kButtonRight),
        up    = pd.buttonIsPressed(pd.kButtonUp),
        down  = pd.buttonIsPressed(pd.kButtonDown),
        fire  = pd.buttonIsPressed(pd.kButtonA),
        bomb  = pd.buttonIsPressed(pd.kButtonB),
        start = pd.buttonJustPressed(pd.kButtonA),
    }
end

local function spawnBoom(x, y)
    local b = booms:spawn()
    if b then b.x, b.y, b.t = x, y, 0 end
end

local function updateBooms(dt)
    booms:update(function(b)
        b.t = b.t + dt
        if 1 + math.floor(b.t / 0.05) > #Sprites.boom then b.dead = true end
    end)
end

local function hurtPlayer(x, y)
    spawnBoom(x or Player.x, y or Player.y)
    if not Player.loseLife() then state = OVER end
end

local function collide()
    -- player shots/bombs vs enemies
    Bullets.pp:each(function(b)
        if b.dead then return end
        if useTerrain and b.grav and Terrain.hits(b.x, b.y, 2) then
            b.dead = true; spawnBoom(b.x, b.y); return
        end
        Enemies.pool:each(function(e)
            if b.dead or e.dead then return end
            if Lib.circlesHit(b.x, b.y, b.r, e.x, e.y, e.r) then
                b.dead = true
                e.hp = e.hp - b.dmg
                if e.hp <= 0 then
                    e.dead = true
                    score = score + (e.spec.score or 100)
                    if useFuel and e.spec.fuel then
                        Player.fuel = math.min(100, Player.fuel + e.spec.fuel)
                    end
                    spawnBoom(e.x, e.y)
                end
            end
        end)
    end)

    if not Player.vulnerable() then return end

    if useTerrain and Terrain.hits(Player.x, Player.y, Player.r) then
        hurtPlayer()
        return
    end

    Bullets.ep:each(function(b)
        if b.dead or not Player.vulnerable() then return end
        if Lib.circlesHit(b.x, b.y, b.r, Player.x, Player.y, Player.r) then
            b.dead = true; hurtPlayer()
        end
    end)

    Enemies.pool:each(function(e)
        if e.dead or not Player.vulnerable() then return end
        if Lib.circlesHit(e.x, e.y, e.r, Player.x, Player.y, Player.r) then
            e.dead = true; hurtPlayer(e.x, e.y)
        end
    end)
end

function Shmup.new(c)
    content = c
    Shmup.horizontal = (c.scroll == "horizontal")
    useTerrain = c.terrain ~= nil
    useFuel = c.fuel and true or false

    Sprites.init()
    if c.sprites then c.sprites() end
    Stars.init(Shmup.horizontal and "left" or "down")
    if useTerrain then Terrain.init(c.terrain) end
    Bullets.init()
    Enemies.init(c.enemyCap or 64)
    booms = Pool.new(24)
    for name, spec in pairs(c.enemies) do Enemies.define(name, spec) end
    Player.reset()
    score = 0
    state = TITLE
end

local function startGame()
    score = 0
    Player.reset()
    Bullets.clear()
    Enemies.clear()
    booms:clear()
    Stars.init(Shmup.horizontal and "left" or "down")
    if useTerrain then Terrain.reset() end
    Waves.load(content.waves)
    state = PLAY
end

function Shmup.update(dt)
    local input = readInput()

    if state == TITLE then
        Stars.update(dt)
        if input.start then startGame() end
        return
    elseif state == OVER or state == WIN then
        Stars.update(dt)
        updateBooms(dt)
        if input.start then state = TITLE end
        return
    end

    Stars.update(dt)
    if useTerrain then Terrain.update(dt) end
    Bullets.update(dt)
    Enemies.update(dt)
    Player.update(dt, input)
    Waves.update(dt)
    collide()
    updateBooms(dt)

    if useFuel and Player.alive then
        Player.fuel = Player.fuel - FUEL_RATE * dt
        if Player.fuel <= 0 then Player.fuel = 0; hurtPlayer() end
    end

    if not Player.alive then
        state = OVER
    elseif Waves.finished() then
        state = WIN
    end

    Harness.set("score", score)
    Harness.set("lives", Player.lives)
    Harness.set("enemies", Enemies.count())
    Harness.set("state", state)
end

local function textCentered(str, y)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local w = gfx.getTextSize(str)
    gfx.drawText(str, (SCREEN_W - w) // 2, y)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function drawHUD()
    -- terrain games: reserve a black strip so the white HUD stays legible over
    -- the (white) cavern walls
    if useTerrain then gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, SCREEN_W, 16) end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(string.format("%06d", score), 6, 3)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    for i = 1, Player.lives do
        Sprites.imgs.player.img:draw(SCREEN_W - 6 - i * 14, 2)
    end
    if useFuel then
        local w = 100
        local x = (SCREEN_W - w) // 2
        local y = useTerrain and 6 or (SCREEN_H - 9)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x, y, w, 5)
        gfx.fillRect(x, y, math.floor(w * Player.fuel / 100), 5)
    end
end

function Shmup.draw()
    Stars.draw()

    if state == TITLE then
        textCentered(content.title or "SHMUP", 82)
        textCentered("PRESS A", 128)
        return
    end

    if useTerrain then Terrain.draw() end
    Enemies.draw()
    Bullets.draw()
    Player.draw()
    booms:each(function(b) Sprites.drawBoom(1 + math.floor(b.t / 0.05), b.x, b.y) end)
    drawHUD()

    if state == OVER then
        textCentered("GAME OVER", 96); textCentered("PRESS A", 128)
    elseif state == WIN then
        textCentered("CLEAR!", 96); textCentered("PRESS A", 128)
    end
end
