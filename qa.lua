-- ============================================
-- DISCORD LOGGER PRO - COMPLETE EDITION
-- All Commands: ?whois, ?server stats, ?msgcount, ?ss
-- ============================================

-- ========== WEBHOOK CONFIGURATION ==========
local webhookUrl = "https://discord.com/api/webhooks/1482913836423057428/fYSkY7XfawDG3ClH3tMmsymEzZjqKyiZH4q3LCZSV6_ztlAy7wOkdl22ZYLNZUfQevEi" -- Main webhook for connection & chat
local joinLeaveWebhook = "https://discord.com/api/webhooks/1482913976294572215/hiFyivZJqHlMtf5e4c_QcIwowxbV2xbqYX4Kt4Mkwyxbigq_mrA-d2xvHhWNtRgL0c7N" -- Separate webhook for joins & leaves
local consoleWebhook = "https://discord.com/api/webhooks/YOUR_CONSOLE_WEBHOOK_URL_HERE" -- Console webhook for logs
local whoisWebhook = "https://discord.com/api/webhooks/YOUR_WHOIS_WEBHOOK_URL_HERE" -- For ?whois command
local serverStatsWebhook = "https://discord.com/api/webhooks/YOUR_SERVER_STATS_WEBHOOK_URL_HERE" -- For ?server stats
local screenshotWebhook = "https://discord.com/api/webhooks/YOUR_SCREENSHOT_WEBHOOK_URL_HERE" -- For ?ss command

-- ========== GLOBAL VARIABLES ==========
local loggingEnabled = {
    chat = true,
    joins = true,
    leaves = true,
    console = true
}
local loggingMode = "normal"
local playerLogs = {}
local messageCounts = {}
local startTime = os.time()

-- ========== COLOR CONSTANTS ==========
local Colors = {
    CONNECT = 5763719,
    CHAT = 1752220,
    JOIN = 3066993,
    LEAVE = 15158332,
    INFO = 5814783,
    WARNING = 16776960,
    COMMAND = 15277667,
    CONSOLE = 12312312,
    WHOIS = 10181046,
    STATS = 15844367
}

-- ========== CONSOLE CAPTURE ==========
local oldPrint = print
local consoleBuffer = {}

local function capturePrint(...)
    local args = {...}
    local output = ""
    for i, v in ipairs(args) do
        output = output .. tostring(v)
        if i < #args then output = output .. " " end
    end
    
    table.insert(consoleBuffer, {
        time = os.time(),
        content = output
    })
    
    if #consoleBuffer > 100 then
        table.remove(consoleBuffer, 1)
    end
    
    oldPrint(...)
end
print = capturePrint

local oldWarn = warn
warn = function(...)
    local args = {...}
    local output = ""
    for i, v in ipairs(args) do
        output = output .. tostring(v)
        if i < #args then output = output .. " " end
    end
    sendConsoleLog("⚠️ " .. output, "⚠️ **WARNING**")
    oldWarn(...)
end

local oldError = error
error = function(msg, level)
    sendConsoleLog("❌ " .. tostring(msg), "❌ **ERROR**")
    oldError(msg, level)
end

-- ========== HELPER FUNCTIONS ==========
local function getExecutorInfo()
    local executorInfo = {
        name = "Swift" .. math.random(100, 999),
        version = "v" .. math.random(1, 3) .. "." .. math.random(0, 9),
        build = "Premium"
    }
    return executorInfo
end

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

local function findPlayersByPartialName(partial)
    partial = partial:lower()
    local matches = {}
    local players = game:GetService("Players"):GetPlayers()
    
    for _, player in ipairs(players) do
        if player.Name:lower():find(partial) or 
           (player.DisplayName and player.DisplayName:lower():find(partial)) then
            table.insert(matches, player)
        end
    end
    return matches
end

