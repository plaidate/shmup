-- shmup core: shared utilities — math helpers, a fixed-capacity object pool
-- (swap-remove, no per-frame allocation), and circle collision. Everything
-- hangs off global namespace tables (Lib, Pool) after `import "lib"`.

import "CoreLibs/graphics"

SCREEN_W = 400
SCREEN_H = 240

Lib = {}

function Lib.clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

function Lib.approach(v, target, step)
    if v < target then return math.min(v + step, target) end
    return math.max(v - step, target)
end

function Lib.sign(v) return v > 0 and 1 or (v < 0 and -1 or 0) end

function Lib.distSq(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

function Lib.circlesHit(ax, ay, ar, bx, by, br)
    local rr = ar + br
    return Lib.distSq(ax, ay, bx, by) <= rr * rr
end

Lib.KILL_MARGIN = 40
function Lib.offscreen(x, y)
    local m = Lib.KILL_MARGIN
    return x < -m or x > SCREEN_W + m or y < -m or y > SCREEN_H + m
end

--------------------------------------------------------------------------------
-- Pool: fixed array of preallocated entity tables. spawn() returns a cleared
-- slot (or nil when full); update(fn) runs fn(e) over live slots and compacts
-- out any the callback marked e.dead. Order is not preserved.

Pool = {}
Pool.__index = Pool

function Pool.new(capacity)
    local p = setmetatable({ n = 0, cap = capacity, items = {} }, Pool)
    for i = 1, capacity do p.items[i] = {} end
    return p
end

function Pool:spawn()
    if self.n >= self.cap then return nil end
    self.n = self.n + 1
    local e = self.items[self.n]
    for k in pairs(e) do e[k] = nil end
    e.dead = false
    return e
end

function Pool:clear() self.n = 0 end

function Pool:update(fn)
    local i = 1
    while i <= self.n do
        local e = self.items[i]
        fn(e)
        if e.dead then
            self.items[i] = self.items[self.n]
            self.items[self.n] = e
            self.n = self.n - 1
        else
            i = i + 1
        end
    end
end

function Pool:each(fn)
    for i = 1, self.n do fn(self.items[i]) end
end
