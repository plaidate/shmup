-- shmup core: a horizontal follow-camera over a fixed-width level, for
-- Uridium-style back-and-forth scrolling. The world scrolls in whichever
-- direction the player flies; the camera keeps the player near centre and
-- clamps to the level's ends. Entities live in world coordinates and are drawn
-- at Camera.toScreen(worldX).

Camera = {}

function Camera.init(levelW)
    Camera.levelW = levelW
    Camera.x = 0
end

function Camera.follow(tx)
    Camera.x = Lib.clamp(tx - SCREEN_W / 2, 0, math.max(0, Camera.levelW - SCREEN_W))
end

function Camera.toScreen(wx) return wx - Camera.x end

function Camera.progress()
    return Camera.x / math.max(1, Camera.levelW - SCREEN_W)
end
