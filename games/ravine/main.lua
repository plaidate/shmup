-- Ravine: entry point. Imports the engine (incl. the terrain module), hands it
-- the horizontal game data, and pumps update/draw. d-pad flies, A fires
-- forward, B drops bombs on ground targets.

import "lib"
import "harness"
import "sprites"
import "stars"
import "terrain"
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

-- smoke autopilot: drift up/down to stay in the gap, hold fire, pulse bombs
if Harness.enabled then
    local t = 0
    Harness.autopilot = function()
        t = t + 1
        local ph = (t // 20) % 2
        return {
            up = ph == 0, down = ph == 1, left = false, right = false,
            fire = true, bomb = (t % 12 < 4), start = (t % 45 == 5),
        }
    end
    if playdate.simulator then Harness.shotPath = "build/ravine-shot.png" end
end

local frame = 0
function playdate.update()
    frame = frame + 1
    Harness.frame(frame, function()
        Shmup.update(Config.DT)
        Shmup.draw()
    end)
end
