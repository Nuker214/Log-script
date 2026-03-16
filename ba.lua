-- Alt Account Script - Enhanced Monitoring with Long Embeds
-- Execute this on your alt account

local Webhooks = {
    ["status"] = "https://discord.com/api/webhooks/1483203506168135954/tAKlxOQG5pYXf4es7Gwdn1iyYivdFsaGFSjcUQYSnp2-i4UCfwvRy5WlgZHjvdHsta4l", -- Status updates
    ["errors"] = "https://discord.com/api/webhooks/1483203290316669142/B1xU_L5zsxB3Um_G-TKGuLH-_YRbvDbBBYYB231wVgFl6WGEIsZ6jkTYSrZrhK5RVY_9", -- Error logs
    ["deaths"] = "https://discord.com/api/webhooks/1483203350760521961/0WmoP7pVklwdrn2CJOV_bWMDkJtB3QIj-adYPgDC-EpIl9Z-hnNleUDN7Yi7zQkQN3QL", -- Death alerts
    ["chat_public"] = "https://discord.com/api/webhooks/1483203568281325839/5y-BwtJ5cjmb51kXsvxPwgeeJZtHyB36oMf8ourZtf4orVY8nBT6vgwZEWmzsVe3McBr", -- Public chat feed
    ["chat_private"] = "https://discord.com/api/webhooks/1483203542155137280/Emg65rUxrzSLpHKJ8_qtXEeafR_tUefYSWlpjCYvXcKiSBOJQIuUAmhsvMk6b2rQ1lrA", -- Private chat feed
    ["actions"] = "https://discord.com/api/webhooks/1483203400538525841/BUJFvfHgw_eV6qDs_fgGEH3GzFoelKQ7wTPBMAViYI4cW6nJSwl8x8eZCDjAY2LZYkDZ", -- All alt actions
    ["movement"] = "https://discord.com/api/webhooks/1483203228379119801/Ocajpg_NLYy2PcVUM5N-fYoF1WsQoAyu9tRwX_47Raxn35JqNV4uKpJjQs4b39RCFu5r", -- Movement tracking
    ["players"] = "https://discord.com/api/webhooks/1483203470713552926/oWFtB8WsQAXz8K4U1a1bUNtsP7aAfZXlo5Id7VAtoYlFB0yKdv5bVRKk_BkpRzQY_554", -- Player joins/leaves
    ["debug"] = "https://discord.com/api/webhooks/1483203590108479648/SM-E_6wUgaMjJnKGTsNViEqssLmc94JTcoP8vtrScyNxhLFIjQ4Z6-oUi1MIGLp5N7GM" -- Debug information
}


-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")

-- Tracking variables
local startTime = tick()
local lastPosition = nil
local lastLogTime = 0
local totalDistance = 0
local jumpCount = 0
local damageTaken = 0
local deaths = 0
local actionLog = {}

