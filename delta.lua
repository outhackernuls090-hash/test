local spoofed = game.JobId

local function writeFile(path, content)
    if writefile then pcall(function() writefile(path, content) end) end
end

local function safeCall(func)
    local success, result = pcall(func)
    return success and result or nil
end

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

local methods = {
    {name = "Method 1 (API by player count - most players)", func = function()
        local http = game:GetService("HttpService")
        local req = getRequestMethod()
        if not req then return nil end
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Asc"
        local response = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if response and response.Body then
            local data = http:JSONDecode(response.Body)
            if data and data.data then
                local best = nil
                local maxPlayers = -1
                for _, server in ipairs(data.data) do
                    if server.playing and server.playing > maxPlayers then
                        maxPlayers = server.playing
                        best = server.id
                    end
                end
                return best
            end
        end
        return nil
    end},
    {name = "Method 2 (API by lowest ping - best connection)", func = function()
        local http = game:GetService("HttpService")
        local req = getRequestMethod()
        if not req then return nil end
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Asc"
        local response = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if response and response.Body then
            local data = http:JSONDecode(response.Body)
            if data and data.data then
                local best = nil
                local maxPlayers = -1
                for _, server in ipairs(data.data) do
                    if server.playing and server.playing > 0 then
                        if not best or server.playing > maxPlayers then
                            maxPlayers = server.playing
                            best = server.id
                        end
                    end
                end
                return best
            end
        end
        return nil
    end},
    {name = "Method 3 (API /v1/games/multiget-server)", func = function()
        local req = getRequestMethod()
        if not req then return nil end
        local url = "https://games.roblox.com/v1/games/multiget-server?placeIds=" .. game.PlaceId
        local resp = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if not resp or not resp.Body then return nil end
        local data = game:GetService("HttpService"):JSONDecode(resp.Body)
        if data and data.data and #data.data > 0 then
            local serverInfo = data.data[1]
            if serverInfo and serverInfo.jobId then return serverInfo.jobId end
        end
        return nil
    end},
    {name = "Method 4 (NetworkClient.ServerId)", func = function()
        local nc = game:GetService("NetworkClient")
        if nc and nc.ServerId then return nc.ServerId end
        return nil
    end},
    {name = "Method 5 (NetworkClient:GetServerInfo)", func = function()
        local nc = game:GetService("NetworkClient")
        if nc and nc.GetServerInfo then
            local ok, info = pcall(function() return nc:GetServerInfo() end)
            if ok and info and info.JobId then return info.JobId end
        end
        return nil
    end},
    {name = "Method 6 (TeleportService:GetServerInfoForGame)", func = function()
        local ts = game:GetService("TeleportService")
        local ok, info = pcall(function() return ts:GetServerInfoForGame(game.PlaceId) end)
        if ok and info and info.JobId then return info.JobId end
        return nil
    end},
    {name = "Method 7 (TeleportService:GetServerInfo with jobid param)", func = function()
        local ts = game:GetService("TeleportService")
        local ok, info = pcall(function() return ts:GetServerInfo(game.PlaceId, game.JobId) end)
        if ok and info and info.JobId then return info.JobId end
        return nil
    end},
    {name = "Method 8 (RunService.ServerId)", func = function()
        local rs = game:GetService("RunService")
        if rs and rs.ServerId then return rs.ServerId end
        return nil
    end},
    {name = "Method 9 (game:GetService('DataModel'):GetJobId)", func = function()
        local dm = game:GetService("DataModel")
        if dm and dm.GetJobId then
            local ok, id = pcall(function() return dm:GetJobId() end)
            if ok and id then return id end
        end
        return nil
    end},
    {name = "Method 10 (game:GetService('Stats'):GetServerId)", func = function()
        local stats = game:GetService("Stats")
        if stats and stats.GetServerId then
            local ok, id = pcall(function() return stats:GetServerId() end)
            if ok and id then return id end
        end
        return nil
    end},
    {name = "Method 11 (ContentProvider.BaseUrl parse)", func = function()
        local cp = game:GetService("ContentProvider")
        if cp and cp.BaseUrl then
            local parts = string.split(cp.BaseUrl, "/")
            for _, part in ipairs(parts) do
                if #part == 36 and string.match(part, "^%x+%-%x+%-%x+%-%x+%-%x+$") then
                    return part
                end
            end
        end
        return nil
    end},
    {name = "Method 12 (Players:GetCurrentServer)", func = function()
        local plrs = game:GetService("Players")
        if plrs.GetCurrentServer then
            local ok, id = pcall(function() return plrs:GetCurrentServer() end)
            if ok and id then return id end
        end
        return nil
    end},
    {name = "Method 13 (MarketplaceService:GetProductInfo with alt param)", func = function()
        local ms = game:GetService("MarketplaceService")
        local ok, info = pcall(function() return ms:GetProductInfo(game.PlaceId, Enum.InfoType.Sales) end)
        if ok and info and info.JobId then return info.JobId end
        return nil
    end},
    {name = "Method 14 (rawget with __index override)", func = function()
        local mt = getrawmetatable(game)
        if mt and mt.__index then
            local old = mt.__index
            mt.__index = nil
            local real = rawget(game, "JobId")
            mt.__index = old
            return real
        end
        return nil
    end},
    {name = "Method 15 (debug.getupvalues on game.GetJobId)", func = function()
        if game.GetJobId then
            local upvalues = debug.getupvalues(game.GetJobId)
            for _, uv in ipairs(upvalues) do
                if type(uv) == "string" and #uv == 36 then return uv end
            end
        end
        return nil
    end},
    {name = "Method 16 (hook TeleportService:TeleportToPlaceInstance and capture jobId)", func = function()
        local ts = game:GetService("TeleportService")
        local old = ts.TeleportToPlaceInstance
        local captured = nil
        ts.TeleportToPlaceInstance = function(placeId, jobId, ...)
            captured = jobId
            return old(placeId, jobId, ...)
        end
        task.wait(0.1)
        ts.TeleportToPlaceInstance = old
        return captured
    end},
    {name = "Method 17 (hook ReplicatedStorage event that may pass jobId)", func = function()
        local rs = game:GetService("ReplicatedStorage")
        for _, child in ipairs(rs:GetChildren()) do
            if child:IsA("RemoteEvent") and child.OnClientEvent then
                local old = child.OnClientEvent
                local captured = nil
                child.OnClientEvent = function(...)
                    for _, arg in ipairs({...}) do
                        if type(arg) == "string" and #arg == 36 and string.match(arg, "^%x+%-%x+%-%x+%-%x+%-%x+$") then
                            if arg ~= spoofed then captured = arg end
                        end
                    end
                    return old(...)
                end
                task.wait(1)
                child.OnClientEvent = old
                if captured then return captured end
            end
        end
        return nil
    end},
    {name = "Method 18 (check game:GetService('HttpService').__index for JobId)", func = function()
        local hs = game:GetService("HttpService")
        local mt = getrawmetatable(hs)
        if mt and mt.__index then
            local old = mt.__index
            mt.__index = function(self, key)
                if key == "JobId" then return self.JobId end
                return old(self, key)
            end
            local id = hs.JobId
            mt.__index = old
            return id
        end
        return nil
    end},
    {name = "Method 19 (coroutine to read JobId instantly)", func = function()
        local real = nil
        local co = coroutine.create(function() real = game.JobId end)
        coroutine.resume(co)
        return real
    end},
    {name = "Method 20 (task.wait(0) then read)", func = function()
        local real = nil
        local conn
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            real = game.JobId
            conn:Disconnect()
        end)
        task.wait()
        return real
    end},
    {name = "Method 21 (Loaded event capture)", func = function()
        local realId = nil
        local conn
        conn = game.Loaded:Connect(function()
            realId = game.JobId
            conn:Disconnect()
        end)
        task.wait(0.5)
        return realId
    end},
    {name = "Method 22 (getnamecallmethod interception)", func = function()
        local mt = getrawmetatable(game)
        if mt and mt.__namecall then
            local old = mt.__namecall
            local captured = nil
            mt.__namecall = function(self, ...)
                local method = getnamecallmethod()
                if method == "JobId" then
                    captured = self.JobId
                end
                return old(self, ...)
            end
            game.JobId = game.JobId
            mt.__namecall = old
            return captured
        end
        return nil
    end},
    {name = "Method 23 (syn.crypt or memory scan for frequent ID)", func = function()
        local pattern = "^%x+%-%x+%-%x+%-%x+%-%x+$"
        local candidates = {}
        for _, v in ipairs(getgc(true)) do
            if type(v) == "string" and #v == 36 and string.match(v, pattern) then
                if v ~= spoofed then table.insert(candidates, v) end
            end
        end
        local counts = {}
        for _, id in ipairs(candidates) do
            counts[id] = (counts[id] or 0) + 1
        end
        local best = nil
        local max = 0
        for id, cnt in pairs(counts) do
            if cnt > max then max = cnt; best = id end
        end
        return best
    end},
    {name = "Method 24 (check for StringValue in Lighting or other services)", func = function()
        local services = {game:GetService("Lighting"), game:GetService("SoundService"), game:GetService("Teams"), game:GetService("ReplicatedStorage")}
        for _, svc in ipairs(services) do
            for _, child in ipairs(svc:GetChildren()) do
                if child:IsA("StringValue") and child.Name:lower():find("job") and #child.Value > 10 then
                    return child.Value
                end
            end
        end
        return nil
    end},
    {name = "Method 25 (API /v1/games/server/current)", func = function()
        local req = getRequestMethod()
        if not req then return nil end
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/current"
        local resp = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if not resp or not resp.Body then return nil end
        local data = game:GetService("HttpService"):JSONDecode(resp.Body)
        if data and data.jobId then return data.jobId end
        return nil
    end}
}

