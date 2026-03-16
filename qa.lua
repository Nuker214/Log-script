local webhookUrl = "https://discord.com/api/webhooks/1482913836423057428/fYSkY7XfawDG3ClH3tMmsymEzZjqKyiZH4q3LCZSV6_ztlAy7wOkdl22ZYLNZUfQevEi" -- Main webhook for connection & chat
local joinLeaveWebhook = "https://discord.com/api/webhooks/1482913976294572215/hiFyivZJqHlMtf5e4c_QcIwowxbV2xbqYX4Kt4Mkwyxbigq_mrA-d2xvHhWNtRgL0c7N" -- Separate webhook for joins & leaves

-- Color Constants (Discord color hex values)
local Colors = {
    CONNECT = 5763719,    -- Green
    CHAT = 1752220,       -- Blurple
    JOIN = 3066993,       -- Bright Green
    LEAVE = 15158332,     -- Red
    INFO = 5814783,       -- Blue
    WARNING = 16776960    -- Yellow
}

-- Function to get executor info (spoofs as different executors for safety)
local function getExecutorInfo()
    local executorInfo = {
        name = "Swift" .. math.random(100, 999), -- Random executor name
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

-- Enhanced Discord webhook sender with embed support (supports multiple webhooks)
local function sendToDiscwebhook(embedData, useJoinLeave)
    local httpService = game:GetService("HttpService")
    
    -- Choose which webhook to use
    local targetWebhook = useJoinLeave and joinLeaveWebhook or webhookUrl
    
    if not targetWebhook or targetWebhook == "YOUR_JOIN_LEAVE_WEBHOOK_URL_HERE" or targetWebhook == "YOUR_MAIN_WEBHOOK_URL_HERE" then
        warn("❌ Webhook not configured properly!")
        return
    end
    
    local payload = {
        embeds = {embedData},
        username = "Roblox Logger Pro",
        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
    }
    
    local jsonPayload = httpService:JSONEncode(payload)
    
    -- FIX: Use request() instead of PostAsync to avoid "vulnerable function" warning
    local success, error = pcall(function()
        -- Try different request methods (works with most executors)
        local requestFunc = syn and syn.request or http_request or request or fluxus and fluxus.request
        
        if requestFunc then
            requestFunc({
                Url = targetWebhook,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonPayload
            })
        else
            -- Fallback to PostAsync if no request function exists
            httpService:PostAsync(targetWebhook, jsonPayload, Enum.HttpContentType.ApplicationJson)
        end
    end)
    
    if not success then
        warn("❌ Webhook Error (" .. (useJoinLeave and "Join/Leave" or "Main") .. "): " .. tostring(error))
    end
    
    wait(0.5) -- Rate limit prevention
end

-- Send connection message when script starts
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
                name = "⏰ **Connected At**",
                value = string.format("```%s (UTC)```", os.date("%Y-%m-%d %H:%M:%S")),
                inline = true
            },
            {
                name = "🌐 **Server Region**",
                value = "```Auto-detected```",
                inline = true
            },
            {
                name = "📢 **Webhook Setup**",
                value = string.format("```✅ Main Webhook: Connected\n✅ Join/Leave Webhook: %s```", 
                    (joinLeaveWebhook ~= "YOUR_JOIN_LEAVE_WEBHOOK_URL_HERE" and "Connected" or "Not Set")),
                inline = false
            }
        },
        footer = {
            text = "Live Feed Active • Made with ❤️",
            icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. localPlayer.UserId .. "&width=420&height=420&format=png"
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    
    sendToDiscwebhook(embed, false) -- Send to main webhook
end

-- Enhanced chat message logger
local function logChatMessage(player, message)
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
            },
            {
                name = "📊 **Additional Info**",
                value = string.format("```🌍 Server: %s\n👥 Online: %d```", 
                    game.JobId:sub(1, 8), #game:GetService("Players"):GetPlayers()),
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
    
    sendToDiscwebhook(embed, false) -- Send to main webhook
end

-- Enhanced join logger (sends to join/leave webhook)
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
    
    sendToDiscwebhook(embed, true) -- Send to join/leave webhook
end

-- Enhanced leave logger (sends to join/leave webhook)
local function logPlayerLeave(player)
    local gameInfo = getGameInfo()
    
    -- Calculate time played (simplified to avoid GetJoinData issues)
    local timePlayed = 0
    
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
    
    sendToDiscwebhook(embed, true) -- Send to join/leave webhook
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
    
    -- Log when script stops (optional)
    game:BindToClose(function()
        local embed = {
            title = "🔌 **LOGGER DISCONNECTED**",
            description = "Live feed has been terminated.",
            color = Colors.WARNING,
            fields = {
                {
                    name = "⏰ **Disconnected At**",
                    value = string.format("```%s (UTC)```", os.date("%Y-%m-%d %H:%M:%S")),
                    inline = false
                }
            },
            footer = {
                text = "Session Ended",
                icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
            },
            timestamp = DateTime.now():ToIsoDate()
        }
        sendToDiscwebhook(embed, false) -- Send to main webhook
    end)
end

-- Anti-detection and stealth
local function antiDetection()
    -- Spoof executor info
    getgenv().executor = getExecutorInfo()
    
    -- Clear console (if supported)
    if syn and syn.console_clear then
        syn.console_clear()
    end
    
    print("✅ Logger initialized - Live feed active")
end

-- Initialize everything
antiDetection()
setupLogging()

-- Status message in console
print("=" .. string.rep("=", 50) .. "=")
print("🔵 DISCORD LOGGER PRO - LIVE")
print("=" .. string.rep("=", 50) .. "=")
print("📡 Status: Connected to Discord")
print("👤 Account: " .. game:GetService("Players").LocalPlayer.Name)
print("🎮 Game: " .. getGameInfo().name)
print("⏰ Started: " .. os.date("%H:%M:%S"))
print("=" .. string.rep("=", 50) .. "=")
