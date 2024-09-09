SoundEffects = {} --make a table for sound effects
SoundEffects.__index = SoundEffects

function SoundEffects.new()
    local self = setmetatable({}, SoundEffects) --metatable usage! 
    self.laser = love.audio.newSource('music/sfx_laser2.ogg', 'static') -- new sound
    self.laser:setVolume(0.5)
    return self
end

function SoundEffects:playLaser() --make sure to make it load and play!
    self.laser:play()
end
