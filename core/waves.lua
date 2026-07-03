-- shmup core: spawn timeline. Entries: { t=seconds, type, x, y, n, dx, dy }.
-- n copies are spaced by (dx, dy). Vertical games default y to just above the
-- top; horizontal games pass x at the right edge explicitly.

Waves = {}

function Waves.load(script)
    Waves.script = script
    Waves.i = 1
    Waves.t = 0
    Waves.done = false
end

function Waves.update(dt)
    if Waves.done then return end
    Waves.t = Waves.t + dt
    local s = Waves.script
    while Waves.i <= #s and s[Waves.i].t <= Waves.t do
        local w = s[Waves.i]
        local n = w.n or 1
        local dx, dy = w.dx or 0, w.dy or 0
        local bx, by = w.x or (SCREEN_W / 2), w.y or -16
        for k = 0, n - 1 do
            Enemies.spawn(w.type, bx + dx * k, by + dy * k)
        end
        Waves.i = Waves.i + 1
    end
    if Waves.i > #s then Waves.done = true end
end

function Waves.finished() return Waves.done and Enemies.count() == 0 end