-- Function to send webhook with long embeds
local function sendWebhook(webhookName, content, embeds)
    local webhookURL = Webhooks[webhookName]
    if not webhookURL or webhookURL == "WEBHOOK_X_URL" then return end
    
    local data = {
        ["content"] = content,
        ["username"] = "Alt Account",
        ["avatar_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..Players.LocalPlayer.UserId.."&width=420&height=420&format=png"
    }
    
    if embeds then
        data["embeds"] = embeds
    end
    
    local success, err = pcall(function()
        local jsonData = HttpService:JSONEncode(data)
        HttpService:PostAsync(webhookURL, jsonData, Enum.HttpContentType.ApplicationJson)
    end)
end

-- Enhanced embed creator
local function createLongEmbed(title, description, color, fields, footer)
    local embed = {
        ["title"] = title,
        ["description"] = description,
        ["color"] = color,
        ["timestamp"] = DateTime.now():ToIsoDate(),
        ["footer"] = footer or {
            ["text"] = "Alt Account • " .. os.date("%Y-%m-%d %H:%M:%S"),
            ["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..Players.LocalPlayer.UserId.."&width=32&height=32&format=png"
        },
        ["author"] = {
            ["name"] = "Alt: " .. Players.LocalPlayer.Name,
            ["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..Players.LocalPlayer.UserId.."&width=32&height=32&format=png"
        }
    }
    
    if fields then
        embed["fields"] = fields
    end
    
    return {embed}
end

-- Track deaths with detailed embed
local function onDied()
    deaths = deaths + 1
    local char = Players.LocalPlayer.Character
    local position = char and char:FindFirstChild("HumanoidRootPart") and tostring(char.HumanoidRootPart.Position) or "Unknown"
    local killer = "Unknown"
    
    -- Try to find killer
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            local dist = player.Character:FindFirstChild("HumanoidRootPart") and 
                        (player.Character.HumanoidRootPart.Position - (char and char.HumanoidRootPart.Position or Vector3.new(0,0,0))).Magnitude or 9999
            if dist < 20 then
                killer = player.Name
            end
        end
    end
    
    local fields = {
        {
            ["name"] = "💀 ALT DIED",
            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            ["inline"] = false
        },
        {
            ["name"] = "Death Details",
            ["value"] = string.format("├ Time: %s\n├ Position: %s\n├ Death #: %d\n├ Killer: %s\n└ Distance from spawn: %.1f",
                os.date("%H:%M:%S"),
                position,
                deaths,
                killer,
                char and (char.HumanoidRootPart.Position - Vector3.new(0,0,0)).Magnitude or 0),
            ["inline"] = true
        },
        {
            ["name"] = "Session Statistics",
            ["value"] = string.format("├ Uptime: %d minutes\n├ Total Jumps: %d\n├ Damage Taken: %d\n├ Distance Traveled: %.1f\n└ Deaths: %d",
                math.floor((tick() - startTime) / 60),
                jumpCount,
                damageTaken,
                totalDistance,
                deaths),
            ["inline"] = true
        }
    }
    
    sendWebhook("deaths", nil, createLongEmbed("Alt Death", "Alt has died", 15158332, fields))
end

-- Track chat messages
local function onChatted(message, recipient)
    local fields = {
        {
            ["name"] = recipient and "📨 PRIVATE MESSAGE SENT" or "💬 PUBLIC CHAT SENT",
            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            ["inline"] = false
        },
        {
            ["name"] = "Message Details",
            ["value"] = string.format("├ From: %s\n├ To: %s\n├ Length: %d\n├ Words: %d\n├ Time: %s\n└ Content:```%s```",
                Players.LocalPlayer.Name,
                recipient or "All",
                #message,
                #message:gmatch("%S+"),
                os.date("%H:%M:%S"),
                message),
            ["inline"] = false
        },
        {
            ["name"] = "Sender Status",
            ["value"] = string.format("├ Position: %s\n├ Health: %.1f/%.1f\n├ Walkspeed: %.1f\n├ Jump Power: %.1f\n└ Nearby Players: %d",
                Players.LocalPlayer.Character and tostring(Players.LocalPlayer.Character.HumanoidRootPart.Position) or "Unknown",
                Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and Players.LocalPlayer.Character.Humanoid.Health or 0,
                Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and Players.LocalPlayer.Character.Humanoid.MaxHealth or 100,
                Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and Players.LocalPlayer.Character.Humanoid.WalkSpeed or 16,
                Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and Players.LocalPlayer.Character.Humanoid.JumpPower or 50,
                #Players:GetPlayers() - 1),
            ["inline"] = true
        }
    }
    
    if recipient then
        sendWebhook("chat_private", nil, createLongEmbed("Private Message", "PM sent", 15844367, fields))
    else
        sendWebhook("chat_public", nil, createLongEmbed("Public Message", "Chat sent", 5814783, fields))
    end
end

Players.LocalPlayer.Chatted:Connect(onChatted)

-- Track private messages
local function hookPrivateMessages()
    local chatService = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatService and chatService:FindFirstChild("OnNewMessage") then
        chatService.OnNewMessage.OnClientEvent:Connect(function(data)
            if data.FromSpeaker and data.ToSpeaker then
                local fields = {
                    {
                        ["name"] = "📨 PRIVATE MESSAGE RECEIVED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Message Details",
                        ["value"] = string.format("├ From: %s\n├ To: %s\n├ Time: %s\n└ Content:```%s```",
                            data.FromSpeaker,
                            data.ToSpeaker,
                            os.date("%H:%M:%S"),
                            data.Message or "No content"),
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Sender Info",
                        ["value"] = string.format("├ Display Name: %s\n├ Account Age: %d\n└ Status: Active",
                            Players[data.FromSpeaker] and Players[data.FromSpeaker].DisplayName or "Unknown",
                            Players[data.FromSpeaker] and Players[data.FromSpeaker].AccountAge or 0),
                        ["inline"] = true
                    }
                }
                
                sendWebhook("chat_private", nil, createLongEmbed("PM Received", "Private message detected", 15844367, fields))
            end
        end)
    end
end
pcall(hookPrivateMessages)

-- Track movement with detailed logging
RunService.Heartbeat:Connect(function()
    local char = Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        local currentPos = char.HumanoidRootPart.Position
        local currentTime = tick()
        
        -- Calculate distance traveled
        if lastPosition then
            local distance = (currentPos - lastPosition).Magnitude
            if distance < 100 then -- Ignore teleports
                totalDistance = totalDistance + distance
            end
            
            -- Log significant movement
            if distance > 20 and currentTime - lastLogTime > 10 then
                local fields = {
                    {
                        ["name"] = "📍 SIGNIFICANT MOVEMENT DETECTED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Movement Details",
                        ["value"] = string.format("├ From: %s\n├ To: %s\n├ Distance: %.1f studs\n├ Time: %s\n├ Speed: %.1f studs/sec\n└ Total Distance: %.1f",
                            tostring(lastPosition):gsub(" ", ", "),
                            tostring(currentPos):gsub(" ", ", "),
                            distance,
                            os.date("%H:%M:%S"),
                            char.Humanoid.WalkSpeed,
                            totalDistance),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Current Status",
                        ["value"] = string.format("├ Health: %.1f/%.1f\n├ Position Y: %.1f\n├ Gravity: %.1f\n└ Jumping: %s",
                            char.Humanoid.Health,
                            char.Humanoid.MaxHealth,
                            currentPos.Y,
                            Workspace.Gravity,
                            char.Humanoid.Jump and "Yes" or "No"),
                        ["inline"] = true
                    }
                }
                
                sendWebhook("movement", nil, createLongEmbed("Movement Alert", "Alt moved significantly", 16776960, fields))
                lastLogTime = currentTime
            end
        end
        
        lastPosition = currentPos
    end
end)

-- Track jumps
local function onJump()
    jumpCount = jumpCount + 1
    
    local fields = {
        {
            ["name"] = "🦘 JUMP DETECTED",
            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            ["inline"] = false
        },
        {
            ["name"] = "Jump Details",
            ["value"] = string.format("├ Jump #: %d\n├ Time: %s\n├ Position: %s\n├ Jump Power: %.1f\n└ Total Jumps: %d",
                jumpCount,
                os.date("%H:%M:%S"),
                Players.LocalPlayer.Character and tostring(Players.LocalPlayer.Character.HumanoidRootPart.Position) or "Unknown",
                Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and Players.LocalPlayer.Character.Humanoid.JumpPower or 50,
                jumpCount),
            ["inline"] = true
        }
    }
    
    sendWebhook("debug", nil, createLongEmbed("Jump Log", "Jump recorded", 10181046, fields))
end

-- Connect jump detection
local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
if char and char:FindFirstChild("Humanoid") then
    char.Humanoid.Jumping:Connect(onJump)
end

Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
    newChar.Humanoid.Jumping:Connect(onJump)
    newChar.Humanoid.Died:Connect(onDied)
    
    -- Track health changes
    newChar.Humanoid.HealthChanged:Connect(function(health)
        if health < newChar.Humanoid.MaxHealth then
            damageTaken = damageTaken + (newChar.Humanoid.MaxHealth - health)
        end
        
        if health < 20 and health > 0 then
            local fields = {
                {
                    ["name"] = "⚠️ LOW HEALTH WARNING",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Health Details",
                    ["value"] = string.format("├ Current Health: %.1f\n├ Max Health: %.1f\n├ Percentage: %.1f%%\n├ Position: %s\n├ Time: %s\n└ Damage Taken: %d",
                        health,
                        newChar.Humanoid.MaxHealth,
                        (health / newChar.Humanoid.MaxHealth) * 100,
                        tostring(newChar.HumanoidRootPart.Position),
                        os.date("%H:%M:%S"),
                        damageTaken),
                    ["inline"] = true
                }
            }
            
            sendWebhook("debug", nil, createLongEmbed("Low Health", "Alt at critical health", 15158332, fields))
        end
    end)
end)

-- Track player interactions with detailed embeds
Players.PlayerAdded:Connect(function(player)
    local fields = {
        {
            ["name"] = "🟢 PLAYER JOINED SERVER",
            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            ["inline"] = false
        },
        {
            ["name"] = "Player Information",
            ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n├ Account Age: %d days\n├ Join Time: %s\n└ Total Players: %d",
                player.Name,
                player.DisplayName,
                player.UserId,
                player.AccountAge,
                os.date("%H:%M:%S"),
                #Players:GetPlayers()),
            ["inline"] = true
        },
        {
            ["name"] = "Distance from Alt",
            ["value"] = Players.LocalPlayer.Character and player.Character and 
                       string.format("%.1f studs", (Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude) or "Unknown",
            ["inline"] = true
        }
    }
    
    sendWebhook("players", nil, createLongEmbed("Player Joined", player.Name .. " joined", 3066993, fields))
    
    -- Track their chat
    player.Chatted:Connect(function(message)
        if player ~= Players.LocalPlayer then
            local chatFields = {
                {
                    ["name"] = "💬 PLAYER CHAT DETECTED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Message Details",
                    ["value"] = string.format("├ Speaker: %s\n├ Display Name: %s\n├ User ID: %d\n├ Time: %s\n├ Position: %s\n└ Content:```%s```",
                        player.Name,
                        player.DisplayName,
                        player.UserId,
                        os.date("%H:%M:%S"),
                        player.Character and tostring(player.Character.HumanoidRootPart.Position) or "Unknown",
                        message),
                    ["inline"] = false
                },
                {
                    ["name"] = "Speaker Status",
                    ["value"] = string.format("├ Account Age: %d\n├ Health: %s\n├ Distance: %s\n└ In Game: %s",
                        player.AccountAge,
                        player.Character and player.Character.Humanoid and string.format("%.1f/%.1f", player.Character.Humanoid.Health, player.Character.Humanoid.MaxHealth) or "Unknown",
                        Players.LocalPlayer.Character and player.Character and string.format("%.1f", (Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude) or "Unknown",
                        player.Character and "Yes" or "No"),
                    ["inline"] = true
                }
            }
            
            sendWebhook("chat_public", nil, createLongEmbed("Chat Message", "From: " .. player.Name, 5814783, chatFields))
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    local fields = {
        {
            ["name"] = "🔴 PLAYER LEFT SERVER",
            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            ["inline"] = false
        },
        {
            ["name"] = "Player Information",
            ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n├ Account Age: %d days\n├ Time Online: %d minutes\n└ Total Players: %d",
                player.Name,
                player.DisplayName,
                player.UserId,
                player.AccountAge,
                math.floor((tick() - player.JoinTime) / 60),
                #Players:GetPlayers()),
            ["inline"] = true
        },
        {
            ["name"] = "Session Summary",
            ["value"] = string.format("├ Join Time: %s\n├ Leave Time: %s\n└ Session Length: %d minutes",
                os.date("%H:%M:%S", player.JoinTime),
                os.date("%H:%M:%S"),
                math.floor((tick() - player.JoinTime) / 60)),
            ["inline"] = true
        }
    }
    
    sendWebhook("players", nil, createLongEmbed("Player Left", player.Name .. " left", 15158332, fields))
end)

-- Detailed periodic status updates
spawn(function()
    while true do
        wait(60) -- Every minute
        
        local char = Players.LocalPlayer.Character
        local humanoid = char and char:FindFirstChild("Humanoid")
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        
        local nearbyPlayers = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character and rootPart then
                local dist = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                if dist < 50 then
                    nearbyPlayers = nearbyPlayers + 1
                end
            end
        end
        
        local fields = {
            {
                ["name"] = "📊 ALT STATUS UPDATE",
                ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                ["inline"] = false
            },
            {
                ["name"] = "Session Statistics",
                ["value"] = string.format("├ Uptime: %d minutes\n├ Total Jumps: %d\n├ Damage Taken: %d\n├ Total Distance: %.1f studs\n├ Deaths: %d\n└ Commands: %d",
                    math.floor((tick() - startTime) / 60),
                    jumpCount,
                    damageTaken,
                    totalDistance,
                    deaths,
                    #actionLog),
                ["inline"] = true
            },
            {
                ["name"] = "Current Status",
                ["value"] = string.format("├ Position: %s\n├ Health: %s\n├ Walkspeed: %.1f\n├ Jump Power: %.1f\n├ Gravity: %.1f\n└ Nearby Players: %d",
                    rootPart and tostring(rootPart.Position) or "Unknown",
                    humanoid and string.format("%.1f/%.1f", humanoid.Health, humanoid.MaxHealth) or "Unknown",
                    humanoid and humanoid.WalkSpeed or 16,
                    humanoid and humanoid.JumpPower or 50,
                    Workspace.Gravity,
                    nearbyPlayers),
                ["inline"] = true
            },
            {
                ["name"] = "Server Information",
                ["value"] = string.format("├ Game: %s\n├ Place ID: %d\n├ Server ID: %s\n├ Players: %d/%d\n├ Ping: %dms\n└ Time: %s",
                    game.Name,
                    game.PlaceId,
                    game.JobId:sub(1, 8) .. "...",
                    #Players:GetPlayers(),
                    Players.MaxPlayers,
                    math.floor(Stats:GetNetworkPing() * 1000),
                    os.date("%H:%M:%S")),
                ["inline"] = false
            }
        }
        
        sendWebhook("status", nil, createLongEmbed("Periodic Update", "Alt status report", 10181046, fields))
    end
end)

-- Initial join embed
local joinFields = {
    {
        ["name"] = "✅ ALT ACCOUNT ONLINE",
        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        ["inline"] = false
    },
    {
        ["name"] = "Account Information",
        ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n├ Account Age: %d days\n├ Join Time: %s\n└ Membership: %s",
            Players.LocalPlayer.Name,
            Players.LocalPlayer.DisplayName,
            Players.LocalPlayer.UserId,
            Players.LocalPlayer.AccountAge,
            os.date("%H:%M:%S"),
            Players.LocalPlayer.MembershipType == Enum.MembershipType.None and "None" or tostring(Players.LocalPlayer.MembershipType)),
        ["inline"] = true
    },
    {
        ["name"] = "Server Information",
        ["value"] = string.format("├ Game: %s\n├ Place ID: %d\n├ Server ID: %s\n├ Players: %d\n└ Time: %s",
            game.Name,
            game.PlaceId,
            game.JobId,
            #Players:GetPlayers(),
            os.date("%Y-%m-%d %H:%M:%S")),
        ["inline"] = true
    },
    {
        ["name"] = "Monitoring Active",
        ["value"] = "Death Alerts | Chat Logs | Movement Tracking | Player Events | Status Updates",
        ["inline"] = false
    }
}

sendWebhook("status", nil, createLongEmbed("Alt Online", "Monitoring started", 3066993, joinFields))
