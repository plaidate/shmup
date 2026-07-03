-- shmup core: the player ship. Orientation (Shmup.horizontal) picks fire
-- direction and start position; horizontal games also drop bombs (B). Losing a
-- life grants brief invulnerability (a blink), recentres, and refills fuel.

Player = {}

local SPEED <const> = 170
local FIRE_CD <const> = 0.14
local BOMB_CD <const> = 0.35
local START_LIVES <const> = 3

function Player.reset()
    if Shmup.horizontal then
        Player.x, Player.y = 56, SCREEN_H / 2
    else
        Player.x, Player.y = SCREEN_W / 2, SCREEN_H - 30
    end
    Player.lives = START_LIVES
    Player.fireT, Player.bombT = 0, 0
    Player.invuln = 0
    Player.alive = true
    Player.r = 4
    Player.fuel = 100
end

function Player.loseLife()
    Player.lives = Player.lives - 1
    Player.invuln = 1.5
    Player.fuel = 100
    if Shmup.horizontal then
        Player.x, Player.y = 56, SCREEN_H / 2
    else
        Player.x, Player.y = SCREEN_W / 2, SCREEN_H - 30
    end
    if Player.lives <= 0 then Player.alive = false end
    return Player.alive
end

function Player.vulnerable() return Player.alive and Player.invuln <= 0 end

function Player.update(dt, input)
    if not Player.alive then return end
    local dx, dy = 0, 0
    if input.left then dx = dx - 1 end
    if input.right then dx = dx + 1 end
    if input.up then dy = dy - 1 end
    if input.down then dy = dy + 1 end
    Player.x = Lib.clamp(Player.x + dx * SPEED * dt, 8, SCREEN_W - 8)
    Player.y = Lib.clamp(Player.y + dy * SPEED * dt, 10, SCREEN_H - 10)

    Player.fireT = Player.fireT - dt
    if input.fire and Player.fireT <= 0 then
        Player.fireT = FIRE_CD
        if Shmup.horizontal then
            Bullets.playerRight(Player.x + 8, Player.y)
        else
            Bullets.playerUp(Player.x, Player.y - 8)
        end
    end

    Player.bombT = Player.bombT - dt
    if Shmup.horizontal and input.bomb and Player.bombT <= 0 then
        Player.bombT = BOMB_CD
        Bullets.playerBomb(Player.x, Player.y + 6)
    end

    if Player.invuln > 0 then Player.invuln = Player.invuln - dt end
end

function Player.draw()
    if not Player.alive then return end
    if Player.invuln > 0 and (math.floor(Player.invuln * 12) % 2 == 0) then return end
    Sprites.draw(Shmup.horizontal and "pship_h" or "player", Player.x, Player.y)
end
