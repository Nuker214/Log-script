local webhookUrl = "https://discord.com/api/webhooks/1482913836423057428/fYSkY7XfawDG3ClH3tMmsymEzZjqKyiZH4q3LCZSV6_ztlAy7wOkdl22ZYLNZUfQevEi" -- Main webhook for connection & chat
local joinLeaveWebhook = "https://discord.com/api/webhooks/1482913976294572215/hiFyivZJqHlMtf5e4c_QcIwowxbV2xbqYX4Kt4Mkwyxbigq_mrA-d2xvHhWNtRgL0c7N" -- Separate webhook for joins & leaves

-- Global variables for logging control
local loggingEnabled = true
local loggingMode = "normal" -- "normal" or "simple"
local playerLogs = {} -- Track which players to log

-- Color Constants (Discord color hex values)
local Colors = {
    CONNECT = 5763719,    -- Green
    CHAT = 1752220,       -- Blurple
    JOIN = 3066993,       -- Bright Green
    LEAVE = 15158332,     -- Red
    INFO = 5814783,       -- Blue
    WARNING = 16776960,   -- Yellow
    COMMAND = 15277667    -- Pink/Purple for commands
}

-- Function to get executor info
local function getExecutorInfo()
    local executorInfo = {
        name = "Swift" .. math.random(100, 999),
        version = "v" .. math.random(1, 3) .. "." .. math.random(0, 9),
        build = "Premium"
    }
    return executorInfo
end

-- Function to get game information
local function getGameInfo()
    local gameInfo = {
        name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown Game",
        placeId = game.PlaceId,
        jobId = game.JobId,
        players = #game:GetService("Players"):GetPlayers(),
        maxPlayers = game:GetService("Players").MaxPlayers
    }
    return gameInfo
end

-- Discord webhook sender
local function sendToDiscwebhook(embedData, useJoinLeave)
    local httpService = game:GetService("HttpService")
    local targetWebhook = useJoinLeave and joinLeaveWebhook or webhookUrl
    
    local payload = {
        embeds = {embedData},
        username = "Roblox Logger Pro",
        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
    }
    
    local jsonPayload = httpService:JSONEncode(payload)
    
    local success, error = pcall(function()
        local requestFunc = syn and syn.request or http_request or request or fluxus and fluxus.request
        if requestFunc then
            requestFunc({
                Url = targetWebhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonPayload
            })
        else
            httpService:PostAsync(targetWebhook, jsonPayload, Enum.HttpContentType.ApplicationJson)
        end
    end)
    
    if not success then
        warn("❌ Webhook Error: " .. tostring(error))
    end
    
    wait(0.5)
end