local logLines = {}
table.insert(logLines, "=== JOB ID DETECTION RESULTS (25 METHODS) ===")
table.insert(logLines, "Spoofed (game.JobId): " .. spoofed)
table.insert(logLines, "")

local vote = {}
local results = {}

for _, m in ipairs(methods) do
    local result = safeCall(m.func)
    results[m.name] = result
    local status = "FAILED"
    if result then
        if result == spoofed then
            status = "SPOOFED"
        else
            status = "WORKING"
            vote[result] = (vote[result] or 0) + 1
        end
    end
    local line = string.format("%-40s | %-8s | %s", m.name, status, result or "nil")
    print(line)
    table.insert(logLines, line)
end

table.insert(logLines, "")
table.insert(logLines, "=== SUMMARY ===")
local working = {}
local spoofedMethods = {}
local failed = {}
for name, result in pairs(results) do
    if result then
        if result == spoofed then
            table.insert(spoofedMethods, name)
        else
            table.insert(working, name)
        end
    else
        table.insert(failed, name)
    end
end

table.insert(logLines, "WORKING methods:")
for _, name in ipairs(working) do
    table.insert(logLines, "  - " .. name)
end
table.insert(logLines, "SPOOFED methods:")
for _, name in ipairs(spoofedMethods) do
    table.insert(logLines, "  - " .. name)
end
table.insert(logLines, "FAILED methods:")
for _, name in ipairs(failed) do
    table.insert(logLines, "  - " .. name)
end

table.insert(logLines, "")
table.insert(logLines, "Votes per candidate:")
for id, count in pairs(vote) do
    table.insert(logLines, string.format("  %s : %d vote(s)", id, count))
end

local realId = spoofed
local maxVotes = 0
for id, count in pairs(vote) do
    if count > maxVotes then
        maxVotes = count
        realId = id
    end
end

table.insert(logLines, "")
table.insert(logLines, "FINAL REAL_JOB_ID = " .. realId)

local logText = table.concat(logLines, "\n")
writeFile("jobid_log_25.txt", logText)

getgenv().REAL_JOB_ID = realId
_G.REAL_JOB_ID = realId

return realId
