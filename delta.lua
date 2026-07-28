local spoofed = game.JobId

local function safeCall(func)
    local success, result = pcall(func)
    if success then
        return result
    else
        return nil
    end
end

local methods = {
    {name = "Method 1 (stepAnimate hook)", func = function()
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
    {name = "Method 3 (API first diff)", func = function()
        local http = game:GetService("HttpService")
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
        local requestMethod = nil
        if syn and syn.request then requestMethod = syn.request
        elseif fluxus and fluxus.request then requestMethod = fluxus.request
        elseif http and http.request then requestMethod = http.request
        elseif getgenv().request then requestMethod = getgenv().request
        elseif request then requestMethod = request
        elseif http_request then requestMethod = http_request end
        if not requestMethod then return nil end
        local response = requestMethod({
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
    {name = "Method 5 (API any server)", func = function()
        local http = game:GetService("HttpService")
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Asc"
        local requestMethod = nil
        if syn and syn.request then requestMethod = syn.request
        elseif fluxus and fluxus.request then requestMethod = fluxus.request
        elseif http and http.request then requestMethod = http.request
        elseif getgenv().request then requestMethod = getgenv().request
        elseif request then requestMethod = request
        elseif http_request then requestMethod = http_request end
        if not requestMethod then return nil end
        local response = requestMethod({
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
    end}
}

print("=== JOB ID DETECTION RESULTS ===")
print("Spoofed (game.JobId):", spoofed)
print("")

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
    print(string.format("%-30s | %-8s | %s", m.name, status, result or "nil"))
end

print("")
print("=== SUMMARY ===")
local working = {}
local spoofedMethods = {}
local failed = {}
for name, result in pairs(results) do
    local status = "FAILED"
    if result then
        if result == spoofed then
            status = "SPOOFED"
            table.insert(spoofedMethods, name)
        else
            status = "WORKING"
            table.insert(working, name)
        end
    else
        table.insert(failed, name)
    end
end

print("WORKING methods:")
for _, name in ipairs(working) do
    print("  - " .. name)
end
print("SPOOFED methods:")
for _, name in ipairs(spoofedMethods) do
    print("  - " .. name)
end
print("FAILED methods:")
for _, name in ipairs(failed) do
    print("  - " .. name)
end

print("")
print("Votes per candidate:")
for id, count in pairs(vote) do
    print(string.format("  %s : %d vote(s)", id, count))
end

local realId = spoofed
local maxVotes = 0
for id, count in pairs(vote) do
    if count > maxVotes then
        maxVotes = count
        realId = id
    end
end

print("")
print("FINAL REAL_JOB_ID = " .. realId)
getgenv().REAL_JOB_ID = realId
_G.REAL_JOB_ID = realId

return realId
