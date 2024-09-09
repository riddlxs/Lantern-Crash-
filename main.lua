--note to self, remember to include more comments from this project forward.

-- Need to include the Music and SoundEffects classes
require 'Music'
require 'SoundEffects'

if arg[2] == "debug" then --sir's debugging stuff
    require("lldebugger").start()
end

local love_errorhandler = love.errorhandler

function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    else
        return love_errorhandler(msg)
    end
end

-- Game variables
local enemy_speed = 27 --not too slow, not too fast! nts = remember to find the middle ground to make it fun for players. 
local rows = 7
local columns = 6
local enemy_spawn_interval = 7 --new waves spawn every 7 seconds
local time_since_last_spawn = 0
local player_score = 0 -- player score
local high_score = 0  --player high score
local game_over = false --simple boolean for game over
local music
local soundEffects

local shoot_cooldown = 0.1 --cooldown for the fires
local time_since_last_shot = 0

function love.load()
    -- Load images and sounds!
    fire = love.graphics.newImage('sprites/fire05.png')
    enemy_img = love.graphics.newImage('sprites/lantern.png')
    background = love.graphics.newImage('sprites/black.png')
    player_img = love.graphics.newImage('sprites/player.png')
    
    music = Music.new('music/music.mp3') -- set the music, must be mp3 
    music:play()
    soundEffects = SoundEffects.new()
    
    initializeGame()
    love.window.setTitle("Lantern Crash 2024 - Liana Hockin")
    loadHighScore()
end

function love.update(dt)
    -- Basic Player movement
    local screen_width = love.graphics.getWidth()
    local player_right_edge = player.x + player.width
    local player_left_edge = player.x

    if love.keyboard.isDown("a") and player_left_edge > 0 then
        player.x = player.x - player.speed * dt
    elseif love.keyboard.isDown("d") and player_right_edge < screen_width then
        player.x = player.x + player.speed * dt
    end

    -- Bullet movement
    for i = #player.bullets, 1, -1 do
        local bullet = player.bullets[i]
        bullet.y = bullet.y - 300 * dt
        if bullet.y < 0 then
            table.remove(player.bullets, i)
        end
    end

    -- Enemy movement 
    local enemiesBelowScreen = false
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        enemy.y = enemy.y + enemy_speed * dt
        if enemy.y > love.graphics.getHeight() then
            enemiesBelowScreen = true
            table.remove(enemies, i)
        end
    end

    if enemiesBelowScreen then -- tells game when player dies 
        game_over = true
        if player_score > high_score then
            high_score = player_score
            saveHighScore()
        end
        love.timer.sleep(1)
        initializeGame()
        return
    end

    -- Bullet to the enemy collision detection
    for i = #player.bullets, 1, -1 do
        local bullet = player.bullets[i]
        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            if CheckCollision(bullet.x, bullet.y, bullet.width, bullet.height, enemy.x, enemy.y, enemy.width, enemy.height) then
                player_score = player_score + 10
                table.remove(player.bullets, i)
                table.remove(enemies, j)
                break
            end
        end
    end

    -- Enemy spawning
    time_since_last_spawn = time_since_last_spawn + dt
    if time_since_last_spawn >= enemy_spawn_interval then
        time_since_last_spawn = 0
        spawnAdditionalEnemies()
    end

    -- Shooting cooldown!
    time_since_last_shot = time_since_last_shot + dt
end

function love.draw()
    love.graphics.draw(background, 0, 0) --draw background, player, bullets, enemies and highscore
    love.graphics.draw(player_img, player.x, player.y)
    
    for _, bullet in ipairs(player.bullets) do
        love.graphics.draw(fire, bullet.x, bullet.y)
    end

    for _, enemy in ipairs(enemies) do
        love.graphics.draw(enemy_img, enemy.x, enemy.y)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Score: " .. player_score, 10, 10)
    love.graphics.print("High Score: " .. high_score, 10, 30)

end

function love.keypressed(key) --shooting mechanics
    if key == "space" and time_since_last_shot >= shoot_cooldown then
        shoot()
        time_since_last_shot = 0
    elseif key == "r" and game_over then
        initializeGame()
    end
end

function shoot() --play sound effect while shooting bullets
    table.insert(player.bullets, {x = player.x + player.width / 2 - 5, y = player.y, width = 10, height = 20})
    soundEffects:playLaser()
end

function initializeGame() --set up inital game and all the variables!
    player = {
        x = 400,
        y = 550,
        width = 50,
        height = 20,
        speed = 500,
        bullets = {}
    }

    enemies = {}
    enemy_speed = 27
    player_score = 0
    game_over = false

    spawnInitialEnemies()
end

function spawnInitialEnemies()
    local spacing_x = 60
    local spacing_y = 60

    local total_width = (columns - 1) * spacing_x
    local start_x = (love.graphics.getWidth() - total_width) / 2
    local start_y = -40

    enemies = {}

    for i = 0, rows - 1 do
        for j = 0, columns - 1 do
            table.insert(enemies, {
                x = start_x + j * spacing_x,
                y = start_y + i * spacing_y,
                width = 40,
                height = 40
            })
        end
    end
end

function spawnAdditionalEnemies() --additional enemies with collision included
    local spacing_x = 60
    local spacing_y = 60

    local total_width = (columns - 1) * spacing_x
    local start_x = (love.graphics.getWidth() - total_width) / 2
    local start_y = -40

    for i = 0, 6 do -- i is for vertical positioning across rows
        for j = 0, 5 do -- j is for horizontal positioning across rows
            table.insert(enemies, {
                x = start_x + j * spacing_x, -- horizontal position of each enemy
                y = start_y + i * spacing_y, --vertical position of each enemy
                width = 40,
                height = 40
            })
        end
    end
end

function CheckCollision(x1, y1, w1, h1, x2, y2, w2, h2) -- important collision check!! use!!
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

function saveHighScore() --highscore save
    local file = love.filesystem.newFile("highscore.txt", "w") --check txt file in game files, w means write mode! 
    if file then
        file:write(tostring(high_score)) -- new command, tostring, we need to change it to a string before writing it in the file. 
        file:close() --save it, do the same in the load function
    end
end

function loadHighScore()
    if love.filesystem.getInfo("highscore.txt") then
        local file = love.filesystem.newFile("highscore.txt", "r") -- r = read file not write when it comes to loading the highscore! 
        if file then
            local content = file:read()
            file:close()
        end
    end
end