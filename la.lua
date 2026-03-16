-- Main Controller Script
-- Execute this on your main account

local Webhooks = {
    ["commands"] = "https://discord.com/api/webhooks/1483203347874975927/rWkk0gFt5ks8_Bcekzc8KIe7x12uuUvSXEBI85QPX_Me34JeQzkum_pOYfTABDyEZbRs",
    ["status"] = "https://discord.com/api/webhooks/1483203506168135954/tAKlxOQG5pYXf4es7Gwdn1iyYivdFsaGFSjcUQYSnp2-i4UCfwvRy5WlgZHjvdHsta4l",
    ["errors"] = "https://discord.com/api/webhooks/1483203290316669142/B1xU_L5zsxB3Um_G-TKGuLH-_YRbvDbBBYYB231wVgFl6WGEIsZ6jkTYSrZrhK5RVY_9",
    ["deaths"] = "https://discord.com/api/webhooks/1483203350760521961/0WmoP7pVklwdrn2CJOV_bWMDkJtB3QIj-adYPgDC-EpIl9Z-hnNleUDN7Yi7zQkQN3QL",
    ["chat_public"] = "https://discord.com/api/webhooks/1483203568281325839/5y-BwtJ5cjmb51kXsvxPwgeeJZtHyB36oMf8ourZtf4orVY8nBT6vgwZEWmzsVe3McBr",
    ["chat_private"] = "https://discord.com/api/webhooks/1483203542155137280/Emg65rUxrzSLpHKJ8_qtXEeafR_tUefYSWlpjCYvXcKiSBOJQIuUAmhsvMk6b2rQ1lrA",
    ["actions"] = "https://discord.com/api/webhooks/1483203400538525841/BUJFvfHgw_eV6qDs_fgGEH3GzFoelKQ7wTPBMAViYI4cW6nJSwl8x8eZCDjAY2LZYkDZ",
    ["movement"] = "https://discord.com/api/webhooks/1483203228379119801/Ocajpg_NLYy2PcVUM5N-fYoF1WsQoAyu9tRwX_47Raxn35JqNV4uKpJjQs4b39RCFu5r",
    ["players"] = "https://discord.com/api/webhooks/1483203470713552926/oWFtB8WsQAXz8K4U1a1bUNtsP7aAfZXlo5Id7VAtoYlFB0yKdv5bVRKk_BkpRzQY_554",
    ["debug"] = "https://discord.com/api/webhooks/1483203590108479648/SM-E_6wUgaMjJnKGTsNViEqssLmc94JTcoP8vtrScyNxhLFIjQ4Z6-oUi1MIGLp5N7GM"
}

local altName = "Local_TestBot" -- Your alt's username
local cmdPrefix = "!" -- Command prefix

