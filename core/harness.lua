-- shmup core: smoke-test harness. The Makefile stages smokeflag.lua into every
-- build (SMOKE_BUILD=false release / true for -smoke). When off this is a
-- no-op. When on: a pcall-wrapped update that logs errors to the "err"
-- datastore, a periodic heartbeat to "smoke", an autopilot hook the game's
-- input consults, and periodic PNG screenshots in the simulator.

import "smokeflag"

Harness = {
    enabled = SMOKE_BUILD,
    counters = {},
    autopilot = nil,
    extra = nil,
    shotPath = nil,
}

function Harness.set(key, val)
    if not Harness.enabled then return end
    Harness.counters[key] = val
end

function Harness.frame(frame, updateFn)
    if not Harness.enabled then
        updateFn()
        return
    end
    local ok, err = pcall(updateFn)
    if not ok then
        playdate.datastore.write({ err = tostring(err), frame = frame }, "err")
    end
    if frame % 90 == 0 then
        local t = {}
        for k, v in pairs(Harness.counters) do t[k] = v end
        t.frame = frame
        if Harness.extra then pcall(Harness.extra, t) end
        playdate.datastore.write(t, "smoke")
    end
    if Harness.shotPath and playdate.simulator and (frame == 30 or frame % 300 == 0) then
        local img = playdate.graphics.getDisplayImage()
        playdate.simulator.writeToFile(img, Harness.shotPath)
        playdate.simulator.writeToFile(img, (Harness.shotPath:gsub("%.png$", "-" .. frame .. ".png")))
    end
end
