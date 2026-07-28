local function getAllJobIds()
    local results = {}
    local spoofed = game.JobId

    local function method1()
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
    end

    local function method2()
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
    end

    local function method3()
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
    end

    local function method4()
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
    end

    local function method5()
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
    end

    local function method6()
        local rs = game:GetService("ReplicatedStorage")
        for _, child in ipairs(rs:GetChildren()) do
            if child:IsA("StringValue") and child.Name:lower():find("job") and #child.Value > 10 then
                return child.Value
            end
        end
        return nil
    end

    local function method7()
        local pattern = "^%x+%-%x+%-%x+%-%x+%-%x+$"
        for _, v in ipairs(getgc(true)) do
            if type(v) == "string" and #v == 36 and string.match(v, pattern) then
                if v ~= game.JobId then
                    return v
                end
            end
        end
        return nil
    end

    local function method8()
        local ts = game:GetService("TeleportService")
        local ok, info = pcall(function()
            return ts:GetTeleportInfo(game.PlaceId)
        end)
        if ok and info and info.JobId then
            return info.JobId
        end
        return nil
    end

    local function method9()
        local services = {game:GetService("Lighting"), game:GetService("SoundService"), game:GetService("Teams")}
        for _, svc in ipairs(services) do
            for _, child in ipairs(svc:GetChildren()) do
                if child:IsA("StringValue") and child.Name:lower():find("job") and #child.Value > 10 then
                    return child.Value
                end
            end
        end
        return nil
    end

    local function method10()
        return rawget(game, "JobId")
    end

    local function method11()
        if getgenv().REAL_JOB_ID then
            return getgenv().REAL_JOB_ID
        end
        if _G.REAL_JOB_ID then
            return _G.REAL_JOB_ID
        end
        return nil
    end

    local function method12()
        local realId = nil
        local conn
        conn = game.Loaded:Connect(function()
            realId = game.JobId
            conn:Disconnect()
        end)
        task.wait(0.5)
        return realId
    end

    local methods = {
        {name = "Method 1 (stepAnimate hook)", func = method1},
        {name = "Method 2 (clone)", func = method2},
        {name = "Method 3 (API first diff)", func = method3},
        {name = "Method 4 (Teleport hook)", func = method4},
        {name = "Method 5 (API any server)", func = method5},
        {name = "Method 6 (ReplicatedStorage)", func = method6},
        {name = "Method 7 (Memory scan)", func = method7},
        {name = "Method 8 (TeleportInfo)", func = method8},
        {name = "Method 9 (Services)", func = method9},
        {name = "Method 10 (rawget)", func = method10},
        {name = "Method 11 (Environment)", func = method11},
        {name = "Method 12 (Loaded event)", func = method12}
    }

    for i, m in ipairs(methods) do
        local success, result = pcall(m.func)
        if success and result and type(result) == "string" and #result == 36 then
            results[m.name] = result
        else
            results[m.name] = nil
        end
    end

    return results
end

local spoofed = game.JobId
local results = getAllJobIds()

local vote = {}
local methodStatus = {}

print("=== JOB ID DETECTION RESULTS ===")
print("Spoofed (game.JobId):", spoofed)
print("")

for name, id in pairs(results) do
    local status = "FAILED"
    if id then
        if id == spoofed then
            status = "SPOOFED"
        else
            status = "WORKING"
            vote[id] = (vote[id] or 0) + 1
        end
    end
    methodStatus[name] = {id = id, status = status}
end

-- Print in method order
local methodOrder = {
    "Method 1 (stepAnimate hook)",
    "Method 2 (clone)",
    "Method 3 (API first diff)",
    "Method 4 (Teleport hook)",
    "Method 5 (API any server)",
    "Method 6 (ReplicatedStorage)",
    "Method 7 (Memory scan)",
    "Method 8 (TeleportInfo)",
    "Method 9 (Services)",
    "Method 10 (rawget)",
    "Method 11 (Environment)",
    "Method 12 (Loaded event)"
}

for _, name in ipairs(methodOrder) do
    local entry = methodStatus[name]
    if entry then
        local idStr = entry.id or "nil"
        local status = entry.status
        print(string.format("%-25s | %-8s | %s", name, status, idStr))
    end
end

print("")
local realId = spoofed
local maxVotes = 0
for id, count in pairs(vote) do
    if count > maxVotes then
        maxVotes = count
        realId = id
    end
end

print("Votes per candidate:")
for id, count in pairs(vote) do
    print(string.format("  %s : %d vote(s)", id, count))
end

print("")
print("FINAL REAL_JOB_ID = " .. realId)
getgenv().REAL_JOB_ID = realId
_G.REAL_JOB_ID = realId

return realId
