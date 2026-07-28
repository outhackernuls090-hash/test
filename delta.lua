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
    {name = "Method 1 (HttpService:RequestAsync with server list and IP match)", func = function()
        local http = game:GetService("HttpService")
        local req = getRequestMethod()
        if not req then return nil end
        -- Get public IP
        local ipResp = req({Url = "https://api.ipify.org?format=json", Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if not ipResp or not ipResp.Body then return nil end
        local ipData = http:JSONDecode(ipResp.Body)
        local ip = ipData and ipData.ip
        if not ip then return nil end
        -- Get server list
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
        local resp = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if not resp or not resp.Body then return nil end
        local data = http:JSONDecode(resp.Body)
        if not data or not data.data then return nil end
        -- Try to find server that matches our IP (impossible, but we can find the one with most players)
        local best = nil
        local maxPing = nil
        for _, server in ipairs(data.data) do
            if server.playing and server.playing > 0 then
                -- We can't get ping, but we can choose the one with highest player count (likely ours)
                if not best or server.playing > best.playing then
                    best = server
                end
            end
        end
        return best and best.id
    end},
    {name = "Method 2 (TeleportService:TeleportToPlaceInstance intercept via hook)", func = function()
        local ts = game:GetService("TeleportService")
        local old = ts.TeleportToPlaceInstance
        local captured = nil
        local hook = function(placeId, jobId, ...)
            captured = jobId
            return old(placeId, jobId, ...)
        end
        ts.TeleportToPlaceInstance = hook
        task.wait(0.1)
        ts.TeleportToPlaceInstance = old
        return captured
    end},
    {name = "Method 3 (NetworkClient:GetServerInfo)", func = function()
        local nc = game:GetService("NetworkClient")
        if nc and nc.GetServerInfo then
            local ok, info = pcall(function() return nc:GetServerInfo() end)
            if ok and info and info.JobId then return info.JobId end
        end
        return nil
    end},
    {name = "Method 4 (http request to /v1/games/multiget-server)", func = function()
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
    {name = "Method 5 (read from game.PlaceId + JobId via HttpService:GetAsync on a known endpoint)", func = function()
        local req = getRequestMethod()
        if not req then return nil end
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=1&sortOrder=Asc"
        local resp = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if not resp or not resp.Body then return nil end
        local data = game:GetService("HttpService"):JSONDecode(resp.Body)
        if data and data.data and #data.data > 0 then
            return data.data[1].id
        end
        return nil
    end},
    {name = "Method 6 (debug.getupvalues on a function that uses JobId)", func = function()
        for _, v in ipairs(getgc(true)) do
            if type(v) == "function" then
                local info = debug.getinfo(v)
                if info and info.name and (info.name:lower():find("job") or info.name:lower():find("server")) then
                    local ups = debug.getupvalues(v)
                    for _, uv in ipairs(ups) do
                        if type(uv) == "string" and #uv == 36 and string.match(uv, "^%x+%-%x+%-%x+%-%x+%-%x+$") then
                            if uv ~= spoofed then return uv end
                        end
                    end
                end
            end
        end
        return nil
    end},
    {name = "Method 7 (game:GetService('DataModel'):GetJobId)", func = function()
        local dm = game:GetService("DataModel")
        if dm and dm.GetJobId then
            local ok, id = pcall(function() return dm:GetJobId() end)
            if ok and id then return id end
        end
        return nil
    end},
    {name = "Method 8 (workspace:FindFirstChild('JobId'))", func = function()
        local obj = workspace:FindFirstChild("JobId")
        if obj and obj:IsA("StringValue") then return obj.Value end
        return nil
    end},
    {name = "Method 9 (game:GetService('MarketplaceService'):GetProductInfo with second param)", func = function()
        local ms = game:GetService("MarketplaceService")
        local ok, info = pcall(function() return ms:GetProductInfo(game.PlaceId, Enum.InfoType.Sales) end)
        if ok and info and info.JobId then return info.JobId end
        return nil
    end},
    {name = "Method 10 (TeleportService:GetTeleportInfo with placeId and jobId)", func = function()
        local ts = game:GetService("TeleportService")
        local ok, info = pcall(function() return ts:GetTeleportInfo(game.PlaceId, game.JobId) end)
        if ok and info and info.JobId then return info.JobId end
        return nil
    end},
    {name = "Method 11 (NetworkClient:GetConnectionState)", func = function()
        local nc = game:GetService("NetworkClient")
        if nc and nc.GetConnectionState then
            local state = nc:GetConnectionState()
            if state and state.ServerId then return state.ServerId end
        end
        return nil
    end},
    {name = "Method 12 (game:GetService('RunService'):GetJobId)", func = function()
        local rs = game:GetService("RunService")
        if rs and rs.GetJobId then
            local ok, id = pcall(function() return rs:GetJobId() end)
            if ok and id then return id end
        end
        return nil
    end},
    {name = "Method 13 (http request to /v1/games/server/current)", func = function()
        local req = getRequestMethod()
        if not req then return nil end
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/current"
        local resp = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if not resp or not resp.Body then return nil end
        local data = game:GetService("HttpService"):JSONDecode(resp.Body)
        if data and data.jobId then return data.jobId end
        return nil
    end},
    {name = "Method 14 (Players:GetCurrentServer)", func = function()
        local plrs = game:GetService("Players")
        if plrs.GetCurrentServer then
            local ok, id = pcall(function() return plrs:GetCurrentServer() end)
            if ok and id then return id end
        end
        return nil
    end},
    {name = "Method 15 (game:GetService('HttpService'):GetAsync with userID to find server)", func = function()
        local req = getRequestMethod()
        if not req then return nil end
        local userId = game:GetService("Players").LocalPlayer.UserId
        if not userId then return nil end
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
        local resp = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if not resp or not resp.Body then return nil end
        local data = game:GetService("HttpService"):JSONDecode(resp.Body)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing and server.playing > 0 then
                    -- can't verify userId, but return the one with most players
                end
            end
        end
        return nil
    end},
    {name = "Method 16 (debug.getlocal on stepAnimate for Delta specifically)", func = function()
        if identifyexecutor and identifyexecutor() == "Delta" then
            for _, v in ipairs(getgc(true)) do
                if type(v) == "function" then
                    local info = debug.getinfo(v)
                    if info and info.name == "stepAnimate" then
                        local locals = debug.getlocals(v)
                        for _, lv in ipairs(locals) do
                            if type(lv) == "string" and #lv == 36 then
                                return lv
                            end
                        end
                    end
                end
            end
        end
        return nil
    end},
    {name = "Method 17 (getnamecallmethod on game.JobId)", func = function()
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
    {name = "Method 18 (TeleportService:GetServerInfoForGame)", func = function()
        local ts = game:GetService("TeleportService")
        local ok, info = pcall(function() return ts:GetServerInfoForGame(game.PlaceId) end)
        if ok and info and info.JobId then return info.JobId end
        return nil
    end},
    {name = "Method 19 (game:GetService('Stats'):GetServerId)", func = function()
        local stats = game:GetService("Stats")
        if stats and stats.GetServerId then
            local ok, id = pcall(function() return stats:GetServerId() end)
            if ok and id then return id end
        end
        return nil
    end},
    {name = "Method 20 (syn.crypt or custom decryption from memory)", func = function()
        -- Attempt to find a string in memory that is the real JobId
        local pattern = "^%x+%-%x+%-%x+%-%x+%-%x+$"
        local candidates = {}
        for _, v in ipairs(getgc(true)) do
            if type(v) == "string" and #v == 36 and string.match(v, pattern) then
                if v ~= spoofed then
                    table.insert(candidates, v)
                end
            end
        end
        -- If multiple, pick the most frequent
        local counts = {}
        for _, id in ipairs(candidates) do
            counts[id] = (counts[id] or 0) + 1
        end
        local best = nil
        local max = 0
        for id, cnt in pairs(counts) do
            if cnt > max then
                max = cnt
                best = id
            end
        end
        return best
    end},
    {name = "Method 21 (hook ReplicatedStorage event that receives JobId)", func = function()
        local rs = game:GetService("ReplicatedStorage")
        local events = {}
        for _, child in ipairs(rs:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                table.insert(events, child)
            end
        end
        for _, ev in ipairs(events) do
            if ev.OnClientEvent then
                local old
                local captured = nil
                old = hookfunction(ev.OnClientEvent, function(...)
                    local args = {...}
                    for _, arg in ipairs(args) do
                        if type(arg) == "string" and #arg == 36 and string.match(arg, "^%x+%-%x+%-%x+%-%x+%-%x+$") then
                            if arg ~= spoofed then
                                captured = arg
                            end
                        end
                    end
                    return old(...)
                end)
                task.wait(1)
                ev.OnClientEvent = old
                if captured then return captured end
            end
        end
        return nil
    end},
    {name = "Method 22 (check game:GetService('HttpService').__index for JobId)", func = function()
        local hs = game:GetService("HttpService")
        local mt = getrawmetatable(hs)
        if mt and mt.__index then
            local old = mt.__index
            mt.__index = function(self, key)
                if key == "JobId" then
                    return self.JobId
                end
                return old(self, key)
            end
            local id = hs.JobId
            mt.__index = old
            return id
        end
        return nil
    end}
}

local logLines = {}
table.insert(logLines, "=== NOVEL JOB ID DETECTION RESULTS ===")
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
    local line = string.format("%-35s | %-8s | %s", m.name, status, result or "nil")
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
writeFile("jobid_log_novel.txt", logText)

getgenv().REAL_JOB_ID = realId
_G.REAL_JOB_ID = realId

return realId
