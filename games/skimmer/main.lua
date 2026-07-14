-- Skimmer: entry point. d-pad flies, A fires in the direction you are facing.
-- Fly left or right and the camera follows, so the world scrolls both ways.

import "lib"
import "harness"
import "frame"
import "kit"
import "snd"
import "music"
import "fx"
import "sprites"
import "stars"
import "terrain"
import "bullets"
import "enemies"
import "power"
import "boss"
import "player"
import "waves"
import "shmup"
import "content"

-- The hull-runner bot.
--
-- This is the only one of the three that can fail by being SLOW, and that is
-- the point of the free frame: the level is a place with a far end, so there is
-- somewhere to get to. The scroller bots cannot loiter -- the world drags them
-- forward whether they like it or not -- but this one has to decide to go, and
-- a bot that merely survived would hover happily at the near end of the hull
-- forever and report a perfectly green run.
--
-- So: fly right, weave the girders, shoot what is in front of you, kill the core.
local function makeBot()
    local cmd = { left = false, right = false, up = false, down = false,
                  fire = false, bomb = false, start = false }

    local HULL_T <const> = 28
    local HULL_B <const> = 212

    -- The girder we are about to fly into, if any. Girders alternate top and
    -- bottom, so avoiding one means committing to the far side of the corridor
    -- early: at 170 px/s there is no late swerve.
    local function girderAhead()
        for _, p in ipairs(Level.girders) do
            local dx = p.x - Player.x
            if dx > -26 and dx < 96 then return p end
        end
        return nil
    end

    local function dodgeBullets()
        local shift = 0
        local ep = Bullets.ep
        for i = 1, ep.n do
            local b = ep.items[i]
            if not b.dead then
                -- where will it be in a third of a second?
                local px = b.x + b.vx * 0.33
                local py = b.y + b.vy * 0.33
                if math.abs(px - Player.x) < 26 and math.abs(py - Player.y) < 26 then
                    shift = shift + (py >= Player.y and -1 or 1)
                end
            end
        end
        return Lib.sign(shift)
    end

    local function aimY()
        if Boss.active then return Boss.y end
        local best, bd
        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead then
                local dx = e.x - Player.x
                if dx > 40 and dx < 260 and (not bd or dx < bd) then
                    bd, best = dx, e
                end
            end
        end
        return best and best.y or nil
    end

    return function()
        local st = Harness.counters.state or 1
        cmd.left, cmd.right, cmd.up, cmd.down = false, false, false, false
        cmd.fire, cmd.start = false, false

        if st ~= 2 then
            cmd.start = (st == 1)
            return cmd
        end

        -- Once the core is live, hold station short of it: the ring bullets need
        -- room to be dodged, and point-blank they simply spawn on top of you.
        --
        -- 145, not 170. The camera keeps the player at screen centre, so a
        -- stand-off of D puts the boss at screen x = 200 + D -- and at 170 the
        -- bot was duelling a 70px-wide core that was half off the right edge of
        -- its own boss fight. In the free frame, "how far away do I stand" and
        -- "what can I see" are the same number.
        local goal = Boss.active and (Boss.x - 145) or (Content.levelW - 60)
        cmd.right = Player.x < goal - 8
        cmd.left = Player.x > goal + 8

        -- A girder does not dictate an altitude, it forbids a BAND. The first
        -- version treated it as a command ("fly to the far side") and disabled
        -- dodging while one was ahead -- so in the boss arena, where the rings
        -- come at you from every angle, the bot obediently held a straight line
        -- and died. Constraint first, preference second: work out the open
        -- corridor, then choose freely inside it.
        local lo, hi = HULL_T, HULL_B
        local g = girderAhead()
        if g then
            if g.top then lo = HULL_T + g.h + 14 else hi = HULL_B - g.h - 14 end
        end

        local want = aimY() or Player.y
        local d = dodgeBullets()
        if d ~= 0 then want = Player.y + d * 40 end

        want = Lib.clamp(want, lo, hi)
        cmd.up = Player.y > want + 3
        cmd.down = Player.y < want - 3

        cmd.fire = true
        return cmd
    end
end

Shmup.run(Content, {
    autopilot = Harness.enabled and makeBot() or nil,
    extra = function(t)
        t.x = math.floor(Player.x)
        t.bossActive = Boss.active and 1 or 0
    end,
})
