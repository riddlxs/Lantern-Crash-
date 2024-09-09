Music = {} --creates new music table
Music.__index = Music 

function Music.new(filePath)
    local self = setmetatable({}, Music)
    self.source = love.audio.newSource(filePath, 'stream') -- audio should be streamed from mp3 file
    self.source:setLooping(true) --loops the music!
    self.source:setVolume(0.5) --keep at 0.5 so people dont go deaf
    return self
end

function Music:play()
    love.audio.play(self.source)
end

function Music:stop()
    self.source:stop()
end

function Music:setVolume(volume)
    self.source:setVolume(volume)
end