-- Send command confirmation
local function sendCommandConfirmation(command, message)
    local embed = {
        title = "⚙️ **COMMAND EXECUTED**",
        description = message,
        color = Colors.COMMAND,
        fields = {
            {
                name = "Command",
                value = "`" .. command .. "`",
                inline = true
            },
            {
                name = "Status",
                value = "✅ Success",
                inline = true
            }
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
end

-- Send connection message
local function sendConnectionMessage()
    local executor = getExecutorInfo()
    local gameInfo = getGameInfo()
    local localPlayer = game:GetService("Players").LocalPlayer
    
    local embed = {
        title = "✅ **LOGGER CONNECTED**",
        description = "Live feed has been established successfully!",
        color = Colors.CONNECT,
        fields = {
            {
                name = "🤖 **Executor**",
                value = string.format("```%s %s (%s)```", executor.name, executor.version, executor.build),
                inline = true
            },
            {
                name = "👤 **Account**",
                value = string.format("```%s (@%s)```", localPlayer.DisplayName, localPlayer.Name),
                inline = true
            },
            {
                name = "🆔 **User ID**",
                value = string.format("```%s```", localPlayer.UserId),
                inline = true
            },
            {
                name = "🎮 **Game Info**",
                value = string.format("```📌 %s\n📍 Place ID: %s\n🔑 Job ID: %s\n👥 Players: %d/%d```", 
                    gameInfo.name, gameInfo.placeId, gameInfo.jobId:sub(1, 8).."...", gameInfo.players, gameInfo.maxPlayers),
                inline = false
            },
            {
                name = "⌨️ **Available Commands**",
                value = "```?start - Start logging\n?stop - Stop logging\n?log (player) - Log specific player(s)\n?simple - Simple chat format\n?normal - Normal chat format```",
                inline = false
            }
        },
        footer = {
            text = "Live Feed Active • Type ?help for commands",
            icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. localPlayer.UserId .. "&width=420&height=420&format=png"
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    
    sendToDiscwebhook(embed, false)
end

-- Normal chat message logger
local function logChatMessageNormal(player, message)
    local executor = getExecutorInfo()
    
    local embed = {
        title = "💬 **NEW CHAT MESSAGE**",
        color = Colors.CHAT,
        fields = {
            {
                name = "👤 **User Information**",
                value = string.format("```📛 Display: %s\n🔰 Username: @%s\n🆔 User ID: %d```", 
                    player.DisplayName, player.Name, player.UserId),
                inline = true
            },
            {
                name = "⏰ **Timestamp**",
                value = string.format("```🕐 Time: %s\n📅 Date: %s```", 
                    os.date("%H:%M:%S"), os.date("%Y-%m-%d")),
                inline = true
            },
            {
                name = "💭 **Message Content**",
                value = "```" .. message .. "```",
                inline = false
            }
        },
        thumbnail = {
            url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
        },
        footer = {
            text = "Live Chat Feed • Powered by " .. executor.name .. " " .. executor.version,
            icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. game:GetService("Players").LocalPlayer.UserId .. "&width=420&height=420&format=png"
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    
    sendToDiscwebhook(embed, false)
end

-- Simple chat message logger
local function logChatMessageSimple(player, message)
    local embed = {
        title = "💬 **CHAT**",
        color = Colors.CHAT,
        fields = {
            {
                name = "👤 **User**",
                value = string.format("**%s** (@%s)", player.DisplayName, player.Name),
                inline = true
            },
            {
                name = "💭 **Message**",
                value = message,
                inline = false
            }
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    
    sendToDiscwebhook(embed, false)
end

-- Main chat logger router
local function logChatMessage(player, message)
    if not loggingEnabled then return end
    
    -- Check if player is being specifically logged
    if #playerLogs > 0 then
        local shouldLog = false
        for _, loggedPlayer in ipairs(playerLogs) do
            if loggedPlayer.Name == player.Name or loggedPlayer.UserId == player.UserId then
                shouldLog = true
                break
            end
        end
        if not shouldLog then return end
    end
    
    if loggingMode == "simple" then
        logChatMessageSimple(player, message)
    else
        logChatMessageNormal(player, message)
    end
end

-- Enhanced join logger
local function logPlayerJoin(player)
    local gameInfo = getGameInfo()
    
    local embed = {
        title = "🟢 **PLAYER JOINED**",
        description = "A new player has joined the server!",
        color = Colors.JOIN,
        fields = {
            {
                name = "👤 **Player Details**",
                value = string.format("```📛 Display: %s\n🔰 Username: @%s\n🆔 User ID: %d\n📅 Account Age: %d days```", 
                    player.DisplayName, player.Name, player.UserId, player.AccountAge),
                inline = true
            },
            {
                name = "⏰ **Join Time**",
                value = string.format("```🕐 %s\n📅 %s```", 
                    os.date("%H:%M:%S"), os.date("%Y-%m-%d")),
                inline = true
            },
            {
                name = "📊 **Server Status**",
                value = string.format("```👥 Now: %d/%d\n📈 Change: +1```", 
                    #game:GetService("Players"):GetPlayers(), gameInfo.maxPlayers),
                inline = false
            }
        },
        thumbnail = {
            url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
        },
        footer = {
            text = "Join Feed • Live Tracking",
            icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    
    sendToDiscwebhook(embed, true)
end

-- Enhanced leave logger
local function logPlayerLeave(player)
    local gameInfo = getGameInfo()
    
    local embed = {
        title = "🔴 **PLAYER LEFT**",
        description = "A player has left the server.",
        color = Colors.LEAVE,
        fields = {
            {
                name = "👤 **Player Details**",
                value = string.format("```📛 Display: %s\n🔰 Username: @%s\n🆔 User ID: %d```", 
                    player.DisplayName, player.Name, player.UserId),
                inline = true
            },
            {
                name = "⏰ **Leave Time**",
                value = string.format("```🕐 %s\n📅 %s```", 
                    os.date("%H:%M:%S"), os.date("%Y-%m-%d")),
                inline = true
            },
            {
                name = "📊 **Server Status**",
                value = string.format("```👥 Now: %d/%d\n📉 Change: -1```", 
                    #game:GetService("Players"):GetPlayers(), gameInfo.maxPlayers),
                inline = false
            }
        },
        thumbnail = {
            url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
        },
        footer = {
            text = "Leave Feed • Live Tracking",
            icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    
    sendToDiscwebhook(embed, true)
end

-- Command handler
local function handleCommand(player, message)
    if player ~= game:GetService("Players").LocalPlayer then return false end
    
    local args = message:split(" ")
    local command = args[1]:lower()
    
    if command == "?start" then
        loggingEnabled = true
        sendCommandConfirmation("?start", "Logging has been **started**")
        return true
        
    elseif command == "?stop" then
        loggingEnabled = false
        sendCommandConfirmation("?stop", "Logging has been **stopped**")
        return true
        
    elseif command == "?simple" then
        loggingMode = "simple"
        sendCommandConfirmation("?simple", "Switched to **simple** logging mode")
        return true
        
    elseif command == "?normal" then
        loggingMode = "normal"
        sendCommandConfirmation("?normal", "Switched to **normal** logging mode")
        return true
        
    elseif command == "?log" then
        if #args < 2 then
            sendCommandConfirmation("?log", "Usage: ?log Player1, Player2, ...")
            return true
        end
        
        -- Clear previous player logs
        playerLogs = {}
        
        -- Parse player names
        local playerNames = table.concat(args, " "):sub(5):split(",")
        local foundPlayers = {}
        
        for _, name in ipairs(playerNames) do
            name = name:gsub("^%s+", ""):gsub("%s+$", "") -- Trim whitespace
            local targetPlayer = game:GetService("Players"):FindFirstChild(name)
            if targetPlayer then
                table.insert(playerLogs, targetPlayer)
                table.insert(foundPlayers, name)
            end
        end
        
        if #foundPlayers > 0 then
            sendCommandConfirmation("?log", "Now logging: **" .. table.concat(foundPlayers, ", ") .. "**")
        else
            sendCommandConfirmation("?log", "No valid players found")
        end
        return true
    end
    
    return false
end

-- Setup all logging
local function setupLogging()
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    
    -- Send connection message
    wait(1)
    sendConnectionMessage()
    
    -- Log existing players
    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer then
            logPlayerJoin(player)
        end
    end
    
    -- Monitor chat for commands and messages
    localPlayer.Chatted:Connect(function(message)
        handleCommand(localPlayer, message)
    end)
    
    -- Monitor new players
    players.PlayerAdded:Connect(function(player)
        if player ~= localPlayer then
            logPlayerJoin(player)
        end
        
        -- Setup chat logging for new players
        player.Chatted:Connect(function(message)
            logChatMessage(player, message)
        end)
    end)
    
    -- Monitor player leaves
    players.PlayerRemoving:Connect(function(player)
        if player ~= localPlayer then
            logPlayerLeave(player)
        end
    end)
    
    -- Setup chat logging for existing players
    for _, player in ipairs(players:GetPlayers()) do
        player.Chatted:Connect(function(message)
            logChatMessage(player, message)
        end)
    end
end

-- Anti-detection and stealth
local function antiDetection()
    getgenv().executor = getExecutorInfo()
    
    if syn and syn.console_clear then
        syn.console_clear()
    end
    
    print("✅ Logger initialized - Live feed active")
    print("📝 Commands: ?start, ?stop, ?log, ?simple, ?normal")
end

-- Initialize everything
antiDetection()
setupLogging()

-- Status message
print("=" .. string.rep("=", 50) .. "=")
print("🔵 DISCORD LOGGER PRO - LIVE")
print("=" .. string.rep("=", 50) .. "=")
print("📡 Status: Connected to Discord")
print("👤 Account: " .. game:GetService("Players").LocalPlayer.Name)
print("🎮 Game: " .. getGameInfo().name)
print("⌨️ Commands: ?start, ?stop, ?log, ?simple, ?normal")
print("=" .. string.rep("=", 50) .. "=")
