-- Alt Account Script
-- Execute this on your alt account

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

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Function to send webhook
local function sendWebhook(webhookName, content, embeds)
    local webhookURL = Webhooks[webhookName]
    if not webhookURL then return end
    
    local data = {
        ["content"] = content,
        ["username"] = "Alt: " .. Players.LocalPlayer.Name,
        ["avatar_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..Players.LocalPlayer.UserId.."&width=420&height=420&format=png"
    }
    
    if embeds then
        data["embeds"] = embeds
    end
    
    pcall(function()
        local jsonData = HttpService:JSONEncode(data)
        HttpService:PostAsync(webhookURL, jsonData, Enum.HttpContentType.ApplicationJson)
    end)
end

-- Send join notification
local joinEmbed = {
    {
        ["title"] = "🎮 Alt Account Joined",
        ["color"] = 3066993,
        ["fields"] = {
            {
                ["name"] = "Account",
                ["value"] = Players.LocalPlayer.Name,
                ["inline"] = true
            },
            {
                ["name"] = "Server",
                ["value"] = game.JobId,
                ["inline"] = true
            },
            {
                ["name"] = "Game",
                ["value"] = game.Name,
                ["inline"] = false
            }
        },
        ["timestamp"] = DateTime.now():ToIsoDate()
    }
}
sendWebhook("status", nil, joinEmbed)
sendWebhook("debug", "Alt account monitoring started")

-- Track deaths
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoid.Died:Connect(function()
        local deathEmbed = {
            {
                ["title"] = "💀 ALT DIED",
                ["color"] = 15158332,
                ["fields"] = {
                    {
                        ["name"] = "Position",
                        ["value"] = tostring(character:FindFirstChild("HumanoidRootPart").Position),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Time",
                        ["value"] = os.date("%H:%M:%S"),
                        ["inline"] = true
                    }
                }
            }
        }
        sendWebhook("deaths", nil, deathEmbed)
        sendWebhook("actions", "Alt died")
    end)
    
    -- Track health changes
    humanoid.HealthChanged:Connect(function(health)
        if health <= 20 and health > 0 then
            sendWebhook("status", string.format("⚠️ Low health: %.1f", health))
        end
    end)
end

if Players.LocalPlayer.Character then
    onCharacterAdded(Players.LocalPlayer.Character)
end
Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Track chat messages
Players.LocalPlayer.Chatted:Connect(function(message)
    local chatEmbed = {
        {
            ["title"] = "📝 Alt Chat",
            ["color"] = 5814783,
            ["description"] = message,
            ["fields"] = {
                {
                    ["name"] = "From",
                    ["value"] = Players.LocalPlayer.Name,
                    ["inline"] = true
                }
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }
    }
    sendWebhook("chat_public", nil, chatEmbed)
end)

-- Track other players' private messages (if possible)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        player.Chatted:Connect(function(message)
            -- Check if it might be a private message
            if message:find("@") or message:find("/w") then
                local privateEmbed = {
                    {
                        ["title"] = "🔒 Possible Private Message",
                        ["color"] = 15158332,
                        ["description"] = message,
                        ["fields"] = {
                            {
                                ["name"] = "From",
                                ["value"] = player.Name,
                                ["inline"] = true
                            },
                            {
                                ["name"] = "To",
                                ["value"] = "Unknown",
                                ["inline"] = true
                            }
                        }
                    }
                }
                sendWebhook("chat_private", nil, privateEmbed)
            end
        end)
    end
end

-- Periodic status updates
spawn(function()
    while true do
        wait(300) -- Every 5 minutes
        local char = Players.LocalPlayer.Character
        local humanoid = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        local statusEmbed = {
            {
                ["title"] = "📊 Alt Status Update",
                ["color"] = 10181046,
                ["fields"] = {
                    {
                        ["name"] = "Position",
                        ["value"] = root and tostring(root.Position) or "Unknown",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Health",
                        ["value"] = humanoid and tostring(humanoid.Health) or "Unknown",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Players",
                        ["value"] = tostring(#Players:GetPlayers()),
                        ["inline"] = true
                    }
                },
                ["timestamp"] = DateTime.now():ToIsoDate()
            }
        }
        sendWebhook("status", nil, statusEmbed)
    end
end)

sendWebhook("status", "✅ **Alt account is ready and being monitored!**")
