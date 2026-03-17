-- ============================================
-- DISCORD LOGGER PRO - ULTIMATE EDITION
-- All Commands + Performance + Uptime + Serverhop + Console
-- ============================================

-- ========== WEBHOOK CONFIGURATION ==========
local webhookUrl = "https://discord.com/api/webhooks/1482913836423057428/fYSkY7XfawDG3ClH3tMmsymEzZjqKyiZH4q3LCZSV6_ztlAy7wOkdl22ZYLNZUfQevEi" -- Main webhook for connection & chat
local joinLeaveWebhook = "https://discord.com/api/webhooks/1482913976294572215/hiFyivZJqHlMtf5e4c_QcIwowxbV2xbqYX4Kt4Mkwyxbigq_mrA-d2xvHhWNtRgL0c7N" -- Separate webhook for joins & leaves
local whoisWebhook = "https://discord.com/api/webhooks/1483184762926403846/p4auNyoTdXl79RoY-8v_ngDQiRXS3ulCCHFpH5lWuN5G2w_F_ow6fVACmEOkaIK5S0uC" -- For ?whois command
local serverStatsWebhook = "https://discord.com/api/webhooks/1483183902783967233/0bR3I2G5qHXGmfP2IpE4tJ0jY7FHz0JeEpwSh4l8_G09tUDeiRzaKsuSlGl7zP0CnApu" -- For ?server stats

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
local commandHistory = {}
local serverhopEnabled = false
local currentServer = game.JobId

-- ========== COLOR CONSTANTS ==========
local Colors = {
    CONNECT = 5763719,
    CHAT = 1752220,
    JOIN = 3066993,
    LEAVE = 15158332,
    INFO = 5814783,
    WARNING = 16776960,
    COMMAND = 15277667,
    WHOIS = 10181046,
    STATS = 15844367,
    SUCCESS = 3066993,
    ERROR = 15158332,
    DIVIDER = 12312312,
    ALERT = 16776960,
    PERFORMANCE = 10181046,
    UPTIME = 15844367,
    CONSOLE = 12312312
}

-- ========== CONSOLE LOGGING SYSTEM ==========
local consoleBuffer = {}
local consoleEnabled = true

-- Enhanced print function that logs to console AND Discord
local oldPrint = print
print = function(...)
    local args = {...}
    local output = ""
    for i, v in ipairs(args) do
        output = output .. tostring(v)
        if i < #args then output = output .. " " end
    end
    
    -- Add to console buffer
    table.insert(consoleBuffer, {
        time = os.time(),
        content = output,
        type = "print"
    })
    if #consoleBuffer > 100 then table.remove(consoleBuffer, 1) end
    
    -- Send to Discord console if enabled
    if consoleEnabled and loggingEnabled.console then
        local embed = {
            title = "📋 **CONSOLE LOG**",
            description = "──────────────────────────────",
            color = Colors.CONSOLE,
            fields = {
                {name = "📝 **Message**", value = "──────────────────────────────", inline = false},
                {name = "Content", value = "```" .. output .. "```", inline = false},
                {name = "⏰ **Timestamp**", value = "──────────────────────────────", inline = false},
                {name = "🕐 Time", value = os.date("%H:%M:%S"), inline = true},
                {name = "📅 Date", value = os.date("%Y-%m-%d"), inline = true},
                {name = "📊 Type", value = "Print", inline = true}
            },
            footer = {text = "Console Logger • Live Feed"},
            timestamp = DateTime.now():ToIsoDate()
        }
        sendToWebhook(webhookUrl, embed, "Console Logger")
    end
    
    -- Call original print
    oldPrint(...)
end

-- Enhanced warn function
local oldWarn = warn
warn = function(...)
    local args = {...}
    local output = ""
    for i, v in ipairs(args) do
        output = output .. tostring(v)
        if i < #args then output = output .. " " end
    end
    
    table.insert(consoleBuffer, {
        time = os.time(),
        content = output,
        type = "warn"
    })
    if #consoleBuffer > 100 then table.remove(consoleBuffer, 1) end
    
    if consoleEnabled and loggingEnabled.console then
        local embed = {
            title = "⚠️ **CONSOLE WARNING**",
            description = "──────────────────────────────",
            color = Colors.WARNING,
            fields = {
                {name = "📝 **Warning**", value = "──────────────────────────────", inline = false},
                {name = "Content", value = "```" .. output .. "```", inline = false},
                {name = "⏰ **Timestamp**", value = "──────────────────────────────", inline = false},
                {name = "🕐 Time", value = os.date("%H:%M:%S"), inline = true},
                {name = "📅 Date", value = os.date("%Y-%m-%d"), inline = true},
                {name = "📊 Type", value = "Warning", inline = true}
            },
            footer = {text = "Console Logger • Warning"},
            timestamp = DateTime.now():ToIsoDate()
        }
        sendToWebhook(webhookUrl, embed, "Console Logger")
    end
    
    oldWarn(...)
end

-- Enhanced error function
local oldError = error
error = function(msg, level)
    table.insert(consoleBuffer, {
        time = os.time(),
        content = tostring(msg),
        type = "error"
    })
    if #consoleBuffer > 100 then table.remove(consoleBuffer, 1) end
    
    if consoleEnabled and loggingEnabled.console then
        local embed = {
            title = "❌ **CONSOLE ERROR**",
            description = "──────────────────────────────",
            color = Colors.ERROR,
            fields = {
                {name = "📝 **Error**", value = "──────────────────────────────", inline = false},
                {name = "Content", value = "```" .. tostring(msg) .. "```", inline = false},
                {name = "⏰ **Timestamp**", value = "──────────────────────────────", inline = false},
                {name = "🕐 Time", value = os.date("%H:%M:%S"), inline = true},
                {name = "📅 Date", value = os.date("%Y-%m-%d"), inline = true},
                {name = "📊 Type", value = "Error", inline = true}
            },
            footer = {text = "Console Logger • Error"},
            timestamp = DateTime.now():ToIsoDate()
        }
        sendToWebhook(webhookUrl, embed, "Console Logger")
    end
    
    oldError(msg, level)
