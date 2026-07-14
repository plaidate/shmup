-- Ravine: entry point. Imports the engine, hands it the game data, calls the
-- cabinet. d-pad flies, A fires forward, B drops bombs on the ground targets.

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

-- The cave-flying bot.
--
-- It steers by Terrain.groundY / Terrain.ceilY -- which is to say, by THE SAME
-- SAMPLED PROFILE THE COLLIDER USES. That is not a convenience, it is the
-- engine's second design rule made executable: when the drawn wall and the hit
-- wall were different curves (as they were, by up to a pixel, before the
-- terrain was rewritten), a bot flying the exact centre of the gap would still
-- occasionally clip a wall it was nowhere near -- and it would do it rarely
-- enough to look like flakiness rather than like a bug.
--
-- Bombing is the other half. Bombs are ballistic and the world is moving, so
-- the bot solves for the drop point rather than flying over the target and
-- hoping: fall time from the ship's altitude down to the target's, then the x
-- at which a bomb launched now meets a target that is itself sliding left.
local function makeBot()
    local cmd = { left = false, right = false, up = false, down = false,
                  fire = false, bomb = false, start = false }

    local HOLD_X <const> = 104     -- station-keeping: room to see what is coming
    local GRAV <const> = 320       -- must match Bullets.playerBomb
    local BOMB_VX <const> = 90
    local BOMB_VY <const> = 30

    -- Where should we be, vertically? The middle of the gap a little way ahead:
    -- at 66 px/s, the wall we have to clear is one we can already see.
    local function gapCenter()
        local ahead = math.min(SCREEN_W - 1, Player.x + 46)
        local g = Terrain.groundY(ahead)
        local c = Terrain.ceilY(ahead)
        return (g + c) / 2, c, g
    end

    -- Fall time for a bomb dropped now, from
    --   ty = py + BOMB_VY*t + GRAV*t^2/2
    local function fallTime(py, ty)
        local a = GRAV / 2
        local disc = BOMB_VY * BOMB_VY + 4 * a * (ty - py)
        if disc <= 0 then return nil end
        return (-BOMB_VY + math.sqrt(disc)) / (2 * a)
    end

    local function wantBomb()
        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead and (e.type == "dump" or e.type == "tank") then
                local t = fallTime(Player.y + 6, e.y)
                if t then
                    -- The bomb drifts right at BOMB_VX while the target slides
                    -- left with the world at Frame.speed: they close at the sum.
                    local dropX = e.x - (BOMB_VX + Frame.speed) * t
                    if math.abs(Player.x - dropX) < 11 then return true end
                end
            end
        end
        return false
    end

    -- The nearest thing we can actually shoot, while it is still far enough
    -- away that lining up on it is safe. Bullets fly flat along our row, so
    -- "aiming" in the side frame means choosing an altitude. The boss counts:
    -- it is the biggest air target there is.
    local function aimY()
        if Boss.active then return Boss.y end
        local best, bd
        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead and e.type == "ufo" then
                local dx = e.x - Player.x
                if dx > 80 and (not bd or dx < bd) then bd, best = dx, e end
            end
        end
        return best and best.y or nil
    end

    -- Incoming fire: solve for when it reaches our column and step out of the
    -- row it will be in when it gets there.
    --
    -- And incoming HULLS. The first bot only dodged bullets, and it kept dying
    -- three-quarters of the way through the cavern -- to the rockets, which
    -- launch off the floor and climb straight up through the gap you are flying
    -- down the middle of. In this frame the enemy is not the thing shooting at
    -- you; it is the thing occupying the space you are about to be in.
    local function dodgeY()
        local shift = 0

        local ep = Bullets.ep
        for i = 1, ep.n do
            local b = ep.items[i]
            if not b.dead and b.vx < -20 then
                local t = (b.x - Player.x) / -b.vx
                if t > 0 and t < 1.2 then
                    local dy = (b.y + b.vy * t) - Player.y
                    if math.abs(dy) < 26 then
                        shift = shift + (dy >= 0 and -1 or 1)
                    end
                end
            end
        end

        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead then
                local dx = e.x - Player.x
                if dx > -14 and dx < 76 then
                    local dy = e.y - Player.y
                    if math.abs(dy) < 26 then
                        -- lean away, hard: a hull costs a life, a bullet costs
                        -- a life, and the hull is bigger
                        shift = shift + (dy >= 0 and -2 or 2)
                    end
                end
            end
        end

        return Lib.sign(shift)
    end

    return function()
        local st = Harness.counters.state or 1
        cmd.left, cmd.right, cmd.up, cmd.down = false, false, false, false
        cmd.fire, cmd.bomb, cmd.start = false, false, false

        if st ~= 2 then
            cmd.start = (st == 1)
            return cmd
        end

        local mid, ceil, ground = gapCenter()
        local want = mid

        -- Line the gun up on whatever is still far enough away to shoot. A bot
        -- that only ever dodges never kills the air targets, so they pile up
        -- ahead of it and it eventually gets cornered by the sheer number of
        -- them -- which is precisely how this one kept dying at 93% of the
        -- level, one wave short of the boss.
        local aim = aimY()
        if aim then want = aim end

        -- Dodge, and let it override the aim: the gap is a hard constraint, the
        -- bullet is a preference, and being alive beats being on target.
        local d = dodgeY()
        if d ~= 0 then
            want = Player.y + d * 46
        end
        want = Lib.clamp(want, ceil + 16, ground - 16)

        cmd.up = Player.y > want + 3
        cmd.down = Player.y < want - 3

        cmd.left = Player.x > HOLD_X + 6
        cmd.right = Player.x < HOLD_X - 6

        cmd.fire = true
        cmd.bomb = wantBomb()
        return cmd
    end
end

Shmup.run(Content, {
    autopilot = Harness.enabled and makeBot() or nil,
    extra = function(t)
        t.fuel = math.floor(Player.fuel)
        t.bossActive = Boss.active and 1 or 0
    end,
})
