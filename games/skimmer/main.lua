-- Skimmer: entry point. d-pad flies, A fires in the facing direction. Fly left
-- or right and the camera follows -> the world scrolls both ways.

import "lib"
import "harness"
import "sprites"
import "camera"
import "config"
import "game"

playdate.display.setRefreshRate(SMOKE_BUILD and 0 or 30)
math.randomseed(playdate.getSecondsSinceEpoch())

Sk.init()

local function readInput()
    if Harness.enabled and Harness.autopilot then return Harness.autopilot() end
    local pd = playdate
    return {
        left = pd.buttonIsPressed(pd.kButtonLeft), right = pd.buttonIsPressed(pd.kButtonRight),
        up = pd.buttonIsPressed(pd.kButtonUp), down = pd.buttonIsPressed(pd.kButtonDown),
        fire = pd.buttonIsPressed(pd.kButtonA), start = pd.buttonJustPressed(pd.kButtonA),
    }
end

-- smoke autopilot: mostly fly right, periodically reverse left (to exercise the
-- back-and-forth scroll), bob to weave girders, hold fire
if Harness.enabled then
    local t = 0
    Harness.autopilot = function()
        t = t + 1
        local goLeft = (t % 300) >= 230
        local vph = (t // 22) % 2
        return { left = goLeft, right = not goLeft, up = vph == 0, down = vph == 1,
                 fire = true, start = (t % 45 == 5) }
    end
    if playdate.simulator then Harness.shotPath = "build/skimmer-shot.png" end
end

local frame = 0
function playdate.update()
    frame = frame + 1
    Harness.frame(frame, function()
        Sk.update(Config.DT, readInput())
        Sk.draw()
    end)
end
