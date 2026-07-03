-- shmup core: bullet pools and firing patterns. Two pools (player / enemy).
-- Player fire has an up variant (vertical games) and a right variant + bombs
-- (horizontal games). Enemy patterns: aimed / spread / ring. Bullets may carry
-- gravity (b.grav) so bombs arc downward.

import "CoreLibs/graphics"

Bullets = {}

function Bullets.init()
    Bullets.pp = Pool.new(48)
    Bullets.ep = Pool.new(200)
end

local function add(pool, x, y, vx, vy, sprite, r, dmg, grav)
    local b = pool:spawn()
    if not b then return end
    b.x, b.y, b.vx, b.vy = x, y, vx, vy
    b.sprite, b.r, b.dmg, b.grav = sprite, r, dmg or 1, grav
end

function Bullets.playerUp(x, y)
    add(Bullets.pp, x - 5, y, 0, -520, "shot", 3, 1)
    add(Bullets.pp, x + 5, y, 0, -520, "shot", 3, 1)
end

function Bullets.playerRight(x, y)
    add(Bullets.pp, x, y, 560, 0, "shot_h", 3, 1)
end

function Bullets.playerBomb(x, y)
    add(Bullets.pp, x, y, 90, 30, "bomb", 3, 1, 320)
end

function Bullets.eAimed(x, y, speed)
    local dx, dy = Player.x - x, Player.y - y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 0.01 then d = 0.01 end
    add(Bullets.ep, x, y, dx / d * speed, dy / d * speed, "orb", 3, 1)
end

function Bullets.eSpread(x, y, center, count, arc, speed)
    if count < 1 then return end
    local a0 = center - arc / 2
    local step = count > 1 and arc / (count - 1) or 0
    for i = 0, count - 1 do
        local a = a0 + step * i
        add(Bullets.ep, x, y, math.cos(a) * speed, math.sin(a) * speed, "orb", 3, 1)
    end
end

function Bullets.eRing(x, y, count, speed)
    local step = (2 * math.pi) / count
    for i = 0, count - 1 do
        local a = step * i
        add(Bullets.ep, x, y, math.cos(a) * speed, math.sin(a) * speed, "orb", 3, 1)
    end
end

local function step(pool, dt)
    pool:update(function(b)
        if b.grav then b.vy = b.vy + b.grav * dt end
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if Lib.offscreen(b.x, b.y) then b.dead = true end
    end)
end

function Bullets.update(dt)
    step(Bullets.pp, dt)
    step(Bullets.ep, dt)
end

function Bullets.draw()
    Bullets.pp:each(function(b) Sprites.draw(b.sprite, b.x, b.y) end)
    Bullets.ep:each(function(b) Sprites.draw(b.sprite, b.x, b.y) end)
end

function Bullets.clear()
    Bullets.pp:clear()
    Bullets.ep:clear()
end
