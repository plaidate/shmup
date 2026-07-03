-- shmup core: enemy pool + reusable movement (Movers) and fire (Firers)
-- behaviours. A game registers types with Enemies.define; each type is data:
-- { sprite, hp, r, score, fuel, move=fn(e,dt), fire=fn(e,dt) }. Vertical and
-- horizontal (left-scrolling / ground-riding) movers are both provided.

Enemies = {}
Movers = {}
Firers = {}

local types = {}

function Enemies.init(cap)
    Enemies.pool = Pool.new(cap or 64)
    types = {}
end

function Enemies.define(name, spec) types[name] = spec end

function Enemies.spawn(name, x, y)
    local sp = types[name]
    if not sp then return end
    local e = Enemies.pool:spawn()
    if not e then return end
    e.type, e.spec = name, sp
    e.x, e.y = x, y
    e.hp = sp.hp or 1
    e.r = sp.r or 6
    e.age, e.fireT = 0, 0
    e.data = {}
end

function Enemies.update(dt)
    Enemies.pool:update(function(e)
        e.age = e.age + dt
        if e.spec.move then e.spec.move(e, dt) end
        if e.spec.fire then e.spec.fire(e, dt) end
        -- die once fully off any edge (spawn just outside the margin survives)
        if e.x < -Lib.KILL_MARGIN or e.x > SCREEN_W + Lib.KILL_MARGIN
            or e.y < -Lib.KILL_MARGIN or e.y > SCREEN_H + Lib.KILL_MARGIN then
            e.dead = true
        end
    end)
end

function Enemies.draw()
    Enemies.pool:each(function(e) Sprites.draw(e.spec.sprite, e.x, e.y) end)
end

function Enemies.count() return Enemies.pool.n end
function Enemies.clear() Enemies.pool:clear() end

-- ---- vertical movement (top -> bottom) ----
function Movers.straight(speed)
    return function(e, dt) e.y = e.y + speed * dt end
end

function Movers.sine(speed, amp, freq)
    return function(e, dt)
        e.data.x0 = e.data.x0 or e.x
        e.y = e.y + speed * dt
        e.x = e.data.x0 + math.sin(e.age * freq) * amp
    end
end

function Movers.dropHover(targetY, dropSpeed, driftAmp, driftFreq)
    return function(e, dt)
        e.data.x0 = e.data.x0 or e.x
        if e.y < targetY then
            e.y = math.min(e.y + dropSpeed * dt, targetY)
        else
            e.x = e.data.x0 + math.sin(e.age * driftFreq) * driftAmp
        end
    end
end

-- ---- horizontal movement (right -> left) ----
function Movers.left(speed)
    return function(e, dt) e.x = e.x - speed * dt end
end

function Movers.leftSine(speed, amp, freq)
    return function(e, dt)
        e.data.y0 = e.data.y0 or e.y
        e.x = e.x - speed * dt
        e.y = e.data.y0 + math.sin(e.age * freq) * amp
    end
end

-- ride the scrolling ground, snapping to the terrain surface
function Movers.groundLeft(speed, yoff)
    yoff = yoff or 8
    return function(e, dt)
        e.x = e.x - speed * dt
        if Terrain and Terrain.active then e.y = Terrain.groundY(e.x) - yoff end
    end
end

-- launch: drift left with the world while rising (a ground rocket)
function Movers.rocketUp(worldSpeed, riseSpeed)
    return function(e, dt)
        e.x = e.x - worldSpeed * dt
        e.y = e.y - riseSpeed * dt
    end
end

-- ---- fire behaviours ----
function Firers.none() return function() end end

function Firers.aimed(interval, speed)
    return function(e, dt)
        e.fireT = e.fireT + dt
        if e.fireT >= interval then e.fireT = 0; Bullets.eAimed(e.x, e.y, speed) end
    end
end

function Firers.spread(interval, count, arc, speed)
    return function(e, dt)
        e.fireT = e.fireT + dt
        if e.fireT >= interval then
            e.fireT = 0
            Bullets.eSpread(e.x, e.y, math.pi / 2, count, arc, speed)
        end
    end
end

function Firers.ring(interval, count, speed)
    return function(e, dt)
        e.fireT = e.fireT + dt
        if e.fireT >= interval then e.fireT = 0; Bullets.eRing(e.x, e.y, count, speed) end
    end
end
