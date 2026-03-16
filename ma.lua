local Webhooks = {
    ["commands"] = "https://discord.com/api/webhooks/1483203347874975927/rWkk0gFt5ks8_Bcekzc8KIe7x12uuUvSXEBI85QPX_Me34JeQzkum_pOYfTABDyEZbRs", -- All commands executed
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

local altName = "AltAccountName" -- Your alt's username
local cmdPrefix = "!" -- Command prefix

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local NetworkClient = game:GetService("NetworkClient")

-- Connection status
local altConnected = false
local followTarget = nil
local circleTarget = nil
local npcMode = false
local isSpinning = false
local loopJumping = false
local loopFollowing = false
local anonymousMode = false
local originalName = ""
local originalDisplayName = ""
local commandHistory = {}
local actionHistory = {}

-- Character modification tracking
local originalWalkspeed = 16
local originalJumppower = 50
local currentWalkspeed = 16
local currentJumppower = 50
local originalGravity = 196.2

-- Function to send Discord webhook with long embeds
local function sendWebhook(webhookName, content, embeds)
    local webhookURL = Webhooks[webhookName]
    if not webhookURL or webhookURL == "WEBHOOK_X_URL" then return end
    
    -- Split long embeds if needed (Discord limit is 6000 characters per embed)
    if embeds and #HttpService:JSONEncode(embeds) > 6000 then
        -- Split into multiple embeds
        local chunks = {}
        local currentChunk = {}
        local currentSize = 0
        
        for _, embed in ipairs(embeds) do
            local embedStr = HttpService:JSONEncode(embed)
            if currentSize + #embedStr > 6000 then
                table.insert(chunks, {chunk})
                currentChunk = {embed}
                currentSize = #embedStr
            else
                table.insert(currentChunk, embed)
                currentSize = currentSize + #embedStr
            end
        end
        
        if #currentChunk > 0 then
            table.insert(chunks, currentChunk)
        end
        
        -- Send each chunk
        for _, chunk in ipairs(chunks) do
            local data = {
                ["content"] = content,
                ["username"] = "Alt Controller",
                ["avatar_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..Players.LocalPlayer.UserId.."&width=420&height=420&format=png",
                ["embeds"] = chunk
            }
            
            local success, err = pcall(function()
                local jsonData = HttpService:JSONEncode(data)
                HttpService:PostAsync(webhookURL, jsonData, Enum.HttpContentType.ApplicationJson)
            end)
        end
    else
        local data = {
            ["content"] = content,
            ["username"] = "Alt Controller",
            ["avatar_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..Players.LocalPlayer.UserId.."&width=420&height=420&format=png"
        }
        
        if embeds then
            data["embeds"] = embeds
        end
        
        local success, err = pcall(function()
            local jsonData = HttpService:JSONEncode(data)
            HttpService:PostAsync(webhookURL, jsonData, Enum.HttpContentType.ApplicationJson)
        end)
        
        if not success then
            warn("Failed to send webhook: " .. tostring(err))
        end
    end
end

-- Enhanced embed creator with LONG detailed embeds
local function createLongEmbed(title, description, color, fields, footer, author, image, thumbnail)
    local embed = {
        ["title"] = title,
        ["description"] = description,
        ["color"] = color,
        ["timestamp"] = DateTime.now():ToIsoDate(),
        ["footer"] = footer or {
            ["text"] = "Alt Controller v3.0 • " .. os.date("%Y-%m-%d %H:%M:%S"),
            ["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..Players.LocalPlayer.UserId.."&width=32&height=32&format=png"
        },
        ["author"] = author or {
            ["name"] = "Alt Controller System",
            ["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..Players.LocalPlayer.UserId.."&width=32&height=32&format=png"
        }
    }
    
    if fields then
        embed["fields"] = fields
    end
    
    if image then
        embed["image"] = image
    end
    
    if thumbnail then
        embed["thumbnail"] = thumbnail
    end
    
    return {embed}
end

-- Function to get detailed player info
local function getDetailedPlayerInfo(player)
    local char = player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    
    local info = {
        ["Basic Info"] = {
            ["Username"] = player.Name,
            ["Display Name"] = player.DisplayName,
            ["User ID"] = tostring(player.UserId),
            ["Account Age"] = tostring(player.AccountAge) .. " days",
            ["Membership"] = player.MembershipType == Enum.MembershipType.None and "None" or tostring(player.MembershipType),
            ["Join Time"] = os.date("%H:%M:%S", player.JoinTime)
        },
        ["Character Status"] = {
            ["In Game"] = char and "Yes" or "No",
            ["Health"] = humanoid and string.format("%.1f/%.1f", humanoid.Health, humanoid.MaxHealth) or "N/A",
            ["Position"] = rootPart and string.format("X: %.1f, Y: %.1f, Z: %.1f", rootPart.Position.X, rootPart.Position.Y, rootPart.Position.Z) or "N/A",
            ["Walkspeed"] = humanoid and string.format("%.1f", humanoid.WalkSpeed) or "N/A",
            ["Jump Power"] = humanoid and string.format("%.1f", humanoid.JumpPower) or "N/A",
            ["Gravity"] = char and Workspace.Gravity ~= 196.2 and string.format("%.1f", Workspace.Gravity) or "Default"
        },
        ["Network Info"] = {
            ["Ping"] = tostring(math.floor(player:GetNetworkPing() * 1000)) .. "ms",
            ["Distance from Alt"] = Players.LocalPlayer.Character and rootPart and string.format("%.1f", (Players.LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude) or "Unknown"
        }
    }
    
    return info
end

-- Function to create a long status embed
local function createLongStatusEmbed()
    local char = Players.LocalPlayer.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    
    local fields = {
        {
            ["name"] = "📊 SYSTEM STATUS",
            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━",
            ["inline"] = false
        },
        {
            ["name"] = "Connection",
            ["value"] = string.format("├ Connected: ✅\n├ Alt Name: %s\n├ Command Prefix: `%s`\n├ Uptime: %s\n└ Commands Run: %d",
                altName, cmdPrefix, os.date("%H:%M:%S"), #commandHistory),
            ["inline"] = true
        },
        {
            ["name"] = "Performance",
            ["value"] = string.format("├ FPS: %d\n├ Memory: %.1f MB\n├ Ping: %dms\n├ Players: %d\n└ Server ID: %s",
                math.floor(1 / RunService.Heartbeat:Wait()), 
                Stats:GetMemoryUsageMbForTag("Total") or 0,
                math.floor(Stats:GetNetworkPing() * 1000),
                #Players:GetPlayers(),
                game.JobId:sub(1, 8)),
            ["inline"] = true
        },
        {
            ["name"] = "🎮 CHARACTER STATUS",
            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━",
            ["inline"] = false
        },
        {
            ["name"] = "Health & Position",
            ["value"] = string.format("├ Health: %s%.1f/%.1f%s\n├ Position:\n│  X: %.1f\n│  Y: %.1f\n│  Z: %.1f\n└ Distance from spawn: %.1f",
                humanoid and humanoid.Health < 20 and "⚠️ " or "❤️ ",
                humanoid and humanoid.Health or 0,
                humanoid and humanoid.MaxHealth or 100,
                humanoid and humanoid.Health == 0 and " 💀" or "",
                rootPart and rootPart.Position.X or 0,
                rootPart and rootPart.Position.Y or 0,
                rootPart and rootPart.Position.Z or 0,
                rootPart and (rootPart.Position - Vector3.new(0,0,0)).Magnitude or 0),
            ["inline"] = true
        },
        {
            ["name"] = "Movement Stats",
            ["value"] = string.format("├ Walkspeed: %.1f %s\n├ Jump Power: %.1f %s\n├ Gravity: %.1f %s\n├ Auto Rotate: %s\n└ NPC Mode: %s",
                humanoid and humanoid.WalkSpeed or 16,
                humanoid and humanoid.WalkSpeed ~= 16 and "⚡" or "",
                humanoid and humanoid.JumpPower or 50,
                humanoid and humanoid.JumpPower ~= 50 and "📈" or "",
                Workspace.Gravity,
                Workspace.Gravity ~= 196.2 and "🌍" or "",
                humanoid and tostring(humanoid.AutoRotate) or "true",
                npcMode and "✅" or "❌"),
            ["inline"] = true
        },
        {
            ["name"] = "⚡ ACTIVE MODES",
            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━",
            ["inline"] = false
        },
        {
            ["name"] = "Current States",
            ["value"] = string.format("├ Following: %s\n├ Circling: %s\n├ Spinning: %s\n├ Loop Jumping: %s\n├ Loop Following: %s\n├ Anonymous: %s\n├ Godmode: %s\n└ Noclip: %s",
                followTarget and followTarget.Name or "None",
                circleTarget and circleTarget.Name or "None",
                isSpinning and "✅" or "❌",
                loopJumping and "✅" or "❌",
                loopFollowing and "✅" or "❌",
                anonymousMode and "✅" or "❌",
                humanoid and humanoid.MaxHealth > 100 and "✅" or "❌",
                char and char:FindFirstChild("HumanoidRootPart") and not char.HumanoidRootPart.CanCollide and "✅" or "❌"),
            ["inline"] = true
        },
        {
            ["name"] = "Target Info",
            ["value"] = followTarget and string.format("├ Target: %s\n├ Distance: %.1f\n├ Health: %.1f\n└ Following: %s",
                followTarget.Name,
                followTarget.Character and rootPart and (followTarget.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude or 0,
                followTarget.Character and followTarget.Character.Humanoid and followTarget.Character.Humanoid.Health or 0,
                loopFollowing and "Loop" or "Normal") or "No target",
            ["inline"] = true
        },
        {
            ["name"] = "📜 RECENT COMMANDS",
            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━",
            ["inline"] = false
        }
    }
    
    -- Add recent commands
    local recentCommands = ""
    for i = math.max(1, #commandHistory - 4), #commandHistory do
        local cmd = commandHistory[i]
        if cmd then
            recentCommands = recentCommands .. string.format("├ `%s` - %s ago\n", cmd.command, os.date("%M:%S", cmd.time))
        end
    end
    if recentCommands == "" then
        recentCommands = "├ No recent commands\n"
    end
    
    table.insert(fields, {
        ["name"] = "Last 5 Commands",
        ["value"] = recentCommands .. "└ Use !history for more",
        ["inline"] = false
    })
    
    -- Add server info
    table.insert(fields, {
        ["name"] = "🌐 SERVER INFO",
        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━",
        ["inline"] = false
    })
    
    table.insert(fields, {
        ["name"] = "Details",
        ["value"] = string.format("├ Game: %s\n├ Place ID: %d\n├ Server ID: %s\n├ Players: %d/%d\n├ Respawn Time: %s\n└ Network Mode: %s",
            game.Name,
            game.PlaceId,
            game.JobId,
            #Players:GetPlayers(),
            Players.MaxPlayers,
            os.date("%H:%M:%S", Players.RespawnTime or 0),
            NetworkClient and tostring(NetworkClient.NetworkMode) or "Unknown"),
        ["inline"] = false
    })
    
    return fields
end

-- Command handler with 30+ commands and long embeds
local commands = {
    -- Basic Movement Commands (1-5)
    ["follow"] = function(args, speaker)
        if #args < 1 then
            sendWebhook("commands", "❌ Usage: !follow [playername]")
            return
        end
        local targetName = args[1]
        local target = Players:FindFirstChild(targetName)
        
        if target then
            followTarget = target
            table.insert(commandHistory, {command = "follow " .. targetName, time = tick()})
            
            local fields = {
                {
                    ["name"] = "🎯 FOLLOW COMMAND EXECUTED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Target Information",
                    ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n├ Account Age: %d days\n├ Position: %s\n├ Health: %s\n└ Distance: %.1f",
                        target.Name,
                        target.DisplayName,
                        target.UserId,
                        target.AccountAge,
                        target.Character and tostring(target.Character.HumanoidRootPart.Position) or "Unknown",
                        target.Character and target.Character.Humanoid and string.format("%.1f/%.1f", target.Character.Humanoid.Health, target.Character.Humanoid.MaxHealth) or "Unknown",
                        Players.LocalPlayer.Character and target.Character and (Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude or 0),
                    ["inline"] = true
                },
                {
                    ["name"] = "Executor Information",
                    ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n└ Time: %s",
                        speaker.Name,
                        speaker.DisplayName,
                        speaker.UserId,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Follow Settings",
                    ["value"] = string.format("├ Mode: %s\n├ Distance: Auto-adjusting\n├ Speed: %.1f\n└ Status: Active",
                        loopFollowing and "Loop Following" or "Normal Following",
                        Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and Players.LocalPlayer.Character.Humanoid.WalkSpeed or 16),
                    ["inline"] = false
                }
            }
            
            sendWebhook("commands", nil, createLongEmbed("Follow Command", "Now tracking player: " .. targetName, 5814783, fields))
            sendWebhook("status", "✅ Now following: " .. targetName)
        end
    end,
    
    ["move"] = function(args, speaker)
        if #args < 2 then
            sendWebhook("commands", "❌ Usage: !move [direction] [seconds]")
            return
        end
        local direction = args[1]:lower()
        local duration = tonumber(args[2]) or 2
        
        local moveVector = Vector3.new(0,0,0)
        local directionNames = {forward = "Forward", back = "Backward", left = "Left", right = "Right"}
        local directionName = directionNames[direction] or direction
        
        if direction == "forward" then moveVector = Workspace.CurrentCamera.CFrame.LookVector * 16
        elseif direction == "back" then moveVector = -Workspace.CurrentCamera.CFrame.LookVector * 16
        elseif direction == "left" then moveVector = -Workspace.CurrentCamera.CFrame.RightVector * 16
        elseif direction == "right" then moveVector = Workspace.CurrentCamera.CFrame.RightVector * 16
        end
        
        table.insert(commandHistory, {command = "move " .. direction .. " " .. duration, time = tick()})
        
        spawn(function()
            local startTime = tick()
            local startPos = Players.LocalPlayer.Character and Players.LocalPlayer.Character.HumanoidRootPart and Players.LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(0,0,0)
            
            while tick() - startTime < duration do
                local char = Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:Move(moveVector)
                end
                RunService.Heartbeat:Wait()
            end
            
            local endPos = Players.LocalPlayer.Character and Players.LocalPlayer.Character.HumanoidRootPart and Players.LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(0,0,0)
            local distance = (endPos - startPos).Magnitude
            
            local fields = {
                {
                    ["name"] = "🚶 MOVEMENT COMMAND EXECUTED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Movement Details",
                    ["value"] = string.format("├ Direction: %s\n├ Duration: %d seconds\n├ Speed: %.1f\n├ Start Position: %s\n├ End Position: %s\n└ Distance Traveled: %.1f",
                        directionName,
                        duration,
                        16,
                        tostring(startPos):gsub(" ", ", "),
                        tostring(endPos):gsub(" ", ", "),
                        distance),
                    ["inline"] = true
                },
                {
                    ["name"] = "Movement Vector",
                    ["value"] = string.format("├ X: %.2f\n├ Y: %.2f\n└ Z: %.2f",
                        moveVector.X,
                        moveVector.Y,
                        moveVector.Z),
                    ["inline"] = true
                },
                {
                    ["name"] = "Executor",
                    ["value"] = string.format("├ Username: %s\n└ Time: %s",
                        speaker.Name,
                        os.date("%H:%M:%S")),
                    ["inline"] = false
                }
            }
            
            sendWebhook("movement", nil, createLongEmbed("Movement Executed", "Alt moved " .. directionName, 16776960, fields))
        end)
    end,
    
    ["jump"] = function(args, speaker)
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Jump = true
            table.insert(commandHistory, {command = "jump", time = tick()})
            
            local fields = {
                {
                    ["name"] = "🦘 JUMP COMMAND EXECUTED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Jump Details",
                    ["value"] = string.format("├ Jump Power: %.1f\n├ Position: %s\n├ Height at Jump: %.1f\n└ Time: %s",
                        char.Humanoid.JumpPower,
                        tostring(char.HumanoidRootPart.Position),
                        char.HumanoidRootPart.Position.Y,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Executor",
                    ["value"] = string.format("├ Username: %s\n└ User ID: %d",
                        speaker.Name,
                        speaker.UserId),
                    ["inline"] = true
                }
            }
            
            sendWebhook("actions", nil, createLongEmbed("Jump Action", "Alt jumped", 16776960, fields))
        end
    end,
    
    ["loopjump"] = function(args, speaker)
        local count = tonumber(args[1]) or 10
        loopJumping = true
        table.insert(commandHistory, {command = "loopjump " .. count, time = tick()})
        
        spawn(function()
            local jumped = 0
            local startTime = tick()
            local jumpTimes = {}
            
            while loopJumping and jumped < count do
                local char = Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.Jump = true
                    table.insert(jumpTimes, tick())
                end
                wait(0.3)
                jumped = jumped + 1
            end
            loopJumping = false
            
            local totalTime = tick() - startTime
            local avgJumpTime = totalTime / jumped
            
            local fields = {
                {
                    ["name"] = "🔄 LOOP JUMP COMPLETED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Jump Statistics",
                    ["value"] = string.format("├ Total Jumps: %d\n├ Duration: %.2f seconds\n├ Average Jump Rate: %.2f jumps/sec\n├ Start Time: %s\n└ End Time: %s",
                        jumped,
                        totalTime,
                        jumped / totalTime,
                        os.date("%H:%M:%S", startTime),
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Jump Details",
                    ["value"] = string.format("├ Jump Power Used: %.1f\n├ Final Position: %s\n└ Height Achieved: %.1f",
                        Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and Players.LocalPlayer.Character.Humanoid.JumpPower or 50,
                        Players.LocalPlayer.Character and tostring(Players.LocalPlayer.Character.HumanoidRootPart.Position) or "Unknown",
                        Players.LocalPlayer.Character and Players.LocalPlayer.Character.HumanoidRootPart and Players.LocalPlayer.Character.HumanoidRootPart.Position.Y or 0),
                    ["inline"] = true
                },
                {
                    ["name"] = "Executor",
                    ["value"] = string.format("├ Username: %s\n└ Time: %s",
                        speaker.Name,
                        os.date("%H:%M:%S")),
                    ["inline"] = false
                }
            }
            
            sendWebhook("actions", nil, createLongEmbed("Loop Jump Complete", "Performed " .. jumped .. " jumps", 16776960, fields))
        end)
        
        sendWebhook("status", "🔄 Loop jumping started (" .. count .. " jumps)")
    end,
    
    ["loopfollow"] = function(args, speaker)
        if #args < 1 then
            sendWebhook("commands", "❌ Usage: !loopfollow [playername]")
            return
        end
        local targetName = args[1]
        local target = Players:FindFirstChild(targetName)
        
        if target then
            loopFollowing = true
            followTarget = target
            table.insert(commandHistory, {command = "loopfollow " .. targetName, time = tick()})
            
            local fields = {
                {
                    ["name"] = "🔄 LOOP FOLLOW ACTIVATED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Target Information",
                    ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n├ Account Age: %d\n├ Current Position: %s\n├ Current Health: %s\n└ Distance: %.1f",
                        target.Name,
                        target.DisplayName,
                        target.UserId,
                        target.AccountAge,
                        target.Character and tostring(target.Character.HumanoidRootPart.Position) or "Unknown",
                        target.Character and target.Character.Humanoid and string.format("%.1f/%.1f", target.Character.Humanoid.Health, target.Character.Humanoid.MaxHealth) or "Unknown",
                        Players.LocalPlayer.Character and target.Character and (Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude or 0),
                    ["inline"] = true
                },
                {
                    ["name"] = "Follow Settings",
                    ["value"] = string.format("├ Mode: Loop Follow\n├ Update Rate: 10Hz\n├ Min Distance: 5 studs\n├ Current Speed: %.1f\n└ Status: Active",
                        Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and Players.LocalPlayer.Character.Humanoid.WalkSpeed or 16),
                    ["inline"] = true
                },
                {
                    ["name"] = "Loop Parameters",
                    ["value"] = string.format("├ Start Time: %s\n├ Target Distance: Auto-adjusting\n└ Max Follow Range: Unlimited",
                        os.date("%H:%M:%S")),
                    ["inline"] = false
                }
            }
            
            sendWebhook("commands", nil, createLongEmbed("Loop Follow Command", "Now loop following: " .. targetName, 5814783, fields))
            sendWebhook("status", "🔄 Loop following " .. targetName)
        end
    end,
    
    -- Rotation Commands (6-7)
    ["spin"] = function(args, speaker)
        isSpinning = true
        local speed = tonumber(args[1]) or 10
        table.insert(commandHistory, {command = "spin " .. speed, time = tick()})
        
        spawn(function()
            local char = Players.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local startCFrame = char.HumanoidRootPart.CFrame
                local rotations = 0
                local startTime = tick()
                
                while isSpinning do
                    char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(speed), 0)
                    rotations = rotations + (speed / 360)
                    wait(0.03)
                end
                
                local totalTime = tick() - startTime
                local fields = {
                    {
                        ["name"] = "🌀 SPIN COMPLETED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Spin Statistics",
                        ["value"] = string.format("├ Total Rotations: %.2f\n├ Duration: %.2f seconds\n├ Speed: %d degrees/step\n├ Start Time: %s\n└ End Time: %s",
                            rotations,
                            totalTime,
                            speed,
                            os.date("%H:%M:%S", startTime),
                            os.date("%H:%M:%S")),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Position Change",
                        ["value"] = string.format("├ Start Position: %s\n├ End Position: %s\n└ Movement: %s",
                            tostring(startCFrame.Position),
                            tostring(char.HumanoidRootPart.CFrame.Position),
                            (char.HumanoidRootPart.CFrame.Position - startCFrame.Position).Magnitude < 0.1 and "None" or "Moved"),
                        ["inline"] = true
                    }
                }
                
                sendWebhook("actions", nil, createLongEmbed("Spin Complete", "Alt stopped spinning", 16776960, fields))
            end
        end)
        
        sendWebhook("actions", "🌀 Spinning started (speed: " .. speed .. ")")
    end,
    
    ["unspin"] = function(args, speaker)
        isSpinning = false
        table.insert(commandHistory, {command = "unspin", time = tick()})
        sendWebhook("actions", "⏹️ Spinning stopped")
    end,
    
    -- Teleport Commands (8-9)
    ["tp"] = function(args, speaker)
        if #args < 1 then
            sendWebhook("commands", "❌ Usage: !tp [playername]")
            return
        end
        local target = Players:FindFirstChild(args[1])
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local char = Players.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local startPos = char.HumanoidRootPart.Position
                local targetPos = target.Character.HumanoidRootPart.Position
                local distance = (targetPos - startPos).Magnitude
                
                char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
                
                table.insert(commandHistory, {command = "tp " .. args[1], time = tick()})
                
                local fields = {
                    {
                        ["name"] = "✨ TELEPORT COMMAND EXECUTED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Teleport Details",
                        ["value"] = string.format("├ Target: %s\n├ Distance Teleported: %.1f studs\n├ Start Position: %s\n├ End Position: %s\n└ Time: %s",
                            target.Name,
                            distance,
                            tostring(startPos),
                            tostring(targetPos),
                            os.date("%H:%M:%S")),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Target Info",
                        ["value"] = string.format("├ Display Name: %s\n├ User ID: %d\n├ Account Age: %d\n├ Health: %s\n└ Position: %s",
                            target.DisplayName,
                            target.UserId,
                            target.AccountAge,
                            target.Character and target.Character.Humanoid and string.format("%.1f/%.1f", target.Character.Humanoid.Health, target.Character.Humanoid.MaxHealth) or "Unknown",
                            tostring(targetPos)),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Executor",
                        ["value"] = string.format("├ Username: %s\n└ User ID: %d",
                            speaker.Name,
                            speaker.UserId),
                        ["inline"] = false
                    }
                }
                
                sendWebhook("movement", nil, createLongEmbed("Teleport Executed", "Teleported to " .. target.Name, 16776960, fields))
            end
        end
    end,
    
    ["circle"] = function(args, speaker)
        if #args < 2 then
            sendWebhook("commands", "❌ Usage: !circle [playername] [radius]")
            return
        end
        local targetName = args[1]
        local radius = tonumber(args[2]) or 5
        local speed = tonumber(args[3]) or 0.1
        local target = Players:FindFirstChild(targetName)
        
        if target then
            circleTarget = target
            table.insert(commandHistory, {command = "circle " .. targetName .. " " .. radius, time = tick()})
            
            local fields = {
                {
                    ["name"] = "⭕ CIRCLE COMMAND ACTIVATED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Circle Parameters",
                    ["value"] = string.format("├ Target: %s\n├ Radius: %.1f studs\n├ Speed: %.2f rad/step\n├ Circumference: %.1f studs\n└ Orbit Time: %.2f seconds",
                        targetName,
                        radius,
                        speed,
                        2 * math.pi * radius,
                        (2 * math.pi) / speed * 0.05),
                    ["inline"] = true
                },
                {
                    ["name"] = "Target Information",
                    ["value"] = string.format("├ Display Name: %s\n├ User ID: %d\n├ Position: %s\n├ Health: %s\n└ Distance: %.1f",
                        target.DisplayName,
                        target.UserId,
                        target.Character and tostring(target.Character.HumanoidRootPart.Position) or "Unknown",
                        target.Character and target.Character.Humanoid and string.format("%.1f/%.1f", target.Character.Humanoid.Health, target.Character.Humanoid.MaxHealth) or "Unknown",
                        Players.LocalPlayer.Character and target.Character and (Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude or 0),
                    ["inline"] = true
                },
                {
                    ["name"] = "Circle Status",
                    ["value"] = string.format("├ Start Time: %s\n├ Current Angle: 0°\n├ Status: Active\n└ Executor: %s",
                        os.date("%H:%M:%S"),
                        speaker.Name),
                    ["inline"] = false
                }
            }
            
            sendWebhook("commands", nil, createLongEmbed("Circle Command", "Circling " .. targetName, 5814783, fields))
            
            spawn(function()
                local angle = 0
                local startTime = tick()
                local fullRotations = 0
                
                while circleTarget == target do
                    local char = Players.LocalPlayer.Character
                    local targetChar = target.Character
                    if char and targetChar and char:FindFirstChild("HumanoidRootPart") and targetChar:FindFirstChild("HumanoidRootPart") then
                        angle = angle + speed
                        if angle >= 2 * math.pi then
                            angle = angle - 2 * math.pi
                            fullRotations = fullRotations + 1
                        end
                        
                        local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                        char.HumanoidRootPart.CFrame = CFrame.new(targetChar.HumanoidRootPart.Position + offset)
                    end
                    wait(0.05)
                end
                
                local totalTime = tick() - startTime
                local finalFields = {
                    {
                        ["name"] = "⭕ CIRCLE COMPLETED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Circle Statistics",
                        ["value"] = string.format("├ Total Rotations: %.1f\n├ Duration: %.2f seconds\n├ Total Distance: %.1f studs\n├ Start Time: %s\n└ End Time: %s",
                            fullRotations + angle / (2 * math.pi),
                            totalTime,
                            (fullRotations + angle / (2 * math.pi)) * 2 * math.pi * radius,
                            os.date("%H:%M:%S", startTime),
                            os.date("%H:%M:%S")),
                        ["inline"] = true
                    }
                }
                
                sendWebhook("movement", nil, createLongEmbed("Circle Complete", "Stopped circling " .. targetName, 16776960, finalFields))
            end)
        end
    end,
    
    -- Chat Commands (10-12)
    ["chat"] = function(args, speaker)
        if #args < 1 then
            sendWebhook("commands", "❌ Usage: !chat [message]")
            return
        end
        local message = table.concat(args, " ")
        local chatService = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        
        if chatService and chatService:FindFirstChild("SayMessageRequest") then
            chatService.SayMessageRequest:FireServer(message, "All")
            table.insert(commandHistory, {command = "chat " .. message:sub(1, 20) .. "...", time = tick()})
            
            local fields = {
                {
                    ["name"] = "💬 PUBLIC CHAT SENT",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Message Details",
                    ["value"] = string.format("├ Channel: Public\n├ Length: %d characters\n├ Words: %d\n├ Time: %s\n└ Content:```%s```",
                        #message,
                        #message:gsub("%S+", ""),
                        os.date("%H:%M:%S"),
                        message),
                    ["inline"] = false
                },
                {
                    ["name"] = "Sender Info",
                    ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n└ Position: %s",
                        Players.LocalPlayer.Name,
                        Players.LocalPlayer.DisplayName,
                        Players.LocalPlayer.UserId,
                        Players.LocalPlayer.Character and tostring(Players.LocalPlayer.Character.HumanoidRootPart.Position) or "Unknown"),
                    ["inline"] = true
                },
                {
                    ["name"] = "Command Executor",
                    ["value"] = string.format("├ Username: %s\n└ User ID: %d",
                        speaker.Name,
                        speaker.UserId),
                    ["inline"] = true
                }
            }
            
            sendWebhook("chat_public", nil, createLongEmbed("Public Chat Message", "Alt sent a public message", 5814783, fields))
        end
    end,
    
    ["pm"] = function(args, speaker)
        if #args < 2 then
            sendWebhook("commands", "❌ Usage: !pm [playername] [message]")
            return
        end
        local targetName = args[1]
        local message = table.concat(args, " ", 2)
        local target = Players:FindFirstChild(targetName)
        
        if target then
            local chatService = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatService and chatService:FindFirstChild("SayMessageRequest") then
                chatService.SayMessageRequest:FireServer("/w " .. targetName .. " " .. message, "All")
                table.insert(commandHistory, {command = "pm " .. targetName .. " ...", time = tick()})
                
                local fields = {
                    {
                        ["name"] = "📨 PRIVATE MESSAGE SENT",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Message Details",
                        ["value"] = string.format("├ Recipient: %s\n├ Recipient ID: %d\n├ Length: %d characters\n├ Words: %d\n├ Time: %s\n└ Content:```%s```",
                            target.Name,
                            target.UserId,
                            #message,
                            #message:gsub("%S+", ""),
                            os.date("%H:%M:%S"),
                            message),
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Recipient Status",
                        ["value"] = string.format("├ Display Name: %s\n├ Account Age: %d\n├ In Game: %s\n├ Position: %s\n└ Health: %s",
                            target.DisplayName,
                            target.AccountAge,
                            target.Character and "Yes" or "No",
                            target.Character and tostring(target.Character.HumanoidRootPart.Position) or "Unknown",
                            target.Character and target.Character.Humanoid and string.format("%.1f/%.1f", target.Character.Humanoid.Health, target.Character.Humanoid.MaxHealth) or "Unknown"),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Sender Info",
                        ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n└ Position: %s",
                            Players.LocalPlayer.Name,
                            Players.LocalPlayer.DisplayName,
                            Players.LocalPlayer.UserId,
                            Players.LocalPlayer.Character and tostring(Players.LocalPlayer.Character.HumanoidRootPart.Position) or "Unknown"),
                        ["inline"] = true
                    }
                }
                
                sendWebhook("chat_private", nil, createLongEmbed("Private Message", "PM sent to " .. targetName, 15844367, fields))
            end
        end
    end,
    
    ["chatlive"] = function(args, speaker)
        local status = args[1] and args[1]:lower() == "on"
        table.insert(commandHistory, {command = "chatlive " .. (status and "on" or "off"), time = tick()})
        
        if status then
            -- Enable live chat feed monitoring
            local chatConnections = {}
            
            local function setupChatListener(player)
                chatConnections[player] = player.Chatted:Connect(function(msg)
                    local fields = {
                        {
                            ["name"] = "📡 LIVE CHAT FEED",
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
                                msg),
                            ["inline"] = false
                        },
                        {
                            ["name"] = "Speaker Status",
                            ["value"] = string.format("├ Account Age: %d days\n├ Health: %s\n├ Distance from Alt: %s\n└ In Game: %s",
                                player.AccountAge,
                                player.Character and player.Character.Humanoid and string.format("%.1f/%.1f", player.Character.Humanoid.Health, player.Character.Humanoid.MaxHealth) or "Unknown",
                                Players.LocalPlayer.Character and player.Character and string.format("%.1f", (Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude) or "Unknown",
                                player.Character and "Yes" or "No"),
                            ["inline"] = true
                        }
                    }
                    
                    sendWebhook("chat_public", nil, createLongEmbed("Live Chat Message", "From: " .. player.Name, 5814783, fields))
                end)
            end
            
            for _, player in ipairs(Players:GetPlayers()) do
                setupChatListener(player)
            end
            
            Players.PlayerAdded:Connect(setupChatListener)
            
            local fields = {
                {
                    ["name"] = "📡 LIVE CHAT FEED ACTIVATED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Feed Settings",
                    ["value"] = string.format("├ Status: Active\n├ Monitored Players: %d\n├ Start Time: %s\n├ Update Rate: Real-time\n└ Format: Full details with embeds",
                        #Players:GetPlayers(),
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Executor",
                    ["value"] = string.format("├ Username: %s\n└ User ID: %d",
                        speaker.Name,
                        speaker.UserId),
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Live Chat Enabled", "Now monitoring all chat messages", 3066993, fields))
        end
    end,
    
    -- Emote Commands (13-15)
    ["emote"] = function(args, speaker)
        if #args < 1 then return end
        local emote = args[1]:lower()
        local emotes = {
            wave = {id = "5077702695", name = "Wave"},
            point = {id = "5077710197", name = "Point"},
            dance1 = {id = "5077710490", name = "Dance 1"},
            dance2 = {id = "4585378808", name = "Dance 2"},
            dance3 = {id = "3366357277", name = "Dance 3"},
            laugh = {id = "5077709884", name = "Laugh"},
            cheer = {id = "5077708450", name = "Cheer"},
            cry = {id = "5077709074", name = "Cry"},
            salute = {id = "5077711121", name = "Salute"},
            sit = {id = "5077710769", name = "Sit"}
        }
        
        if emotes[emote] then
            local char = Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. emotes[emote].id
                local track = char.Humanoid:LoadAnimation(anim)
                track:Play()
                
                table.insert(commandHistory, {command = "emote " .. emote, time = tick()})
                
                local fields = {
                    {
                        ["name"] = "🎭 EMOTE PERFORMED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Emote Details",
                        ["value"] = string.format("├ Emote: %s\n├ Animation ID: %s\n├ Duration: %.1f seconds\n├ Start Time: %s\n└ Position: %s",
                            emotes[emote].name,
                            emotes[emote].id,
                            track.Length,
                            os.date("%H:%M:%S"),
                            tostring(char.HumanoidRootPart.Position)),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Character Status",
                        ["value"] = string.format("├ Health: %.1f/%.1f\n├ Walkspeed: %.1f\n└ Jump Power: %.1f",
                            char.Humanoid.Health,
                            char.Humanoid.MaxHealth,
                            char.Humanoid.WalkSpeed,
                            char.Humanoid.JumpPower),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Executor",
                        ["value"] = string.format("├ Username: %s\n└ User ID: %d",
                            speaker.Name,
                            speaker.UserId),
                        ["inline"] = false
                    }
                }
                
                sendWebhook("actions", nil, createLongEmbed("Emote Performed", "Alt did " .. emotes[emote].name, 16776960, fields))
            end
        end
    end,
    
    ["dance"] = function(args, speaker)
        local danceStyle = args[1] or "random"
        local dances = {
            ["1"] = {id = "5077710490", name = "Dance 1"},
            ["2"] = {id = "4585378808", name = "Dance 2"},
            ["3"] = {id = "3366357277", name = "Dance 3"},
            ["break"] = {id = "2532993273", name = "Breakdance"},
            ["robot"] = {id = "2532993640", name = "Robot"}
        }
        
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local selectedDance
            
            if danceStyle == "random" then
                local keys = {}
                for k in pairs(dances) do keys[#keys+1] = k end
                selectedDance = dances[keys[math.random(#keys)]]
            else
                selectedDance = dances[danceStyle]
            end
            
            if selectedDance then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. selectedDance.id
                local track = char.Humanoid:LoadAnimation(anim)
                track:Play()
                
                table.insert(commandHistory, {command = "dance " .. danceStyle, time = tick()})
                
                local fields = {
                    {
                        ["name"] = "💃 DANCE PERFORMED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Dance Details",
                        ["value"] = string.format("├ Style: %s\n├ Animation ID: %s\n├ Duration: %.1f seconds\n├ Start Time: %s\n└ Position: %s",
                            selectedDance.name,
                            selectedDance.id,
                            track.Length,
                            os.date("%H:%M:%S"),
                            tostring(char.HumanoidRootPart.Position)),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Dance Statistics",
                        ["value"] = string.format("├ Energy Cost: Low\n├ Style: %s\n├ Difficulty: Medium\n└ Mood: Happy",
                            danceStyle == "break" and "Energetic" or "Casual"),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Executor",
                        ["value"] = string.format("├ Username: %s\n└ User ID: %d",
                            speaker.Name,
                            speaker.UserId),
                        ["inline"] = false
                    }
                }
                
                sendWebhook("actions", nil, createLongEmbed("Dance Performed", "Alt danced " .. selectedDance.name, 16776960, fields))
            end
        end
    end,
    
    -- Mode Commands (16-17)
    ["actnpc"] = function(args, speaker)
        npcMode = not npcMode
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            table.insert(commandHistory, {command = "actnpc " .. (npcMode and "on" or "off"), time = tick()})
            
            if npcMode then
                -- Save original values
                originalWalkspeed = char.Humanoid.WalkSpeed
                originalJumppower = char.Humanoid.JumpPower
                
                -- Set NPC-like values
                char.Humanoid.WalkSpeed = 8
                char.Humanoid.JumpPower = 0
                char.Humanoid.AutoRotate = false
                
                local fields = {
                    {
                        ["name"] = "🤖 NPC MODE ACTIVATED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "NPC Settings",
                        ["value"] = string.format("├ Walkspeed: 8 (was %.1f)\n├ Jump Power: 0 (was %.1f)\n├ Auto Rotate: Disabled\n├ Behavior: Random movement\n└ Interaction: Passive",
                            originalWalkspeed,
                            originalJumppower),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Movement Pattern",
                        ["value"] = "├ Move Random → Wait → Look Around\n├ Cycle Time: 3-8 seconds\n├ Look Range: 20 studs\n└ Detection Radius: 10 studs",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "NPC Statistics",
                        ["value"] = string.format("├ Start Time: %s\n├ Current Position: %s\n├ Nearby Players: %d\n└ Status: Active",
                            os.date("%H:%M:%S"),
                            tostring(char.HumanoidRootPart.Position),
                            #Players:GetPlayers() - 1),
                        ["inline"] = false
                    }
                }
                
                sendWebhook("status", nil, createLongEmbed("NPC Mode Enabled", "Alt now acting like an NPC", 16776960, fields))
                
                -- Random movement pattern
                spawn(function()
                    local moveStartTime = tick()
                    local moveCount = 0
                    
                    while npcMode do
                        local randomDir = Vector3.new(math.random(-10,10)/10, 0, math.random(-10,10)/10)
                        char.Humanoid:Move(randomDir)
                        local moveDuration = math.random(3,8)
                        wait(moveDuration)
                        
                        char.Humanoid:Move(Vector3.new(0,0,0))
                        moveCount = moveCount + 1
                        
                        -- Random look around
                        if math.random() > 0.7 and char:FindFirstChild("HumanoidRootPart") then
                            local lookPos = char.HumanoidRootPart.Position + Vector3.new(math.random(-20,20), 0, math.random(-20,20))
                            char.HumanoidRootPart.CFrame = CFrame.lookAt(char.HumanoidRootPart.Position, lookPos)
                        end
                        
                        wait(math.random(2,5))
                        
                        -- Log movement every 5 moves
                        if moveCount % 5 == 0 then
                            local moveFields = {
                                {
                                    ["name"] = "🤖 NPC Movement Update",
                                    ["value"] = string.format("├ Total Moves: %d\n├ Time in NPC Mode: %d seconds\n├ Current Position: %s\n└ Distance Traveled: %.1f",
                                        moveCount,
                                        tick() - moveStartTime,
                                        tostring(char.HumanoidRootPart.Position),
                                        (char.HumanoidRootPart.Position - Vector3.new(0,0,0)).Magnitude),
                                    ["inline"] = false
                                }
                            }
                            sendWebhook("debug", nil, createLongEmbed("NPC Update", "Movement statistics", 10181046, moveFields))
                        end
                    end
                end)
            else
                -- Restore normal values
                char.Humanoid.WalkSpeed = originalWalkspeed
                char.Humanoid.JumpPower = originalJumppower
                char.Humanoid.AutoRotate = true
                
                local fields = {
                    {
                        ["name"] = "👤 NPC MODE DEACTIVATED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Restored Settings",
                        ["value"] = string.format("├ Walkspeed: %.1f\n├ Jump Power: %.1f\n├ Auto Rotate: Enabled\n└ End Time: %s",
                            originalWalkspeed,
                            originalJumppower,
                            os.date("%H:%M:%S")),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "NPC Mode Statistics",
                        ["value"] = string.format("├ Total Time in NPC Mode: %d seconds\n├ Final Position: %s\n└ Returned to normal",
                            tick() - (commandHistory[#commandHistory] and commandHistory[#commandHistory].time or tick()),
                            tostring(char.HumanoidRootPart.Position)),
                        ["inline"] = true
                    }
                }
                
                sendWebhook("status", nil, createLongEmbed("NPC Mode Disabled", "Alt returned to normal", 15158332, fields))
            end
        end
    end,
    
    ["anony"] = function(args, speaker)
        anonymousMode = not anonymousMode
        table.insert(commandHistory, {command = "anony " .. (anonymousMode and "on" or "off"), time = tick()})
        
        if anonymousMode then
            originalName = Players.LocalPlayer.Name
            originalDisplayName = Players.LocalPlayer.DisplayName
            
            -- Use various anonymous names
            local anonyNames = {"Player", "Guest", "Unknown", "User", "Visitor", "Stranger", "Hidden", "Anonymous"}
            local randomName = anonyNames[math.random(#anonyNames)]
            
            -- Attempt to change display name (if possible)
            pcall(function()
                if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Players.LocalPlayer.Character.Humanoid.DisplayName = randomName
                end
            end)
            
            local fields = {
                {
                    ["name"] = "🥷 ANONYMOUS MODE ACTIVATED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Identity Changes",
                    ["value"] = string.format("├ Original Name: %s\n├ Original Display: %s\n├ New Display: %s\n├ User ID: %d (hidden)\n└ Account Age: Hidden",
                        originalName,
                        originalDisplayName,
                        randomName,
                        Players.LocalPlayer.UserId),
                    ["inline"] = true
                },
                {
                    ["name"] = "Privacy Settings",
                    ["value"] = "├ Name: Hidden\n├ Display Name: Changed\n├ Join Time: Hidden\n├ Account Age: Hidden\n└ Status: Anonymous",
                    ["inline"] = true
                },
                {
                    ["name"] = "Detection Risk",
                    ["value"] = string.format("├ Other Players: %d\n├ Distance from Others: Varies\n└ Risk Level: %s",
                        #Players:GetPlayers() - 1,
                        #Players:GetPlayers() > 10 and "Medium" or "Low"),
                    ["inline"] = false
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Anonymous Mode Enabled", "Alt identity hidden", 16776960, fields))
        else
            -- Restore original name
            pcall(function()
                if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Players.LocalPlayer.Character.Humanoid.DisplayName = originalDisplayName
                end
            end)
            
            local fields = {
                {
                    ["name"] = "👤 ANONYMOUS MODE DISABLED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Identity Restored",
                    ["value"] = string.format("├ Name: %s\n├ Display Name: %s\n├ User ID: %d\n└ Time: %s",
                        originalName,
                        originalDisplayName,
                        Players.LocalPlayer.UserId,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Anonymous Mode Disabled", "Alt identity revealed", 15158332, fields))
        end
    end,
    
    -- Combat Commands (18)
    ["touchfling"] = function(args, speaker)
        if #args < 1 then
            sendWebhook("commands", "❌ Usage: !touchfling [playername]")
            return
        end
        local targetName = args[1]
        local target = Players:FindFirstChild(targetName)
        
        if target and target.Character then
            table.insert(commandHistory, {command = "touchfling " .. targetName, time = tick()})
            
            local fields = {
                {
                    ["name"] = "💥 TOUCH FLING INITIATED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Target Information",
                    ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n├ Health: %s\n├ Position: %s\n└ Distance: %.1f",
                        target.Name,
                        target.DisplayName,
                        target.UserId,
                        target.Character.Humanoid and string.format("%.1f/%.1f", target.Character.Humanoid.Health, target.Character.Humanoid.MaxHealth) or "Unknown",
                        tostring(target.Character.HumanoidRootPart.Position),
                        (Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude),
                    ["inline"] = true
                },
                {
                    ["name"] = "Fling Parameters",
                    ["value"] = string.format("├ Force: 40,000\n├ Velocity: (1000, 500, 1000)\n├ Duration: 0.3 seconds\n├ Technique: Weld + Velocity\n└ Success Chance: High",
                        target.Name),
                    ["inline"] = true
                }
            }
            
            sendWebhook("actions", nil, createLongEmbed("Touch Fling", "Attempting to fling " .. targetName, 15158332, fields))
            
            spawn(function()
                local char = Players.LocalPlayer.Character
                local targetChar = target.Character
                
                if char and targetChar then
                    local touchPart = char:FindFirstChild("HumanoidRootPart")
                    local targetPart = targetChar:FindFirstChild("HumanoidRootPart")
                    
                    if touchPart and targetPart then
                        -- Create weld for fling
                        local weld = Instance.new("Weld")
                        weld.Part0 = touchPart
                        weld.Part1 = targetPart
                        weld.C0 = CFrame.new(0, 0, 0)
                        weld.C1 = CFrame.new(0, 0, 0)
                        weld.Parent = touchPart
                        
                        wait(0.1)
                        weld:Destroy()
                        
                        -- Apply velocity
                        local bv = Instance.new("BodyVelocity")
                        bv.Velocity = Vector3.new(1000, 500, 1000)
                        bv.P = 10000
                        bv.MaxForce = Vector3.new(40000, 40000, 40000)
                        bv.Parent = targetPart
                        
                        wait(0.2)
                        bv:Destroy()
                        
                        local resultFields = {
                            {
                                ["name"] = "💥 FLING RESULTS",
                                ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                                ["inline"] = false
                            },
                            {
                                ["name"] = "Outcome",
                                ["value"] = string.format("├ Target: %s\n├ Initial Health: %s\n├ Final Health: %s\n├ Distance Flung: Unknown\n└ Time: %s",
                                    target.Name,
                                    target.Character.Humanoid and string.format("%.1f", target.Character.Humanoid.Health) or "Unknown",
                                    target.Character.Humanoid and string.format("%.1f", target.Character.Humanoid.Health) or "Unknown",
                                    os.date("%H:%M:%S")),
                                ["inline"] = false
                            }
                        }
                        
                        sendWebhook("debug", nil, createLongEmbed("Fling Executed", "Touch fling completed", 10181046, resultFields))
                    end
                end
            end)
        end
    end,
    
    -- Power Commands (19-22)
    ["speed"] = function(args, speaker)
        if #args < 1 then
            sendWebhook("commands", "❌ Usage: !speed [value]")
            return
        end
        local newSpeed = tonumber(args[1])
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local oldSpeed = char.Humanoid.WalkSpeed
            currentWalkspeed = newSpeed
            char.Humanoid.WalkSpeed = newSpeed
            
            table.insert(commandHistory, {command = "speed " .. newSpeed, time = tick()})
            
            local fields = {
                {
                    ["name"] = "⚡ SPEED MODIFICATION",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Speed Change",
                    ["value"] = string.format("├ Old Speed: %.1f\n├ New Speed: %.1f\n├ Change: %+.1f\n├ Percentage: %+.1f%%\n└ Time: %s",
                        oldSpeed,
                        newSpeed,
                        newSpeed - oldSpeed,
                        ((newSpeed - oldSpeed) / oldSpeed) * 100,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Performance Impact",
                    ["value"] = string.format("├ Movement Rate: %.1f studs/sec\n├ Game Limit: 16-100\n├ Legality: %s\n└ Status: Active",
                        newSpeed,
                        newSpeed > 50 and "Likely detectable" or "Probably safe"),
                    ["inline"] = true
                },
                {
                    ["name"] = "Executor",
                    ["value"] = string.format("├ Username: %s\n└ User ID: %d",
                        speaker.Name,
                        speaker.UserId),
                    ["inline"] = false
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Speed Changed", "Alt speed modified", 16776960, fields))
        end
    end,
    
    ["jumppower"] = function(args, speaker)
        if #args < 1 then
            sendWebhook("commands", "❌ Usage: !jumppower [value]")
            return
        end
        local newPower = tonumber(args[1])
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local oldPower = char.Humanoid.JumpPower
            currentJumppower = newPower
            char.Humanoid.JumpPower = newPower
            
            table.insert(commandHistory, {command = "jumppower " .. newPower, time = tick()})
            
            local fields = {
                {
                    ["name"] = "📈 JUMP POWER MODIFICATION",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Jump Power Change",
                    ["value"] = string.format("├ Old Power: %.1f\n├ New Power: %.1f\n├ Change: %+.1f\n├ Percentage: %+.1f%%\n├ Max Height: %.1f studs\n└ Time: %s",
                        oldPower,
                        newPower,
                        newPower - oldPower,
                        ((newPower - oldPower) / oldPower) * 100,
                        newPower * 0.5,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Physics Impact",
                    ["value"] = string.format("├ Gravity: %.1f\n├ Hang Time: %.2f sec\n├ Jump Force: %.1f N\n└ Status: Active",
                        Workspace.Gravity,
                        math.sqrt(2 * newPower / Workspace.Gravity),
                        newPower * 50),
                    ["inline"] = true
                },
                {
                    ["name"] = "Executor",
                    ["value"] = string.format("├ Username: %s\n└ User ID: %d",
                        speaker.Name,
                        speaker.UserId),
                    ["inline"] = false
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Jump Power Changed", "Alt jump power modified", 16776960, fields))
        end
    end,
    
    ["gravity"] = function(args, speaker)
        if #args < 1 then
            sendWebhook("commands", "❌ Usage: !gravity [value]")
            return
        end
        local newGravity = tonumber(args[1])
        local oldGravity = Workspace.Gravity
        Workspace.Gravity = newGravity
        
        table.insert(commandHistory, {command = "gravity " .. newGravity, time = tick()})
        
        local fields = {
            {
                ["name"] = "🌍 GRAVITY MODIFICATION",
                ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                ["inline"] = false
            },
            {
                ["name"] = "Gravity Change",
                ["value"] = string.format("├ Old Gravity: %.1f\n├ New Gravity: %.1f\n├ Change: %+.1f\n├ Percentage: %+.1f%%\n├ Earth Normal: 196.2\n└ Time: %s",
                    oldGravity,
                    newGravity,
                    newGravity - oldGravity,
                    ((newGravity - oldGravity) / oldGravity) * 100,
                    os.date("%H:%M:%S")),
                ["inline"] = true
            },
            {
                ["name"] = "Physics Effects",
                ["value"] = string.format("├ Jump Height: %.1f studs\n├ Fall Speed: %.1f studs/sec\n├ Terminal Velocity: %.1f\n└ Environment: %s",
                    currentJumppower * 0.5,
                    newGravity * 0.5,
                    newGravity * 2,
                    newGravity < 100 and "Low-G" or (newGravity > 300 and "High-G" or "Normal")),
                ["inline"] = true
            },
            {
                ["name"] = "Executor",
                ["value"] = string.format("├ Username: %s\n└ User ID: %d",
                    speaker.Name,
                    speaker.UserId),
                ["inline"] = false
            }
        }
        
        sendWebhook("status", nil, createLongEmbed("Gravity Changed", "World gravity modified", 16776960, fields))
    end,
    
    ["resetpower"] = function(args, speaker)
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local oldSpeed = char.Humanoid.WalkSpeed
            local oldPower = char.Humanoid.JumpPower
            local oldGravity = Workspace.Gravity
            
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
            Workspace.Gravity = 196.2
            
            table.insert(commandHistory, {command = "resetpower", time = tick()})
            
            local fields = {
                {
                    ["name"] = "🔄 POWERS RESET",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Reset Values",
                    ["value"] = string.format("├ Speed: %.1f → 16.0\n├ Jump Power: %.1f → 50.0\n├ Gravity: %.1f → 196.2\n└ Time: %s",
                        oldSpeed,
                        oldPower,
                        oldGravity,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Changes Made",
                    ["value"] = string.format("├ Speed Change: %+.1f\n├ Jump Change: %+.1f\n├ Gravity Change: %+.1f\n└ Status: Default",
                        16 - oldSpeed,
                        50 - oldPower,
                        196.2 - oldGravity),
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Powers Reset", "All stats returned to default", 3066993, fields))
        end
    end,
    
    -- Server Commands (23-24)
    ["respawn"] = function(args, speaker)
        table.insert(commandHistory, {command = "respawn", time = tick()})
        
        local fields = {
            {
                ["name"] = "🔄 RESPAWN INITIATED",
                ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                ["inline"] = false
            },
            {
                ["name"] = "Respawn Details",
                ["value"] = string.format("├ Reason: Manual command\n├ Time: %s\n├ Position before: %s\n├ Health before: %.1f\n└ Executor: %s",
                    os.date("%H:%M:%S"),
                    Players.LocalPlayer.Character and tostring(Players.LocalPlayer.Character.HumanoidRootPart.Position) or "Unknown",
                    Players.LocalPlayer.Character and Players.LocalPlayer.Character.Humanoid and Players.LocalPlayer.Character.Humanoid.Health or 0,
                    speaker.Name),
                ["inline"] = false
            }
        }
        
        sendWebhook("actions", nil, createLongEmbed("Respawn", "Alt respawning", 16776960, fields))
        sendWebhook("deaths", nil, createLongEmbed("Manual Respawn", "Alt respawned by command", 15158332, fields))
        
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
        end
    end,
    
    ["leave"] = function(args, speaker)
        table.insert(commandHistory, {command = "leave", time = tick()})
        
        local fields = {
            {
                ["name"] = "👋 ALT LEAVING GAME",
                ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                ["inline"] = false
            },
            {
                ["name"] = "Departure Details",
                ["value"] = string.format("├ Reason: Manual leave command\n├ Time: %s\n├ Session Length: %d minutes\n├ Players Online: %d\n└ Executor: %s",
                    os.date("%H:%M:%S"),
                    math.floor((tick() - Players.LocalPlayer.JoinTime) / 60),
                    #Players:GetPlayers(),
                    speaker.Name),
                ["inline"] = false
            },
            {
                ["name"] = "Session Statistics",
                ["value"] = string.format("├ Commands Used: %d\n├ Distance Traveled: %.1f studs\n├ Deaths: %d\n└ Jumps: Unknown",
                    #commandHistory,
                    Players.LocalPlayer.Character and (Players.LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0,0,0)).Magnitude or 0,
                    0),
                ["inline"] = true
            }
        }
        
        sendWebhook("status", nil, createLongEmbed("Alt Leaving", "Alt is leaving the game", 15158332, fields))
        wait(1)
        Players.LocalPlayer:Kick("Alt leaving as requested")
    end,
    
    -- Utility Commands (25-35)
    ["fly"] = function(args, speaker)
        local duration = tonumber(args[1]) or 5
        local height = tonumber(args[2]) or 50
        
        table.insert(commandHistory, {command = "fly " .. duration .. " " .. height, time = tick()})
        
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local bg = Instance.new("BodyGyro")
            local bv = Instance.new("BodyVelocity")
            
            bg.P = 10000
            bg.MaxTorque = Vector3.new(10000, 10000, 10000)
            bg.Parent = char.HumanoidRootPart
            
            bv.Velocity = Vector3.new(0, height/5, 0)
            bv.MaxForce = Vector3.new(0, 40000, 0)
            bv.Parent = char.HumanoidRootPart
            
            local startPos = char.HumanoidRootPart.Position
            
            local fields = {
                {
                    ["name"] = "🕊️ FLIGHT INITIATED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Flight Parameters",
                    ["value"] = string.format("├ Duration: %d seconds\n├ Target Height: %d studs\n├ Ascent Speed: %.1f studs/sec\n├ Start Position: %s\n└ Start Time: %s",
                        duration,
                        height,
                        height/5,
                        tostring(startPos),
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Physics Settings",
                    ["value"] = string.format("├ BodyGyro Power: 10,000\n├ BodyVelocity Force: 40,000\n├ Max Torque: 10,000\n└ Stability: High",
                        duration,
                        height),
                    ["inline"] = true
                }
            }
            
            sendWebhook("actions", nil, createLongEmbed("Flight", "Alt taking off", 16776960, fields))
            
            wait(duration)
            
            local endPos = char.HumanoidRootPart.Position
            bg:Destroy()
            bv:Destroy()
            
            local resultFields = {
                {
                    ["name"] = "🕊️ FLIGHT COMPLETED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Flight Results",
                    ["value"] = string.format("├ Start Position: %s\n├ End Position: %s\n├ Height Gained: %.1f studs\n├ Max Altitude: %.1f\n└ End Time: %s",
                        tostring(startPos),
                        tostring(endPos),
                        endPos.Y - startPos.Y,
                        endPos.Y,
                        os.date("%H:%M:%S")),
                    ["inline"] = false
                }
            }
            
            sendWebhook("actions", nil, createLongEmbed("Flight Complete", "Alt landed", 16776960, resultFields))
        end
    end,
    
    ["invisible"] = function(args, speaker)
        local char = Players.LocalPlayer.Character
        if char then
            table.insert(commandHistory, {command = "invisible", time = tick()})
            
            local partsHidden = 0
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                    partsHidden = partsHidden + 1
                end
            end
            
            local fields = {
                {
                    ["name"] = "👻 INVISIBLE MODE ENABLED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Invisibility Details",
                    ["value"] = string.format("├ Parts Hidden: %d\n├ Transparency: 100%%\n├ Detection Chance: Low\n├ Duration: Until disabled\n└ Time: %s",
                        partsHidden,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Effectiveness",
                    ["value"] = string.format("├ Visible to Players: No\n├ Visible to NPCs: No\n├ Collisions: %s\n└ Shadows: Hidden",
                        char.HumanoidRootPart and tostring(char.HumanoidRootPart.CanCollide) or "Unknown"),
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Invisible Mode", "Alt is now invisible", 16776960, fields))
        end
    end,
    
    ["visible"] = function(args, speaker)
        local char = Players.LocalPlayer.Character
        if char then
            table.insert(commandHistory, {command = "visible", time = tick()})
            
            local partsRevealed = 0
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                    partsRevealed = partsRevealed + 1
                end
            end
            
            local fields = {
                {
                    ["name"] = "👤 VISIBLE MODE ENABLED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Visibility Details",
                    ["value"] = string.format("├ Parts Revealed: %d\n├ Transparency: 0%%\n├ Visibility: Full\n├ Time: %s\n└ Status: Visible to all",
                        partsRevealed,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Visible Mode", "Alt is now visible", 3066993, fields))
        end
    end,
    
    ["freeze"] = function(args, speaker)
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            table.insert(commandHistory, {command = "freeze", time = tick()})
            
            char.HumanoidRootPart.Anchored = true
            
            local fields = {
                {
                    ["name"] = "❄️ ALT FROZEN",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Freeze Details",
                    ["value"] = string.format("├ Position: %s\n├ Anchored: Yes\n├ Movement: Disabled\n├ Rotation: %s\n└ Time: %s",
                        tostring(char.HumanoidRootPart.Position),
                        isSpinning and "Spinning (frozen)" : "Frozen",
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Physics State",
                    ["value"] = string.format("├ Can Collide: %s\n├ Mass: %.1f\n├ Velocity: 0\n└ Status: Stationary",
                        tostring(char.HumanoidRootPart.CanCollide),
                        char.HumanoidRootPart:GetMass()),
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Alt Frozen", "Alt has been frozen in place", 5814783, fields))
        end
    end,
    
    ["unfreeze"] = function(args, speaker)
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            table.insert(commandHistory, {command = "unfreeze", time = tick()})
            
            char.HumanoidRootPart.Anchored = false
            
            local fields = {
                {
                    ["name"] = "🔥 ALT UNFROZEN",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Unfreeze Details",
                    ["value"] = string.format("├ Position: %s\n├ Anchored: No\n├ Movement: Enabled\n├ Rotation: %s\n└ Time: %s",
                        tostring(char.HumanoidRootPart.Position),
                        isSpinning and "Spinning" : "Normal",
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Alt Unfrozen", "Alt can move again", 3066993, fields))
        end
    end,
    
    ["kill"] = function(args, speaker)
        table.insert(commandHistory, {command = "kill " .. (args[1] or "self"), time = tick()})
        
        if #args < 1 or args[1]:lower() == "self" then
            -- Kill self
            local char = Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local fields = {
                    {
                        ["name"] = "💀 SELF-DESTRUCT INITIATED",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Details",
                        ["value"] = string.format("├ Target: Self\n├ Health Before: %.1f\n├ Position: %s\n├ Time: %s\n└ Executor: %s",
                            char.Humanoid.Health,
                            tostring(char.HumanoidRootPart.Position),
                            os.date("%H:%M:%S"),
                            speaker.Name),
                        ["inline"] = false
                    }
                }
                
                sendWebhook("actions", nil, createLongEmbed("Self Destruct", "Alt killing itself", 15158332, fields))
                sendWebhook("deaths", nil, createLongEmbed("Alt Death", "Alt self-destructed", 15158332, fields))
                
                char.Humanoid.Health = 0
            end
        else
            -- Kill target (if possible)
            local target = Players:FindFirstChild(args[1])
            if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                local fields = {
                    {
                        ["name"] = "🔪 KILL ATTEMPT",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Target Information",
                        ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n├ Health Before: %.1f\n├ Position: %s\n└ Distance: %.1f",
                            target.Name,
                            target.DisplayName,
                            target.UserId,
                            target.Character.Humanoid.Health,
                            tostring(target.Character.HumanoidRootPart.Position),
                            (Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Attempt Details",
                        ["value"] = string.format("├ Method: Health set to 0\n├ Time: %s\n├ Executor: %s\n└ Success: Attempted",
                            os.date("%H:%M:%S"),
                            speaker.Name),
                        ["inline"] = true
                    }
                }
                
                sendWebhook("actions", nil, createLongEmbed("Kill Attempt", "Attempting to kill " .. target.Name, 15158332, fields))
                
                target.Character.Humanoid.Health = 0
                
                wait(0.1)
                
                local resultFields = {
                    {
                        ["name"] = "🔪 KILL RESULT",
                        ["value"] = string.format("├ Target: %s\n├ Final Health: 0\n├ Status: %s\n└ Time: %s",
                            target.Name,
                            target.Character and "Dead" or "Unknown",
                            os.date("%H:%M:%S")),
                        ["inline"] = false
                    }
                }
                
                sendWebhook("debug", nil, createLongEmbed("Kill Result", "Kill attempt completed", 10181046, resultFields))
            end
        end
    end,
    
    ["bring"] = function(args, speaker)
        if #args < 1 then
            sendWebhook("commands", "❌ Usage: !bring [playername]")
            return
        end
        
        local target = Players:FindFirstChild(args[1])
        local char = Players.LocalPlayer.Character
        
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and char and char:FindFirstChild("HumanoidRootPart") then
            local oldPos = target.Character.HumanoidRootPart.Position
            local newPos = char.HumanoidRootPart.Position + Vector3.new(0,3,0)
            
            target.Character.HumanoidRootPart.CFrame = CFrame.new(newPos)
            
            table.insert(commandHistory, {command = "bring " .. args[1], time = tick()})
            
            local fields = {
                {
                    ["name"] = "🫴 BRING COMMAND EXECUTED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Target Information",
                    ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n├ Old Position: %s\n├ New Position: %s\n└ Distance Moved: %.1f",
                        target.Name,
                        target.DisplayName,
                        target.UserId,
                        tostring(oldPos),
                        tostring(newPos),
                        (newPos - oldPos).Magnitude),
                    ["inline"] = true
                },
                {
                    ["name"] = "Bring Details",
                    ["value"] = string.format("├ Method: Teleport\n├ Time: %s\n├ Executor: %s\n└ Status: Complete",
                        os.date("%H:%M:%S"),
                        speaker.Name),
                    ["inline"] = true
                }
            }
            
            sendWebhook("movement", nil, createLongEmbed("Player Brought", "Brought " .. target.Name .. " to alt", 16776960, fields))
        end
    end,
    
    ["view"] = function(args, speaker)
        table.insert(commandHistory, {command = "view " .. (args[1] or "self"), time = tick()})
        
        if #args < 1 or args[1]:lower() == "self" or args[1]:lower() == "me" then
            Workspace.CurrentCamera.CameraSubject = Players.LocalPlayer.Character
            
            local fields = {
                {
                    ["name"] = "👁️ CAMERA RESET",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "View Details",
                    ["value"] = string.format("├ Subject: Self\n├ Position: %s\n├ Camera Mode: Follow\n└ Time: %s",
                        Players.LocalPlayer.Character and tostring(Players.LocalPlayer.Character.HumanoidRootPart.Position) or "Unknown",
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Camera Reset", "Viewing alt", 3066993, fields))
        else
            local target = Players:FindFirstChild(args[1])
            if target and target.Character then
                Workspace.CurrentCamera.CameraSubject = target.Character
                
                local fields = {
                    {
                        ["name"] = "👁️ VIEWING PLAYER",
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Target Information",
                        ["value"] = string.format("├ Username: %s\n├ Display Name: %s\n├ User ID: %d\n├ Position: %s\n├ Health: %s\n└ Distance: %.1f",
                            target.Name,
                            target.DisplayName,
                            target.UserId,
                            target.Character and tostring(target.Character.HumanoidRootPart.Position) or "Unknown",
                            target.Character and target.Character.Humanoid and string.format("%.1f/%.1f", target.Character.Humanoid.Health, target.Character.Humanoid.MaxHealth) or "Unknown",
                            Players.LocalPlayer.Character and target.Character and (Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude or 0),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "View Settings",
                        ["value"] = string.format("├ Camera Mode: Follow\n├ Perspective: Third Person\n├ Start Time: %s\n└ Executor: %s",
                            os.date("%H:%M:%S"),
                            speaker.Name),
                        ["inline"] = true
                    }
                }
                
                sendWebhook("status", nil, createLongEmbed("Viewing Player", "Now viewing " .. target.Name, 5814783, fields))
            end
        end
    end,
    
    ["godmode"] = function(args, speaker)
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            table.insert(commandHistory, {command = "godmode", time = tick()})
            
            local oldMaxHealth = char.Humanoid.MaxHealth
            local oldHealth = char.Humanoid.Health
            
            char.Humanoid.MaxHealth = math.huge
            char.Humanoid.Health = math.huge
            
            local fields = {
                {
                    ["name"] = "🛡️ GODMODE ENABLED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Health Statistics",
                    ["value"] = string.format("├ Old Max Health: %.1f\n├ New Max Health: Infinite\n├ Old Health: %.1f\n├ New Health: Infinite\n└ Time: %s",
                        oldMaxHealth,
                        oldHealth,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Protection Details",
                    ["value"] = "├ Damage: No effect\n├ Fall Damage: Disabled\n├ Kill Commands: Immune\n├ Explosions: Immune\n└ Status: Invincible",
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Godmode Enabled", "Alt is now invincible", 16776960, fields))
        end
    end,
    
    ["noclip"] = function(args, speaker)
        local char = Players.LocalPlayer.Character
        if char then
            table.insert(commandHistory, {command = "noclip", time = tick()})
            
            local partsModified = 0
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    partsModified = partsModified + 1
                end
            end
            
            local fields = {
                {
                    ["name"] = "🚫 NOCLIP ENABLED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Noclip Details",
                    ["value"] = string.format("├ Parts Modified: %d\n├ Collision: Disabled\n├ Phase Through: Yes\n├ Walls: Pass through\n└ Time: %s",
                        partsModified,
                        os.date("%H:%M:%S")),
                    ["inline"] = true
                },
                {
                    ["name"] = "Movement Capabilities",
                    ["value"] = "├ Through Terrain: Yes\n├ Through Parts: Yes\n├ Through Players: Yes\n├ Through Vehicles: Yes\n└ Status: Active",
                    ["inline"] = true
                }
            }
            
            sendWebhook("status", nil, createLongEmbed("Noclip Enabled", "Alt can phase through objects", 16776960, fields))
        end
    end,
    
    ["explode"] = function(args, speaker)
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            table.insert(commandHistory, {command = "explode", time = tick()})
            
            local radius = tonumber(args[1]) or 10
            local pressure = tonumber(args[2]) or 50000
            
            local explosion = Instance.new("Explosion")
            explosion.Position = char.HumanoidRootPart.Position
            explosion.BlastRadius = radius
            explosion.BlastPressure = pressure
            explosion.DestroyJointRadiusPercent = 1
            explosion.Parent = Workspace
            
            local affectedPlayers = 0
            local affectedParts = 0
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (player.Character.HumanoidRootPart.Position - explosion.Position).Magnitude
                    if distance <= radius then
                        affectedPlayers = affectedPlayers + 1
                    end
                end
            end
            
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and part.Position and (part.Position - explosion.Position).Magnitude <= radius then
                    affectedParts = affectedParts + 1
                end
            end
            
            local fields = {
                {
                    ["name"] = "💥 EXPLOSION DETONATED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Explosion Parameters",
                    ["value"] = string.format("├ Radius: %.1f studs\n├ Pressure: %.1f\n├ Position: %s\n├ Time: %s\n└ Executor: %s",
                        radius,
                        pressure,
                        tostring(explosion.Position),
                        os.date("%H:%M:%S"),
                        speaker.Name),
                    ["inline"] = true
                },
                {
                    ["name"] = "Explosion Effects",
                    ["value"] = string.format("├ Players Affected: %d\n├ Parts Affected: %d\n├ Destruction Radius: %.1f%%\n└ Blast Force: %s",
                        affectedPlayers,
                        affectedParts,
                        explosion.DestroyJointRadiusPercent * 100,
                        pressure > 100000 and "Extreme" or (pressure > 50000 and "High" or "Normal")),
                    ["inline"] = true
                }
            }
            
            sendWebhook("actions", nil, createLongEmbed("Explosion", "Alt detonated an explosion", 15158332, fields))
        end
    end,
    
    ["spam"] = function(args, speaker)
        if #args < 2 then
            sendWebhook("commands", "❌ Usage: !spam [message] [count]")
            return
        end
        
        local count = tonumber(args[#args]) or 5
        local message = table.concat(args, " ", 1, #args-1)
        
        table.insert(commandHistory, {command = "spam " .. message:sub(1, 10) .. "... " .. count, time = tick()})
        
        local fields = {
            {
                ["name"] = "📢 SPAM COMMAND INITIATED",
                ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                ["inline"] = false
            },
            {
                ["name"] = "Spam Parameters",
                ["value"] = string.format("├ Message: %s\n├ Character Count: %d\n├ Repetitions: %d\n├ Total Characters: %d\n└ Start Time: %s",
                    message:sub(1, 50) .. (#message > 50 and "..." or ""),
                    #message,
                    count,
                    #message * count,
                    os.date("%H:%M:%S")),
                ["inline"] = true
            },
            {
                ["name"] = "Spam Details",
                ["value"] = string.format("├ Channel: Public\n├ Delay: 0.5 seconds\n├ Duration: %.1f seconds\n├ Executor: %s\n└ Status: Running",
                    count * 0.5,
                    speaker.Name),
                ["inline"] = true
            }
        }
        
        sendWebhook("chat_public", nil, createLongEmbed("Spam Started", "Alt will spam " .. count .. " messages", 15844367, fields))
        
        spawn(function()
            local sent = 0
            for i = 1, count do
                local chatService = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                if chatService and chatService:FindFirstChild("SayMessageRequest") then
                    chatService.SayMessageRequest:FireServer(message .. " (" .. i .. "/" .. count .. ")", "All")
                    sent = sent + 1
                end
                wait(0.5)
            end
            
            local resultFields = {
                {
                    ["name"] = "📢 SPAM COMPLETED",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                },
                {
                    ["name"] = "Results",
                    ["value"] = string.format("├ Messages Sent: %d/%d\n├ Success Rate: 100%%\n├ End Time: %s\n└ Status: Complete",
                        sent,
                        count,
                        os.date("%H:%M:%S")),
                    ["inline"] = false
                }
            }
            
            sendWebhook("debug", nil, createLongEmbed("Spam Complete", "Spam finished", 3066993, resultFields))
        end)
    end,
    
    -- Info Commands (36-39)
    ["playerinfo"] = function(args, speaker)
        if #args < 1 then
            -- Show own info
            local info = getDetailedPlayerInfo(Players.LocalPlayer)
            local fields = {
                {
                    ["name"] = "📊 PLAYER INFORMATION - SELF",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                }
            }
            
            for category, data in pairs(info) do
                local value = ""
                for key, val in pairs(data) do
                    value = value .. "├ " .. key .. ": " .. tostring(val) .. "\n"
                end
                table.insert(fields, {
                    ["name"] = category,
                    ["value"] = value:sub(1, -2),
                    ["inline"] = true
                })
            end
            
            table.insert(fields, {
                ["name"] = "Request Time",
                ["value"] = os.date("%Y-%m-%d %H:%M:%S"),
                ["inline"] = false
            })
            
            table.insert(commandHistory, {command = "playerinfo self", time = tick()})
            sendWebhook("status", nil, createLongEmbed("Player Info", "Self information", 5814783, fields))
        else
            local target = Players:FindFirstChild(args[1])
            if target then
                local info = getDetailedPlayerInfo(target)
                local fields = {
                    {
                        ["name"] = "📊 PLAYER INFORMATION - " .. target.Name:upper(),
                        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                        ["inline"] = false
                    }
                }
                
                for category, data in pairs(info) do
                    local value = ""
                    for key, val in pairs(data) do
                        value = value .. "├ " .. key .. ": " .. tostring(val) .. "\n"
                    end
                    table.insert(fields, {
                        ["name"] = category,
                        ["value"] = value:sub(1, -2),
                        ["inline"] = true
                    })
                end
                
                table.insert(fields, {
                    ["name"] = "Request Info",
                    ["value"] = string.format("├ Requested by: %s\n├ Time: %s\n└ User ID: %d",
                        speaker.Name,
                        os.date("%H:%M:%S"),
                        speaker.UserId),
                    ["inline"] = false
                })
                
                table.insert(commandHistory, {command = "playerinfo " .. args[1], time = tick()})
                sendWebhook("status", nil, createLongEmbed("Player Info", "Information for " .. target.Name, 5814783, fields))
            end
        end
    end,
    
    ["players"] = function(args, speaker)
        table.insert(commandHistory, {command = "players", time = tick()})
        
        local playerList = {}
        local staffList = {}
        local friendsList = {}
        
        for _, player in ipairs(Players:GetPlayers()) do
            local hasStaff = player:GetRankInGroup(1) > 0 or false -- Check if staff
            local isFriend = player:IsFriendsWith(Players.LocalPlayer.UserId) or false
            
            local playerInfo = string.format("├ %s (ID: %d) - %s - %s",
                player.Name,
                player.UserId,
                player.Character and "🟢" or "🔴",
                player.AccountAge > 365 and "Old" or (player.AccountAge > 30 and "Regular" or "New")
            )
            
            if hasStaff then
                table.insert(staffList, playerInfo)
            elseif isFriend then
                table.insert(friendsList, playerInfo)
            else
                table.insert(playerList, playerInfo)
            end
        end
        
        local fields = {
            {
                ["name"] = "🌐 PLAYER LIST - " .. #Players:GetPlayers() .. " TOTAL",
                ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                ["inline"] = false
            },
            {
                ["name"] = "Server Information",
                ["value"] = string.format("├ Game: %s\n├ Place ID: %d\n├ Server ID: %s\n├ Max Players: %d\n└ Time: %s",
                    game.Name,
                    game.PlaceId,
                    game.JobId:sub(1, 8) .. "...",
                    Players.MaxPlayers,
                    os.date("%H:%M:%S")),
                ["inline"] = false
            }
        }
        
        if #staffList > 0 then
            table.insert(fields, {
                ["name"] = "👮 Staff Members (" .. #staffList .. ")",
                ["value"] = table.concat(staffList, "\n"),
                ["inline"] = false
            })
        end
        
        if #friendsList > 0 then
            table.insert(fields, {
                ["name"] = "🤝 Friends (" .. #friendsList .. ")",
                ["value"] = table.concat(friendsList, "\n"),
                ["inline"] = false
            })
        end
        
        if #playerList > 0 then
            table.insert(fields, {
                ["name"] = "👤 Other Players (" .. #playerList .. ")",
                ["value"] = table.concat(playerList, "\n"),
                ["inline"] = false
            })
        end
        
        sendWebhook("players", nil, createLongEmbed("Player List", "All players in server", 10181046, fields))
    end,
    
    ["status"] = function(args, speaker)
        table.insert(commandHistory, {command = "status", time = tick()})
        local fields = createLongStatusEmbed()
        sendWebhook("status", nil, createLongEmbed("Alt Status Report", "Complete system status", 5814783, fields))
    end,
    
    ["history"] = function(args, speaker)
        local count = tonumber(args[1]) or 20
        table.insert(commandHistory, {command = "history " .. count, time = tick()})
        
        local recentCommands = {}
        for i = math.max(1, #commandHistory - count + 1), #commandHistory do
            local cmd = commandHistory[i]
            if cmd then
                table.insert(recentCommands, string.format("├ `%s` - %s ago", 
                    cmd.command, 
                    os.date("%M:%S", tick() - cmd.time)))
            end
        end
        
        local fields = {
            {
                ["name"] = "📜 COMMAND HISTORY",
                ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                ["inline"] = false
            },
            {
                ["name"] = "Statistics",
                ["value"] = string.format("├ Total Commands: %d\n├ Showing: Last %d\n├ First Command: %s\n└ Last Command: %s",
                    #commandHistory,
                    math.min(count, #commandHistory),
                    #commandHistory > 0 and commandHistory[1].command or "None",
                    #commandHistory > 0 and commandHistory[#commandHistory].command or "None"),
                ["inline"] = false
            },
            {
                ["name"] = "Recent Commands",
                ["value"] = #recentCommands > 0 and table.concat(recentCommands, "\n") or "No commands in history",
                ["inline"] = false
            }
        }
        
        sendWebhook("debug", nil, createLongEmbed("Command History", "Recent command log", 10181046, fields))
    end,
    
    ["help"] = function(args, speaker)
        table.insert(commandHistory, {command = "help", time = tick()})
        
        local helpSections = {
            {
                name = "🎮 MOVEMENT COMMANDS",
                commands = {
                    "`!follow [player]` - Follow a player",
                    "`!move [dir] [sec]` - Move direction (forward/back/left/right)",
                    "`!jump` - Single jump",
                    "`!loopjump [count]` - Loop jump (default: 10)",
                    "`!loopfollow [player]` - Continuously follow player"
                }
            },
            {
                name = "🔄 ROTATION COMMANDS",
                commands = {
                    "`!spin [speed]` - Start spinning (speed: degrees/step)",
                    "`!unspin` - Stop spinning"
                }
            },
            {
                name = "✨ TELEPORT COMMANDS",
                commands = {
                    "`!tp [player]` - Teleport to player",
                    "`!circle [player] [radius] [speed]` - Circle around player"
                }
            },
            {
                name = "💬 CHAT COMMANDS",
                commands = {
                    "`!chat [message]` - Send public chat",
                    "`!pm [player] [message]` - Send private message",
                    "`!spam [message] [count]` - Spam chat messages",
                    "`!chatlive [on/off]` - Enable live chat feed"
                }
            },
            {
                name = "🎭 EMOTE COMMANDS",
                commands = {
                    "`!emote [name]` - Do emote (wave/point/dance1/laugh/cheer/cry/salute/sit)",
                    "`!dance [style]` - Dance (1/2/3/break/robot)"
                }
            },
            {
                name = "🤖 MODE COMMANDS",
                commands = {
                    "`!actnpc` - Toggle NPC mode",
                    "`!anony` - Toggle anonymous mode",
                    "`!invisible` - Become invisible",
                    "`!visible` - Become visible",
                    "`!godmode` - Enable invincibility",
                    "`!noclip` - Enable noclip"
                }
            },
            {
                name = "⚔️ COMBAT COMMANDS",
                commands = {
                    "`!touchfling [player]` - Attempt to fling player",
                    "`!kill [player/self]` - Kill target or self",
                    "`!explode [radius] [pressure]` - Create explosion"
                }
            },
            {
                name = "⚡ POWER COMMANDS",
                commands = {
                    "`!speed [value]` - Change walkspeed",
                    "`!jumppower [value]` - Change jump power",
                    "`!gravity [value]` - Change world gravity",
                    "`!resetpower` - Reset all powers to default",
                    "`!fly [seconds] [height]` - Fly for duration"
                }
            },
            {
                name = "❄️ UTILITY COMMANDS",
                commands = {
                    "`!freeze` - Freeze in place",
                    "`!unfreeze` - Unfreeze",
                    "`!bring [player]` - Bring player to alt",
                    "`!view [player/self]` - View player",
                    "`!respawn` - Respawn alt",
                    "`!leave` - Leave game"
                }
            },
            {
                name = "📊 INFO COMMANDS",
                commands = {
                    "`!playerinfo [player]` - Get detailed player info",
                    "`!players` - List all players",
                    "`!status` - Show alt status",
                    "`!history [count]` - Show command history",
                    "`!help` - Show this menu"
                }
            }
        }
        
        local fields = {
            {
                ["name"] = "🎮 ALT CONTROLLER - COMMAND LIST",
                ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n**Version:** 3.0 | **Commands:** 40+ | **Prefix:** `!`",
                ["inline"] = false
            }
        }
        
        for _, section in ipairs(helpSections) do
            local value = table.concat(section.commands, "\n")
            table.insert(fields, {
                ["name"] = section.name,
                ["value"] = value,
                ["inline"] = false
            })
        end
        
        table.insert(fields, {
            ["name"] = "📡 WEBHOOKS ACTIVE",
            ["value"] = "Commands | Status | Errors | Deaths | Chat Public | Chat Private | Actions | Movement | Players | Debug",
            ["inline"] = false
        })
        
        sendWebhook("commands", nil, createLongEmbed("Help Menu", "Complete command reference", 5814783, fields))
    end
}

-- Chat listener
local function onPlayerChatted(player, message)
    if player == Players.LocalPlayer then return end
    
    if message:sub(1, 1) == cmdPrefix then
        local args = {}
        for word in message:gmatch("%S+") do
            table.insert(args, word)
        end
        
        if #args > 0 then
            local command = args[1]:sub(2):lower()
            table.remove(args, 1)
            
            if commands[command] then
                local success, err = pcall(function()
                    commands[command](args, player)
                end)
                
                if not success then
                    local errorFields = {
                        {
                            ["name"] = "❌ COMMAND ERROR",
                            ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                            ["inline"] = false
                        },
                        {
                            ["name"] = "Error Details",
                            ["value"] = string.format("├ Command: %s\n├ Error: %s\n├ Time: %s\n├ Executor: %s\n└ User ID: %d",
                                command,
                                tostring(err),
                                os.date("%H:%M:%S"),
                                player.Name,
                                player.UserId),
                            ["inline"] = false
                        },
                        {
                            ["name"] = "Stack Trace",
                            ["value"] = debug.traceback() or "Not available",
                            ["inline"] = false
                        }
                    }
                    
                    sendWebhook("errors", nil, createLongEmbed("Command Error", "Failed to execute command", 15158332, errorFields))
                end
            else
                sendWebhook("commands", "❌ Unknown command: " .. command .. "\nType !help for commands")
            end
        end
    end
end

-- Setup chat connection
for _, player in ipairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end)

-- Follow system
RunService.Heartbeat:Connect(function()
    if followTarget and not loopFollowing then
        local char = Players.LocalPlayer.Character
        local targetChar = followTarget.Character
        if char and targetChar and char:FindFirstChild("Humanoid") and targetChar:FindFirstChild("HumanoidRootPart") then
            local distance = (char.HumanoidRootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude
            if distance > 5 then
                local direction = (targetChar.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Unit
                char.Humanoid:Move(direction * 16)
            else
                char.Humanoid:Move(Vector3.new(0,0,0))
            end
        end
    end
end)

-- Track all chats for webhook
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if player ~= Players.LocalPlayer then
            local fields = {
                {
                    ["name"] = "💬 CHAT MESSAGE DETECTED",
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
                    ["name"] = "Speaker Info",
                    ["value"] = string.format("├ Account Age: %d days\n├ Health: %s\n├ Distance from Alt: %s\n└ In Game: %s",
                        player.AccountAge,
                        player.Character and player.Character.Humanoid and string.format("%.1f/%.1f", player.Character.Humanoid.Health, player.Character.Humanoid.MaxHealth) or "Unknown",
                        Players.LocalPlayer.Character and player.Character and string.format("%.1f", (Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude) or "Unknown",
                        player.Character and "Yes" or "No"),
                    ["inline"] = true
                }
            }
            
            sendWebhook("chat_public", nil, createLongEmbed("Chat Message", "From: " .. player.Name, 5814783, fields))
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(message)
        if player ~= Players.LocalPlayer then
            local fields = {
                {
                    ["name"] = "💬 CHAT MESSAGE DETECTED",
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
                    ["name"] = "Speaker Info",
                    ["value"] = string.format("├ Account Age: %d days\n├ Health: %s\n├ Distance from Alt: %s\n└ In Game: %s",
                        player.AccountAge,
                        player.Character and player.Character.Humanoid and string.format("%.1f/%.1f", player.Character.Humanoid.Health, player.Character.Humanoid.MaxHealth) or "Unknown",
                        Players.LocalPlayer.Character and player.Character and string.format("%.1f", (Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude) or "Unknown",
                        player.Character and "Yes" or "No"),
                    ["inline"] = true
                }
            }
            
            sendWebhook("chat_public", nil, createLongEmbed("Chat Message", "From: " .. player.Name, 5814783, fields))
        end
    end)
end

-- Track player joins/leaves
Players.PlayerAdded:Connect(function(player)
    local fields = {
        {
            ["name"] = "🟢 PLAYER JOINED",
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
            ["name"] = "Account Details",
            ["value"] = string.format("├ Membership: %s\n├ Verified: Yes\n├ Banned: No\n└ Age Group: %s",
                player.MembershipType == Enum.MembershipType.None and "None" or tostring(player.MembershipType),
                player.AccountAge < 30 and "New" or (player.AccountAge < 365 and "Regular" or "Veteran")),
            ["inline"] = true
        }
    }
    
    sendWebhook("players", nil, createLongEmbed("Player Joined", player.Name .. " joined the game", 3066993, fields))
end)

Players.PlayerRemoving:Connect(function(player)
    local fields = {
        {
            ["name"] = "🔴 PLAYER LEFT",
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
                #Players:GetPlayers() - 1),
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
    
    sendWebhook("players", nil, createLongEmbed("Player Left", player.Name .. " left the game", 15158332, fields))
end)

-- Initial ready message with long embed
local startupFields = {
    {
        ["name"] = "🎮 ALT CONTROLLER ONLINE",
        ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        ["inline"] = false
    },
    {
        ["name"] = "System Information",
        ["value"] = string.format("├ Version: 3.0\n├ Commands: 40+\n├ Webhooks: 10\n├ Prefix: '!'\n├ Alt Name: %s\n└ Start Time: %s",
            altName,
            os.date("%Y-%m-%d %H:%M:%S")),
        ["inline"] = true
    },
    {
        ["name"] = "Server Information",
        ["value"] = string.format("├ Game: %s\n├ Place ID: %d\n├ Server ID: %s\n├ Players: %d\n├ Ping: %dms\n└ Uptime: Starting",
            game.Name,
            game.PlaceId,
            game.JobId:sub(1, 8) .. "...",
            #Players:GetPlayers(),
            math.floor(Stats:GetNetworkPing() * 1000)),
        ["inline"] = true
    },
    {
        ["name"] = "Active Webhooks",
        ["value"] = "Commands | Status | Errors | Deaths | Chat Public | Chat Private | Actions | Movement | Players | Debug",
        ["inline"] = false
    },
    {
        ["name"] = "Quick Start",
        ["value"] = "Type `!help` in Roblox chat to see all commands\nAll actions are logged to Discord with detailed embeds",
        ["inline"] = false
    }
}

sendWebhook("status", nil, createLongEmbed("System Ready", "Alt controller initialized", 3066993, startupFields))