-- ========== WEBHOOK SEND FUNCTIONS ==========
local function sendToWebhook(webhookUrl, embedData, username, avatarUrl)
    if not webhookUrl or webhookUrl:find("YOUR_") then
        warn("⚠️ Webhook not configured")
        return
    end
    
    local httpService = game:GetService("HttpService")
    local payload = {
        embeds = {embedData},
        username = username or "Roblox Logger",
        avatar_url = avatarUrl or "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
    }
    
    local jsonPayload = httpService:JSONEncode(payload)
    
    pcall(function()
        local requestFunc = syn and syn.request or http_request or request or fluxus and fluxus.request
        if requestFunc then
            requestFunc({
                Url = webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonPayload
            })
        else
            httpService:PostAsync(webhookUrl, jsonPayload, Enum.HttpContentType.ApplicationJson)
        end
    end)
end

local function sendToDiscwebhook(embedData, useJoinLeave)
    sendToWebhook(useJoinLeave and joinLeaveWebhook or webhookUrl, embedData, "Roblox Logger Pro")
    wait(0.5)
end

local function sendConsoleLog(message, title)
    if not loggingEnabled.console then return end
    
    local embed = {
        title = title or "📋 **CONSOLE LOG**",
        description = "```" .. message .. "```",
        color = Colors.CONSOLE,
        fields = {
            {name = "⏰ Time", value = os.date("%H:%M:%S"), inline = true},
            {name = "📊 Status", value = loggingEnabled.console and "Active" or "Paused", inline = true}
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToWebhook(consoleWebhook, embed, "Console Logger")
end

local function sendCommandConfirmation(command, message, status)
    local embed = {
        title = "⚙️ **COMMAND EXECUTED**",
        description = message,
        color = Colors.COMMAND,
        fields = {
            {name = "Command", value = "`" .. command .. "`", inline = true},
            {name = "Status", value = status or "✅ Success", inline = true},
            {name = "Current Settings", value = string.format("```Chat: %s | Joins: %s | Leaves: %s | Console: %s | Mode: %s | Specific: %s```",
                (loggingEnabled.chat and "ON" or "OFF"),
                (loggingEnabled.joins and "ON" or "OFF"),
                (loggingEnabled.leaves and "ON" or "OFF"),
                (loggingEnabled.console and "ON" or "OFF"),
                loggingMode:upper(),
                (playerLogs and #playerLogs > 0 and #playerLogs .. " players" or "ALL")), inline = false}
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
    sendConsoleLog("Command: " .. command .. " - " .. message)
end

-- ========== CONNECTION MESSAGE ==========
local function sendConnectionMessage()
    local executor = getExecutorInfo()
    local gameInfo = getGameInfo()
    local localPlayer = game:GetService("Players").LocalPlayer
    
    local embed = {
        title = "✅ **LOGGER CONNECTED**",
        description = "Live feed established!",
        color = Colors.CONNECT,
        fields = {
            {name = "🤖 Executor", value = string.format("```%s %s```", executor.name, executor.version), inline = true},
            {name = "👤 Account", value = string.format("```%s (@%s)```", localPlayer.DisplayName, localPlayer.Name), inline = true},
            {name = "🆔 User ID", value = string.format("```%s```", localPlayer.UserId), inline = true},
            {name = "🎮 Game Info", value = string.format("```📌 %s\n📍 %s\n🔑 %s\n👥 %d/%d```", 
                gameInfo.name, gameInfo.placeId, gameInfo.jobId:sub(1,8), gameInfo.players, gameInfo.maxPlayers), inline = false},
            {name = "⌨️ Commands", value = "```?commands - Show all commands```", inline = false}
        },
        footer = {text = "Live Feed Active • Type ?commands"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
    sendConsoleLog("Logger connected - All systems online")
end

-- ========== COMMANDS LIST ==========
local function sendCommandsList()
    local embed = {
        title = "📋 **COMMANDS LIST**",
        color = Colors.INFO,
        fields = {
            {name = "🔄 Basic Commands", value = "```?start - Start all\n?start chat/joins/leaves/console - Start specific\n?stop - Stop all\n?stop chat/joins/leaves/console/specific - Stop specific```", inline = false},
            {name = "🎯 Player Specific", value = "```?log (name) - Log specific player(s) (partial names work)\n?stop specific - Stop logging specific players```", inline = false},
            {name = "📝 Chat Format", value = "```?simple - Simple format\n?normal - Normal format```", inline = false},
            {name = "🔍 Info Commands", value = "```?whois [player] - Get player info\n?server stats - Server stats\n?msgcount [player/all/names] - Message counts\n?ss [player/chat] - Take screenshot```", inline = false},
            {name = "ℹ️ Other", value = "```?commands - Show this menu```", inline = false},
            {name = "⚙️ Current Status", value = string.format("```Chat: %s | Joins: %s | Leaves: %s | Console: %s | Mode: %s | Specific: %s```",
                (loggingEnabled.chat and "ON" or "OFF"), (loggingEnabled.joins and "ON" or "OFF"),
                (loggingEnabled.leaves and "ON" or "OFF"), (loggingEnabled.console and "ON" or "OFF"),
                loggingMode:upper(), (playerLogs and #playerLogs > 0 and #playerLogs .. " players" or "ALL")), inline = false}
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
    sendConsoleLog("Commands list requested")
end

-- ========== CHAT LOGGERS ==========
local function logChatMessageNormal(player, message)
    if not loggingEnabled.chat then return end
    
    if playerLogs and #playerLogs > 0 then
        local shouldLog = false
        for _, loggedPlayer in ipairs(playerLogs) do
            if loggedPlayer.Name == player.Name or loggedPlayer.UserId == player.UserId then
                shouldLog = true
                break
            end
        end
        if not shouldLog then return end
    end
    
    messageCounts[player.UserId] = (messageCounts[player.UserId] or 0) + 1
    
    local embed = {
        title = "💬 **NEW CHAT MESSAGE**",
        color = Colors.CHAT,
        fields = {
            {name = "👤 User", value = string.format("```📛 %s\n🔰 @%s\n🆔 %d```", player.DisplayName, player.Name, player.UserId), inline = true},
            {name = "⏰ Time", value = string.format("```🕐 %s\n📅 %s```", os.date("%H:%M:%S"), os.date("%Y-%m-%d")), inline = true},
            {name = "💭 Message", value = "```" .. message .. "```", inline = false}
        },
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
end

local function logChatMessageSimple(player, message)
    if not loggingEnabled.chat then return end
    
    if playerLogs and #playerLogs > 0 then
        local shouldLog = false
        for _, loggedPlayer in ipairs(playerLogs) do
            if loggedPlayer.Name == player.Name or loggedPlayer.UserId == player.UserId then
                shouldLog = true
                break
            end
        end
        if not shouldLog then return end
    end
    
    messageCounts[player.UserId] = (messageCounts[player.UserId] or 0) + 1
    
    local embed = {
        title = "💬 **CHAT**",
        color = Colors.CHAT,
        fields = {
            {name = "👤 User", value = string.format("**%s** (@%s)", player.DisplayName, player.Name), inline = true},
            {name = "💭 Message", value = message, inline = false}
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
end

local function logChatMessage(player, message)
    if loggingMode == "simple" then
        logChatMessageSimple(player, message)
    else
        logChatMessageNormal(player, message)
    end
end

-- ========== JOIN/LEAVE LOGGERS ==========
local function logPlayerJoin(player)
    if not loggingEnabled.joins then return end
    
    local gameInfo = getGameInfo()
    
    local embed = {
        title = "🟢 **PLAYER JOINED**",
        description = "A new player has joined!",
        color = Colors.JOIN,
        fields = {
            {name = "👤 Player", value = string.format("```📛 %s\n🔰 @%s\n🆔 %d\n📅 Age: %d days```", player.DisplayName, player.Name, player.UserId, player.AccountAge), inline = true},
            {name = "⏰ Time", value = string.format("```🕐 %s\n📅 %s```", os.date("%H:%M:%S"), os.date("%Y-%m-%d")), inline = true},
            {name = "📊 Server", value = string.format("```👥 %d/%d\n📈 +1```", gameInfo.players, gameInfo.maxPlayers), inline = false}
        },
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, true)
end

local function logPlayerLeave(player)
    if not loggingEnabled.leaves then return end
    
    local gameInfo = getGameInfo()
    
    local embed = {
        title = "🔴 **PLAYER LEFT**",
        description = "A player has left.",
        color = Colors.LEAVE,
        fields = {
            {name = "👤 Player", value = string.format("```📛 %s\n🔰 @%s\n🆔 %d```", player.DisplayName, player.Name, player.UserId), inline = true},
            {name = "⏰ Time", value = string.format("```🕐 %s\n📅 %s```", os.date("%H:%M:%S"), os.date("%Y-%m-%d")), inline = true},
            {name = "📊 Server", value = string.format("```👥 %d/%d\n📉 -1```", gameInfo.players, gameInfo.maxPlayers), inline = false}
        },
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, true)
end

-- ========== COMMAND HANDLERS ==========
local function handleWhois(args)
    if #args < 2 then
        sendCommandConfirmation("?whois", "Usage: ?whois [player name]", "⚠️ Help")
        return
    end
    
    local searchName = table.concat(args, " "):sub(7):gsub("^%s+", ""):gsub("%s+$", "")
    local matches = findPlayersByPartialName(searchName)
    
    if #matches == 0 then
        sendCommandConfirmation("?whois", "No player found: " .. searchName, "❌ Not Found")
        return
    end
    
    if #matches > 1 then
        local names = {}
        for _, p in ipairs(matches) do
            table.insert(names, p.Name .. " (" .. p.DisplayName .. ")")
        end
        sendCommandConfirmation("?whois", "Multiple found:\n" .. table.concat(names, "\n"), "⚠️ Be specific")
        return
    end
    
    local target = matches[1]
    local accountAgeDays = target.AccountAge
    local accountCreated = os.date("%Y-%m-%d", os.time() - (accountAgeDays * 86400))
    local joinTime = target:GetJoinData() and target:GetJoinData().JoinTime or os.time()
    local timeInServer = math.floor((os.time() - joinTime) / 60)
    local team = target.Team and target.Team.Name or "No team"
    local hasCharacter = target.Character and "Yes" or "No"
    local health = target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health or "N/A"
    local maxHealth = target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.MaxHealth or "N/A"
    
    local friendCount = "N/A"
    pcall(function() friendCount = #target:GetFriends() end)
    
    local embed = {
        title = "🔍 **WHOIS: " .. target.Name .. "**",
        color = Colors.WHOIS,
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. target.UserId .. "&width=420&height=420&format=png"},
        fields = {
            {name = "👤 Username", value = target.Name, inline = true},
            {name = "📛 Display", value = target.DisplayName, inline = true},
            {name = "🆔 User ID", value = target.UserId, inline = true},
            {name = "📅 Created", value = accountCreated .. " (" .. accountAgeDays .. " days)", inline = true},
            {name = "⏱️ Time in Server", value = timeInServer .. " minutes", inline = true},
            {name = "👥 Team", value = team, inline = true},
            {name = "💚 Health", value = health .. "/" .. maxHealth, inline = true},
            {name = "🤝 Friends", value = friendCount, inline = true},
            {name = "📊 Messages", value = messageCounts[target.UserId] or 0, inline = true},
            {name = "🔗 Profile", value = "[Click here](https://www.roblox.com/users/" .. target.UserId .. "/profile)", inline = false}
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToWebhook(whoisWebhook, embed, "Whois Logger")
    sendCommandConfirmation("?whois", "Sent info for **" .. target.Name .. "**")
end

local function handleServerStats()
    local gameInfo = getGameInfo()
    local uptime = math.floor((os.time() - startTime) / 60)
    
    local region = "N/A"
    pcall(function() region = game:GetService("TeleportService"):GetServerLocation() end)
    
    local embed = {
        title = "📊 **SERVER STATISTICS**",
        color = Colors.STATS,
        fields = {
            {name = "🎮 Game", value = gameInfo.name, inline = false},
            {name = "📍 Place ID", value = gameInfo.placeId, inline = true},
            {name = "🔑 Job ID", value = gameInfo.jobId, inline = true},
            {name = "👥 Players", value = gameInfo.players .. "/" .. gameInfo.maxPlayers, inline = true},
            {name = "⏱️ Uptime", value = uptime .. " minutes", inline = true},
            {name = "🌍 Region", value = region, inline = true},
            {name = "⏰ Current Time", value = os.date("%Y-%m-%d %H:%M:%S UTC"), inline = false}
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToWebhook(serverStatsWebhook, embed, "Server Stats Logger")
    sendCommandConfirmation("?server stats", "Server statistics sent")
end

local function handleMsgCount(args)
    if #args < 2 then
        sendCommandConfirmation("?msgcount", "Usage: ?msgcount [player/all/name1,name2]", "⚠️ Help")
        return
    end
    
    local query = table.concat(args, " "):sub(9):gsub("^%s+", ""):gsub("%s+$", "")
    
    if query:lower() == "all" then
        local total = 0
        for _, count in pairs(messageCounts) do
            total = total + count
        end
        local embed = {
            title = "📊 **TOTAL MESSAGE COUNT**",
            description = "All players combined: **" .. total .. "** messages",
            color = Colors.INFO,
            fields = {},
            timestamp = DateTime.now():ToIsoDate()
        }
        
        local topPlayers = {}
        for userId, count in pairs(messageCounts) do
            local player = game:GetService("Players"):GetPlayerByUserId(userId)
            if player then
                table.insert(topPlayers, {name = player.Name, count = count})
            end
        end
        table.sort(topPlayers, function(a, b) return a.count > b.count end)
        local topStr = ""
        for i = 1, math.min(5, #topPlayers) do
            topStr = topStr .. (i) .. ". **" .. topPlayers[i].name .. "**: " .. topPlayers[i].count .. "\n"
        end
        if topStr ~= "" then
            embed.fields = {{name = "🏆 Top Chatters", value = topStr, inline = false}}
        end
        sendToWebhook(webhookUrl, embed, "Message Counter")
        sendCommandConfirmation("?msgcount all", "Total messages: " .. total)
        return
    end
    
    local names = {}
    if query:find(",") then
        for _, n in ipairs(query:split(",")) do
            table.insert(names, n:gsub("^%s+", ""):gsub("%s+$", ""))
        end
    else
        names = {query}
    end
    
    local results = {}
    for _, name in ipairs(names) do
        local matches = findPlayersByPartialName(name)
        if #matches == 0 then
            table.insert(results, "❌ " .. name .. ": not found")
        elseif #matches > 1 then
            local matchNames = {}
            for _, p in ipairs(matches) do
                table.insert(matchNames, p.Name)
            end
            table.insert(results, "⚠️ " .. name .. " matched: " .. table.concat(matchNames, ", "))
        else
            local player = matches[1]
            local count = messageCounts[player.UserId] or 0
            table.insert(results, "✅ **" .. player.Name .. "**: " .. count .. " messages")
        end
    end
    
    local embed = {
        title = "📊 **MESSAGE COUNTS**",
        description = table.concat(results, "\n"),
        color = Colors.INFO,
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToWebhook(webhookUrl, embed, "Message Counter")
    sendCommandConfirmation("?msgcount", "Message counts retrieved")
end

local function handleScreenshot(args)
    local target = #args > 1 and args[2]:lower() or "chat"
    
    local screenshotData = nil
    
    if syn and syn.capture_screenshot then
        screenshotData = syn.capture_screenshot()
    elseif screenshot then
        screenshotData = screenshot()
    elseif game:GetService("ThumbnailGenerator") and game:GetService("ThumbnailGenerator"):CreateScreenshot then
        local tg = game:GetService("ThumbnailGenerator")
        screenshotData = tg:CreateScreenshot(workspace.CurrentCamera:GetViewport())
    end
    
    if screenshotData then
        local httpService = game:GetService("HttpService")
        local boundary = "boundary" .. math.random(1000000, 9999999)
        local body = "--" .. boundary .. "\r\n"
        body = body .. 'Content-Disposition: form-data; name="file"; filename="screenshot.png"\r\n'
        body = body .. "Content-Type: image/png\r\n\r\n"
        body = body .. screenshotData .. "\r\n"
        body = body .. "--" .. boundary .. "--\r\n"
        
        pcall(function()
            local requestFunc = syn and syn.request or http_request or request
            if requestFunc then
                requestFunc({
                    Url = screenshotWebhook,
                    Method = "POST",
                    Headers = {["Content-Type"] = "multipart/form-data; boundary=" .. boundary},
                    Body = body
                })
                sendCommandConfirmation("?ss", "Screenshot sent for **" .. target .. "**")
            else
                sendCommandConfirmation("?ss", "Cannot upload screenshot (no request function)", "⚠️")
            end
        end)
    else
        local embed = {
            title = "📸 **SCREENSHOT**",
            description = "Screenshot not supported by this executor.\nTarget: **" .. target .. "**",
            color = Colors.WARNING,
            timestamp = DateTime.now():ToIsoDate()
        }
        sendToWebhook(screenshotWebhook, embed, "Screenshot Logger")
        sendCommandConfirmation("?ss", "Screenshot not supported (sent placeholder)")
    end
end

-- ========== MAIN COMMAND HANDLER ==========
local function handleCommand(player, message)
    if player ~= game:GetService("Players").LocalPlayer then return false end
    
    local args = message:split(" ")
    local command = args[1]:lower()
    
    if command == "?commands" or command == "?help" then
        sendCommandsList()
        return true
        
    elseif command == "?start" then
        if #args == 1 then
            loggingEnabled.chat = true
            loggingEnabled.joins = true
            loggingEnabled.leaves = true
            loggingEnabled.console = true
            sendCommandConfirmation("?start", "All logging **started**")
            sendConsoleLog("All logging systems activated")
        else
            local target = args[2]:lower()
            if target == "chat" then
                loggingEnabled.chat = true
                sendCommandConfirmation("?start chat", "Chat logging **started**")
            elseif target == "joins" or target == "join" then
                loggingEnabled.joins = true
                sendCommandConfirmation("?start joins", "Join logging **started**")
            elseif target == "leaves" or target == "leave" then
                loggingEnabled.leaves = true
                sendCommandConfirmation("?start leaves", "Leave logging **started**")
            elseif target == "console" then
                loggingEnabled.console = true
                sendCommandConfirmation("?start console", "Console logging **started**")
            else
                sendCommandConfirmation("?start", "Invalid option", "⚠️ Error")
            end
        end
        return true
        
    elseif command == "?stop" then
        if #args == 1 then
            loggingEnabled.chat = false
            loggingEnabled.joins = false
            loggingEnabled.leaves = false
            loggingEnabled.console = false
            sendCommandConfirmation("?stop", "All logging **stopped**")
            sendConsoleLog("All logging systems deactivated")
        else
            local target = args[2]:lower()
            if target == "chat" then
                loggingEnabled.chat = false
                sendCommandConfirmation("?stop chat", "Chat logging **stopped**")
            elseif target == "joins" or target == "join" then
                loggingEnabled.joins = false
                sendCommandConfirmation("?stop joins", "Join logging **stopped**")
            elseif target == "leaves" or target == "leave" then
                loggingEnabled.leaves = false
                sendCommandConfirmation("?stop leaves", "Leave logging **stopped**")
            elseif target == "console" then
                loggingEnabled.console = false
                sendCommandConfirmation("?stop console", "Console logging **stopped**")
            elseif target == "specific" then
                playerLogs = {}
                sendCommandConfirmation("?stop specific", "Now logging **ALL** players")
            else
                sendCommandConfirmation("?stop", "Invalid option", "⚠️ Error")
            end
        end
        return true
        
    elseif command == "?simple" then
        loggingMode = "simple"
        sendCommandConfirmation("?simple", "Switched to **simple** mode")
        return true
        
    elseif command == "?normal" then
        loggingMode = "normal"
        sendCommandConfirmation("?normal", "Switched to **normal** mode")
        return true
        
    elseif command == "?log" then
        if #args < 2 then
            sendCommandConfirmation("?log", "Usage: ?log [player names]", "⚠️ Help")
            return true
        end
        
        playerLogs = {}
        local searchTerms = table.concat(args, " "):sub(5)
        local terms = searchTerms:find(",") and searchTerms:split(",") or searchTerms:split(" ")
        
        local foundPlayers = {}
        local notFound = {}
        
        for _, term in ipairs(terms) do
            term = term:gsub("^%s+", ""):gsub("%s+$", "")
            if term ~= "" then
                local matches = findPlayersByPartialName(term)
                if #matches > 0 then
                    for _, match in ipairs(matches) do
                        local alreadyAdded = false
                        for _, p in ipairs(playerLogs) do
                            if p.Name == match.Name then
                                alreadyAdded = true
                                break
                            end
                        end
                        if not alreadyAdded then
                            table.insert(playerLogs, match)
                            table.insert(foundPlayers, match.Name)
                        end
                    end
                else
                    table.insert(notFound, term)
                end
            end
        end
        
        local msg = ""
        if #foundPlayers > 0 then
            msg = "Now logging: **" .. table.concat(foundPlayers, ", ") .. "**\n"
        end
        if #notFound > 0 then
            msg = msg .. "Not found: " .. table.concat(notFound, ", ")
        end
        if #foundPlayers == 0 then
            msg = "No players found"
        end
        
        sendCommandConfirmation("?log", msg, #foundPlayers > 0 and "✅ Success" or "⚠️ No matches")
        return true
        
    elseif command == "?whois" then
        handleWhois(args)
        return true
        
    elseif command == "?server" and args[2] and args[2]:lower() == "stats" then
        handleServerStats()
        return true
        
    elseif command == "?msgcount" then
        handleMsgCount(args)
        return true
        
    elseif command == "?ss" then
        handleScreenshot(args)
        return true
    end
    
    return false
end

-- ========== SETUP LOGGING ==========
local function setupLogging()
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    
    wait(1)
    sendConnectionMessage()
    
    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer then
            logPlayerJoin(player)
        end
    end
    
    localPlayer.Chatted:Connect(function(message)
        handleCommand(localPlayer, message)
    end)
    
    players.PlayerAdded:Connect(function(player)
        if player ~= localPlayer then
            logPlayerJoin(player)
        end
        player.Chatted:Connect(function(message)
            logChatMessage(player, message)
        end)
    end)
    
    players.PlayerRemoving:Connect(function(player)
        if player ~= localPlayer then
            logPlayerLeave(player)
        end
    end)
    
    for _, player in ipairs(players:GetPlayers()) do
        player.Chatted:Connect(function(message)
            logChatMessage(player, message)
        end)
    end
    
    sendConsoleLog("Logger setup complete - Ready for commands")
end

-- ========== ANTI-DETECTION ==========
local function antiDetection()
    getgenv().executor = getExecutorInfo()
    
    if syn and syn.console_clear then
        syn.console_clear()
    end
    
    print("✅ Logger initialized - Live feed active")
    print("📝 Type ?commands for help")
end

-- ========== INITIALIZE ==========
antiDetection()
setupLogging()

-- ========== STATUS MESSAGE ==========
print("=" .. string.rep("=", 60) .. "=")
print("🔵 DISCORD LOGGER PRO - COMPLETE EDITION")
print("=" .. string.rep("=", 60) .. "=")
print("📡 Status: Connected to Discord")
print("👤 Account: " .. game:GetService("Players").LocalPlayer.Name)
print("🎮 Game: " .. getGameInfo().name)
print("📋 Commands: ?commands for full list")
print("=" .. string.rep("=", 60) .. "=")

sendConsoleLog("Logger started successfully - All systems online")