end

-- ========== WEBHOOK SEND FUNCTIONS ==========
local function sendToWebhook(webhookUrl, embedData, username)
    if not webhookUrl then return end
    
    local httpService = game:GetService("HttpService")
    
    -- Try multiple methods to send webhook
    local methods = {
        -- Method 1: Synapse request
        function()
            if syn and syn.request then
                syn.request({
                    Url = webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = httpService:JSONEncode({
                        embeds = {embedData},
                        username = username or "Logger",
                        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
                    })
                })
                return true
            end
            return false
        end,
        
        -- Method 2: Krnl request
        function()
            if http_request then
                http_request({
                    Url = webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = httpService:JSONEncode({
                        embeds = {embedData},
                        username = username or "Logger",
                        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
                    })
                })
                return true
            end
            return false
        end,
        
        -- Method 3: Fluxus request
        function()
            if fluxus and fluxus.request then
                fluxus.request({
                    Url = webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = httpService:JSONEncode({
                        embeds = {embedData},
                        username = username or "Logger",
                        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
                    })
                })
                return true
            end
            return false
        end,
        
        -- Method 4: Generic request
        function()
            if request then
                request({
                    Url = webhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = httpService:JSONEncode({
                        embeds = {embedData},
                        username = username or "Logger",
                        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
                    })
                })
                return true
            end
            return false
        end,
        
        -- Method 5: PostAsync (last resort)
        function()
            pcall(function()
                httpService:PostAsync(webhookUrl, httpService:JSONEncode({
                    embeds = {embedData},
                    username = username or "Logger",
                    avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png"
                }), Enum.HttpContentType.ApplicationJson)
            end)
            return true
        end
    }
    
    for _, method in ipairs(methods) do
        if method() then
            break
        end
    end
end

local function sendToDiscwebhook(embedData, useJoinLeave)
    sendToWebhook(useJoinLeave and joinLeaveWebhook or webhookUrl, embedData, "Logger")
    wait(0.5)
end

