local spoofed = game.JobId

local function writeFile(path, content)
    local success = false
    if writefile then
        success = pcall(function() writefile(path, content) end)
    end
    if not success and appendfile then
        success = pcall(function()
            if not isfile(path) then writefile(path, "") end
            appendfile(path, content)
        end)
    end
    if not success and savefile then
        success = pcall(function() savefile(path, content) end)
    end
end

local function safeCall(func)
    local success, result = pcall(func)
    if success then
        return result
    else
        return nil
    end
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
    {name = "Method 1 (stepAnimate)", func = function()
        local realJobId = game.JobId
        if identifyexecutor and identifyexecutor() == "Delta" then
            local stepAnimate = nil
            local printed = false
            local searchStart = tick()
            repeat
                for _, v in ipairs(getgc(true)) do
                    if typeof(v) == "function" then
                        local info = debug.getinfo(v)
                        if info and info.name == "stepAnimate" then
                            stepAnimate = v
                            break
                        end
                    end
                end
                if tick() - searchStart > 5 then break end
                task.wait()
            until stepAnimate
            if stepAnimate then
                local old
                old = hookfunction(stepAnimate, function(dt)
                    if not printed then
                        printed = true
                        realJobId = game.JobId
                    end
                    return old(dt)
                end)
                local waitStart = tick()
                repeat
                    task.wait()
                    if tick() - waitStart > 5 then break end
                until printed
            end
        end
        return realJobId
    end},
    {name = "Method 2 (clone)", func = function()
        local real = game.JobId
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "JobId" then
                return game.JobId
            end
            return oldIndex(self, key)
        end)
        local cloned = game:Clone()
        if cloned and cloned.JobId then
            real = cloned.JobId
        end
        if cloned then cloned:Destroy() end
        mt.__index = oldIndex
        return real
    end},
    {name = "Method 3 (API diff)", func = function()
        local http = game:GetService("HttpService")
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
        local req = getRequestMethod()
        if not req then return nil end
        local response = req({
            Url = url,
            Method = "GET",
            Headers = {["User-Agent"] = "Mozilla/5.0"}
        })
        if response and response.Body then
            local data = http:JSONDecode(response.Body)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if server.playing and server.playing > 0 and server.id ~= game.JobId then
                        return server.id
                    end
                end
            end
        end
        return nil
    end},
    {name = "Method 4 (Teleport hook)", func = function()
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
    {name = "Method 5 (API any)", func = function()
        local http = game:GetService("HttpService")
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Asc"
        local req = getRequestMethod()
        if not req then return nil end
        local response = req({
            Url = url,
            Method = "GET",
            Headers = {["User-Agent"] = "Mozilla/5.0"}
        })
        if response and response.Body then
            local data = http:JSONDecode(response.Body)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if server.playing and server.playing > 0 then
                        return server.id
                    end
                end
            end
        end
        return nil
    end},
    {name = "Method 6 (ReplicatedStorage)", func = function()
        local rs = game:GetService("ReplicatedStorage")
        for _, child in ipairs(rs:GetChildren()) do
            if child:IsA("StringValue") and child.Name:lower():find("job") and #child.Value > 10 then
                return child.Value
            end
        end
        return nil
    end},
    {name = "Method 7 (Memory scan)", func = function()
        local pattern = "^%x+%-%x+%-%x+%-%x+%-%x+$"
        for _, v in ipairs(getgc(true)) do
            if type(v) == "string" and #v == 36 and string.match(v, pattern) then
                if v ~= game.JobId then
                    return v
                end
            end
        end
        return nil
    end},
    {name = "Method 8 (TeleportInfo)", func = function()
        local ts = game:GetService("TeleportService")
        local ok, info = pcall(function()
            return ts:GetTeleportInfo(game.PlaceId)
        end)
        if ok and info and info.JobId then
            return info.JobId
        end
        return nil
    end},
    {name = "Method 9 (Services)", func = function()
        local services = {game:GetService("Lighting"), game:GetService("SoundService"), game:GetService("Teams")}
        for _, svc in ipairs(services) do
            for _, child in ipairs(svc:GetChildren()) do
                if child:IsA("StringValue") and child.Name:lower():find("job") and #child.Value > 10 then
                    return child.Value
                end
            end
        end
        return nil
    end},
    {name = "Method 10 (rawget)", func = function()
        return rawget(game, "JobId")
    end},
    {name = "Method 11 (Environment)", func = function()
        if getgenv().REAL_JOB_ID then
            return getgenv().REAL_JOB_ID
        end
        if _G.REAL_JOB_ID then
            return _G.REAL_JOB_ID
        end
        return nil
    end},
    {name = "Method 12 (Loaded event)", func = function()
        local realId = nil
        local conn
        conn = game.Loaded:Connect(function()
            realId = game.JobId
            conn:Disconnect()
        end)
        task.wait(0.5)
        return realId
    end},
    {name = "Method 13 (NetworkClient)", func = function()
        local nc = game:GetService("NetworkClient")
        if nc and nc.ServerId then
            return nc.ServerId
        end
        return nil
    end},
    {name = "Method 14 (TeleportService alternate)", func = function()
        local ts = game:GetService("TeleportService")
        local ok, data = pcall(function()
            return ts:GetTeleportInfo(game.PlaceId, game.JobId)
        end)
        if ok and data and data.JobId then
            return data.JobId
        end
        return nil
    end},
    {name = "Method 15 (HttpService API with player count)", func = function()
        local http = game:GetService("HttpService")
        local req = getRequestMethod()
        if not req then return nil end
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Asc"
        local response = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if response and response.Body then
            local data = http:JSONDecode(response.Body)
            if data and data.data then
                local myJob = game.JobId
                for _, server in ipairs(data.data) do
                    if server.id == myJob then
                        return server.id
                    end
                end
                -- If not found, return the one with most players
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
    {name = "Method 16 (ContentProvider)", func = function()
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
    {name = "Method 17 (RunService)", func = function()
        local rs = game:GetService("RunService")
        if rs and rs.RenderStepped then
            local ok, info = pcall(function()
                return rs:GetPropertyChangedSignal("Heartbeat")
            end)
            if ok then
                -- Some executors store job id in hidden property
                local mt = getrawmetatable(rs)
                if mt and mt.__index then
                    local job = mt.__index(rs, "JobId")
                    if job and #job == 36 then return job end
                end
            end
        end
        return nil
    end},
    {name = "Method 18 (MarketplaceService)", func = function()
        local ms = game:GetService("MarketplaceService")
        local ok, info = pcall(function()
            return ms:GetProductInfo(game.PlaceId)
        end)
        if ok and info and info.JobId then
            return info.JobId
        end
        return nil
    end},
    {name = "Method 19 (ScriptContext)", func = function()
        local sc = game:GetService("ScriptContext")
        if sc and sc.Scripts then
            for _, script in ipairs(sc:GetChildren()) do
                if script:IsA("LocalScript") then
                    local src = script.Source
                    if src then
                        local match = string.match(src, "([%x-]+%-[%x-]+%-[%x-]+%-[%x-]+%-[%x-]+)")
                        if match and #match == 36 then
                            return match
                        end
                    end
                end
            end
        end
        return nil
    end},
    {name = "Method 20 (Players)", func = function()
        local plrs = game:GetService("Players")
        if plrs and plrs.LocalPlayer then
            local userId = plrs.LocalPlayer.UserId
            local req = getRequestMethod()
            if req then
                local url = "https://users.roblox.com/v1/users/" .. userId
                local response = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
                if response and response.Body then
                    local data = game:GetService("HttpService"):JSONDecode(response.Body)
                    if data and data.id then
                        -- Not helpful, but maybe the response includes job id? Unlikely.
                    end
                end
            end
        end
        return nil
    end},
    {name = "Method 21 (HttpService GetAsync with GameId)", func = function()
        local http = game:GetService("HttpService")
        local req = getRequestMethod()
        if not req then return nil end
        local url = "https://games.roblox.com/v1/games?universeIds=" .. game.GameId
        local response = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if response and response.Body then
            local data = http:JSONDecode(response.Body)
            if data and data.data and #data.data > 0 then
                local gameInfo = data.data[1]
                if gameInfo and gameInfo.placeId and gameInfo.instanceId then
                    return gameInfo.instanceId
                end
            end
        end
        return nil
    end},
    {name = "Method 22 (Memory pattern brute)", func = function()
        local pattern = "^%x+%-%x+%-%x+%-%x+%-%x+$"
        local candidates = {}
        for _, v in ipairs(getgc(true)) do
            if type(v) == "string" and #v == 36 and string.match(v, pattern) then
                table.insert(candidates, v)
            end
        end
        -- Return the one that appears most often (excluding spoofed)
        local counts = {}
        for _, id in ipairs(candidates) do
            if id ~= game.JobId then
                counts[id] = (counts[id] or 0) + 1
            end
        end
        local best = nil
        local maxCount = 0
        for id, count in pairs(counts) do
            if count > maxCount then
                maxCount = count
                best = id
            end
        end
        return best
    end}
}

local logLines = {}
table.insert(logLines, "=== JOB ID DETECTION RESULTS ===")
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
    local line = string.format("%-30s | %-8s | %s", m.name, status, result or "nil")
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

writeFile("jobid_log.txt", logText)

getgenv().REAL_JOB_ID = realId
_G.REAL_JOB_ID = realId

return realId
