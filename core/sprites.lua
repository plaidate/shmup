-- shmup core: procedural 1-bit sprites — code-drawn once at load, crisp solid
-- white on transparent (the OpenTyrian 1-bit lesson: solid shapes, not dither).
-- Games can add their own via Sprites.define in a content.sprites hook.

import "CoreLibs/graphics"
local gfx <const> = playdate.graphics

Sprites = { imgs = {}, boom = {} }

function Sprites.define(name, w, h, drawFn)
    local img = gfx.image.new(w, h)
    gfx.pushContext(img)
    gfx.setColor(gfx.kColorWhite)
    drawFn(w, h)
    gfx.popContext()
    Sprites.imgs[name] = { img = img, w = w, h = h }
end

function Sprites.draw(name, x, y)
    local s = Sprites.imgs[name]
    if s then s.img:draw(x - s.w // 2, y - s.h // 2) end
end

function Sprites.init()
    -- player, upward (vertical games)
    Sprites.define("player", 16, 15, function(w, h)
        gfx.fillTriangle(w / 2, 0, w / 2 - 3, h - 3, w / 2 + 3, h - 3)
        gfx.fillTriangle(0, h, 5, h - 6, 5, h)
        gfx.fillTriangle(w, h, w - 5, h - 6, w - 5, h)
        gfx.fillRect(w / 2 - 1, 2, 2, h - 4)
    end)

    -- player, rightward (horizontal games)
    Sprites.define("pship_h", 16, 14, function(w, h)
        gfx.fillTriangle(w, h / 2, 0, 3, 0, h - 3)
        gfx.fillTriangle(0, 0, 6, 5, 0, 5)
        gfx.fillTriangle(0, h, 6, h - 5, 0, h - 5)
        gfx.fillRect(2, h / 2 - 1, w - 5, 2)
    end)

    Sprites.define("grunt", 12, 12, function(w, h)
        gfx.fillTriangle(w / 2, h, 0, 2, w, 2)
        gfx.fillRect(w / 2 - 3, 0, 6, 3)
    end)

    Sprites.define("darter", 11, 13, function(w, h)
        gfx.fillTriangle(w / 2, h, 1, 0, w - 1, 0)
    end)

    Sprites.define("gunner", 20, 16, function(w, h)
        gfx.fillTriangle(w / 2, h, 2, 3, w - 2, 3)
        gfx.fillRect(0, 0, w, 5)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(w / 2 - 1, 1, 2, 3)
        gfx.setColor(gfx.kColorWhite)
    end)

    Sprites.define("shot", 3, 9, function(w, h) gfx.fillRect(0, 0, w, h) end)
    Sprites.define("shot_h", 9, 3, function(w, h) gfx.fillRect(0, 0, w, h) end)
    Sprites.define("orb", 6, 6, function(w, h) gfx.fillCircleAtPoint(w / 2, h / 2, w / 2) end)
    Sprites.define("bomb", 6, 7, function(w, h)
        gfx.fillCircleAtPoint(w / 2, h / 2 + 1, 2)
        gfx.fillRect(w / 2 - 1, 0, 2, 3)
    end)

    Sprites.boom = {}
    for i = 1, 4 do
        local r = 2 + i * 4
        local sz = r * 2 + 2
        local img = gfx.image.new(sz, sz)
        gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(i < 3 and 3 or 2)
        gfx.drawCircleAtPoint(sz / 2, sz / 2, r)
        if i <= 2 then gfx.fillCircleAtPoint(sz / 2, sz / 2, 2) end
        gfx.popContext()
        Sprites.boom[i] = { img = img, sz = sz }
    end
    gfx.setLineWidth(1)
end

function Sprites.drawBoom(frame, x, y)
    local b = Sprites.boom[frame]
    if b then b.img:draw(x - b.sz // 2, y - b.sz // 2) end
end