-- ========== ENHANCED COMMAND EMBEDS WITH ALERTS ==========
local function sendCommandEmbed(command, executor, status, details, alertType)
    local gameInfo = getGameInfo()
    local localPlayer = game:GetService("Players").LocalPlayer
    
    -- Add to command history
    table.insert(commandHistory, {
        command = command,
        time = os.time(),
        status = status,
        executor = executor
    })
    if #commandHistory > 10 then table.remove(commandHistory, 1) end
    
    local statusColor = status == "Success" and Colors.SUCCESS or (status == "Error" and Colors.ERROR or Colors.WARNING)
    local statusEmoji = status == "Success" and "✅" or (status == "Error" and "❌" or "⚠️")
    
    -- Special alert for mode changes
    if alertType == "mode_change" then
        statusColor = Colors.ALERT
        statusEmoji = "🔄"
    end
    
    local embed = {
        title = "🎮 **COMMAND EXECUTED**",
        description = "──────────────────────────────\n**Command Alert**\n──────────────────────────────",
        color = statusColor,
        fields = {
            {name = "📋 **Command Details**", value = "──────────────────────────────", inline = false},
            {name = "⌨️ Command", value = "```" .. command .. "```", inline = true},
            {name = "👤 Executor", value = string.format("%s (@%s)", localPlayer.DisplayName, localPlayer.Name), inline = true},
            {name = "🆔 User ID", value = localPlayer.UserId, inline = true},
            {name = "📊 Status", value = string.format("%s %s", statusEmoji, status), inline = true},
            {name = "⏰ Time", value = os.date("%H:%M:%S"), inline = true},
            {name = "📅 Date", value = os.date("%Y-%m-%d"), inline = true},
            
            {name = "📝 **Command Details**", value = "──────────────────────────────", inline = false},
            {name = "ℹ️ Information", value = details or "Command executed successfully", inline = false},
            
            {name = "⚙️ **Current Settings**", value = "──────────────────────────────", inline = false},
            {name = "💬 Chat", value = (loggingEnabled.chat and "✅ ON" or "❌ OFF"), inline = true},
            {name = "🟢 Joins", value = (loggingEnabled.joins and "✅ ON" or "❌ OFF"), inline = true},
            {name = "🔴 Leaves", value = (loggingEnabled.leaves and "✅ ON" or "❌ OFF"), inline = true},
            {name = "📝 Mode", value = loggingMode:upper(), inline = true},
            {name = "🎯 Specific", value = (playerLogs and #playerLogs > 0 and #playerLogs .. " players" or "ALL"), inline = true},
            {name = "👥 Players", value = gameInfo.players .. "/" .. gameInfo.maxPlayers, inline = true},
            {name = "🔄 Serverhop", value = (serverhopEnabled and "✅ ON" or "❌ OFF"), inline = true},
            {name = "📋 Console", value = (consoleEnabled and "✅ ON" or "❌ OFF"), inline = true},
            
            {name = "📊 **Server Info**", value = "──────────────────────────────", inline = false},
            {name = "🎮 Game", value = gameInfo.name, inline = false},
            {name = "📍 Place ID", value = gameInfo.placeId, inline = true},
            {name = "🔑 Job ID", value = gameInfo.jobId:sub(1,8), inline = true}
        },
        footer = {text = "Command Logger • Live Feed • Alert System Active"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
    
    -- Also log to console
    if consoleEnabled then
        oldPrint(string.format("[COMMAND] %s executed by %s - %s", command, executor, status))
    end
end

-- ========== HELPER FUNCTIONS ==========
local function getExecutorInfo()
    local executorInfo = {
        name = "Logger" .. math.random(100, 999),
        version = "v" .. math.random(1, 3) .. "." .. math.random(0, 9),
        build = "Premium"
    }
    return executorInfo
end

local function getGameInfo()
    local success, productInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    
    local gameInfo = {
        name = (success and productInfo.Name) or "Unknown Game",
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

-- ========== CONNECTION MESSAGE ==========
local function sendConnectionMessage()
    local executor = getExecutorInfo()
    local gameInfo = getGameInfo()
    local localPlayer = game:GetService("Players").LocalPlayer
    
    local embed = {
        title = "✅ **LOGGER CONNECTED**",
        description = "──────────────────────────────\n**Live feed has been established successfully!**\n──────────────────────────────",
        color = Colors.CONNECT,
        fields = {
            {name = "🤖 **Executor Information**", value = "──────────────────────────────", inline = false},
            {name = "🤖 Name", value = executor.name, inline = true},
            {name = "📦 Version", value = executor.version, inline = true},
            {name = "🏗️ Build", value = executor.build, inline = true},
            
            {name = "👤 **Account Information**", value = "──────────────────────────────", inline = false},
            {name = "👤 Display", value = localPlayer.DisplayName, inline = true},
            {name = "🔰 Username", value = "@" .. localPlayer.Name, inline = true},
            {name = "🆔 User ID", value = localPlayer.UserId, inline = true},
            
            {name = "🎮 **Game Information**", value = "──────────────────────────────", inline = false},
            {name = "🎮 Name", value = gameInfo.name, inline = false},
            {name = "📍 Place ID", value = gameInfo.placeId, inline = true},
            {name = "🔑 Job ID", value = gameInfo.jobId:sub(1,8) .. "...", inline = true},
            {name = "👥 Players", value = gameInfo.players .. "/" .. gameInfo.maxPlayers, inline = true},
            
            {name = "⌨️ **Available Commands**", value = "──────────────────────────────", inline = false},
            {name = "Commands", value = "```?commands - Show all commands with current values\n?performance [player] - Check player performance\n?uptime - Show server uptime\n?serverhop - Toggle server following\n?console - Toggle console logging\n?start/stop - Control logging\n?log - Track specific players\n?whois - Player info\n?server stats - Server info\n?msgcount - Message counts```", inline = false}
        },
        footer = {text = "Type ?commands for full command list with current values • Live Feed Active"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
    
    -- Console log
    if consoleEnabled then
        oldPrint("[SYSTEM] Logger connected - All systems online")
    end
end

-- ========== ENHANCED COMMANDS LIST WITH CURRENT VALUES ==========
local function sendCommandsList()
    local gameInfo = getGameInfo()
    local localPlayer = game:GetService("Players").LocalPlayer
    local uptime = math.floor((os.time() - startTime) / 60)
    
    local embed = {
        title = "📋 **COMMANDS LIST**",
        description = "──────────────────────────────\n**All Available Commands with Current Values**\n──────────────────────────────",
        color = Colors.INFO,
        fields = {
            {name = "🔄 **Basic Commands**", value = "──────────────────────────────", inline = false},
            {name = "?start", value = "Start all logging", inline = true},
            {name = "?stop", value = "Stop all logging", inline = true},
            {name = "?start chat", value = "Start chat only", inline = true},
            {name = "?start joins", value = "Start joins only", inline = true},
            {name = "?start leaves", value = "Start leaves only", inline = true},
            {name = "?stop chat", value = "Stop chat only", inline = true},
            {name = "?stop joins", value = "Stop joins only", inline = true},
            {name = "?stop leaves", value = "Stop leaves only", inline = true},
            {name = "?stop specific", value = "Stop player-specific", inline = true},
            
            {name = "🎯 **Player Commands**", value = "──────────────────────────────", inline = false},
            {name = "?log [names]", value = "Log specific players", inline = false},
            {name = "?whois [player]", value = "Get detailed player info", inline = false},
            {name = "?msgcount [player/all]", value = "Get message counts", inline = false},
            {name = "?performance [player]", value = "Check player performance", inline = false},
            
            {name = "📊 **Server Commands**", value = "──────────────────────────────", inline = false},
            {name = "?server stats", value = "Server statistics", inline = true},
            {name = "?uptime", value = "Show server uptime", inline = true},
            {name = "?serverhop", value = "Toggle server following", inline = true},
            
            {name = "📝 **Format Commands**", value = "──────────────────────────────", inline = false},
            {name = "?simple", value = "Switch to SIMPLE mode", inline = true},
            {name = "?normal", value = "Switch to NORMAL mode", inline = true},
            
            {name = "📋 **Console Commands**", value = "──────────────────────────────", inline = false},
            {name = "?console", value = "Toggle console logging", inline = true},
            
            {name = "ℹ️ **Info Commands**", value = "──────────────────────────────", inline = false},
            {name = "?commands/?help", value = "Show this list", inline = true},
            
            {name = "⚙️ **CURRENT VALUES**", value = "──────────────────────────────", inline = false},
            {name = "💬 Chat Status", value = (loggingEnabled.chat and "✅ ON" or "❌ OFF"), inline = true},
            {name = "🟢 Joins Status", value = (loggingEnabled.joins and "✅ ON" or "❌ OFF"), inline = true},
            {name = "🔴 Leaves Status", value = (loggingEnabled.leaves and "✅ ON" or "❌ OFF"), inline = true},
            {name = "📝 Current Mode", value = loggingMode:upper(), inline = true},
            {name = "🎯 Player Filter", value = (playerLogs and #playerLogs > 0 and #playerLogs .. " players" or "ALL"), inline = true},
            {name = "🔄 Serverhop", value = (serverhopEnabled and "✅ ON" or "❌ OFF"), inline = true},
            {name = "📋 Console", value = (consoleEnabled and "✅ ON" or "❌ OFF"), inline = true},
            {name = "👥 Server Players", value = gameInfo.players .. "/" .. gameInfo.maxPlayers, inline = true},
            {name = "⏱️ Uptime", value = uptime .. " minutes", inline = true},
            
            {name = "👤 **Account Info**", value = "──────────────────────────────", inline = false},
            {name = "👤 Display", value = localPlayer.DisplayName, inline = true},
            {name = "🔰 Username", value = "@" .. localPlayer.Name, inline = true},
            {name = "🆔 User ID", value = localPlayer.UserId, inline = true},
            
            {name = "🎮 **Game Info**", value = "──────────────────────────────", inline = false},
            {name = "🎮 Game", value = gameInfo.name, inline = false},
            {name = "📍 Place ID", value = gameInfo.placeId, inline = true},
            {name = "🔑 Job ID", value = gameInfo.jobId:sub(1,8), inline = true}
        },
        footer = {text = "Logger Pro • All commands shown with current values • Live Feed"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
    sendCommandEmbed("?commands", "System", "Success", "Command list displayed with current values")
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
    local gameInfo = getGameInfo()
    
    local embed = {
        title = "💬 **NEW CHAT MESSAGE**",
        description = "──────────────────────────────",
        color = Colors.CHAT,
        fields = {
            {name = "👤 **User Information**", value = "──────────────────────────────", inline = false},
            {name = "📛 Display Name", value = player.DisplayName, inline = true},
            {name = "🔰 Username", value = "@" .. player.Name, inline = true},
            {name = "🆔 User ID", value = player.UserId, inline = true},
            
            {name = "⏰ **Timestamp**", value = "──────────────────────────────", inline = false},
            {name = "🕐 Time", value = os.date("%H:%M:%S"), inline = true},
            {name = "📅 Date", value = os.date("%Y-%m-%d"), inline = true},
            
            {name = "💭 **Message Content**", value = "──────────────────────────────", inline = false},
            {name = "Message", value = "```" .. message .. "```", inline = false},
            
            {name = "📊 **Server Information**", value = "──────────────────────────────", inline = false},
            {name = "🌍 Server", value = gameInfo.jobId:sub(1,8), inline = true},
            {name = "👥 Online", value = gameInfo.players .. "/" .. gameInfo.maxPlayers, inline = true},
            {name = "📨 Message #", value = messageCounts[player.UserId], inline = true}
        },
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"},
        footer = {text = "Chat Logger • Live Feed"},
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
    local gameInfo = getGameInfo()
    
    local embed = {
        title = "💬 **CHAT MESSAGE**",
        description = "──────────────────────────────",
        color = Colors.CHAT,
        fields = {
            {name = "👤 User", value = string.format("%s (@%s)", player.DisplayName, player.Name), inline = true},
            {name = "⏰ Time", value = os.date("%H:%M:%S"), inline = true},
            {name = "💬 Message", value = message, inline = false},
            {name = "📊 Info", value = string.format("Msg #%d • %d/%d online", messageCounts[player.UserId], gameInfo.players, gameInfo.maxPlayers), inline = false}
        },
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"},
        footer = {text = "Chat Logger • Simple Mode"},
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
        description = "──────────────────────────────\n**A new player has joined the server!**\n──────────────────────────────",
        color = Colors.JOIN,
        fields = {
            {name = "👤 **Player Details**", value = "──────────────────────────────", inline = false},
            {name = "📛 Display Name", value = player.DisplayName, inline = true},
            {name = "🔰 Username", value = "@" .. player.Name, inline = true},
            {name = "🆔 User ID", value = player.UserId, inline = true},
            {name = "📅 Account Age", value = player.AccountAge .. " days", inline = true},
            
            {name = "⏰ **Join Time**", value = "──────────────────────────────", inline = false},
            {name = "🕐 Time", value = os.date("%H:%M:%S"), inline = true},
            {name = "📅 Date", value = os.date("%Y-%m-%d"), inline = true},
            
            {name = "📊 **Server Status**", value = "──────────────────────────────", inline = false},
            {name = "👥 Previous", value = gameInfo.players - 1, inline = true},
            {name = "👥 Current", value = gameInfo.players, inline = true},
            {name = "📈 Change", value = "+1", inline = true},
            {name = "🎯 Max Players", value = gameInfo.maxPlayers, inline = true}
        },
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"},
        footer = {text = "Join Logger • Live Tracking"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, true)
    
    if consoleEnabled then
        oldPrint(string.format("[JOIN] %s (@%s) joined the server", player.DisplayName, player.Name))
    end
end

local function logPlayerLeave(player)
    if not loggingEnabled.leaves then return end
    
    local gameInfo = getGameInfo()
    
    local embed = {
        title = "🔴 **PLAYER LEFT**",
        description = "──────────────────────────────\n**A player has left the server**\n──────────────────────────────",
        color = Colors.LEAVE,
        fields = {
            {name = "👤 **Player Details**", value = "──────────────────────────────", inline = false},
            {name = "📛 Display Name", value = player.DisplayName, inline = true},
            {name = "🔰 Username", value = "@" .. player.Name, inline = true},
            {name = "🆔 User ID", value = player.UserId, inline = true},
            
            {name = "⏰ **Leave Time**", value = "──────────────────────────────", inline = false},
            {name = "🕐 Time", value = os.date("%H:%M:%S"), inline = true},
            {name = "📅 Date", value = os.date("%Y-%m-%d"), inline = true},
            
            {name = "📊 **Server Status**", value = "──────────────────────────────", inline = false},
            {name = "👥 Previous", value = gameInfo.players + 1, inline = true},
            {name = "👥 Current", value = gameInfo.players, inline = true},
            {name = "📉 Change", value = "-1", inline = true},
            {name = "🎯 Max Players", value = gameInfo.maxPlayers, inline = true},
            
            {name = "📨 **Chat Stats**", value = "──────────────────────────────", inline = false},
            {name = "💬 Messages", value = messageCounts[player.UserId] or 0, inline = true}
        },
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"},
        footer = {text = "Leave Logger • Live Tracking"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, true)
    
    if consoleEnabled then
        oldPrint(string.format("[LEAVE] %s (@%s) left the server", player.DisplayName, player.Name))
    end
end

-- ========== NEW COMMAND: PERFORMANCE CHECK ==========
local function handlePerformance(args)
    if #args < 3 then
        sendCommandEmbed("?performance", "System", "Error", "Usage: ?performance check [player]")
        return
    end
    
    local targetName = table.concat(args, " "):sub(14):gsub("^%s+", ""):gsub("%s+$", "")
    local matches = findPlayersByPartialName(targetName)
    
    if #matches == 0 then
        sendCommandEmbed("?performance", "System", "Error", "No player found: " .. targetName)
        return
    end
    
    if #matches > 1 then
        local names = {}
        for _, p in ipairs(matches) do
            table.insert(names, p.Name)
        end
        sendCommandEmbed("?performance", "System", "Warning", "Multiple players found:\n" .. table.concat(names, "\n") .. "\nPlease be more specific")
        return
    end
    
    local target = matches[1]
    local gameInfo = getGameInfo()
    
    -- Gather performance metrics
    local fps = 60 -- Estimated, can't get real FPS
    local ping = 50 -- Estimated
    local memory = "N/A"
    local cpu = "N/A"
    local network = "N/A"
    
    pcall(function()
        -- Try to get network stats
        if target:FindFirstChild("NetworkClient") then
            network = "Connected"
        end
        
        -- Check if player is moving
        local isMoving = "No"
        if target.Character and target.Character:FindFirstChild("Humanoid") then
            local humanoid = target.Character.Humanoid
            if humanoid.MoveDirection.Magnitude > 0 then
                isMoving = "Yes"
            end
        end
    end)
    
    local embed = {
        title = "⚡ **PERFORMANCE CHECK: " .. target.Name .. "**",
        description = "──────────────────────────────\n**Player Performance Metrics**\n──────────────────────────────",
        color = Colors.PERFORMANCE,
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. target.UserId .. "&width=420&height=420&format=png"},
        fields = {
            {name = "👤 **Player Info**", value = "──────────────────────────────", inline = false},
            {name = "👤 Username", value = target.Name, inline = true},
            {name = "📛 Display", value = target.DisplayName, inline = true},
            {name = "🆔 User ID", value = target.UserId, inline = true},
            
            {name = "📊 **Performance Metrics**", value = "──────────────────────────────", inline = false},
            {name = "⚡ FPS", value = fps .. " (estimated)", inline = true},
            {name = "📶 Ping", value = ping .. "ms (estimated)", inline = true},
            {name = "💾 Memory", value = memory, inline = true},
            {name = "⚙️ CPU", value = cpu, inline = true},
            {name = "🌐 Network", value = network, inline = true},
            {name = "🚶 Moving", value = isMoving, inline = true},
            
            {name = "📊 **Statistics**", value = "──────────────────────────────", inline = false},
            {name = "💬 Messages", value = messageCounts[target.UserId] or 0, inline = true},
            {name = "⏱️ Join Time", value = target:GetJoinData() and math.floor((os.time() - target:GetJoinData().JoinTime) / 60) .. " min" or "N/A", inline = true},
            {name = "👥 Server", value = gameInfo.players .. "/" .. gameInfo.maxPlayers, inline = true}
        },
        footer = {text = "Performance Check • " .. os.date("%H:%M:%S")},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
    sendCommandEmbed("?performance check", target.Name, "Success", "Performance metrics for **" .. target.Name .. "**")
end

-- ========== NEW COMMAND: UPTIME ==========
local function handleUptime()
    local gameInfo = getGameInfo()
    local uptime = math.floor((os.time() - startTime) / 60)
    local uptimeSeconds = os.time() - startTime
    local uptimeHours = math.floor(uptime / 60)
    local uptimeMinutes = uptime % 60
    local uptimeDays = math.floor(uptimeHours / 24)
    local uptimeRemainingHours = uptimeHours % 24
    
    local uptimeString = string.format("%d days, %d hours, %d minutes, %d seconds", 
        uptimeDays, uptimeRemainingHours, uptimeMinutes, uptimeSeconds % 60)
    
    local embed = {
        title = "⏱️ **SERVER UPTIME**",
        description = "──────────────────────────────\n**Current Server Uptime Information**\n──────────────────────────────",
        color = Colors.UPTIME,
        fields = {
            {name = "📊 **Uptime Breakdown**", value = "──────────────────────────────", inline = false},
            {name = "⏱️ Total Seconds", value = uptimeSeconds .. " seconds", inline = true},
            {name = "⏱️ Total Minutes", value = uptime .. " minutes", inline = true},
            {name = "⏱️ Total Hours", value = uptimeHours .. " hours", inline = true},
            {name = "📅 Days", value = uptimeDays, inline = true},
            {name = "🕐 Hours", value = uptimeRemainingHours, inline = true},
            {name = "⏰ Minutes", value = uptimeMinutes, inline = true},
            
            {name = "📊 **Full Uptime**", value = "──────────────────────────────", inline = false},
            {name = "Uptime", value = "```" .. uptimeString .. "```", inline = false},
            
            {name = "🕐 **Time Information**", value = "──────────────────────────────", inline = false},
            {name = "Started At", value = os.date("%Y-%m-%d %H:%M:%S", startTime), inline = true},
            {name = "Current Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true},
            
            {name = "🎮 **Server Info**", value = "──────────────────────────────", inline = false},
            {name = "Game", value = gameInfo.name, inline = false},
            {name = "Place ID", value = gameInfo.placeId, inline = true},
            {name = "Job ID", value = gameInfo.jobId, inline = true}
        },
        footer = {text = "Uptime Logger • Real-time Data"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToDiscwebhook(embed, false)
    sendCommandEmbed("?uptime", "System", "Success", "Server uptime: **" .. uptimeString .. "**")
end

-- ========== NEW COMMAND: SERVERHOP ==========
local function handleServerhop()
    serverhopEnabled = not serverhopEnabled
    
    local status = serverhopEnabled and "ENABLED" or "DISABLED"
    local message = serverhopEnabled and 
        "🔄 Serverhop has been **ENABLED**\n\nThe script will now follow you to new servers!" or 
        "⏹️ Serverhop has been **DISABLED**\n\nThe script will stay in current server only"
    
    sendCommandEmbed("?serverhop", "System", "Success", message)
    
    if consoleEnabled then
        oldPrint("[SERVERHOP] " .. (serverhopEnabled and "Enabled - Will follow to new servers" or "Disabled - Staying in current server"))
    end
end

-- ========== NEW COMMAND: CONSOLE TOGGLE ==========
local function handleConsole()
    consoleEnabled = not consoleEnabled
    loggingEnabled.console = consoleEnabled
    
    local status = consoleEnabled and "ENABLED" or "DISABLED"
    local message = consoleEnabled and 
        "📋 Console logging has been **ENABLED**\n\nAll console output will now be sent to Discord!" or 
        "⏹️ Console logging has been **DISABLED**\n\nConsole output will no longer be sent to Discord"
    
    sendCommandEmbed("?console", "System", "Success", message)
    
    if consoleEnabled then
        oldPrint("[CONSOLE] Console logging enabled - All output will be sent to Discord")
    end
end

-- ========== COMMAND HANDLERS ==========
local function handleWhois(args)
    if #args < 2 then
        sendCommandEmbed("?whois", "System", "Error", "Usage: ?whois [player name]")
        return
    end
    
    local searchName = table.concat(args, " "):sub(7):gsub("^%s+", ""):gsub("%s+$", "")
    local matches = findPlayersByPartialName(searchName)
    
    if #matches == 0 then
        sendCommandEmbed("?whois", "System", "Error", "No player found: " .. searchName)
        return
    end
    
    if #matches > 1 then
        local names = {}
        for _, p in ipairs(matches) do
            table.insert(names, p.Name .. " (" .. p.DisplayName .. ")")
        end
        sendCommandEmbed("?whois", "System", "Warning", "Multiple players found:\n" .. table.concat(names, "\n"))
        return
    end
    
    local target = matches[1]
    local accountAgeDays = target.AccountAge
    local accountCreated = os.date("%Y-%m-%d", os.time() - (accountAgeDays * 86400))
    local gameInfo = getGameInfo()
    
    -- Get character info if available
    local health = "N/A"
    local maxHealth = "N/A"
    local position = "N/A"
    local team = "None"
    local level = "N/A"
    local cash = "N/A"
    
    pcall(function()
        if target.Character and target.Character:FindFirstChild("Humanoid") then
            health = target.Character.Humanoid.Health
            maxHealth = target.Character.Humanoid.MaxHealth
            if target.Character:FindFirstChild("HumanoidRootPart") then
                local pos = target.Character.HumanoidRootPart.Position
                position = string.format("(%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z)
            end
        end
        if target.Team then
            team = target.Team.Name
        end
        
        -- Try to get game-specific stats
        if target:FindFirstChild("leaderstats") then
            for _, stat in ipairs(target.leaderstats:GetChildren()) do
                if stat.Name:lower():find("level") then level = stat.Value end
                if stat.Name:lower():find("cash") or stat.Name:lower():find("money") or stat.Name:lower():find("points") then
                    cash = stat.Value
                end
            end
        end
    end)
    
    local embed = {
        title = "🔍 **WHOIS: " .. target.Name .. "**",
        description = "──────────────────────────────\n**Player Information**\n──────────────────────────────",
        color = Colors.WHOIS,
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. target.UserId .. "&width=420&height=420&format=png"},
        fields = {
            {name = "👤 **Basic Info**", value = "──────────────────────────────", inline = false},
            {name = "👤 Username", value = target.Name, inline = true},
            {name = "📛 Display", value = target.DisplayName, inline = true},
            {name = "🆔 User ID", value = target.UserId, inline = true},
            
            {name = "📅 **Account Info**", value = "──────────────────────────────", inline = false},
            {name = "📅 Created", value = accountCreated, inline = true},
            {name = "⏰ Age", value = accountAgeDays .. " days", inline = true},
            
            {name = "⚔️ **Game Stats**", value = "──────────────────────────────", inline = false},
            {name = "📊 Level", value = level, inline = true},
            {name = "💰 Cash", value = cash, inline = true},
            {name = "👥 Team", value = team, inline = true},
            {name = "❤️ Health", value = health .. "/" .. maxHealth, inline = true},
            {name = "📍 Position", value = position, inline = true},
            
            {name = "📊 **Statistics**", value = "──────────────────────────────", inline = false},
            {name = "💬 Messages", value = messageCounts[target.UserId] or 0, inline = true},
            {name = "🌍 Server", value = gameInfo.jobId:sub(1,8), inline = true},
            {name = "👥 Online", value = gameInfo.players .. "/" .. gameInfo.maxPlayers, inline = true},
            
            {name = "🔗 **Links**", value = "──────────────────────────────", inline = false},
            {name = "Profile", value = "[Click here to view profile](https://www.roblox.com/users/" .. target.UserId .. "/profile)", inline = false}
        },
        footer = {text = "Whois Logger • Requested at " .. os.date("%H:%M:%S")},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToWebhook(whoisWebhook, embed, "Whois Logger")
    sendCommandEmbed("?whois", target.Name, "Success", "Sent info for **" .. target.Name .. "**")
end

local function handleServerStats()
    local gameInfo = getGameInfo()
    local uptime = math.floor((os.time() - startTime) / 60)
    local uptimeHours = math.floor(uptime / 60)
    local uptimeMinutes = uptime % 60
    
    local embed = {
        title = "📊 **SERVER STATISTICS**",
        description = "──────────────────────────────\n**Current Server Information**\n──────────────────────────────",
        color = Colors.STATS,
        fields = {
            {name = "🎮 **Game Information**", value = "──────────────────────────────", inline = false},
            {name = "🎮 Name", value = gameInfo.name, inline = false},
            {name = "📍 Place ID", value = gameInfo.placeId, inline = true},
            {name = "🔑 Job ID", value = gameInfo.jobId, inline = true},
            
            {name = "👥 **Player Statistics**", value = "──────────────────────────────", inline = false},
            {name = "👥 Current", value = gameInfo.players, inline = true},
            {name = "🎯 Max", value = gameInfo.maxPlayers, inline = true},
            {name = "📊 Available", value = gameInfo.maxPlayers - gameInfo.players, inline = true},
            
            {name = "⏱️ **Server Uptime**", value = "──────────────────────────────", inline = false},
            {name = "⏱️ Minutes", value = uptime .. " min", inline = true},
            {name = "⏱️ Hours", value = uptimeHours .. "h " .. uptimeMinutes .. "m", inline = true},
            
            {name = "⏰ **Time Information**", value = "──────────────────────────────", inline = false},
            {name = "🕐 Local", value = os.date("%H:%M:%S"), inline = true},
            {name = "📅 Date", value = os.date("%Y-%m-%d"), inline = true},
            {name = "🌍 UTC", value = os.date("!%H:%M:%S"), inline = true}
        },
        footer = {text = "Server Stats Logger • Real-time Data"},
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToWebhook(serverStatsWebhook, embed, "Server Stats Logger")
    sendCommandEmbed("?server stats", "System", "Success", "Server statistics sent")
end

local function handleMsgCount(args)
    if #args < 2 then
        sendCommandEmbed("?msgcount", "System", "Error", "Usage: ?msgcount [player/all/name1,name2]")
        return
    end
    
    local query = table.concat(args, " "):sub(9):gsub("^%s+", ""):gsub("%s+$", "")
    local gameInfo = getGameInfo()
    
    if query:lower() == "all" then
        local total = 0
        for _, count in pairs(messageCounts) do
            total = total + count
        end
        
        local topPlayers = {}
        for userId, count in pairs(messageCounts) do
            local player = game:GetService("Players"):GetPlayerByUserId(userId)
            if player then
                table.insert(topPlayers, {name = player.Name, count = count})
            end
        end
        table.sort(topPlayers, function(a, b) return a.count > b.count end)
        
        local topStr = ""
        for i = 1, math.min(10, #topPlayers) do
            topStr = topStr .. "**" .. i .. ".** " .. topPlayers[i].name .. ": " .. topPlayers[i].count .. " messages\n"
        end
        
        local embed = {
            title = "📊 **TOTAL MESSAGE COUNT**",
            description = "──────────────────────────────\n**All Players Combined**\n──────────────────────────────",
            color = Colors.INFO,
            fields = {
                {name = "📊 **Statistics**", value = "──────────────────────────────", inline = false},
                {name = "💬 Total", value = total, inline = true},
                {name = "👥 Active", value = #topPlayers, inline = true},
                {name = "👥 Server", value = gameInfo.players .. "/" .. gameInfo.maxPlayers, inline = true},
                {name = "🏆 **Top Chatters**", value = "──────────────────────────────", inline = false},
                {name = "Leaderboard", value = topStr ~= "" and topStr or "No messages yet", inline = false}
            },
            timestamp = DateTime.now():ToIsoDate()
        }
        sendToWebhook(webhookUrl, embed, "Message Counter")
        sendCommandEmbed("?msgcount all", "System", "Success", "Total messages: " .. total)
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
            table.insert(results, "❌ **" .. name .. "**: not found")
        elseif #matches > 1 then
            local matchNames = {}
            for _, p in ipairs(matches) do
                table.insert(matchNames, p.Name)
            end
            table.insert(results, "⚠️ **" .. name .. "** → " .. table.concat(matchNames, ", "))
        else
            local player = matches[1]
            local count = messageCounts[player.UserId] or 0
            table.insert(results, "✅ **" .. player.Name .. "**: " .. count .. " messages")
        end
    end
    
    local embed = {
        title = "📊 **MESSAGE COUNTS**",
        description = "──────────────────────────────\n**Individual Player Stats**\n──────────────────────────────",
        color = Colors.INFO,
        fields = {
            {name = "📊 **Results**", value = "──────────────────────────────", inline = false},
            {name = "Statistics", value = table.concat(results, "\n"), inline = false},
            {name = "👥 Server", value = gameInfo.players .. "/" .. gameInfo.maxPlayers, inline = true}
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    sendToWebhook(webhookUrl, embed, "Message Counter")
    sendCommandEmbed("?msgcount", "System", "Success", "Message counts retrieved")
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
            sendCommandEmbed("?start", "System", "Success", "✅ All logging has been **STARTED**\n\n**New Values:**\n💬 Chat: ON\n🟢 Joins: ON\n🔴 Leaves: ON")
        else
            local target = args[2]:lower()
            if target == "chat" then
                loggingEnabled.chat = true
                sendCommandEmbed("?start chat", "System", "Success", "✅ Chat logging has been **STARTED**\n\n**New Values:**\n💬 Chat: ON\n🟢 Joins: " .. (loggingEnabled.joins and "ON" or "OFF") .. "\n🔴 Leaves: " .. (loggingEnabled.leaves and "ON" or "OFF"))
            elseif target == "joins" or target == "join" then
                loggingEnabled.joins = true
                sendCommandEmbed("?start joins", "System", "Success", "✅ Join logging has been **STARTED**\n\n**New Values:**\n💬 Chat: " .. (loggingEnabled.chat and "ON" or "OFF") .. "\n🟢 Joins: ON\n🔴 Leaves: " .. (loggingEnabled.leaves and "ON" or "OFF"))
            elseif target == "leaves" or target == "leave" then
                loggingEnabled.leaves = true
                sendCommandEmbed("?start leaves", "System", "Success", "✅ Leave logging has been **STARTED**\n\n**New Values:**\n💬 Chat: " .. (loggingEnabled.chat and "ON" or "OFF") .. "\n🟢 Joins: " .. (loggingEnabled.joins and "ON" or "OFF") .. "\n🔴 Leaves: ON")
            else
                sendCommandEmbed("?start", "System", "Error", "❌ Invalid option. Use: ?start [chat/joins/leaves]")
            end
        end
        return true
        
    elseif command == "?stop" then
        if #args == 1 then
            loggingEnabled.chat = false
            loggingEnabled.joins = false
            loggingEnabled.leaves = false
            sendCommandEmbed("?stop", "System", "Success", "⏹️ All logging has been **STOPPED**\n\n**New Values:**\n💬 Chat: OFF\n🟢 Joins: OFF\n🔴 Leaves: OFF")
        else
            local target = args[2]:lower()
            if target == "chat" then
                loggingEnabled.chat = false
                sendCommandEmbed("?stop chat", "System", "Success", "⏹️ Chat logging has been **STOPPED**\n\n**New Values:**\n💬 Chat: OFF\n🟢 Joins: " .. (loggingEnabled.joins and "ON" or "OFF") .. "\n🔴 Leaves: " .. (loggingEnabled.leaves and "ON" or "OFF"))
            elseif target == "joins" or target == "join" then
                loggingEnabled.joins = false
                sendCommandEmbed("?stop joins", "System", "Success", "⏹️ Join logging has been **STOPPED**\n\n**New Values:**\n💬 Chat: " .. (loggingEnabled.chat and "ON" or "OFF") .. "\n🟢 Joins: OFF\n🔴 Leaves: " .. (loggingEnabled.leaves and "ON" or "OFF"))
            elseif target == "leaves" or target == "leave" then
                loggingEnabled.leaves = false
                sendCommandEmbed("?stop leaves", "System", "Success", "⏹️ Leave logging has been **STOPPED**\n\n**New Values:**\n💬 Chat: " .. (loggingEnabled.chat and "ON" or "OFF") .. "\n🟢 Joins: " .. (loggingEnabled.joins and "ON" or "OFF") .. "\n🔴 Leaves: OFF")
            elseif target == "specific" then
                playerLogs = {}
                sendCommandEmbed("?stop specific", "System", "Success", "⏹️ Player-specific logging **STOPPED**\n\n**New Values:**\n🎯 Now logging: **ALL** players")
            else
                sendCommandEmbed("?stop", "System", "Error", "❌ Invalid option. Use: ?stop [chat/joins/leaves/specific]")
            end
        end
        return true
        
    elseif command == "?simple" then
        loggingMode = "simple"
        sendCommandEmbed("?simple", "System", "Success", "🔄 Switched to **SIMPLE** mode\n\n**New Values:**\n📝 Chat Format: **SIMPLE**\nPrevious: NORMAL", "mode_change")
        return true
        
    elseif command == "?normal" then
        loggingMode = "normal"
        sendCommandEmbed("?normal", "System", "Success", "🔄 Switched to **NORMAL** mode\n\n**New Values:**\n📝 Chat Format: **NORMAL**\nPrevious: SIMPLE", "mode_change")
        return true
        
    elseif command == "?log" then
        if #args < 2 then
            sendCommandEmbed("?log", "System", "Error", "Usage: ?log [player names]")
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
            msg = "Now logging: **" .. table.concat(foundPlayers, ", ") .. "**"
        end
        if #notFound > 0 then
            msg = msg .. "\nNot found: " .. table.concat(notFound, ", ")
        end
        if #foundPlayers == 0 then
            msg = "No players found"
        end
        
        sendCommandEmbed("?log", "System", #foundPlayers > 0 and "Success" or "Warning", "🎯 **Player filter updated**\n\n" .. msg .. "\n\n**New Values:**\n🎯 Tracking: " .. (#playerLogs > 0 and #playerLogs .. " players" or "ALL"))
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
        
    elseif command == "?performance" and args[2] and args[2]:lower() == "check" then
        handlePerformance(args)
        return true
        
    elseif command == "?uptime" then
        handleUptime()
        return true
        
    elseif command == "?serverhop" then
        handleServerhop()
        return true
        
    elseif command == "?console" then
        handleConsole()
        return true
    end
    
    return false
end

-- ========== SERVERHOP MONITOR ==========
local function monitorServerhop()
    while serverhopEnabled do
        wait(5)
        if game.JobId ~= currentServer then
            -- Server changed
            local oldServer = currentServer
            currentServer = game.JobId
            
            -- Log server change
            local embed = {
                title = "🔄 **SERVER HOP DETECTED**",
                description = "──────────────────────────────\n**Following you to new server!**\n──────────────────────────────",
                color = Colors.ALERT,
                fields = {
                    {name = "📊 **Server Change**", value = "──────────────────────────────", inline = false},
                    {name = "📌 Previous Server", value = oldServer:sub(1,8), inline = true},
                    {name = "📍 New Server", value = currentServer:sub(1,8), inline = true},
                    {name = "⏰ Time", value = os.date("%H:%M:%S"), inline = true},
                    {name = "📅 Date", value = os.date("%Y-%m-%d"), inline = true}
                },
                footer = {text = "Serverhop Active • Following you"},
                timestamp = DateTime.now():ToIsoDate()
            }
            sendToDiscwebhook(embed, false)
            
            if consoleEnabled then
                oldPrint("[SERVERHOP] Detected server change - Following to new server")
            end
            
            -- Re-initialize logging in new server
            wait(2)
            sendConnectionMessage()
        end
    end
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
    
    -- Start serverhop monitor
    spawn(monitorServerhop)
    
    if consoleEnabled then
        oldPrint("[SYSTEM] Logger setup complete - Ready for commands")
    end
end

-- ========== INITIALIZE ==========
print("✅ Logger initialized - Live feed active")
print("📝 Type ?commands for help")

spawn(function()
    setupLogging()
end)

wait(0.5)
print("=" .. string.rep("=", 50) .. "=")
print("🔵 DISCORD LOGGER PRO - ULTIMATE EDITION")
print("=" .. string.rep("=", 50) .. "=")
print("📡 Status: Connected to Discord")
print("👤 Account: " .. game:GetService("Players").LocalPlayer.Name)
print("🎮 Game: " .. getGameInfo().name)
print("📋 Commands: ?commands for full list with values")
print("📋 Console Logging: ACTIVE")
print("=" .. string.rep("=", 50) .. "=")
