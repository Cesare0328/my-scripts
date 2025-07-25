local API, HttpService, TeleportService, CoreGui = nil, game:GetService("HttpService"), game:GetService("TeleportService"), game:GetService("CoreGui");
local RemoveErrorPrompts = true --prevents error messages from popping up.
local IterationSpeed = 0.25 --speed in which next server is picked for teleport (the higher it is the slower the teleports but more likely to work).
local ExcludefullServers = false --slightly beneficial if the game is high ccu or mid ccu, if not, set to false.

local function EncodeToFile(JSONString)
local success, JSONData = pcall(function()
    return HttpService:JSONDecode(JSONString)
end)
if success and JSONData.data then
    JSONData.gameId = game.PlaceId
    local sucess, encoded = pcall(function()
        return HttpService:JSONEncode(JSONData)
    end)
    if sucess then
        writefile("Servers.JSON", encoded)
    else
        error("Failed to encode JSON string.")
        return
    end
else
    error("Failed to decode JSONData.")
    return
end
return JSONData
end

local function NextCursor(ep)
    return game:HttpGet(API .. "&excludeFullGames=" .. tostring(ExcludefullServers) .. ((ep and "&cursor=" .. ep) or ""))
end

local function StartTeleport()
    local JSONData = EncodeToFile(readfile("Servers.JSON"))
    for i = 0, 99 do
        if #JSONData.data <= 1 then
            EncodeToFile(NextCursor(JSONData.nextPageCursor))
            TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
        end
        if JSONData.data[i] then
            local JobId = JSONData.data[i].id
            table.remove(JSONData.data, i)
            local sucess, encoded = pcall(function()
                return HttpService:JSONEncode(JSONData)
            end)
            writefile("Servers.JSON", encoded)
            appendfile("Attempts.txt", JobId .. "\n")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, JobId, game.Players.LocalPlayer)
            task.wait(IterationSpeed)
        end
    end
end

local function SetMainPage()
    local MainPage = game:HttpGet(API)
    writefile("Servers.JSON", MainPage)
    StartTeleport()
end

API = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"

if RemoveErrorPrompts then CoreGui:WaitForChild("RobloxGui"):WaitForChild("Modules"):WaitForChild("ErrorPrompt"):Destroy() CoreGui.RobloxPromptGui:Destroy() end

if isfile("Servers.JSON") then
    local success, JSONData = pcall(function()
        return HttpService:JSONDecode(readfile("Servers.JSON"))
    end)
    if success and JSONData then
        if JSONData.gameId ~= game.PlaceId then
            warn("Game mismatch from cache, remaking cache for --> " .. game.PlaceId)
            SetMainPage()
        end
        if JSONData.data and #JSONData.data >= 1 then
            StartTeleport()
        else
            if success and JSONData.nextPageCursor then
                EncodeToFile(NextCursor(JSONData.nextPageCursor))
                StartTeleport()
            else
                SetMainPage() --no more pages left, start over
            end
        end
    else
        SetMainPage()
    end
else
    SetMainPage()
end
