-- Nova Strike: entry point. A thin driver — it imports the engine, hands it
-- the game data, and pumps update/draw. All gameplay lives in the engine core.

import "lib"
import "harness"
import "sprites"
import "stars"
import "bullets"
import "enemies"
import "player"
import "waves"
import "shmup"
import "config"
import "content"

playdate.display.setRefreshRate(SMOKE_BUILD and 0 or 30)
math.randomseed(playdate.getSecondsSinceEpoch())

Shmup.new(Content)

-- smoke-test autopilot: sweep sideways and hold fire so waves get shot, and
-- pulse A so the title/game-over screens advance on their own
if Harness.enabled then
    local t = 0
    Harness.autopilot = function()
        t = t + 1
        local phase = (t // 40) % 4
        return {
            left  = phase == 1,
            right = phase == 3,
            up    = false,
            down  = false,
            fire  = true,
            start = (t % 45 == 5),
        }
    end
    if playdate.simulator then Harness.shotPath = "shmup/build/nova-shot.png" end
end

local frame = 0
function playdate.update()
    frame = frame + 1
    Harness.frame(frame, function()
        Shmup.update(Config.DT)
        Shmup.draw()
    end)
end
