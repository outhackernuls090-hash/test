local function getRealJobId()
    local http = game:GetService("HttpService")
    
    local function getRequestMethod()
        if syn and syn.request then return syn.request end
        if fluxus and fluxus.request then return fluxus.request end
        if http and http.request then return http.request end
        if getgenv().request then return getgenv().request end
        if request then return request end
        if http_request then return http_request end
        if game:GetService("HttpService").RequestAsync then
            return function(req)
                return game:GetService("HttpService"):RequestAsync({
                    Url = req.Url,
                    Method = req.Method,
                    Headers = req.Headers,
                    Body = req.Body
                })
            end
        end
        return nil
    end

    local req = getRequestMethod()
    if not req then return nil end

    -- Fetch all public servers for this place
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Asc"
    local response = req({
        Url = url,
        Method = "GET",
        Headers = {["User-Agent"] = "Mozilla/5.0"}
    })

    if not response or not response.Body then return nil end

    local data = http:JSONDecode(response.Body)
    if not data or not data.data then return nil end

    local servers = data.data

    -- Get current player count from the client (should match the server we are in)
    local playerCount = #game:GetService("Players"):GetPlayers()

    -- First priority: find a server with the exact same player count
    for _, server in ipairs(servers) do
        if server.playing == playerCount then
            return server.id
        end
    end

    -- If no exact match (unlikely), fallback to the server with the most players
    local bestServer = nil
    local maxPlayers = -1
    for _, server in ipairs(servers) do
        if server.playing and server.playing > maxPlayers then
            maxPlayers = server.playing
            bestServer = server.id
        end
    end

    return bestServer
end

-- Usage
local realId = getRealJobId()
if realId then
    print("REAL_JOB_ID =", realId)
    getgenv().REAL_JOB_ID = realId
    _G.REAL_JOB_ID = realId
else
    print("Failed to retrieve real JobId")
end