-- Services with multiple methods to avoid cross-experience errors
local Services = {
    Players = game:GetService("Players"),
    HttpService = game:GetService("HttpService"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    UserInputService = game:GetService("UserInputService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TeleportService = game:GetService("TeleportService"),
    MarketplaceService = game:GetService("MarketplaceService"),
    Chat = game:GetService("Chat")
}

local Players = Services.Players
local HttpService = Services.HttpService
local RunService = Services.RunService
local Workspace = Services.Workspace

-- State variables
local altConnected = false
local followTarget = nil
local loopFollowActive = false
local spinning = false
local npcMode = false
local currentSpeed = 16
local currentJumpPower = 50
local spasmActive = false
local circleActive = false
local circleTarget = nil
local lastCommand = ""
local anonyMode = false
local jerkActive = false

-- Function to send Discord webhook with retry logic
local function sendWebhook(webhookName, content, embeds)
    local webhookURL = Webhooks[webhookName]
    if not webhookURL then return end
    
    local data = {
        ["content"] = content,
        ["username"] = "Alt Controller",
        ["avatar_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..Players.LocalPlayer.UserId.."&width=420&height=420&format=png"
    }
    
    if embeds then
        data["embeds"] = embeds
    end
    
    local success = false
    local retries = 3
    
    while not success and retries > 0 do
        success, _ = pcall(function()
            local jsonData = HttpService:JSONEncode(data)
            HttpService:PostAsync(webhookURL, jsonData, Enum.HttpContentType.ApplicationJson)
        end)
        
        if not success then
            retries = retries - 1
            wait(0.5)
        end
    end
    
    if not success then
        warn("Failed to send webhook to " .. webhookName)
    end
end

-- Function to execute remote with multiple methods
local function fireRemote(remotePath, ...)
    local success = false
    
    -- Method 1: Direct firing
    success = pcall(function()
        local remote = remotePath
        if type(remotePath) == "string" then
            remote = Services.ReplicatedStorage:FindFirstChild(remotePath)
        end
        if remote then
            remote:FireServer(...)
        end
    end)
    
    if not success then
        -- Method 2: Invoke server
        pcall(function()
            local remote = type(remotePath) == "string" and Services.ReplicatedStorage:FindFirstChild(remotePath) or remotePath
            if remote and remote:IsA("RemoteFunction") then
                remote:InvokeServer(...)
            end
        end)
    end
end

-- Function to send chat message with multiple methods
local function sendChatMessage(message, isPrivate, targetPlayer)
    local success = false
    
    -- Method 1: Default chat system
    success = pcall(function()
        local chatEvent = Services.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvent then
            local sayRequest = chatEvent:FindFirstChild("SayMessageRequest")
            if sayRequest then
                sayRequest:FireServer(message, isPrivate and "Whisper" or "All")
            end
        end
    end)
    
    -- Method 2: Alternative chat system
    if not success then
        pcall(function()
            local chatRemote = Services.ReplicatedStorage:FindFirstChild("ChatRemote")
            if chatRemote then
                chatRemote:FireServer(message, isPrivate and targetPlayer or nil)
            end
        end)
    end
    
    -- Method 3: Direct Chat service
    if not success then
        pcall(function()
            Services.Chat:Chat(Players.LocalPlayer.Character, message)
        end)
    end
    
    -- Log to Discord
    local webhookName = isPrivate and "chat_private" or "chat_public"
    local embed = {
        {
            ["title"] = isPrivate and "🔒 Private Chat" or "💬 Public Chat",
            ["color"] = isPrivate and 15158332 or 5814783,
            ["description"] = message,
            ["fields"] = {
                {
                    ["name"] = "From",
                    ["value"] = Players.LocalPlayer.Name,
                    ["inline"] = true
                },
                {
                    ["name"] = "To",
                    ["value"] = isPrivate and targetPlayer or "Everyone",
                    ["inline"] = true
                }
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }
    }
    sendWebhook(webhookName, nil, embed)
end

-- Command handler
local function handleCommand(command, args, speaker)
    -- Log command to Discord
    local cmdEmbed = {
        {
            ["title"] = "Command Executed",
            ["color"] = 5814783,
            ["fields"] = {
                {
                    ["name"] = "Command",
                    ["value"] = command,
                    ["inline"] = true
                },
                {
                    ["name"] = "Executor",
                    ["value"] = speaker.Name,
                    ["inline"] = true
                },
                {
                    ["name"] = "Arguments",
                    ["value"] = #args > 0 and table.concat(args, " ") or "None",
                    ["inline"] = false
                }
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }
    }
    sendWebhook("commands", nil, cmdEmbed)
    
    local char = Players.LocalPlayer.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    
    -- Follow Player
    if command == "follow" and #args > 0 then
        local targetName = args[1]
        followTarget = Players:FindFirstChild(targetName)
        if followTarget then
            sendWebhook("status", "✅ Now following: " .. targetName)
            sendWebhook("actions", "Started following " .. targetName)
        else
            sendWebhook("errors", "❌ Player not found: " .. targetName)
        end
        
    -- Move
    elseif command == "move" and #args >= 2 then
        local direction = args[1]:lower()
        local duration = tonumber(args[2]) or 2
        
        local moveVector = Vector3.new(0,0,0)
        if direction == "forward" then moveVector = Workspace.CurrentCamera.CFrame.LookVector * currentSpeed
        elseif direction == "back" then moveVector = -Workspace.CurrentCamera.CFrame.LookVector * currentSpeed
        elseif direction == "left" then moveVector = -Workspace.CurrentCamera.CFrame.RightVector * currentSpeed
        elseif direction == "right" then moveVector = Workspace.CurrentCamera.CFrame.RightVector * currentSpeed
        end
        
        spawn(function()
            local startTime = tick()
            while tick() - startTime < duration do
                if humanoid then
                    humanoid:Move(moveVector)
                end
                RunService.Heartbeat:Wait()
            end
            humanoid:Move(Vector3.new(0,0,0))
        end)
        
        sendWebhook("movement", string.format("🚶 Moving %s for %d seconds", direction, duration))
        sendWebhook("actions", "Moving " .. direction)
        
    -- Jump
    elseif command == "jump" then
        if humanoid then
            humanoid.Jump = true
            sendWebhook("actions", "Jumped")
            sendWebhook("movement", "Jumped at " .. tostring(rootPart and rootPart.Position or "unknown"))
        end
        
    -- Loop Jump
    elseif command == "loopjump" then
        local count = tonumber(args[1]) or 10
        spawn(function()
            for i = 1, count do
                if humanoid then
                    humanoid.Jump = true
                end
                wait(0.5)
            end
        end)
        sendWebhook("actions", string.format("Loop jumping %d times", count))
        
    -- Loop Follow Player
    elseif command == "loopfollow" and #args > 0 then
        local targetName = args[1]
        followTarget = Players:FindFirstChild(targetName)
        loopFollowActive = true
        
        spawn(function()
            while loopFollowActive and followTarget and followTarget.Character do
                if rootPart and followTarget.Character:FindFirstChild("HumanoidRootPart") then
                    rootPart.CFrame = followTarget.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
                end
                wait(2)
            end
        end)
        sendWebhook("actions", "Loop following " .. targetName)
        
    -- Spin
    elseif command == "spin" then
        spinning = true
        spawn(function()
            while spinning and rootPart do
                rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(10), 0)
                wait(0.03)
            end
        end)
        sendWebhook("actions", "Started spinning")
        
    -- Unspin
    elseif command == "unspin" then
        spinning = false
        sendWebhook("actions", "Stopped spinning")
        
    -- Teleport to player
    elseif command == "tp" and #args > 0 then
        local target = Players:FindFirstChild(args[1])
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and rootPart then
            rootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
            sendWebhook("movement", "✨ Teleported to " .. args[1])
            sendWebhook("actions", "Teleported to " .. args[1])
        else
            sendWebhook("errors", "Failed to teleport to " .. args[1])
        end
        
    -- Circle player
    elseif command == "circle" and #args > 0 then
        local target = Players:FindFirstChild(args[1])
        if target and target.Character then
            circleTarget = target
            circleActive = true
            spawn(function()
                local angle = 0
                while circleActive and circleTarget and circleTarget.Character and rootPart do
                    local radius = 10
                    local center = circleTarget.Character.HumanoidRootPart.Position
                    angle = angle + 0.1
                    local x = center.X + math.cos(angle) * radius
                    local z = center.Z + math.sin(angle) * radius
                    rootPart.CFrame = CFrame.new(x, center.Y, z)
                    wait(0.05)
                end
            end)
            sendWebhook("actions", "Circling " .. args[1])
        end
        
    -- Chat {message}
    elseif command == "chat" and #args > 0 then
        local message = table.concat(args, " ")
        sendChatMessage(message, false)
        
    -- Private chat {message}
    elseif command == "privatechat" and #args >= 2 then
        local target = args[1]
        table.remove(args, 1)
        local message = table.concat(args, " ")
        sendChatMessage(message, true, target)
        
    -- Emote
    elseif command == "emote" and #args > 0 then
        local emote = args[1]:lower()
        local emotes = {
            wave = "rbxassetid://5077702695",
            point = "rbxassetid://5077710197",
            laugh = "rbxassetid://5077709884",
            cheer = "rbxassetid://5077700427"
        }
        
        if emotes[emote] and humanoid then
            local anim = Instance.new("Animation")
            anim.AnimationId = emotes[emote]
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            sendWebhook("actions", "Playing emote: " .. emote)
        end
        
    -- Dance
    elseif command == "dance" then
        if humanoid then
            local dances = {
                "rbxassetid://5077710490",
                "rbxassetid://5077709385",
                "rbxassetid://5077708668"
            }
            local anim = Instance.new("Animation")
            anim.AnimationId = dances[math.random(#dances)]
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            sendWebhook("actions", "Dancing")
        end
        
    -- Act NPC
    elseif command == "actnpc" then
        npcMode = not npcMode
        if npcMode and humanoid then
            humanoid.WalkSpeed = 8
            humanoid.JumpPower = 0
            humanoid.AutoRotate = false
            spawn(function()
                while npcMode do
                    local randomDir = Vector3.new(math.random(-10,10)/10, 0, math.random(-10,10)/10)
                    humanoid:Move(randomDir)
                    wait(math.random(3,8))
                    humanoid:Move(Vector3.new(0,0,0))
                    wait(math.random(2,5))
                end
            end)
            sendWebhook("actions", "NPC mode activated")
        elseif not npcMode and humanoid then
            humanoid.WalkSpeed = currentSpeed
            humanoid.JumpPower = currentJumpPower
            humanoid.AutoRotate = true
            sendWebhook("actions", "NPC mode deactivated")
        end
        
    -- Touch Fling
    elseif command == "touchfling" and #args > 0 then
        local target = Players:FindFirstChild(args[1])
        if target and target.Character and rootPart and target.Character:FindFirstChild("HumanoidRootPart") then
            spawn(function()
                -- Method 1: AlignPosition fling
                local align = Instance.new("AlignPosition")
                align.Parent = rootPart
                align.MaxForce = 1000000
                align.Responsiveness = 200
                align.Target = target.Character.HumanoidRootPart
                wait(0.1)
                align:Destroy()
                
                -- Method 2: Velocity fling
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(1000, 500, 1000)
                bv.MaxForce = Vector3.new(40000, 40000, 40000)
                bv.Parent = target.Character.HumanoidRootPart
                wait(0.2)
                bv:Destroy()
            end)
            sendWebhook("actions", "Touch flung " .. args[1])
        end
        
    -- Jumppower change
    elseif command == "jumppower" and #args > 0 then
        local newPower = tonumber(args[1])
        if newPower and humanoid then
            currentJumpPower = newPower
            humanoid.JumpPower = newPower
            sendWebhook("status", string.format("📈 Jump power changed to %d", newPower))
        end
        
    -- Speed power change
    elseif command == "speed" and #args > 0 then
        local newSpeed = tonumber(args[1])
        if newSpeed and humanoid then
            currentSpeed = newSpeed
            humanoid.WalkSpeed = newSpeed
            sendWebhook("status", string.format("⚡ Speed changed to %d", newSpeed))
        end
        
    -- Respawn
    elseif command == "respawn" then
        local humanoid = char and char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0
            wait(2)
            Players.LocalPlayer:LoadCharacter()
            sendWebhook("deaths", "🔄 Manual respawn")
        end
        
    -- Leave
    elseif command == "leave" then
        sendWebhook("status", "👋 Alt leaving game")
        wait(1)
        Players.LocalPlayer:Destroy()
        
    -- Gravity change
    elseif command == "gravity" and #args > 0 then
        local newGravity = tonumber(args[1])
        if newGravity then
            Workspace.Gravity = newGravity
            sendWebhook("status", string.format("🌍 Gravity changed to %d", newGravity))
        end
        
    -- Anony player (make anonymous)
    elseif command == "anony" then
        anonyMode = not anonyMode
        if anonyMode and char then
            -- Hide name
            local head = char:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("BillboardGui")
                if billboard then
                    billboard.Enabled = false
                end
            end
            sendWebhook("actions", "Anonymous mode enabled")
        elseif not anonyMode and char then
            local head = char:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("BillboardGui")
                if billboard then
                    billboard.Enabled = true
                end
            end
            sendWebhook("actions", "Anonymous mode disabled")
        end
        
    -- Jerk off (funny movement)
    elseif command == "jerkoff" then
        jerkActive = not jerkActive
        if jerkActive and humanoid and rootPart then
            spawn(function()
                while jerkActive do
                    rootPart.CFrame = rootPart.CFrame * CFrame.Angles(math.rad(30), 0, 0)
                    wait(0.1)
                    rootPart.CFrame = rootPart.CFrame * CFrame.Angles(math.rad(-30), 0, 0)
                    wait(0.1)
                end
            end)
            sendWebhook("actions", "Jerk mode activated")
        else
            sendWebhook("actions", "Jerk mode deactivated")
        end
        
    -- Spasm
    elseif command == "spasm" then
        spasmActive = not spasmActive
        if spasmActive and rootPart then
            spawn(function()
                while spasmActive do
                    rootPart.CFrame = rootPart.CFrame * CFrame.Angles(
                        math.random(-50,50)/100,
                        math.random(-50,50)/100,
                        math.random(-50,50)/100
                    )
                    wait(0.05)
                end
            end)
            sendWebhook("actions", "Spasm mode activated")
        else
            sendWebhook("actions", "Spasm mode deactivated")
        end
        
    -- Lay
    elseif command == "lay" then
        if humanoid then
            humanoid.Sit = true
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(math.rad(90), 0, 0)
            sendWebhook("actions", "Laying down")
        end
        
    -- Sit
    elseif command == "sit" then
        if humanoid then
            humanoid.Sit = true
            sendWebhook("actions", "Sitting")
        end
        
    -- Help command
    elseif command == "help" then
        local helpMsg = [[
**Available Commands:**
• `follow [player]` - Follow a player
• `move [dir] [sec]` - Move direction
• `jump` - Single jump
• `loopjump [count]` - Loop jump
• `loopfollow [player]` - Loop follow
• `spin` - Start spinning
• `unspin` - Stop spinning
• `tp [player]` - Teleport to player
• `circle [player]` - Circle around player
• `chat [msg]` - Public chat
• `privatechat [player] [msg]` - Private chat
• `emote [type]` - Play emote
• `dance` - Dance
• `actnpc` - Toggle NPC mode
• `touchfling [player]` - Touch fling
• `jumppower [value]` - Change jump power
• `speed [value]` - Change speed
• `respawn` - Respawn alt
• `leave` - Leave game
• `gravity [value]` - Change gravity
• `anony` - Toggle anonymous
• `jerkoff` - Toggle jerk mode
• `spasm` - Toggle spasm
• `lay` - Lay down
• `sit` - Sit
• `status` - Check alt status
        ]]
        sendWebhook("status", helpMsg)
        
    elseif command == "status" then
        local statusMsg = string.format([[
**Alt Status:**
• Connected: %s
• Following: %s
• Spinning: %s
• NPC Mode: %s
• Speed: %d
• Jump Power: %d
• Position: %s
        ]],
        altConnected and "✅" or "❌",
        followTarget and followTarget.Name or "None",
        spinning and "✅" or "❌",
        npcMode and "✅" or "❌",
        currentSpeed,
        currentJumpPower,
        rootPart and tostring(rootPart.Position) or "Unknown"
        )
        sendWebhook("status", statusMsg)
    end
end

-- Chat listener with multiple methods
local function setupChatListeners()
    -- Method 1: Player Chatted event
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            player.Chatted:Connect(function(message)
                if message:sub(1, #cmdPrefix) == cmdPrefix then
                    local parts = {}
                    for word in message:gmatch("%S+") do
                        table.insert(parts, word)
                    end
                    
                    if #parts > 0 then
                        local command = parts[1]:sub(#cmdPrefix + 1):lower()
                        table.remove(parts, 1)
                        handleCommand(command, parts, player)
                    end
                else
                    -- Log public chat
                    local embed = {
                        {
                            ["title"] = "💬 Public Chat",
                            ["color"] = 5814783,
                            ["description"] = message,
                            ["fields"] = {
                                {
                                    ["name"] = "From",
                                    ["value"] = player.Name,
                                    ["inline"] = true
                                }
                            }
                        }
                    }
                    sendWebhook("chat_public", nil, embed)
                end
            end)
        end
    end
    
    -- Method 2: Handle new players
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            if message:sub(1, #cmdPrefix) == cmdPrefix then
                local parts = {}
                for word in message:gmatch("%S+") do
                    table.insert(parts, word)
                end
                
                if #parts > 0 then
                    local command = parts[1]:sub(#cmdPrefix + 1):lower()
                    table.remove(parts, 1)
                    handleCommand(command, parts, player)
                end
            else
                local embed = {
                    {
                        ["title"] = "💬 Public Chat",
                        ["color"] = 5814783,
                        ["description"] = message,
                        ["fields"] = {
                            {
                                ["name"] = "From",
                                ["value"] = player.Name,
                                ["inline"] = true
                            }
                        }
                    }
                }
                sendWebhook("chat_public", nil, embed)
            end
        end)
    end)
    
    -- Log player joins/leaves
    Players.PlayerAdded:Connect(function(player)
        local embed = {
            {
                ["title"] = "Player Joined",
                ["color"] = 3066993,
                ["description"] = player.Name,
                ["footer"] = {
                    ["text"] = "User ID: " .. player.UserId
                }
            }
        }
        sendWebhook("players", nil, embed)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        local embed = {
            {
                ["title"] = "Player Left",
                ["color"] = 15158332,
                ["description"] = player.Name
            }
        }
        sendWebhook("players", nil, embed)
    end)
end

-- Movement tracking
local lastPos = nil
RunService.Heartbeat:Connect(function()
    local char = Players.LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Track significant movement
    if lastPos and (root.Position - lastPos).Magnitude > 20 then
        local embed = {
            {
                ["title"] = "Significant Movement",
                ["color"] = 10181046,
                ["description"] = string.format("Moved from %s to %s", tostring(lastPos), tostring(root.Position)),
                ["timestamp"] = DateTime.now():ToIsoDate()
            }
        }
        sendWebhook("movement", nil, embed)
    end
    lastPos = root.Position
    
    -- Follow logic
    if followTarget and not loopFollowActive then
        local targetChar = followTarget.Character
        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
            local targetPos = targetChar.HumanoidRootPart.Position
            local direction = (targetPos - root.Position).Unit
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                if (targetPos - root.Position).Magnitude > 5 then
                    humanoid:Move(direction * currentSpeed)
                else
                    humanoid:Move(Vector3.new(0,0,0))
                end
            end
        end
    end
end)

-- Initialize
setupChatListeners()
sendWebhook("debug", "✅ Controller script initialized with 10 webhooks")
sendWebhook("status", "✅ **Alt Controller is online!**\nUse `"..cmdPrefix.."help` for commands")
