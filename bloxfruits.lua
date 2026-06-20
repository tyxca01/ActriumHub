local HttpSvc   = game:GetService("HttpService")
local LogSvc    = game:GetService("LogService")
local RunSvc    = game:GetService("RunService")
local Players   = game:GetService("Players")
local RepStore  = game:GetService("ReplicatedStorage")
local TweenSvc  = game:GetService("TweenService")
local UIS       = game:GetService("UserInputService")
local VirtUser  = game:GetService("VirtualUser")
local Stats     = game:GetService("Stats")
local LP        = Players.LocalPlayer
local CommF_    = RepStore.Remotes.CommF_
local WEBHOOK_URL = "https://discord.com/api/webhooks/1514678787126857769/mvua5h3pmKChO6iR1E_v9gYr4UsEnbF0m6W8zqU2CUZ0rzI6enUuG_hq-SangGJp5gVP"

local function _getRequest()
    return (typeof(request) == "function" and request)
        or (typeof(http_request) == "function" and http_request)
        or (typeof(http) == "table" and typeof(http.request) == "function" and http.request)
        or (typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request)
        or (typeof(fluxus) == "table" and typeof(fluxus.request) == "function" and fluxus.request)
end

local function _safePost(url, data)
    if not url or url == "" then return false, "missing webhook url" end
    local body = HttpSvc:JSONEncode(data)
    local lastErr
    local req = _getRequest()
    if req then
        local ok, res = pcall(function()
            return req({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end)
        if ok then
            local status = type(res) == "table" and (res.StatusCode or res.Status or res.status_code) or nil
            if not status or (tonumber(status) and tonumber(status) >= 200 and tonumber(status) < 300) then
                return true, status or "request sent"
            end
            lastErr = "request status " .. tostring(status)
        else
            lastErr = tostring(res)
        end
    end

    if typeof(HttpPost) == "function" then
        local ok, err = pcall(function()
            return HttpPost(url, body)
        end)
        if ok then return true, "httppost sent" end
        lastErr = tostring(err)
    end

    local ok, err = pcall(function()
        HttpSvc:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
    end)
    if ok then return true, "postasync sent" end
    return false, lastErr and (lastErr .. " | " .. tostring(err)) or tostring(err)
end
local function _concat(args)
    for i = 1, #args do args[i] = tostring(args[i]) end
    return table.concat(args, "\t")
end
local function _webhook(txt)
    local content = tostring(txt)
    if #content > 1900 then
        content = content:sub(1, 1900) .. "\n...truncated"
    end
    return _safePost(WEBHOOK_URL, { content = content })
end
local _debugCooldowns = {}
local _debugCooldownCount = 0
local DEBUG_ENABLED = false -- master switch: keep false in production; the webhook spam from hot loops was causing client-side instability for users
local DEBUG_MAX_COOLDOWN_KEYS = 200 -- hard cap so this table can never grow unbounded over a session

local _print, _warn, _error = print, warn, error
if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end
if setfpscap then setfpscap(120) end
local Config = { Version = "1.0.0" }
local Library, SaveManager, InterfaceManager
do
    local ok, res = pcall(function()
        local fn, compileErr = loadstring(game:HttpGet("https://raw.githubusercontent.com/xritura01/Ui/main/Ui.lua", true))
        if not fn then
            error("Failed to compile UI library: " .. tostring(compileErr))
        end
        return { fn() }
    end)
    if not ok or not res then error("Failed to load UI library") end
    Library, SaveManager, InterfaceManager = res[1], res[2], res[3]
end
local placeIdStr = string.format("%.0f", game.PlaceId)
local World1 = (placeIdStr == "2753915549")
local World2 = (string.format("%.0f", game.PlaceId) == "79091703265657")
local World3 = (placeIdStr == "100117331123089")
print("[Actrium] PlaceId: " .. placeIdStr .. " | W1=" .. tostring(World1) .. " W2=" .. tostring(World2) .. " W3=" .. tostring(World3))
_G.Settings = {
    Main = {
        ["Select Weapon"]            = "Melee",
        ["Selected Weapon"]          = "",
        ["Farm Level Method"]        = "Quest",
        ["Auto Farm"]                = false,
        ["Auto Fast Farm"]           = false,
        ["Mastery Method"]           = "Quest",
        ["Auto Farm Fruit Mastery"]  = false,
        ["Auto Farm Gun Mastery"]    = false,
        ["Selected Mastery Sword"]   = nil,
        ["Auto Farm Sword Mastery"]  = false,
        ["Auto Summon Tyrant Of The Skies"] = false,
        ["Auto Kill Tyrant Of The Skies"]   = false,
        ["Selected Mon"]             = nil,
        ["Auto Farm Mon"]            = false,
        ["Selected Boss"]            = nil,
        ["Auto Farm Boss"]           = false,
        ["Auto Farm All Boss"]       = false,
    },
    Farm = {
        ["Auto Elite Hunter"]        = false,
        ["Auto Elite Hunter Hop"]    = false,
        ["Selected Bone Farm Method"]= "Quest",
        ["Auto Farm Bone"]           = false,
        ["Auto Random Surprise"]     = false,
        ["Auto Pirate Raid"]         = false,
        ["Auto Farm Chest Tween"]    = false,
        ["Auto Farm Chest Instant"]  = false,
        ["Auto Chest Hop"]           = false,
        ["Auto Farm Chest Mirage"]   = false,
        ["Auto Stop Items"]          = false,
        ["Auto Farm Katakuri"]       = false,
        ["Auto Spawn Cake Prince"]   = false,
        ["Auto Kill Cake Prince"]    = false,
        ["Auto Kill Dough King"]     = false,
        ["Selected Material"]        = nil,
        ["Auto Farm Material"]       = false,
    },
    Setting = {
        ["Spin Position"]            = false,
        ["Farm Distance"]            = 35,
        ["Player Tween Speed"]       = 350,
        ["Bring Mob"]                = true,
        ["Bring Mob Mode"]           = "Normal",
        ["Fast Attack Mode"]         = "Normal",
        ["Attack Aura"]              = true,
        ["Hide Notification"]        = false,
        ["Hide Damage Text"]         = true,
        ["Black Screen"]             = false,
        ["White Screen"]             = false,
        ["Mastery Health"]           = 25,
        ["Fruit Mastery Skill Z"]    = true,
        ["Fruit Mastery Skill X"]    = true,
        ["Fruit Mastery Skill C"]    = true,
        ["Fruit Mastery Skill V"]    = false,
        ["Fruit Mastery Skill F"]    = false,
        ["Gun Mastery Skill Z"]      = true,
        ["Gun Mastery Skill X"]      = true,
        ["Auto Set Spawn Point"]     = true,
        ["Auto Observation"]         = false,
        ["Auto Haki"]                = true,
        ["Auto Rejoin"]              = true,
        ["Fast Attack Delay"]        = 0.22,
    },
    Stats = {
        ["Auto Add Melee Stats"]       = false,
        ["Auto Add Defense Stats"]     = false,
        ["Auto Add Devil Fruit Stats"] = false,
        ["Auto Add Sword Stats"]       = false,
        ["Auto Add Gun Stats"]         = false,
        ["Point Stats"]                = 1,
    },
    Items = {
        ["Auto Second Sea"]           = false,
        ["Auto Third Sea"]            = false,
        ["Auto Super Human"]          = false,
        ["Auto Death Step"]           = false,
        ["Auto Fishman Karate"]       = false,
        ["Auto Electric Claw"]        = false,
        ["Auto Dragon Talon"]         = false,
        ["Auto God Human"]            = false,
        ["Auto Saber"]                = false,
        ["Auto Buddy Sword"]          = false,
        ["Auto Soul Guitar"]          = false,
        ["Auto Rengoku"]              = false,
        ["Auto Hallow Scythe"]        = false,
        ["Auto Warden Sword"]         = false,
        ["Auto Yama"]                 = false,
        ["Auto Tushita"]              = false,
        ["Auto Dragon Trident"]       = false,
        ["Auto Pole"]                 = false,
        ["Auto Shark Saw"]            = false,
        ["Auto Dark Dagger"]          = false,
        ["Auto Press Haki Button"]    = false,
        ["Auto Cursed Dual Katana"]   = false,
        ["Auto Canvander"]            = false,
        ["Auto Greybeard"]            = false,
        ["Auto Swan Glasses"]         = false,
        ["Auto Arena Trainer"]        = false,
        ["Auto Rainbow Haki"]         = false,
        ["Auto Holy Torch"]           = false,
        ["Auto Bartilo Quest"]        = false,
        ["Auto Farm Factory"]         = false,
    },
    Esp = {
        ["ESP Player"]    = false,
        ["ESP Chest"]     = false,
        ["ESP DevilFruit"]= false,
        ["ESP RealFruit"] = false,
        ["ESP Flower"]    = false,
        ["ESP Island"]    = false,
        ["ESP Npc"]       = false,
        ["ESP Sea Beast"] = false,
        ["ESP Monster"]   = false,
        ["ESP Mirage"]    = false,
        ["ESP Kitsune"]   = false,
        ["ESP Frozen"]    = false,
        ["ESP Gear"]      = false,
        ["ESP Advanced Fruit Dealer"] = false,
        ["ESP Aura"]      = false,
        ["ESP Prehistoric"] = false,
    },
    SeaEvent = {
        ["Selected Boat"]                  = "Guardian",
        ["Selected Zone"]                  = "Zone 5",
        ["Boat Tween Speed"]               = 300,
        ["Sail Boat"]                      = false,
        ["Auto Farm Shark"]                = true,
        ["Auto Farm Piranha"]              = true,
        ["Auto Farm Fish Crew Member"]     = true,
        ["Auto Farm Ghost Ship"]           = true,
        ["Auto Farm Pirate Brigade"]       = true,
        ["Auto Farm Pirate Grand Brigade"] = true,
        ["Auto Farm Terrorshark"]          = true,
        ["Auto Farm Seabeasts"]            = true,
        ["Dodge Seabeasts Attack"]         = true,
        ["Dodge Terrorshark Attack"]       = true,
    },
    SeaStack = {
        ["Tween To Frozen Dimension"]   = false,
        ["Summon Frozen Dimension"]     = false,
        ["Tween To Kitsune Island"]     = false,
        ["Summon Kitsune Island"]       = false,
        ["Auto Collect Azure Ember"]    = false,
        ["Set Azure Ember"]             = 20,
        ["Auto Trade Azure Ember"]      = false,
        ["Tween To Mirage Island"]      = false,
        ["Auto Attack Seabeasts"]       = false,
        ["Summon Prehistoric Island"]   = false,
        ["Tween To Prehistoric Island"] = false,
        ["Auto Kill Lava Golem"]        = false,
        ["Teleport To Advanced Fruit Dealer"] = false,
    },
    SettingSea = {
        ["Lightning"]                = false,
        ["Increase Boat Speed"]      = false,
        ["No Clip Rock"]             = false,
        ["Use Devil Fruit Skill"]    = true,
        ["Use Melee Skill"]          = true,
        ["Use Sword Skill"]          = true,
        ["Use Gun Skill"]            = true,
        ["Devil Fruit Z Skill"]      = true,
        ["Devil Fruit X Skill"]      = true,
        ["Devil Fruit C Skill"]      = true,
        ["Devil Fruit V Skill"]      = false,
        ["Devil Fruit F Skill"]      = false,
        ["Melee Z Skill"]            = true,
        ["Melee X Skill"]            = true,
        ["Melee C Skill"]            = true,
        ["Melee V Skill"]            = true,
    },
    Race = {
        ["Auto Race V2"]                  = false,
        ["Auto Race V3"]                  = false,
        ["Selected Place"]               = nil,
        ["Teleport To Place"]            = false,
        ["Auto Buy Gear"]                = false,
        ["Tween To Highest Mirage"]      = false,
        ["Find Blue Gear"]               = false,
        ["Look Moon Ability"]            = false,
        ["Auto Train"]                   = false,
        ["Auto Kill Player After Trial"] = false,
        ["Auto Trial"]                   = false,
    },
    Raid = {
        ["Selected Chip"]     = nil,
        ["Auto Raid"]         = false,
        ["Auto Awaken"]       = false,
        ["Price Devil Fruit"] = 1000000,
        ["Unstore Devil Fruit"]= false,
        ["Law Raid"]          = false,
    },
    Shop = {
        ["Auto Buy Legendary Sword"] = false,
        ["Auto Buy Haki Color"]      = false,
    },
    LocalPlayer = {
        ["Infinite Ability"]  = true,
        ["Infinite Energy"]   = false,
        ["Infinite Geppo"]    = false,
        ["Infinite Soru"]     = false,
        ["Dodge No Cooldown"] = false,
        ["Active Race V3"]    = false,
        ["Active Race V4"]    = true,
        ["Walk On Water"]     = true,
        ["No Clip"]           = false,
    },
    Fruit = {
        ["Auto Buy Random Fruit"] = false,
        ["Store Rarity Fruit"]    = "Common - Mythical",
        ["Auto Store Fruit"]      = false,
        ["Fruit Notification"]    = false,
        ["Teleport To Fruit"]     = false,
        ["Tween To Fruit"]        = false,
    },
    DragonDojo = {
        ["Auto Farm Blaze Ember"] = false,
        ["Auto Collect Blaze Ember"] = false,
    },
    Combat = {
        ["Auto Kill Player Quest"] = false,
        ["Aimbot Gun"] = false,
        ["Aimbot Skill Nearest"] = false,
        ["Aimbot Skill"] = false,
        ["Enable PvP"] = false,
    },
    Misc = {
        ["Hide Chat"] = false,
        ["Hide Leaderboard"] = false,
        ["Highlight Mode"] = false,
    },
}

local State = {
    Mon          = "",         
    NameMon      = "",           
    NameQuest    = "",
    LevelQuest   = 1,
    CFrameQuest  = CFrame.new(),
    CFrameMon    = CFrame.new(),
    MonFarm      = "",           
    PosMon       = CFrame.new(),
    Pos          = CFrame.new(0, 35, 0),
    BringMobDist = 250,
    SelectWeaponGun = "",
    EspNum       = math.random(1, 1000000),
    StopTween    = false,
    Skillaimbot  = false,
    AimBotSkillPosition = Vector3.new(),
    UseSkill     = false,
    UseGunSkill  = false,
    SeaSkill     = false,
    ActiveTween  = nil,
    TweenTarget  = nil,
    TweenGen     = 0,
    TweenStartedAt = 0,
    MoveActive   = false,
}

local MaterialMon = {}
local MaterialPos = CFrame.new()

local function GetChar()     return LP.Character end
local function GetHRP()      local c = GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHumanoid() local c = GetChar() return c and c:FindFirstChild("Humanoid") end

local function FormatDebugValue(value)
    local valueType = typeof(value)
    if valueType == "Vector3" then
        return string.format("%.1f, %.1f, %.1f", value.X, value.Y, value.Z)
    elseif valueType == "CFrame" then
        local p = value.Position
        return string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
    elseif valueType == "Instance" then
        return value:GetFullName()
    end
    return tostring(value)
end

local function SendDebug(tag, message, extra, cooldown)
    if not DEBUG_ENABLED then return end -- hard kill switch: prevents hot-loop webhook spam entirely
    cooldown = cooldown or 3
    local key = tostring(tag) .. ":" .. tostring(message)
    local now = os.clock()
    if _debugCooldowns[key] and (now - _debugCooldowns[key]) < cooldown then return end

    -- Hard cap on cooldown table size: if we've hit the cap, wipe it rather than
    -- growing forever. This is the actual memory-leak fix — previously every
    -- unique tag:message combination (many of which embedded dynamic data like
    -- positions/names) became a permanent key for the rest of the session.
    if _debugCooldownCount >= DEBUG_MAX_COOLDOWN_KEYS then
        _debugCooldowns = {}
        _debugCooldownCount = 0
    end
    if not _debugCooldowns[key] then
        _debugCooldownCount += 1
    end
    _debugCooldowns[key] = now

    task.spawn(function()
        pcall(function()
            local lines = {"[DEBUG][" .. tostring(tag) .. "] " .. tostring(message)}
            local hrp = GetHRP()
            table.insert(lines, "pos=" .. (hrp and FormatDebugValue(hrp.Position) or "no-hrp"))
            table.insert(lines, "method=" .. tostring(_G.Settings.Main["Farm Level Method"]))
            table.insert(lines, "mon=" .. tostring(State.Mon) .. " nameMon=" .. tostring(State.NameMon))
            table.insert(lines, "quest=" .. tostring(State.NameQuest) .. " levelQuest=" .. tostring(State.LevelQuest))
            table.insert(lines, "monFarm=" .. tostring(State.MonFarm))
            if extra then
                for k, v in pairs(extra) do
                    table.insert(lines, tostring(k) .. "=" .. FormatDebugValue(v))
                end
            end
            _webhook(table.concat(lines, "\n"))
        end)
    end)
end

pcall(function()
    local env = getgenv and getgenv() or _G
    env.SendDebug = SendDebug
    env.senddebug = SendDebug
    env.TestWebhook = function(message)
        return _webhook("[TEST] " .. tostring(message or "webhook online"))
    end
end)

local function AutoHaki()
    local char = GetChar()
    if not char then
        SendDebug("AutoHaki", "missing character", nil, 10)
        return
    end
    if not char:FindFirstChild("HasBuso") then
        SendDebug("AutoHaki", "enabling buso", nil, 10)
        pcall(function() CommF_:InvokeServer("Buso") end)
    end
end

local function EquipWeapon(name)
    if not name or name == "" then return end
    pcall(function()
        if not GetChar():FindFirstChild(name) then
            local tool = LP.Backpack:FindFirstChild(name)
            if tool then GetHumanoid():EquipTool(tool) end
        end
    end)
end

local function UnEquipWeapon(name)
    if not name or name == "" then return end
    pcall(function()
        local t = GetChar():FindFirstChild(name)
        if t then t.Parent = LP.Backpack end
    end)
end
task.spawn(function()
    local angle = 0
    while task.wait() do
        if _G.Settings.Setting["Spin Position"] then
            local r   = math.rad(angle)
            local fd  = _G.Settings.Setting["Farm Distance"]
            State.Pos = CFrame.new(math.cos(r)*20, fd, math.sin(r)*20)
            angle = (angle + 30) % 360
        else
            State.Pos = CFrame.new(0, _G.Settings.Setting["Farm Distance"], 0)
        end
    end
end)
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            for _, v in pairs(LP.Backpack:GetChildren()) do
                if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
                    State.SelectWeaponGun = v.Name
                end
            end
        end)
    end
end)
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            local sel = _G.Settings.Main["Select Weapon"]
            local tipMap = {
                Melee = "Melee", Sword = "Sword", Gun = "Gun", Fruit = "Blox Fruit"
            }
            local tip = tipMap[sel]
            if not tip then return end
            for _, v in pairs(LP.Backpack:GetChildren()) do
                if v:IsA("Tool") and v.ToolTip == tip then
                    _G.Settings.Main["Selected Weapon"] = v.Name
                end
            end
        end)
    end
end)
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            if setscriptable then setscriptable(LP, "SimulationRadius", true) end
            if sethiddenproperty then sethiddenproperty(LP, "SimulationRadius", math.huge) end
        end)
    end
end)

local function IsNoClipNeeded()
    local s = _G.Settings
    return s.Main["Auto Farm"] or s.Main["Auto Farm Mon"] or s.Main["Auto Farm Boss"]
        or s.Main["Auto Farm All Boss"] or s.Main["Auto Farm Sword Mastery"]
        or s.Main["Auto Farm Fruit Mastery"] or s.Main["Auto Farm Gun Mastery"]
        or s.Main["Auto Summon Tyrant Of The Skies"] or s.Main["Auto Kill Tyrant Of The Skies"]
        or s.Farm["Auto Farm Chest Tween"] or s.Farm["Auto Farm Chest Instant"]
        or s.Farm["Auto Farm Material"] or s.Farm["Auto Farm Chest Mirage"]
        or s.Farm["Auto Elite Hunter"] or s.Farm["Auto Farm Bone"]
        or s.Farm["Auto Kill Cake Prince"] or s.Farm["Auto Kill Dough King"]
        or s.Farm["Auto Pirate Raid"] or s.Farm["Auto Farm Katakuri"]
        or s.Items["Auto Saber"] or s.Items["Auto Greybeard"] or s.Items["Auto Pole"]
        or s.Items["Auto Shark Saw"] or s.Items["Auto Warden Sword"]
        or s.Items["Auto Second Sea"] or s.Items["Auto Third Sea"]
        or s.Items["Auto Farm Factory"] or s.Items["Auto Swan Glasses"]
        or s.Items["Auto Rengoku"] or s.Items["Auto Bartilo Quest"]
        or s.Items["Auto Dragon Trident"] or s.Items["Auto Cursed Dual Katana"]
        or s.Items["Auto Canvander"] or s.Items["Auto Arena Trainer"]
        or s.Items["Auto Rainbow Haki"] or s.Items["Auto Holy Torch"]
        or s.Items["Auto Dark Dagger"] or s.Items["Auto Buddy Sword"]
        or s.Items["Auto Soul Guitar"] or s.Items["Auto Tushita"]
        or s.Items["Auto Hallow Scythe"] or s.Items["Auto Yama"]
        or s.Items["Auto Press Haki Button"]
        or s.Race["Auto Race V2"] or s.Race["Auto Race V3"]
        or s.Race["Auto Train"] or s.Race["Auto Trial"]
        or s.Race["Tween To Highest Mirage"] or s.Race["Find Blue Gear"]
        or s.SeaStack["Tween To Kitsune Island"] or s.SeaStack["Summon Frozen Dimension"]
        or s.SeaStack["Tween To Mirage Island"] or s.SeaStack["Summon Kitsune Island"]
        or s.SeaStack["Summon Prehistoric Island"] or s.SeaStack["Tween To Prehistoric Island"]
        or s.SeaStack["Teleport To Advanced Fruit Dealer"]
        or s.LocalPlayer["No Clip"]
        or s.SeaEvent["Sail Boat"]
        or s.DragonDojo["Auto Farm Blaze Ember"]
        or s.Raid["Auto Raid"] or s.Raid["Law Raid"]
end

task.spawn(function()
    RunSvc.Stepped:Connect(function()
        if IsNoClipNeeded() then
            local char = GetChar()
            if char then
                for _, v in ipairs(char:GetChildren()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end
    end)
end)

task.spawn(function()
    while task.wait() do
        if IsNoClipNeeded() then
            local hrp = GetHRP()
            if hrp then
                if not hrp:FindFirstChild("BodyClip") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name     = "BodyClip"
                    bv.Parent   = hrp
                    bv.MaxForce = Vector3.new(100000, 100000, 100000)
                    bv.Velocity = Vector3.new(0, 0, 0)
                end
            end
        else
            local hrp = GetHRP()
            if hrp and hrp:FindFirstChild("BodyClip") then
                hrp.BodyClip:Destroy()
            end
        end
    end
end)

local function SetCharacterCFrame(char, cf)
    local hrp = GetHRP()
    if not char or not hrp then return false end
    local hum = GetHumanoid()
    if hum then
        hum.Sit = false
        hum.PlatformStand = false
    end
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
    pcall(function() hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
    pcall(function() char:PivotTo(cf) end)
    pcall(function() hrp.CFrame = cf end)
    return true
end

local function TweenPlayer(pos)
    if typeof(pos) ~= "CFrame" then
        SendDebug("Tween", "bad type: " .. typeof(pos), nil, 5)
        return
    end

    local char = GetChar()
    local hrp = GetHRP()
    if not char or not hrp then
        SendDebug("Tween", "no char or hrp", { char = char, hrp = hrp }, 5)
        return
    end

    local originalTarget = pos
    local travelY = hrp.Position.Y

    local distance = (hrp.Position - pos.Position).Magnitude
    if distance <= 50 then
        hrp.CFrame = pos
        State.ActiveTween = nil
        State.TweenTarget = nil
        return
    end

    if State.ActiveTween and State.TweenTarget then
        local targetDist = (State.TweenTarget.Position - pos.Position).Magnitude
        if targetDist <= 25 then
            State.TweenTarget = pos
            return
        end
    end

    State.TweenTarget = pos

    local tweenSpeed = tonumber(_G.Settings.Setting["Player Tween Speed"]) or 325
    if tweenSpeed > 350 then tweenSpeed = 350 end

    if State.ActiveTween and typeof(State.ActiveTween) == "table" and State.ActiveTween.Stop then
        State.ActiveTween:Stop()
    end

    local tweenHandle = {}
    State.ActiveTween = tweenHandle
    State.TweenGen = (State.TweenGen or 0) + 1
    local myGen = State.TweenGen

    task.spawn(function()
        local currentChar = GetChar()
        local currentHrp = GetHRP()

        if not currentChar or not currentHrp then
            if State.TweenGen == myGen then
                State.ActiveTween = nil
                State.TweenTarget = nil
            end
            return
        end

        if currentChar ~= char then
            if State.TweenGen == myGen then
                State.ActiveTween = nil
                State.TweenTarget = nil
            end
            return
        end

        local existingRoot = currentChar:FindFirstChild("Root")
        if existingRoot then
            existingRoot:Destroy()
        end

        local rootPart = Instance.new("Part")
        rootPart.Size = Vector3.new(1, 0.5, 1)
        rootPart.Name = "Root"
        rootPart.Anchored = true
        rootPart.Transparency = 1
        rootPart.CanCollide = false
        rootPart.CFrame = currentHrp.CFrame
        rootPart.Parent = currentChar

        local checkpointDistance = 2000
        local reachedFinal = false

        while not reachedFinal and not State.StopTween and State.TweenGen == myGen do
            local currentPos = rootPart.Position
            local direction = (originalTarget.Position - currentPos).Unit
            local remaining = (originalTarget.Position - currentPos).Magnitude

            if remaining <= checkpointDistance then
                pos = originalTarget
                reachedFinal = true
            else
                local checkpointPos = currentPos + (direction * checkpointDistance)
                checkpointPos = Vector3.new(checkpointPos.X, travelY, checkpointPos.Z)
                pos = CFrame.new(checkpointPos, checkpointPos + originalTarget.LookVector)
            end

            -- FIXED: use rootPart position, not stale HRP
            local distanceToPos = (rootPart.Position - pos.Position).Magnitude
            local duration = distanceToPos / tweenSpeed

            local tween = TweenSvc:Create(
                rootPart,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                { CFrame = pos }
            )

            local conn
            local syncCount = 0
            local retargeted = false

            -- 10 updates/sec
            local syncInterval = 0.10
            local lastSync = 0

            tween:Play()

            conn = RunSvc.Heartbeat:Connect(function()

                if State.StopTween or State.TweenGen ~= myGen then
                    conn:Disconnect()
                    tween:Cancel()

                    if rootPart.Parent then
                        rootPart:Destroy()
                    end

                    if State.TweenGen == myGen then
                        State.ActiveTween = nil
                        State.TweenTarget = nil
                    end
                    return
                end

                local hrpNow = GetHRP()

                if not hrpNow or not rootPart.Parent then
                    conn:Disconnect()

                    if rootPart.Parent then
                        rootPart:Destroy()
                    end

                    if State.TweenGen == myGen then
                        State.ActiveTween = nil
                        State.TweenTarget = nil
                    end
                    return
                end

                ------------------------------------------------
                -- ALWAYS RUN RETARGET LOGIC (NOT THROTTLED)
                ------------------------------------------------
                if State.TweenTarget then
                    local drift = (State.TweenTarget.Position - pos.Position).Magnitude

                    if drift > 30 and not retargeted then
                        retargeted = true
                        originalTarget = State.TweenTarget

                        conn:Disconnect()
                        tween:Cancel()
                        return
                    end
                end

                ------------------------------------------------
                -- ONLY THROTTLE HRP SYNC
                ------------------------------------------------
                local now = tick()
                if now - lastSync >= syncInterval then
                    lastSync = now

                    local gap = (rootPart.Position - hrpNow.Position).Magnitude

                    if gap >= 2 then
                        local oldVel = hrpNow.AssemblyLinearVelocity

                        hrpNow.CFrame = rootPart.CFrame

                        pcall(function()
                            hrpNow.AssemblyLinearVelocity = oldVel
                        end)

                        syncCount += 1
                    end
                end
            end)

            tween.Completed:Wait()

            if conn then
                conn:Disconnect()
            end

            if State.StopTween or State.TweenGen ~= myGen then
                if rootPart.Parent then
                    rootPart:Destroy()
                end

                if State.TweenGen == myGen then
                    State.ActiveTween = nil
                    State.TweenTarget = nil
                end
                return
            end

            if retargeted then
                reachedFinal = false
            else
                -- final sync so checkpoint doesn't lag behind
                local hrpNow = GetHRP()
                if hrpNow and rootPart.Parent then
                    hrpNow.CFrame = rootPart.CFrame
                end

                if not reachedFinal then
                    task.wait(1.5)
                end
            end
        end

        if State.TweenGen ~= myGen then
            if rootPart.Parent then
                rootPart:Destroy()
            end
            return
        end

        local finalHrp = GetHRP()
        if finalHrp and rootPart.Parent then
            finalHrp.CFrame = rootPart.CFrame
        end

        if rootPart.Parent then
            rootPart:Destroy()
        end

        if State.TweenGen == myGen then
            State.ActiveTween = nil
            State.TweenTarget = nil
        end
    end)
end

-- Safety-net sync loop: if a Root part exists without an active Heartbeat connection,
-- sync HRP to Root every frame. Primary syncing is now handled inside TweenPlayer().
RunSvc.Heartbeat:Connect(function()
    pcall(function()
        local char = GetChar()
        if not char then return end
        local root = char:FindFirstChild("Root")
        if not root then return end
        local hrp = GetHRP()
        if not hrp then return end
        local gap = (root.Position - hrp.Position).Magnitude
        if gap >= 1 then
            hrp.CFrame = root.CFrame
            SendDebug("TweenSync", "synced hrp->root gap=" .. string.format("%.1f", gap), nil, 10)
        end
    end)
end)

local function Hop()
    local module = (loadstring(game:HttpGet("https://raw.githubusercontent.com/raw-scriptpastebin/FE/main/Server_Hop_Settings")))()
    module:Teleport(game.PlaceId)
end

local function GetDistance(target)
    return math.floor((target.Position - GetHRP().Position).Magnitude)
end

local function TweenBoat(pos)
    local boatKey = _G.Settings.SeaEvent["Selected Boat"]
    if not boatKey then
        return { Stop = function() end }
    end
    local Boat = workspace.Boats and workspace.Boats[boatKey]
    if not Boat or not Boat:FindFirstChild("VehicleSeat") then
        return { Stop = function() end }
    end

    local targetCFrame = pos
    if typeof(pos) == "Instance" and pos:IsA("BasePart") then
        targetCFrame = pos.CFrame
    elseif typeof(pos) ~= "CFrame" then
        return { Stop = function() end }
    end

    local seat = Boat.VehicleSeat
    local startPos = seat.Position
    local endPos = targetCFrame.Position
    local distance = (startPos - endPos).Magnitude

    if distance <= 25 then
        return { Stop = function() end }
    end

    local speed = tonumber(_G.Settings.SeaEvent["Boat Tween Speed"]) or 100
    if speed <= 0 then speed = 100 end
    local duration = math.clamp(distance / speed, 0.5, 60)

    local tween = TweenSvc:Create(seat, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), { CFrame = targetCFrame })

    State.ActiveTween = tween

    pcall(function() tween:Play() end)

    local StopTweenBoat = {}
    function StopTweenBoat:Stop()
        pcall(function()
            if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
                tween:Cancel()
            end
        end)
        if State.ActiveTween == tween then
            State.ActiveTween = nil
        end
    end
    return StopTweenBoat
end

function CheckBoat()
    for i, v in pairs(workspace.Boats:GetChildren()) do
        if v.Name == _G.Settings.SeaEvent["Selected Boat"] then
            for _, child in pairs(v:GetChildren()) do
                if child.Name == "MyBoatEsp" then
                    return v;
                end
            end
        end
    end
    return false;
end

function CheckEnemiesBoat()
    if workspace.Enemies:FindFirstChild("FishBoat") or
        workspace.Enemies:FindFirstChild("PirateBrigade") or
        workspace.Enemies:FindFirstChild("PirateGrandBrigade") then
        return true;
    end
    return false;
end

function CheckShark()
    for i, v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == "Shark" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and
            v.Humanoid.Health > 0 then
            if workspace.Enemies:FindFirstChild("Shark") then
                if (v.HumanoidRootPart.Position - LP.Character.HumanoidRootPart.Position).Magnitude <=
                    200 then
                    return true;
                end
            end
        end
    end
    return false;
end

function CheckPiranha()
    for i, v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == "Piranha" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and
            v.Humanoid.Health > 0 then
            if workspace.Enemies:FindFirstChild("Piranha") then
                if (v.HumanoidRootPart.Position - LP.Character.HumanoidRootPart.Position).Magnitude <=
                    200 then
                    return true;
                end
            end
        end
    end
    return false;
end

function CheckSeaBeast()
    if workspace:FindFirstChild("SeaBeasts") then
        for i, v in pairs(workspace.SeaBeasts:GetChildren()) do
            if v:FindFirstChild("Humanoid") or v:FindFirstChild("HumanoidRootPart") or v.Humanoid.Health < 0 then
                return true;
            end
        end
    end
    return false;
end

function AddEsp(Name, Parent)
    if Parent:FindFirstChild(Name) then return end -- defensive guard: prevents duplicate BillboardGui stacking if a caller forgets to check first
    local BillboardGui = Instance.new("BillboardGui");
    local TextLabel = Instance.new("TextLabel");
    BillboardGui.Parent = Parent;
    BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    BillboardGui.Active = true;
    BillboardGui.Name = Name;
    BillboardGui.AlwaysOnTop = true;
    BillboardGui.LightInfluence = 1;
    BillboardGui.Size = UDim2.new(0, 200, 0, 50);
    BillboardGui.StudsOffset = Vector3.new(0, 2.5, 0);
    TextLabel.Parent = BillboardGui;
    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
    TextLabel.BackgroundTransparency = 1;
    TextLabel.Size = UDim2.new(1, 0, 1, 0);
    TextLabel.Font = Enum.Font.GothamBold;
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
    TextLabel.TextSize = 15;
    TextLabel.Text = "";
end

local CFrameSelectedZone;
task.spawn(function()
    pcall(function()
        while task.wait(0.2) do
            if _G.Settings.SeaEvent["Selected Zone"] == "Zone 1" then
                CFrameSelectedZone = CFrame.new(-21998.375, 30.0006084, -682.309143, 0.120013528, 0.00690158736,
                    0.99274826, -0.0574118942, 0.998350561, -0.000000000236509201, -0.991110802, -0.0569955558,
                    0.120211802);
            elseif _G.Settings.SeaEvent["Selected Zone"] == "Zone 2" then
                CFrameSelectedZone = CFrame.new(-26779.5215, 30.0005474, -822.858032, 0.307457417, 0.019647358,
                    0.951358974, -0.0637726262, 0.997964442, -0.000000000415334017, -0.949422479, -0.0606706589,
                    0.308084518);
            elseif _G.Settings.SeaEvent["Selected Zone"] == "Zone 3" then
                CFrameSelectedZone = CFrame.new(-31171.957, 30.0001011, -2256.93774, 0.37637493, 0.0150483791,
                    0.926345229, -0.0399504974, 0.999201655, 0.0000000000270896673, -0.925605655, -0.0370079502,
                    0.376675636);
            elseif _G.Settings.SeaEvent["Selected Zone"] == "Zone 4" then
                CFrameSelectedZone = CFrame.new(-34054.6875, 30.2187767, -2560.12012, 0.0935864747, -0.00122954219,
                    0.995610416, 0.0624034069, 0.998040259, -0.00463332096, -0.993653536, 0.062563099, 0.0934797972);
            elseif _G.Settings.SeaEvent["Selected Zone"] == "Zone 5" then
                CFrameSelectedZone = CFrame.new(-38887.5547, 30.0004578, -2162.99023, -0.188895494, -0.00704088295,
                    0.981971979, -0.0372481011, 0.999306023, -0.00000000139882339, -0.981290519, -0.0365765914,
                    -0.189026669);
            elseif _G.Settings.SeaEvent["Selected Zone"] == "Zone 6" then
                CFrameSelectedZone = CFrame.new(-44541.7617, 30.0003204, -1244.8584, -0.0844199061, -0.00553312758,
                    0.9964149, -0.0654025897, 0.997858942, 0.000000000202319411, -0.99428153, -0.0651681125,
                    -0.0846010372);
            elseif _G.Settings.SeaEvent["Selected Zone"] == "Infinite" then
                CFrameSelectedZone = CFrame.new(-148073.359, 8.99999523, 7721.05078, -0.0825930536, -0.00000154416148,
                    0.996583343, -0.000018696026, 1, -0.000000000000391858095, -0.996583343, -0.0000186321486,
                    -0.0825930536);
            end
        end
    end);
end);

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if _G.Settings.SeaEvent["Sail Boat"] then
                if not CheckBoat() then
                    local BuyBoatCFrame = CFrame.new(-16927.451171875, 9.0863618850708, 433.8642883300781);
                    if (BuyBoatCFrame.Position - LP.Character.HumanoidRootPart.Position).Magnitude >
                        2000 then
                        BTP(BuyBoatCFrame);
                    else
                        TweenPlayer(BuyBoatCFrame);
                    end
                    if (CFrame.new(-16927.451171875, 9.0863618850708, 433.8642883300781).Position -
                        LP.Character.HumanoidRootPart.Position).Magnitude <= 10 then
                        State.StopTween = true;
                        State.MoveActive = false;
                        CommF_:InvokeServer("BuyBoat", _G.Settings
                            .SeaEvent["Selected Boat"]);
                        for i, v in pairs(workspace.Boats:GetChildren()) do
                            if v.Name == _G.Settings.SeaEvent["Selected Boat"] then
                                if (v.VehicleSeat.CFrame.Position -
                                    LP.Character.HumanoidRootPart.Position).Magnitude <=
                                    100 then
                                    if not v:FindFirstChild("MyBoatEsp") then
                                        AddEsp("MyBoatEsp", v);
                                    end
                                end
                            end
                        end
                        task.wait(1);
                    end
                elseif CheckBoat() then
                    for i, v in pairs(workspace.Boats:GetChildren()) do
                        if v.Name == _G.Settings.SeaEvent["Selected Boat"] then
                            if v:FindFirstChild("MyBoatEsp") then
                                if GetHumanoid().Sit == false then
                                    if CheckShark() and _G.Settings.SeaEvent["Auto Farm Shark"] or
                                        workspace.Enemies:FindFirstChild("Terrorshark") and
                                        _G.Settings.SeaEvent["Auto Farm Terrorshark"] or CheckPiranha() and
                                        _G.Settings.SeaEvent["Auto Farm Piranha"] or
                                        workspace.Enemies:FindFirstChild("Fish Crew Member") and
                                        _G.Settings.SeaEvent["Auto Farm Fish Crew Member"] or
                                        workspace.Enemies:FindFirstChild("FishBoat") and
                                        _G.Settings.SeaEvent["Auto Farm Ghost Ship"] or
                                        workspace.Enemies:FindFirstChild("PirateBrigade") and
                                        _G.Settings.SeaEvent["Auto Farm Pirate Brigade"] or
                                        workspace.Enemies:FindFirstChild("PirateGrandBrigade") and
                                        _G.Settings.SeaEvent["Auto Farm Pirate Grand Brigade"] or CheckSeaBeast() and
                                        _G.Settings.SeaEvent["Auto Farm Seabeasts"] then
                                        State.StopTween = true;
                                        State.MoveActive = false;
                                    else
                                        TweenPlayer(v.VehicleSeat.CFrame * CFrame.new(0, 1, 0));
                                    end
                                else
                                    repeat
                                        task.wait();
                                        StopTweenBoat = TweenBoat(CFrameSelectedZone);
                                    until CheckShark() and _G.Settings.SeaEvent["Auto Farm Shark"] or
                                        workspace.Enemies:FindFirstChild("Terrorshark") and
                                        _G.Settings.SeaEvent["Auto Farm Terrorshark"] or CheckPiranha() and
                                        _G.Settings.SeaEvent["Auto Farm Piranha"] or
                                        workspace.Enemies:FindFirstChild("Fish Crew Member") and
                                        _G.Settings.SeaEvent["Auto Farm Fish Crew Member"] or
                                        workspace.Enemies:FindFirstChild("FishBoat") and
                                        _G.Settings.SeaEvent["Auto Farm Ghost Ship"] or
                                        workspace.Enemies:FindFirstChild("PirateBrigade") and
                                        _G.Settings.SeaEvent["Auto Farm Pirate Brigade"] or
                                        workspace.Enemies:FindFirstChild("PirateGrandBrigade") and
                                        _G.Settings.SeaEvent["Auto Farm Pirate Grand Brigade"] or CheckSeaBeast() and
                                        _G.Settings.SeaEvent["Auto Farm Seabeasts"] or
                                        GetHumanoid().Sit == false or
                                        _G.Settings.SeaEvent["Sail Boat"] == false;
                                    if StopTweenBoat then
                                        StopTweenBoat:Stop();
                                    end
                                    local VIM = game:GetService("VirtualInputManager")
                                    VIM:SendKeyEvent(true, 32, false, game);
                                    task.wait(0.1);
                                    VIM:SendKeyEvent(false, 32, false, game);
                                end
                            end
                        end
                    end
                end
            end
        end);
    end
end);

task.spawn(function()
    pcall(function()
        while task.wait(0.2) do
            if _G.Settings.SeaEvent["Sail Boat"] then
                if CheckShark() and _G.Settings.SeaEvent["Auto Farm Shark"] or
                    workspace.Enemies:FindFirstChild("Terrorshark") and
                    _G.Settings.SeaEvent["Auto Farm Terrorshark"] or CheckPiranha() and
                    _G.Settings.SeaEvent["Auto Farm Piranha"] or
                    workspace.Enemies:FindFirstChild("Fish Crew Member") and
                    _G.Settings.SeaEvent["Auto Farm Fish Crew Member"] or
                    workspace.Enemies:FindFirstChild("FishBoat") and
                    _G.Settings.SeaEvent["Auto Farm Ghost Ship"] or
                    workspace.Enemies:FindFirstChild("PirateBrigade") and
                    _G.Settings.SeaEvent["Auto Farm Pirate Brigade"] or
                    workspace.Enemies:FindFirstChild("PirateGrandBrigade") and
                    _G.Settings.SeaEvent["Auto Farm Pirate Grand Brigade"] or CheckSeaBeast() and
                    _G.Settings.SeaEvent["Auto Farm Seabeasts"] then
                    if GetHumanoid().Sit == true then
                        local VIM = game:GetService("VirtualInputManager")
                        VIM:SendKeyEvent(true, 32, false, game);
                        task.wait(0.1);
                        VIM:SendKeyEvent(false, 32, false, game);
                    end
                end
            end
        end
    end);
end);

function DodgeSeabeasts()
    local seaBeastsFolder = workspace.SeaBeasts;
    for _, seaBeast in pairs(seaBeastsFolder:GetChildren()) do
        if seaBeast:FindFirstChild("Humanoid") and seaBeast:FindFirstChild("Anims") then
            local humanoid = seaBeast.Humanoid;
            local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid;
            for _, anim in pairs(seaBeast.Anims:GetChildren()) do
                if anim:IsA("Animation") then
                    if anim.AnimationId == "rbxassetid://8708221792" or anim.AnimationId == "rbxassetid://8708222556" or
                        anim.AnimationId == "rbxassetid://8708223619" or anim.AnimationId == "rbxassetid://8708225668" then
                        for _, animationTrack in pairs(animator:GetPlayingAnimationTracks()) do
                            if animationTrack.Animation.AnimationId == anim.AnimationId then
                                if animationTrack.IsPlaying then
                                    return true;
                                else
                                    return false;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.SeaEvent["Sail Boat"] then
            pcall(function()
                if _G.Settings.SeaEvent["Sail Boat"] and
                    workspace.Enemies:FindFirstChild("Fish Crew Member") and
                    _G.Settings.SeaEvent["Auto Farm Fish Crew Member"] then
                    for i, v in pairs(workspace.Enemies:GetChildren()) do
                        if workspace.Enemies:FindFirstChild("Fish Crew Member") then
                            if v.Name == "Fish Crew Member" then
                                if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and
                                    v.Humanoid.Health > 0 then
                                    repeat
                                        RunSvc.Heartbeat:Wait();
                                        AutoHaki();
                                        EquipWeapon(_G.Settings.Main["Selected Weapon"]);
                                        TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos);
                                        Attack();
                                        State.SeaSkill = false;
                                    until not _G.Settings.SeaEvent["Auto Farm Fish Crew Member"] or (not v.Parent) or
                                        v.Humanoid.Health <= 0;
                                end
                            end
                        end
                    end
                elseif _G.Settings.SeaEvent["Sail Boat"] and
                    workspace.Enemies:FindFirstChild("FishBoat") and
                    _G.Settings.SeaEvent["Auto Farm Ghost Ship"] then
                    for i, v in pairs(workspace.Enemies:GetChildren()) do
                        if workspace.Enemies:FindFirstChild("FishBoat") then
                            repeat
                                RunSvc.Heartbeat:Wait();
                                local BoatCFrame = v.Engine.CFrame;
                                if (BoatCFrame.Position - LP.Character.HumanoidRootPart.Position).Magnitude <=
                                    50 then
                                    State.SeaSkill = true;
                                else
                                    State.SeaSkill = false;
                                end
                                TweenPlayer(BoatCFrame);
                                AutoHaki();
                                State.Skillaimbot = true;
                                local AimSkill = v.Engine.CFrame * CFrame.new(0, (-15), 0);
                                State.AimBotSkillPosition = AimSkill.Position;
                            until not v.Parent or v.Health < 0 or
                                (not workspace.Enemies:FindFirstChild("FishBoat")) or
                                (not v:FindFirstChild("Engine")) or (not _G.Settings.SeaEvent["Auto Farm Ghost Ship"]);
                            State.Skillaimbot = false;
                            State.SeaSkill = false;
                        end
                    end
                elseif _G.Settings.SeaEvent["Sail Boat"] and
                    workspace.Enemies:FindFirstChild("PirateGrandBrigade") and
                    _G.Settings.SeaEvent["Auto Farm Pirate Grand Brigade"] then
                    for i, v in pairs(workspace.Enemies:GetChildren()) do
                        if workspace.Enemies:FindFirstChild("PirateGrandBrigade") then
                            repeat
                                RunSvc.Heartbeat:Wait();
                                local BoatCFrame = v.Engine.CFrame;
                                AutoHaki();
                                if (BoatCFrame.Position - LP.Character.HumanoidRootPart.Position).Magnitude <=
                                    50 then
                                    State.SeaSkill = true;
                                else
                                    State.SeaSkill = false;
                                end
                                TweenPlayer(BoatCFrame);
                                State.Skillaimbot = true;
                                local AimSkill = v.Engine.CFrame * CFrame.new(0, (-15), 0);
                                State.AimBotSkillPosition = AimSkill.Position;
                            until not v.Parent or v.Health.Value < 0 or
                                (not workspace.Enemies:FindFirstChild("PirateGrandBrigade")) or
                                (not v:FindFirstChild("Engine")) or
                                (not _G.Settings.SeaEvent["Auto Farm Pirate Grand Brigade"]);
                            State.Skillaimbot = false;
                            State.SeaSkill = false;
                        end
                    end
                elseif _G.Settings.SeaEvent["Sail Boat"] and
                    workspace.Enemies:FindFirstChild("PirateBrigade") and
                    _G.Settings.SeaEvent["Auto Farm Pirate Brigade"] then
                    for i, v in pairs(workspace.Enemies:GetChildren()) do
                        if workspace.Enemies:FindFirstChild("PirateBrigade") then
                            repeat
                                RunSvc.Heartbeat:Wait();
                                local BoatCFrame = v.Engine.CFrame;
                                if (BoatCFrame.Position - LP.Character.HumanoidRootPart.Position).Magnitude <=
                                    50 then
                                    State.SeaSkill = true;
                                else
                                    State.SeaSkill = false;
                                end
                                TweenPlayer(BoatCFrame);
                                State.Skillaimbot = true;
                                AutoHaki();
                                local AimSkill = v.Engine.CFrame * CFrame.new(0, (-15), 0);
                                State.AimBotSkillPosition = AimSkill.Position;
                            until not v.Parent or v.Health.Value < 0 or
                                (not workspace.Enemies:FindFirstChild("PirateBrigade")) or
                                (not v:FindFirstChild("Engine")) or
                                (not _G.Settings.SeaEvent["Auto Farm Pirate Brigade"]);
                            State.Skillaimbot = false;
                            State.SeaSkill = false;
                        end
                    end
                elseif _G.Settings.SeaEvent["Sail Boat"] and CheckSeaBeast() and
                    _G.Settings.SeaEvent["Auto Farm Seabeasts"] then
                    if workspace:FindFirstChild("SeaBeasts") then
                        for i, v in pairs(workspace.SeaBeasts:GetChildren()) do
                            if CheckSeaBeast() then
                                repeat
                                    RunSvc.Heartbeat:Wait();
                                    local CFrameSeaBeast = v.HumanoidRootPart.CFrame * CFrame.new(0, 400, 0);
                                    if (CFrameSeaBeast.Position -
                                        LP.Character.HumanoidRootPart.CFrame.Position).Magnitude <=
                                        400 then
                                        State.SeaSkill = true;
                                    else
                                        State.SeaSkill = false;
                                    end
                                    AutoHaki();
                                    State.Skillaimbot = true;
                                    State.AimBotSkillPosition = v.HumanoidRootPart.CFrame.Position;
                                    if DodgeSeabeasts() then
                                        TweenPlayer(v.HumanoidRootPart.CFrame *
                                                        CFrame.new(math.random((-200), 300), 400,
                                                math.random((-200), 300)));
                                    else
                                        TweenPlayer(v.HumanoidRootPart.CFrame * CFrame.new(0, 400, 0));
                                    end
                                until not _G.Settings.SeaEvent["Auto Farm Seabeasts"] or CheckSeaBeast() == false or
                                    (not v:FindFirstChild("Humanoid")) or (not v:FindFirstChild("HumanoidRootPart")) or
                                    v.Humanoid.Health <= 0 or (not v.Parent);
                                State.Skillaimbot = false;
                                State.SeaSkill = false;
                            else
                                State.Skillaimbot = false;
                                State.SeaSkill = false;
                            end
                        end
                    end
                elseif _G.Settings.SeaEvent["Sail Boat"] and
                    workspace.Enemies:FindFirstChild("Terrorshark") and
                    _G.Settings.SeaEvent["Auto Farm Terrorshark"] then
                    for i, v in pairs(workspace.Enemies:GetChildren()) do
                        if workspace.Enemies:FindFirstChild("Terrorshark") then
                            if v.Name == "Terrorshark" then
                                if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and
                                    v.Humanoid.Health > 0 then
                                    repeat
                                        RunSvc.Heartbeat:Wait();
                                        AutoHaki();
                                        EquipWeapon(_G.Settings.Main["Selected Weapon"]);
                                        Attack();
                                        State.SeaSkill = false;
                                        TweenPlayer(v.HumanoidRootPart.CFrame * CFrame.new(0, 50, 0));
                                    until not _G.Settings.SeaEvent["Auto Farm Terrorshark"] or (not v.Parent) or
                                        v.Humanoid.Health <= 0;
                                end
                            end
                        end
                    end
                elseif _G.Settings.SeaEvent["Sail Boat"] and CheckPiranha() and
                    _G.Settings.SeaEvent["Auto Farm Piranha"] then
                    for i, v in pairs(workspace.Enemies:GetChildren()) do
                        if workspace.Enemies:FindFirstChild("Piranha") then
                            if v.Name == "Piranha" then
                                if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and
                                    v.Humanoid.Health > 0 then
                                    repeat
                                        RunSvc.Heartbeat:Wait();
                                        AutoHaki();
                                        EquipWeapon(_G.Settings.Main["Selected Weapon"]);
                                        TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos);
                                        Attack();
                                        State.SeaSkill = false;
                                    until not _G.Settings.SeaEvent["Auto Farm Piranha"] or (not v.Parent) or
                                        v.Humanoid.Health <= 0;
                                end
                            end
                        end
                    end
                elseif _G.Settings.SeaEvent["Sail Boat"] and CheckShark() and _G.Settings.SeaEvent["Auto Farm Shark"] then
                    for i, v in pairs(workspace.Enemies:GetChildren()) do
                        if workspace.Enemies:FindFirstChild("Shark") then
                            if v.Name == "Shark" then
                                if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and
                                    v.Humanoid.Health > 0 then
                                    repeat
                                        RunSvc.Heartbeat:Wait();
                                        AutoHaki();
                                        EquipWeapon(_G.Settings.Main["Selected Weapon"]);
                                        TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos);
                                        Attack();
                                        State.SeaSkill = false;
                                    until not _G.Settings.SeaEvent["Auto Farm Shark"] or (not v.Parent) or
                                        v.Humanoid.Health <= 0;
                                end
                            end
                        end
                    end
                else
                    State.Skillaimbot = false;
                    State.SeaSkill = false;
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"]);
                end
            end);
        end
    end
end);

function useAllSkill()
    local VIM = game:GetService("VirtualInputManager")
    if not DoneSkillFruit then
        for _, v in pairs(LP.Backpack:GetChildren()) do
            if v:IsA("Tool") and v.ToolTip == "Blox Fruit" then
                GetHumanoid():EquipTool(v)
            end
        end
        VIM:SendKeyEvent(true, "Z", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "Z", false, game)
        VIM:SendKeyEvent(true, "X", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "X", false, game)
        VIM:SendKeyEvent(true, "C", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "C", false, game)
        VIM:SendKeyEvent(true, "V", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "V", false, game)
        VIM:SendKeyEvent(true, "F", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "F", false, game)
        DoneSkillFruit = true
    end
    if not DoneSkillMelee then
        for _, v in pairs(LP.Backpack:GetChildren()) do
            if v:IsA("Tool") and v.ToolTip == "Melee" then
                GetHumanoid():EquipTool(v)
            end
        end
        VIM:SendKeyEvent(true, "Z", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "Z", false, game)
        VIM:SendKeyEvent(true, "X", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "X", false, game)
        VIM:SendKeyEvent(true, "C", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "C", false, game)
        VIM:SendKeyEvent(true, "V", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "V", false, game)
        DoneSkillMelee = true
    end
    if not DoneSkillSword then
        for _, v in pairs(LP.Backpack:GetChildren()) do
            if v:IsA("Tool") and v.ToolTip == "Sword" then
                GetHumanoid():EquipTool(v)
            end
        end
        VIM:SendKeyEvent(true, "Z", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "Z", false, game)
        VIM:SendKeyEvent(true, "X", false, game)
        task.wait()
        VIM:SendKeyEvent(false, "X", false, game)
        DoneSkillSword = true
    end
    if not DoneSkillGun then
        for _, v in pairs(LP.Backpack:GetChildren()) do
            if v:IsA("Tool") and v.ToolTip == "Gun" then
                GetHumanoid():EquipTool(v)
            end
        end
        VIM:SendKeyEvent(true, "Z", false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, "Z", false, game)
        VIM:SendKeyEvent(true, "X", false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, "X", false, game)
        DoneSkillGun = true
    end
    DoneSkillGun = false
    DoneSkillSword = false
    DoneSkillFruit = false
    DoneSkillMelee = false
end

DoneSkillGun = false
DoneSkillSword = false
DoneSkillFruit = false
DoneSkillMelee = false

task.spawn(function()
    while task.wait() do
        pcall(function()
            if State.SeaSkill then
                local VIM = game:GetService("VirtualInputManager")
                if _G.Settings.SettingSea["Use Devil Fruit Skill"] and not DoneSkillFruit then
                    for _, v in pairs(LP.Backpack:GetChildren()) do
                        if v:IsA("Tool") and v.ToolTip == "Blox Fruit" then
                            GetHumanoid():EquipTool(v)
                        end
                    end
                    if _G.Settings.SettingSea["Devil Fruit Z Skill"] then
                        VIM:SendKeyEvent(true, "Z", false, game)
                        task.wait()
                        VIM:SendKeyEvent(false, "Z", false, game)
                    end
                    if _G.Settings.SettingSea["Devil Fruit X Skill"] then
                        VIM:SendKeyEvent(true, "X", false, game)
                        task.wait()
                        VIM:SendKeyEvent(false, "X", false, game)
                    end
                    if _G.Settings.SettingSea["Devil Fruit C Skill"] then
                        VIM:SendKeyEvent(true, "C", false, game)
                        task.wait()
                        VIM:SendKeyEvent(false, "C", false, game)
                    end
                    if _G.Settings.SettingSea["Devil Fruit V Skill"] then
                        VIM:SendKeyEvent(true, "V", false, game)
                        task.wait()
                        VIM:SendKeyEvent(false, "V", false, game)
                    end
                    if _G.Settings.SettingSea["Devil Fruit F Skill"] then
                        VIM:SendKeyEvent(true, "F", false, game)
                        task.wait()
                        VIM:SendKeyEvent(false, "F", false, game)
                    end
                    DoneSkillFruit = true
                end
                if _G.Settings.SettingSea["Use Melee Skill"] and not DoneSkillMelee then
                    for _, v in pairs(LP.Backpack:GetChildren()) do
                        if v:IsA("Tool") and v.ToolTip == "Melee" then
                            GetHumanoid():EquipTool(v)
                        end
                    end
                    if _G.Settings.SettingSea["Melee Z Skill"] then
                        VIM:SendKeyEvent(true, "Z", false, game)
                        task.wait()
                        VIM:SendKeyEvent(false, "Z", false, game)
                    end
                    if _G.Settings.SettingSea["Melee X Skill"] then
                        VIM:SendKeyEvent(true, "X", false, game)
                        task.wait()
                        VIM:SendKeyEvent(false, "X", false, game)
                    end
                    if _G.Settings.SettingSea["Melee C Skill"] then
                        VIM:SendKeyEvent(true, "C", false, game)
                        task.wait()
                        VIM:SendKeyEvent(false, "C", false, game)
                    end
                    if _G.Settings.SettingSea["Melee V Skill"] then
                        VIM:SendKeyEvent(true, "V", false, game)
                        task.wait()
                        VIM:SendKeyEvent(false, "V", false, game)
                    end
                    DoneSkillMelee = true
                end
                if _G.Settings.SettingSea["Use Sword Skill"] and not DoneSkillSword then
                    for _, v in pairs(LP.Backpack:GetChildren()) do
                        if v:IsA("Tool") and v.ToolTip == "Sword" then
                            GetHumanoid():EquipTool(v)
                        end
                    end
                    VIM:SendKeyEvent(true, "Z", false, game)
                    task.wait()
                    VIM:SendKeyEvent(false, "Z", false, game)
                    VIM:SendKeyEvent(true, "X", false, game)
                    task.wait()
                    VIM:SendKeyEvent(false, "X", false, game)
                    DoneSkillSword = true
                end
                if _G.Settings.SettingSea["Use Gun Skill"] and not DoneSkillGun then
                    for _, v in pairs(LP.Backpack:GetChildren()) do
                        if v:IsA("Tool") and v.ToolTip == "Gun" then
                            GetHumanoid():EquipTool(v)
                        end
                    end
                    VIM:SendKeyEvent(true, "Z", false, game)
                    task.wait(0.1)
                    VIM:SendKeyEvent(false, "Z", false, game)
                    VIM:SendKeyEvent(true, "X", false, game)
                    task.wait(0.1)
                    VIM:SendKeyEvent(false, "X", false, game)
                    DoneSkillGun = true
                end
                DoneSkillGun = false
                DoneSkillSword = false
                DoneSkillFruit = false
                DoneSkillMelee = false
            end
        end)
    end
end)

local function EquipWeaponSword()
    pcall(function()
        for _, v in pairs(LP.Backpack:GetChildren()) do
            if v.ToolTip == "Sword" and v:IsA("Tool") then
                local tool = LP.Backpack:FindFirstChild(v.Name)
                if tool then GetHumanoid():EquipTool(tool) end
            end
        end
    end)
end

local function getInfoSword(SwordName)
    if LP.Character:FindFirstChild(SwordName) then return true end
    if LP.Backpack:FindFirstChild(SwordName) then return true end
    return false
end

local function CheckItemCount(itemName, itemCount)
    for _, v in next, CommF_:InvokeServer("getInventory") do
        if v.Name == itemName and v.Count >= itemCount then return true end
    end
    return false
end

local function DetectChest()
    local dist = math.huge
    local name
    for _, v in pairs(workspace:GetChildren()) do
        if string.match(v.Name, "Chest") then
            local mag = (v.Position - GetHRP().Position).magnitude
            if mag < dist then dist = mag name = v end
        end
    end
    if not name then
        for _, v in next, workspace.Map:GetDescendants() do
            if v:IsA("Part") and string.find(v.Name, "Chest") then
                local mag = (v.Position - GetHRP().Position).magnitude
                if mag < dist then dist = mag name = v end
            end
        end
    end
    return name
end

local function DetectPartSpawnMob(name)
    local name1
    if string.find(name, "Lv.") then name1 = name:gsub(" %pLv. %d+%p", "") end
    for _, v in pairs(workspace._WorldOrigin.EnemySpawns:GetChildren()) do
        local stringgsub
        if string.find(v.Name, "Lv.") then stringgsub = v.Name:gsub(" %pLv. %d+%p", "") end
        if v:IsA("Part") and (stringgsub and stringgsub == name or name == v.Name or name1 and v.Name == name1) then return v end
    end
    pcall(function()
        for _, v in pairs(getnilinstances()) do
            local stringgsub
            if string.find(v.Name, "Lv.") then stringgsub = v.Name:gsub(" %pLv. %d+%p", "") end
            if v:IsA("Part") and (stringgsub and stringgsub == name or name == v.Name or name1 and v.Name == name1) then return v end
        end
    end)
end

local MobBlacklist = {}

local function TeleportSpawnMob(Path, value)
    if typeof(Path) == "table" then
        if #MobBlacklist >= 4 then MobBlacklist = {} return end
        local GetPart
        for _, v in next, Path do
            if not table.find(MobBlacklist, v) then
                GetPart = DetectPartSpawnMob(v)
                repeat
                    task.wait()
                    TweenPlayer(GetPart.CFrame * CFrame.new(0, 60, 0))
                until (GetPart.Position - GetHRP().Position).Magnitude <= 100 or DetectMob(Path) or (not value)
            end
        end
    else
        GetPart = DetectPartSpawnMob(Path)
        TweenPlayer(GetPart.CFrame * CFrame.new(0, 60, 0))
    end
end

function DetectMob(c)
    local dist = math.huge
    local name
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        local stringgsub = v.Name:gsub(" %pLv. %d+%p", "")
        if (typeof(c) == "table" and (table.find(c, v.Name) or table.find(c, stringgsub)) or (v.Name == c or c == stringgsub)) and v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            local mag = (v.HumanoidRootPart.Position - GetHRP().Position).magnitude
            if mag < dist then dist = mag name = v end
        end
    end
    return name
end

function getConfigMaterial(Material)
    MaterialMon = {}
    MaterialPos = CFrame.new()
    if Material == "Radioactive" and World2 then
        MaterialMon = {"Factory Staff"}
        MaterialPos = CFrame.new(-507.79, 72.99, -126.46)
    elseif Material == "Mystic Droplet" and World2 then
        MaterialMon = {"Water Fighter"}
        MaterialPos = CFrame.new(-3352.90, 285.02, -10534.84)
    elseif Material == "Magma Ore" and World1 then
        MaterialMon = {"Military Spy"}
        MaterialPos = CFrame.new(-5850.28, 77.29, 8848.67)
    elseif Material == "Magma Ore" and World2 then
        MaterialMon = {"Lava Pirate"}
        MaterialPos = CFrame.new(-5234.61, 51.95, -4732.28)
    elseif Material == "Angel Wings" and World1 then
        MaterialMon = {"Royal Soldier"}
        MaterialPos = CFrame.new(-7827.16, 5606.91, -1705.58)
    elseif Material == "Leather" and World1 then
        MaterialMon = {"Pirate"}
        MaterialPos = CFrame.new(-1211.88, 4.79, 3916.83)
    elseif Material == "Leather" and World2 then
        MaterialMon = {"Marine Captain"}
        MaterialPos = CFrame.new(-2010.51, 73.00, -3326.62)
    elseif Material == "Leather" and World3 then
        MaterialMon = {"Jungle Pirate"}
        MaterialPos = CFrame.new(-11975.79, 331.77, -10620.03)
    elseif Material == "Ectoplasm" and World2 then
        MaterialMon = {"Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer"}
        MaterialPos = CFrame.new(911.36, 125.96, 33159.54)
    elseif Material == "Scrap Metal" and World1 then
        MaterialMon = {"Brute"}
        MaterialPos = CFrame.new(-1132.42, 14.84, 4293.31)
    elseif Material == "Scrap Metal" and World2 then
        MaterialMon = {"Mercenary"}
        MaterialPos = CFrame.new(-972.31, 73.04, 1419.29)
    elseif Material == "Scrap Metal" and World3 then
        MaterialMon = {"Pirate Millionaire"}
        MaterialPos = CFrame.new(-289.63, 43.83, 5583.66)
    elseif Material == "Conjured Cocoa" and World3 then
        MaterialMon = {"Chocolate Bar Battler"}
        MaterialPos = CFrame.new(744.79, 24.77, -12637.73)
    elseif Material == "Dragon Scale" and World3 then
        MaterialMon = {"Dragon Crew Warrior"}
        MaterialPos = CFrame.new(5824.07, 51.39, -1106.69)
    elseif Material == "Gunpowder" and World3 then
        MaterialMon = {"Pistol Billionaire"}
        MaterialPos = CFrame.new(-379.61, 73.84, 5928.53)
    elseif Material == "Fish Tail" and World3 then
        MaterialMon = {"Fishman Captain"}
        MaterialPos = CFrame.new(-10961.01, 331.80, -8914.29)
    elseif Material == "Mini Tusk" and World3 then
        MaterialMon = {"Mythological Pirate"}
        MaterialPos = CFrame.new(-13516.05, 469.82, -6899.16)
    end
end

function getPirateRaidEnemies()
    local PirateRaidPos = CFrame.new(-5515.08, 343.11, -3013.25)
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if (PirateRaidPos.Position - v.HumanoidRootPart.Position).Magnitude <= 2000 then return v end
        end
    end
    return false
end

function checkEagleEye()
    local islandModel = workspace.Map.TikiOutpost.IslandModel
    local targetEyes = { Eye1 = false, Eye2 = false, Eye3 = false, Eye4 = false }
    for _, v in ipairs(islandModel:GetChildren()) do
        if string.match(v.Name, "^Eye%d$") and targetEyes[v.Name] ~= nil then
            if tonumber(v.Transparency) == 0 then targetEyes[v.Name] = true end
        end
    end
    for _, found in pairs(targetEyes) do if not found then return false end end
    return true
end

function AttackGucci()
    for _, model in pairs(workspace.Map.TikiOutpost.IslandModel:GetChildren()) do
        if model:FindFirstChild("EagleBossArena") then
            for _, v in pairs(model.EagleBossArena:GetChildren()) do
                if v.Name == "Tree" then TweenPlayer(CFrame.new(v.WorldPivot.Position)) end
            end
        end
    end
end

function DetectRequestSoulGuitar()
    local Mob = {}
    local PlaceId
    local NameRemote
    if not CheckItemCount("Ectoplasm", 250) then
        Mob = {"Ship Deckhand [Lv. 1250]", "Ship Steward [Lv. 1300]", "Ship Officer [Lv. 1325]", "Ship Engineer [Lv. 1275]"}
        PlaceId = 4442272183
        NameRemote = "TravelDressrosa"
    elseif not CheckItemCount("Bones", 500) then
        Mob = {"Reborn Skeleton [Lv. 1975]", "Demonic Soul [Lv. 2025]", "Living Zombie [Lv. 2000]", "Posessed Mummy [Lv. 2050]"}
        PlaceId = 7449423635
        NameRemote = "TravelZou"
    end
    return Mob, PlaceId, NameRemote
end

function GuitarPuzzleProgress()
    if not CommF_:InvokeServer("GuitarPuzzleProgress", "Check") then
        if game.Lighting.Sky.MoonTextureId == "http://www.roblox.com/asset/?id=9709149431" and
            (game.Lighting.ClockTime > 16 or game.Lighting.ClockTime < 5) then
            if LP:DistanceFromCharacter(Vector3.new(-8654.31, 140.95, 6167.53)) > 50 then
                TweenPlayer(CFrame.new(-8654.31, 140.95, 6167.53))
            end
            CommF_:InvokeServer("gravestoneEvent", 2)
            CommF_:InvokeServer("gravestoneEvent", 2, true)
            task.wait(1)
        end
    elseif not CommF_:InvokeServer("GuitarPuzzleProgress", "Check").Swamp then
    elseif not CommF_:InvokeServer("GuitarPuzzleProgress", "Check").Gravestones then
    elseif not CommF_:InvokeServer("GuitarPuzzleProgress", "Check").Ghost then
        CommF_:InvokeServer("GuitarPuzzleProgress", "Ghost")
    elseif not CommF_:InvokeServer("GuitarPuzzleProgress", "Check").Trophies then
    elseif not CommF_:InvokeServer("GuitarPuzzleProgress", "Check").Pipes then
    end
end

local function Click()
    VirtUser:CaptureController()
    VirtUser:Button1Down(Vector2.new(1280, 672))
end

local function GetCountMaterials(name)
    local inv = CommF_:InvokeServer("getInventory")
    for _, v in pairs(inv) do
        if v.Name == name then return v.Count end
    end
    return 0
end

task.spawn(function()
    for _, v in pairs(workspace._WorldOrigin:GetChildren()) do
        pcall(function()
            if v.Name == "CurvedRing" or v.Name == "SlashHit" or v.Name == "SwordSlash"
                or v.Name == "SlashTail" or v.Name == "Sounds" then
                v:Destroy()
            end
        end)
    end
end)

local _lastAttackScan = 0
local _cachedParts = {}
local function Attack()
    pcall(function()
        local tool = GetChar() and GetChar():FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip ~= "Gun" then
            local now = os.clock()
            local parts
            -- FIX: this used to rebuild the full nearby-parts list on every single
            -- Heartbeat tick (up to 60x/sec), iterating every entity within 60 studs
            -- AND every child part of each one. That's the CPU spike during dense
            -- combat right before a kill, when nearby-entity count is highest.
            -- Throttling to ~10x/sec is still far more than the server needs for
            -- hit registration and cuts this scan's cost by ~6x.
            if now - _lastAttackScan >= 0.1 then
                _lastAttackScan = now
                parts = {}
                for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
                    for _, v in ipairs(x and x:GetChildren() or {}) do
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        local hum = v:FindFirstChild("Humanoid")
                        if v ~= GetChar() and hrp and hum and hum.Health > 0 and (hrp.Position - GetHRP().Position).Magnitude <= 60 then
                            for _, _v in ipairs(v:GetChildren()) do
                                if _v:IsA("BasePart") then parts[#parts+1] = {v, _v} end
                            end
                        end
                    end
                end
                _cachedParts = parts
            else
                parts = _cachedParts
            end
            if #parts > 0 then
                local head = parts[1][1]:FindFirstChild("Head")
                if head then
                    pcall(function()
                        require(RepStore.Modules.Net):RemoteEvent("RegisterHit", true)
                        RepStore.Modules.Net["RE/RegisterAttack"]:FireServer()
                        RepStore.Modules.Net["RE/RegisterHit"]:FireServer(head, parts, {})
                    end)
                end
            end
        end
    end)
end

local function InstantTp(cf)
    pcall(function() GetHRP().CFrame = cf end)
end

function AutoSoulGuitar()
    if CommF_:InvokeServer("soulGuitarBuy", true) == "[You already own this item.]" then return end
    if LP.Data.Fragments.Value < 5000 then return end
    if not CheckItemCount("Ectoplasm", 250) then return end
    if CheckItemCount("Dark Fragment", 1) and CheckItemCount("Ectoplasm", 250) and CheckItemCount("Bones", 500) then
        CommF_:InvokeServer("soulGuitarBuy", true)
        CommF_:InvokeServer("soulGuitarBuy")
        if World3 then GuitarPuzzleProgress() else CommF_:InvokeServer("TravelZou") end
        return
    end
    if not CheckItemCount("Dark Fragment", 1) then
        if World2 then
            local darkbeardName = "Darkbeard [Lv. 1000] [Raid Boss]"
            if workspace.Enemies:FindFirstChild(darkbeardName) then
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v.Name == darkbeardName and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                        repeat
                            task.wait()
                            AutoHaki()
                            EquipWeapon(_G.Settings.Main["Selected Weapon"])
                            v.Humanoid.WalkSpeed = 0
                            v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                            TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                        until v.Humanoid.Health <= 0 or (not v.Parent)
                    end
                end
            elseif LP.Character:FindFirstChild("Fist of Darkness") or LP.Backpack:FindFirstChild("Fist of Darkness") then
                local detection = workspace.Map.DarkbeardArena.Summoner.Detection
                if (detection.Position - GetHRP().Position).Magnitude <= 5 then
                    EquipWeapon("Fist of Darkness")
                    firetouchinterest(LP.Character["Fist of Darkness"].Handle, detection, 0)
                    firetouchinterest(LP.Character["Fist of Darkness"].Handle, detection, 1)
                    firetouchinterest(GetHRP(), detection, 0)
                    firetouchinterest(GetHRP(), detection, 1)
                else
                    TweenPlayer(detection.CFrame)
                end
            else
                local v = DetectChest()
                if v then
                    repeat
                        task.wait()
                        if (GetHRP().Position - v.Position).Magnitude <= 2 then
                            firetouchinterest(v, GetHRP(), 0)
                            firetouchinterest(v, GetHRP(), 1)
                        end
                        InstantTp(v.CFrame * CFrame.new(0, 1, 0))
                    until not v or (not v.Parent) or (not _G.Settings.Items["Auto Soul Guitar"])
                end
            end
        else
            CommF_:InvokeServer("TravelDressrosa")
        end
    else
        local Mob, PlaceId, NameRemote = DetectRequestSoulGuitar()
        if game.PlaceId == PlaceId then
            if not DetectMob(Mob) then
                TeleportSpawnMob(Mob, _G.Settings.Items["Auto Soul Guitar"])
            else
                local v = DetectMob(Mob)
                if v then
                    repeat
                        task.wait()
                        EquipWeapon(_G.Settings.Main["Selected Weapon"])
                        AutoHaki()
                        v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                        State.PosMon = v.HumanoidRootPart.CFrame
                        State.MonFarm = v.Name
                        TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                    until not v or (not v.Parent) or v.Humanoid.Health == 0 or (not _G.Settings.Items["Auto Soul Guitar"])
                    State.MonFarm = ""
                    State.PosMon  = CFrame.new()
                end
            end
        else
            CommF_:InvokeServer(NameRemote)
        end
    end
end

local function BTP(cf)
    pcall(function()
        if (cf.Position - GetHRP().Position).Magnitude >= 2000 and GetHumanoid().Health > 0 then
            repeat
                task.wait()
                SetCharacterCFrame(GetChar(), cf)
                CommF_:InvokeServer("SetSpawnPoint")
            until (cf.Position - GetHRP().Position).Magnitude <= 2000
        else
            SetCharacterCFrame(GetChar(), cf)
        end
    end)
end

local function StopTween(state)
    State.StopTween = true
    SendDebug("Tween", "manual stop", nil, 2)

    if State.ActiveTween then
        pcall(function()
            -- Handle both native Tween Instances (boat tweens) and custom tweenHandle tables
            if typeof(State.ActiveTween) == "Instance" and State.ActiveTween.PlaybackState == Enum.PlaybackState.Playing then
                State.ActiveTween:Cancel()
            elseif typeof(State.ActiveTween) == "table" and State.ActiveTween.Stop then
                State.ActiveTween:Stop()
            end
        end)
    end

    -- FIX: Immediately clear mob targeting so Bring Mob stops teleporting enemies
    State.MonFarm = ""
    State.PosMon = CFrame.new()

    -- FIX: Fully clear tween states to prevent the 25-stud lockout bug
    State.ActiveTween = nil
    State.TweenTarget = nil
    State.MoveActive = false

    pcall(function()
        local hrp = GetHRP()
        if hrp and hrp:FindFirstChild("BodyClip") then
            hrp.BodyClip.Velocity = Vector3.new(0, 0, 0)
        end
    end)

    task.wait(0.1)
    State.StopTween = false
end
local remote, idremote
for _, v in next, ({game.ReplicatedStorage.Util, game.ReplicatedStorage.Common, game.ReplicatedStorage.Remotes,
                    game.ReplicatedStorage.Assets, game.ReplicatedStorage.FX}) do
    for _, n in next, v:GetChildren() do
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end
    v.ChildAdded:Connect(function(n)
        if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
            remote, idremote = n, n:GetAttribute("Id")
        end
    end)
end
task.spawn(function()
    while task.wait(0.05) do
        local char = game.Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local parts = {}
        for _, x in ipairs({workspace.Enemies, workspace.Characters}) do
            for _, v in ipairs(x and x:GetChildren() or {}) do
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local hum = v:FindFirstChild("Humanoid")
                if v ~= char and hrp and hum and hum.Health > 0 and (hrp.Position - root.Position).Magnitude <= 60 then
                    for _, _v in ipairs(v:GetChildren()) do
                        if _v:IsA("BasePart") and (hrp.Position - root.Position).Magnitude <= 60 then
                            parts[#parts + 1] = {v, _v}
                        end
                    end
                end
            end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if #parts > 0 and tool and
            (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword") then
            pcall(function()
                require(game.ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                game.ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head = parts[1][1]:FindFirstChild("Head")
                if not head then
                    return
                end
                game.ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(head, parts, {}, tostring(
                    game.Players.LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
                cloneref(remote):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
                    return string.char(
                        bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                end), bit32.bxor(idremote + 909090, game.ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2), head,
                    parts)
            end)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        local mode = _G.Settings.Setting["Fast Attack Mode"]
        if mode == "Slow"       then _G.Settings.Setting["Fast Attack Delay"] = 0.32
        elseif mode == "Normal" then _G.Settings.Setting["Fast Attack Delay"] = 0.22
        elseif mode == "Fast"   then _G.Settings.Setting["Fast Attack Delay"] = 0.17
        elseif mode == "Super Fast" then _G.Settings.Setting["Fast Attack Delay"] = 0.12 end
    end
end)

task.spawn(function()
    while task.wait() do
        local m = _G.Settings.Setting["Bring Mob Mode"]
        if m == "Low"    then State.BringMobDist = 150
        elseif m == "Normal" then State.BringMobDist = 250
        elseif m == "High"   then State.BringMobDist = 800 end
    end
end)

task.spawn(function()
    while task.wait() do
        local isFarming = _G.Settings.Main["Auto Farm"] or _G.Settings.Main["Auto Farm Mon"] or _G.Settings.Main["Auto Farm Boss"]
        if _G.Settings.Setting["Bring Mob"] and isFarming then
            pcall(function()
                if State.MonFarm == "" then return end
                local hrp = GetHRP()
                if not hrp then return end
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v.Name == State.MonFarm and v:FindFirstChild("HumanoidRootPart") then
                        local dist = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if dist <= State.BringMobDist then
                            v.HumanoidRootPart.CFrame = State.PosMon
                            v.HumanoidRootPart.Size   = Vector3.new(1,1,1)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Setting["Auto Haki"] then
            pcall(AutoHaki)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Setting["Auto Observation"] then
            pcall(function()
                if not LP.PlayerGui.ScreenGui:FindFirstChild("ImageLabel") then
                    VirtUser:CaptureController()
                    VirtUser:SetKeyDown("0x65")
                    task.wait()
                    VirtUser:SetKeyUp("0x65")
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if _G.Settings.Setting["Auto Set Spawn Point"] then
            pcall(function() CommF_:InvokeServer("SetSpawnPoint") end)
        end
    end
end)

task.spawn(function()
    game.CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(v)
        if _G.Settings.Setting["Auto Rejoin"] and v.Name == "ErrorPrompt" then
            pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
        end
    end)
end)

local QD = {} 

local function CheckQuest()
    local lv = LP.Data.Level.Value
    local function set(mon, quest, lvQ, nameMon, cfQ, cfM)
        QD.Mon       = mon
        QD.NameQuest = quest
        QD.LevelQuest= lvQ
        QD.NameMon   = nameMon
        QD.CFrameQuest = cfQ
        QD.CFrameMon   = cfM
    end
    local function apply()
        State.Mon        = QD.Mon
        State.NameQuest  = QD.NameQuest
        State.LevelQuest = QD.LevelQuest
        State.NameMon    = QD.NameMon
        State.CFrameQuest= QD.CFrameQuest
        State.CFrameMon  = QD.CFrameMon
    end

    if World1 then
        if     lv <= 9   then set("Bandit","BanditQuest1",1,"Bandit",CFrame.new(1059.37,15.44,1550.42),CFrame.new(1045.96,27.0,1560.82))
        elseif lv <= 14  then set("Monkey","JungleQuest",1,"Monkey",CFrame.new(-1598.08,35.55,153.37),CFrame.new(-1448.51,67.85,11.46))
        elseif lv <= 29  then set("Gorilla","JungleQuest",2,"Gorilla",CFrame.new(-1598.08,35.55,153.37),CFrame.new(-1129.88,40.46,-525.42))
        elseif lv <= 39  then set("Pirate","BuggyQuest1",1,"Pirate",CFrame.new(-1141.07,4.1,3831.54),CFrame.new(-1103.51,13.75,3896.09))
        elseif lv <= 59  then set("Brute","BuggyQuest1",2,"Brute",CFrame.new(-1141.07,4.1,3831.54),CFrame.new(-1140.08,14.8,4322.92))
        elseif lv <= 74  then set("Desert Bandit","DesertQuest",1,"Desert Bandit",CFrame.new(894.48,5.14,4392.43),CFrame.new(924.79,6.44,4481.58))
        elseif lv <= 89  then set("Desert Officer","DesertQuest",2,"Desert Officer",CFrame.new(894.48,5.14,4392.43),CFrame.new(1608.28,8.61,4371.0))
        elseif lv <= 99  then set("Snow Bandit","SnowQuest",1,"Snow Bandit",CFrame.new(1389.74,88.15,-1298.90),CFrame.new(1354.34,87.27,-1393.94))
        elseif lv <= 119 then set("Snowman","SnowQuest",2,"Snowman",CFrame.new(1389.74,88.15,-1298.90),CFrame.new(1201.64,144.57,-1550.06))
        elseif lv <= 149 then set("Chief Petty Officer","MarineQuest2",1,"Chief Petty Officer",CFrame.new(-5039.58,27.35,4324.68),CFrame.new(-4881.23,22.65,4273.75))
        elseif lv <= 174 then set("Sky Bandit","SkyQuest",1,"Sky Bandit",CFrame.new(-4839.53,716.36,-2619.44),CFrame.new(-4953.20,295.74,-2899.22))
        elseif lv <= 189 then set("Dark Master","SkyQuest",2,"Dark Master",CFrame.new(-4839.53,716.36,-2619.44),CFrame.new(-5259.84,391.39,-2229.03))
        elseif lv <= 209 then set("Prisoner","PrisonerQuest",1,"Prisoner",CFrame.new(5308.93,1.65,475.12),CFrame.new(5098.97,-0.32,474.23))
        elseif lv <= 249 then set("Dangerous Prisoner","PrisonerQuest",2,"Dangerous Prisoner",CFrame.new(5308.93,1.65,475.12),CFrame.new(5654.56,15.63,866.29))
        elseif lv <= 274 then set("Toga Warrior","ColosseumQuest",1,"Toga Warrior",CFrame.new(-1580.04,6.35,-2986.47),CFrame.new(-1820.21,51.68,-2740.66))
        elseif lv <= 299 then set("Gladiator","ColosseumQuest",2,"Gladiator",CFrame.new(-1580.04,6.35,-2986.47),CFrame.new(-1292.83,56.38,-3339.03))
        elseif lv <= 324 then set("Military Soldier","MagmaQuest",1,"Military Soldier",CFrame.new(-5313.37,10.95,8515.29),CFrame.new(-5411.16,11.08,8454.29))
        elseif lv <= 374 then set("Military Spy","MagmaQuest",2,"Military Spy",CFrame.new(-5313.37,10.95,8515.29),CFrame.new(-5802.86,86.26,8828.85))
        elseif lv <= 399 then
            set("Fishman Warrior","FishmanQuest",1,"Fishman Warrior",CFrame.new(61122.65,18.49,1569.39),CFrame.new(60878.30,18.48,1543.75))
            if _G.Settings.Main["Auto Farm"] and (State.CFrameQuest.Position - GetHRP().Position).Magnitude > 10000 then
                pcall(function() CommF_:InvokeServer("requestEntrance",Vector3.new(61163.85,11.67,1819.78)) end)
            end
        elseif lv <= 449 then
            set("Fishman Commando","FishmanQuest",2,"Fishman Commando",CFrame.new(61122.65,18.49,1569.39),CFrame.new(61922.63,18.48,1493.93))
            if _G.Settings.Main["Auto Farm"] and (State.CFrameQuest.Position - GetHRP().Position).Magnitude > 10000 then
                pcall(function() CommF_:InvokeServer("requestEntrance",Vector3.new(61163.85,11.67,1819.78)) end)
            end
        elseif lv <= 474 then
            set("God's Guard","SkyExp1Quest",1,"God's Guard",CFrame.new(-4721.88,843.87,-1949.96),CFrame.new(-4710.04,845.27,-1927.30))
            if _G.Settings.Main["Auto Farm"] and (State.CFrameQuest.Position - GetHRP().Position).Magnitude > 10000 then
                pcall(function() CommF_:InvokeServer("requestEntrance",Vector3.new(-4607.82,872.54,-1667.55)) end)
            end
        elseif lv <= 524 then
            set("Shanda","SkyExp1Quest",2,"Shanda",CFrame.new(-7859.09,5544.19,-381.47),CFrame.new(-7678.48,5566.40,-497.21))
            if _G.Settings.Main["Auto Farm"] and (State.CFrameQuest.Position - GetHRP().Position).Magnitude > 10000 then
                pcall(function() CommF_:InvokeServer("requestEntrance",Vector3.new(-7894.61,5547.14,-380.29)) end)
            end
        elseif lv <= 549 then set("Royal Squad","SkyExp2Quest",1,"Royal Squad",CFrame.new(-7906.81,5634.66,-1411.99),CFrame.new(-7624.25,5658.13,-1467.35))
        elseif lv <= 624 then set("Royal Soldier","SkyExp2Quest",2,"Royal Soldier",CFrame.new(-7906.81,5634.66,-1411.99),CFrame.new(-7836.75,5645.66,-1790.62))
        elseif lv <= 649 then set("Galley Pirate","FountainQuest",1,"Galley Pirate",CFrame.new(5259.81,37.35,4050.02),CFrame.new(5551.02,78.90,3930.41))
        else                   set("Galley Captain","FountainQuest",2,"Galley Captain",CFrame.new(5259.81,37.35,4050.02),CFrame.new(5441.95,42.50,4950.09))
        end
    elseif World2 then
        if     lv <= 724  then set("Raider","Area1Quest",1,"Raider",CFrame.new(-429.54,71.76,1836.18),CFrame.new(-728.32,52.77,2345.77))
        elseif lv <= 774  then set("Mercenary","Area1Quest",2,"Mercenary",CFrame.new(-429.54,71.76,1836.18),CFrame.new(-1004.32,80.15,1424.61))
        elseif lv <= 799  then set("Swan Pirate","Area2Quest",1,"Swan Pirate",CFrame.new(638.43,71.76,918.28),CFrame.new(1068.66,137.61,1322.10))
        elseif lv <= 874  then set("Factory Staff","Area2Quest",2,"Factory Staff",CFrame.new(632.69,73.10,918.66),CFrame.new(73.07,81.86,-27.47))
        elseif lv <= 899  then set("Marine Lieutenant","MarineQuest3",1,"Marine Lieutenant",CFrame.new(-2440.79,71.71,-3216.06),CFrame.new(-2821.37,75.89,-3070.08))
        elseif lv <= 949  then set("Marine Captain","MarineQuest3",2,"Marine Captain",CFrame.new(-2440.79,71.71,-3216.06),CFrame.new(-1861.23,80.17,-3254.69))
        elseif lv <= 974  then set("Zombie","ZombieQuest",1,"Zombie",CFrame.new(-5497.06,47.59,-795.23),CFrame.new(-5657.77,78.96,-928.68))
        elseif lv <= 999  then set("Vampire","ZombieQuest",2,"Vampire",CFrame.new(-5497.06,47.59,-795.23),CFrame.new(-6037.66,32.18,-1340.65))
        elseif lv <= 1049 then set("Snow Trooper","SnowMountainQuest",1,"Snow Trooper",CFrame.new(609.85,400.11,-5372.25),CFrame.new(549.14,427.38,-5563.69))
        elseif lv <= 1099 then set("Winter Warrior","SnowMountainQuest",2,"Winter Warrior",CFrame.new(609.85,400.11,-5372.25),CFrame.new(1142.74,475.63,-5199.41))
        elseif lv <= 1124 then set("Lab Subordinate","IceSideQuest",1,"Lab Subordinate",CFrame.new(-6064.06,15.24,-4902.97),CFrame.new(-5707.47,15.95,-4513.39))
        elseif lv <= 1174 then set("Horned Warrior","IceSideQuest",2,"Horned Warrior",CFrame.new(-6064.06,15.24,-4902.97),CFrame.new(-6341.36,15.95,-5723.16))
        elseif lv <= 1199 then set("Magma Ninja","FireSideQuest",1,"Magma Ninja",CFrame.new(-5428.03,15.06,-5299.43),CFrame.new(-5449.67,76.65,-5808.20))
        elseif lv <= 1249 then set("Lava Pirate","FireSideQuest",2,"Lava Pirate",CFrame.new(-5428.03,15.06,-5299.43),CFrame.new(-5213.33,49.73,-4701.45))
        elseif lv <= 1274 then
            set("Ship Deckhand","ShipQuest1",1,"Ship Deckhand",CFrame.new(1037.80,125.09,32911.60),CFrame.new(1212.01,150.79,33059.24))
            if _G.Settings.Main["Auto Farm"] and (State.CFrameQuest.Position - GetHRP().Position).Magnitude > 10000 then
                pcall(function() CommF_:InvokeServer("requestEntrance",Vector3.new(923.21,126.97,32852.83)) end)
            end
        elseif lv <= 1299 then
            set("Ship Engineer","ShipQuest1",2,"Ship Engineer",CFrame.new(1037.80,125.09,32911.60),CFrame.new(919.47,43.54,32779.96))
            if _G.Settings.Main["Auto Farm"] and (State.CFrameQuest.Position - GetHRP().Position).Magnitude > 10000 then
                pcall(function() CommF_:InvokeServer("requestEntrance",Vector3.new(923.21,126.97,32852.83)) end)
            end
        elseif lv <= 1374 then set("Arctic Warrior","FrostQuest",1,"Arctic Warrior",CFrame.new(5667.65,26.79,-6486.08),CFrame.new(5966.24,62.97,-6179.38))
        elseif lv <= 1424 then set("Snow Lurker","FrostQuest",2,"Snow Lurker",CFrame.new(5667.65,26.79,-6486.08),CFrame.new(5407.07,69.19,-6880.88))
        elseif lv <= 1449 then set("Sea Soldier","ForgottenQuest",1,"Sea Soldier",CFrame.new(-3054.44,235.54,-10142.81),CFrame.new(-3028.22,64.67,-9775.42))
        else                   set("Water Fighter","ForgottenQuest",2,"Water Fighter",CFrame.new(-3054.44,235.54,-10142.81),CFrame.new(-3352.90,285.01,-10534.84))
        end
    elseif World3 then
        if     lv <= 1524 then set("Pirate Millionaire","PiratePortQuest",1,"Pirate Millionaire",CFrame.new(-290.07,42.90,5581.58),CFrame.new(-245.99,47.30,5584.10))
        elseif lv <= 1574 then set("Pistol Billionaire","PiratePortQuest",2,"Pistol Billionaire",CFrame.new(-290.07,42.90,5581.58),CFrame.new(-187.33,86.23,6013.51))
        elseif lv <= 1599 then set("Dragon Crew Warrior","DragonCrewQuest",1,"Dragon Crew Warrior",CFrame.new(6735.99, 127.41, -712.60),CFrame.new(7077.69,55.75,-638.56))
        elseif lv <= 1624 then set("Dragon Crew Archer","DragonCrewQuest",2,"Dragon Crew Archer",CFrame.new(6735.99, 127.41, -712.60),CFrame.new(6753.46, 484.40, 395.71))
        elseif lv <= 1649 then set("Female Islander","AmazonQuest2",1,"Female Islander",CFrame.new(5446.87,601.62,749.45),CFrame.new(4685.25,735.80,815.34))
        elseif lv <= 1699 then set("Giant Islander","AmazonQuest2",2,"Giant Islander",CFrame.new(5446.87,601.62,749.45),CFrame.new(4729.09,590.43,-36.97))
        elseif lv <= 1724 then set("Marine Commodore","MarineTreeIsland",1,"Marine Commodore",CFrame.new(2180.54,27.81,-6741.54),CFrame.new(2286.00,73.13,-7159.80))
        elseif lv <= 1774 then set("Marine Rear Admiral","MarineTreeIsland",2,"Marine Rear Admiral",CFrame.new(2179.98,28.73,-6740.05),CFrame.new(3656.77,160.52,-7001.59))
        elseif lv <= 1799 then set("Fishman Raider","DeepForestIsland3",1,"Fishman Raider",CFrame.new(-10581.65,330.87,-8761.18),CFrame.new(-10407.52,331.76,-8368.51))
        elseif lv <= 1824 then set("Fishman Captain","DeepForestIsland3",2,"Fishman Captain",CFrame.new(-10581.65,330.87,-8761.18),CFrame.new(-10994.70,352.38,-9002.11))
        elseif lv <= 1849 then set("Forest Pirate","DeepForestIsland",1,"Forest Pirate",CFrame.new(-13234.04,331.48,-7625.40),CFrame.new(-13274.47,332.37,-7769.58))
        elseif lv <= 1899 then set("Mythological Pirate","DeepForestIsland",2,"Mythological Pirate",CFrame.new(-13234.04,331.48,-7625.40),CFrame.new(-13680.60,501.08,-6991.18))
        elseif lv <= 1924 then set("Jungle Pirate","DeepForestIsland2",1,"Jungle Pirate",CFrame.new(-12680.38,389.97,-9902.01),CFrame.new(-12256.16,331.73,-10485.83))
        elseif lv <= 1974 then set("Musketeer Pirate","DeepForestIsland2",2,"Musketeer Pirate",CFrame.new(-12680.38,389.97,-9902.01),CFrame.new(-13457.90,391.54,-9859.17))
        elseif lv <= 1999 then set("Reborn Skeleton","HauntedQuest1",1,"Reborn Skeleton",CFrame.new(-9479.21,141.21,5566.09),CFrame.new(-8763.72,165.72,6159.86))
        elseif lv <= 2024 then set("Living Zombie","HauntedQuest1",2,"Living Zombie",CFrame.new(-9479.21,141.21,5566.09),CFrame.new(-10144.13,138.62,5838.08))
        elseif lv <= 2049 then set("Demonic Soul","HauntedQuest2",1,"Demonic Soul",CFrame.new(-9516.99,172.01,6078.46),CFrame.new(-9505.87,172.10,6158.99))
        elseif lv <= 2074 then set("Posessed Mummy","HauntedQuest2",2,"Posessed Mummy",CFrame.new(-9516.99,172.01,6078.46),CFrame.new(-9582.02,6.25,6205.47))
        elseif lv <= 2099 then set("Peanut Scout","NutsIslandQuest",1,"Peanut Scout",CFrame.new(-2104.39,38.10,-10194.21),CFrame.new(-2143.24,47.72,-10029.99))
        elseif lv <= 2124 then set("Peanut President","NutsIslandQuest",2,"Peanut President",CFrame.new(-2104.39,38.10,-10194.21),CFrame.new(-1859.35,38.10,-10422.42))
        elseif lv <= 2149 then set("Ice Cream Chef","IceCreamIslandQuest",1,"Ice Cream Chef",CFrame.new(-820.64,65.81,-10965.79),CFrame.new(-872.24,65.81,-10919.95))
        elseif lv <= 2199 then set("Ice Cream Commander","IceCreamIslandQuest",2,"Ice Cream Commander",CFrame.new(-820.64,65.81,-10965.79),CFrame.new(-558.06,112.04,-11290.77))
        elseif lv <= 2224 then set("Cookie Crafter","CakeQuest1",1,"Cookie Crafter",CFrame.new(-2021.32,37.79,-12028.72),CFrame.new(-2374.13,37.79,-12125.30))
        elseif lv <= 2249 then set("Cake Guard","CakeQuest1",2,"Cake Guard",CFrame.new(-2021.32,37.79,-12028.72),CFrame.new(-1598.30,43.77,-12244.58))
        elseif lv <= 2274 then set("Baking Staff","CakeQuest2",1,"Baking Staff",CFrame.new(-1927.91,37.79,-12842.53),CFrame.new(-1887.80,77.61,-12998.35))
        elseif lv <= 2299 then set("Head Baker","CakeQuest2",2,"Head Baker",CFrame.new(-1927.91,37.79,-12842.53),CFrame.new(-2216.18,82.88,-12869.29))
        elseif lv <= 2324 then set("Cocoa Warrior","ChocQuest1",1,"Cocoa Warrior",CFrame.new(233.22,29.87,-12201.23),CFrame.new(-21.55,80.57,-12352.38))
        elseif lv <= 2349 then set("Chocolate Bar Battler","ChocQuest1",2,"Chocolate Bar Battler",CFrame.new(233.22,29.87,-12201.23),CFrame.new(582.59,77.18,-12463.16))
        elseif lv <= 2374 then set("Sweet Thief","ChocQuest2",1,"Sweet Thief",CFrame.new(150.50,30.69,-12774.50),CFrame.new(165.18,76.05,-12600.83))
        elseif lv <= 2399 then set("Candy Rebel","ChocQuest2",2,"Candy Rebel",CFrame.new(150.50,30.69,-12774.50),CFrame.new(134.86,77.24,-12876.54))
        elseif lv <= 2424 then set("Candy Pirate","CandyQuest1",1,"Candy Pirate",CFrame.new(-1150.04,20.37,-14446.33),CFrame.new(-1310.50,26.01,-14562.40))
        elseif lv <= 2449 then set("Snow Demon","CandyQuest1",2,"Snow Demon",CFrame.new(-1150.04,20.37,-14446.33),CFrame.new(-880.20,71.24,-14538.60))
        elseif lv <= 2474 then set("Isle Outlaw","TikiQuest1",1,"Isle Outlaw",CFrame.new(-16547.74,61.13,-173.41),CFrame.new(-16442.81,116.13,-264.46))
        elseif lv <= 2524 then set("Island Boy","TikiQuest1",2,"Island Boy",CFrame.new(-16547.74,61.13,-173.41),CFrame.new(-16901.26,84.06,-192.88))
        elseif lv <= 2549 then set("Isle Champion","TikiQuest2",2,"Isle Champion",CFrame.new(-16539.07,55.68,1051.57),CFrame.new(-16641.67,235.78,1031.28))
        elseif lv <= 2574 then set("Serpent Hunter","TikiQuest3",1,"Serpent Hunter",CFrame.new(-16661.89,105.28,1576.69),CFrame.new(-16587.89,154.21,1533.40))
        else                   set("Skull Slayer","TikiQuest3",2,"Skull Slayer",CFrame.new(-16661.89,105.28,1576.69),CFrame.new(-16885.20,114.12,1627.94))
        end
    end
    apply()
end

local bossTables = {
    World1 = {"The Gorilla King","Bobby","Yeti","Mob Leader","Vice Admiral","Warden","Chief Warden","Swan",
               "Magma Admiral","Fishman Lord","Wysper","Thunder God","Cyborg","Saber Expert"},
    World2 = {"Diamond","Jeremy","Fajita","Don Swan","Smoke Admiral","Cursed Captain","Darkbeard","Order",
               "Awakened Ice Admiral","Tide Keeper"},
    World3 = {"Stone","Island Empress","Kilo Admiral","Captain Elephant","Beautiful Pirate",
               "rip_indra True Form","Longma","Soul Reaper","Cake Queen"},
}
local tableBoss = World1 and bossTables.World1 or World2 and bossTables.World2 or bossTables.World3

local monTables = {
    World1 = {"Bandit","Monkey","Gorilla","Pirate","Brute","Desert Bandit","Desert Officer","Snow Bandit",
               "Snowman","Chief Petty Officer","Sky Bandit","Dark Master","Toga Warrior","Gladiator",
               "Military Soldier","Military Spy","Fishman Warrior","Fishman Commando","God's Guard","Shanda",
               "Royal Squad","Royal Soldier","Galley Pirate","Galley Captain"},
    World2 = {"Raider","Mercenary","Swan Pirate","Factory Staff","Marine Lieutenant","Marine Captain","Zombie",
               "Vampire","Snow Trooper","Winter Warrior","Lab Subordinate","Horned Warrior","Magma Ninja",
               "Lava Pirate","Ship Deckhand","Ship Engineer","Ship Steward","Ship Officer","Arctic Warrior",
               "Snow Lurker","Sea Soldier","Water Fighter"},
    World3 = {"Pirate Millionaire","Dragon Crew Warrior","Dragon Crew Archer","Female Islander","Giant Islander",
               "Marine Commodore","Marine Rear Admiral","Fishman Raider","Fishman Captain","Forest Pirate",
               "Mythological Pirate","Jungle Pirate","Musketeer Pirate","Reborn Skeleton","Living Zombie",
               "Demonic Soul","Posessed Mummy","Peanut Scout","Peanut President","Ice Cream Chef",
               "Ice Cream Commander","Cookie Crafter","Cake Guard","Baking Staff","Head Baker","Cocoa Warrior",
               "Chocolate Bar Battler","Sweet Thief","Candy Rebel","Candy Pirate","Snow Demon","Isle Outlaw",
               "Island Boy","Sun-kissed Warrior","Isle Champion"},
}
local tableMon = World1 and monTables.World1 or World2 and monTables.World2 or monTables.World3

local function FarmMob(v, toggleKey, extraCondition)
    if not v or not v.Parent then
        SendDebug("FarmMob", "enemy missing parent", { toggle = toggleKey }, 5)
        return
    end
    if not v:FindFirstChild("Humanoid") or not v:FindFirstChild("HumanoidRootPart") then
        SendDebug("FarmMob", "enemy missing humanoid or hrp", { enemy = v.Name, toggle = toggleKey }, 5)
        return
    end
    if v.Humanoid.Health <= 0 then
        SendDebug("FarmMob", "enemy already dead", { enemy = v.Name, toggle = toggleKey }, 5)
        return
    end
    State.PosMon  = v.HumanoidRootPart.CFrame
    State.MonFarm = v.Name
    SendDebug("FarmMob", "engage enemy", {
        enemy = v.Name,
        toggle = toggleKey,
        health = string.format("%.1f", v.Humanoid.Health),
        enemyPos = v.HumanoidRootPart.CFrame,
    }, 3)
    local masteryHpPct = _G.Settings.Setting["Mastery Health"] or 25
    repeat
        RunSvc.Heartbeat:Wait()
        EquipWeapon(_G.Settings.Main["Selected Weapon"])
        AutoHaki()
        if not v.Parent or not v:FindFirstChild("Humanoid") or not v:FindFirstChild("HumanoidRootPart") then
            SendDebug("FarmMob", "enemy disappeared during engage", { enemy = State.MonFarm, toggle = toggleKey }, 3)
            break
        end
        local hpBelowThreshold = v.Humanoid.Health <= v.Humanoid.MaxHealth * masteryHpPct / 100
        if _G.Settings.Main["Auto Farm Fruit Mastery"] then
            State.UseSkill = hpBelowThreshold
        elseif _G.Settings.Main["Auto Farm Gun Mastery"] then
            State.UseGunSkill = hpBelowThreshold
        end
        v.Humanoid.WalkSpeed = 0
        v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
        State.PosMon = v.HumanoidRootPart.CFrame -- keep live so Bring Mob never anchors to a stale snapshot
        TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
    until (not (_G.Settings.Main[toggleKey] or _G.Settings.Farm[toggleKey]))
        or (not v.Parent)
        or v.Humanoid.Health <= 0
        or (extraCondition and extraCondition())
    State.UseSkill = false
    State.UseGunSkill = false
    SendDebug("FarmMob", "leave enemy", {
        enemy = State.MonFarm,
        toggle = toggleKey,
        alive = v.Parent and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0,
    }, 5)
    State.MonFarm = ""
    State.PosMon  = CFrame.new()
end

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if _G.Settings.Main["Auto Fast Farm"] and World1 then
                if LP.Data.Level.Value >= 10 then
                    _G.Settings.Main["Auto Farm"] = false
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Main["Farm Level Method"] == "No Quest" and _G.Settings.Main["Auto Farm"] then
            pcall(function()
                CheckQuest()
                SendDebug("AutoFarm", "no quest method selected target", {
                    enemy = State.Mon,
                    spawn = State.CFrameMon,
                }, 8)
                local mon = State.Mon
                local foundEnemy = false
                if workspace.Enemies:FindFirstChild(mon) then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == mon then
                            foundEnemy = true
                            FarmMob(v, "Auto Farm", function()
                                return not LP.PlayerGui.Main.Quest.Visible
                            end)
                        end
                    end
                end
                if not foundEnemy then
                    SendDebug("AutoFarm", "no quest enemy missing moving to spawn", {
                        enemy = mon,
                        spawn = State.CFrameMon,
                    }, 5)
                    TweenPlayer(State.CFrameMon)
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Main["Farm Level Method"] == "Nearest" and _G.Settings.Main["Auto Farm"] then
            pcall(function()
                local hrp = GetHRP()
                if not hrp then
                    SendDebug("AutoFarm", "nearest missing hrp", nil, 5)
                    return
                end
                local foundEnemy = false
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                        if (hrp.Position - v.HumanoidRootPart.Position).Magnitude <= 5000 then
                            foundEnemy = true
                            SendDebug("AutoFarm", "nearest enemy found", {
                                enemy = v.Name,
                                distance = string.format("%.1f", (hrp.Position - v.HumanoidRootPart.Position).Magnitude),
                            }, 3)
                            FarmMob(v, "Auto Farm")
                        end
                    end
                end
                if not foundEnemy then
                    SendDebug("AutoFarm", "nearest found no enemies within range", nil, 5)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Main["Farm Level Method"] == "Quest" and _G.Settings.Main["Auto Farm"] then
            pcall(function()
                CheckQuest()
                local QuestUI    = LP.PlayerGui.Main.Quest
                local questTitle = QuestUI.Container.QuestTitle.Title.Text
                SendDebug("AutoFarm", "quest method state", {
                    questVisible = QuestUI.Visible,
                    questTitle = questTitle,
                    targetEnemy = State.Mon,
                    questPos = State.CFrameQuest,
                    enemySpawn = State.CFrameMon,
                }, 8)
                if not string.find(questTitle, State.NameMon) then
                    SendDebug("AutoFarm", "wrong quest abandoning", {
                        questTitle = questTitle,
                        expected = State.NameMon,
                    }, 5)
                    CommF_:InvokeServer("AbandonQuest")
                end
                if not QuestUI.Visible then
                    SendDebug("AutoFarm", "moving to quest npc", {
                        quest = State.NameQuest,
                        levelQuest = State.LevelQuest,
                        questPos = State.CFrameQuest,
                    }, 5)
                    TweenPlayer(State.CFrameQuest)
                    if GetHRP() and (State.CFrameQuest.Position - GetHRP().Position).Magnitude <= 5 then
                        SendDebug("AutoFarm", "starting quest", {
                            quest = State.NameQuest,
                            levelQuest = State.LevelQuest,
                        }, 3)
                        CommF_:InvokeServer("StartQuest", State.NameQuest, State.LevelQuest)
                    end
                else
                    local foundEnemy = false
                    if workspace.Enemies:FindFirstChild(State.Mon) then
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if v.Name == State.Mon
                                and string.find(QuestUI.Container.QuestTitle.Title.Text, State.NameMon) then
                                foundEnemy = true
                                SendDebug("AutoFarm", "quest enemy found", {
                                    enemy = v.Name,
                                    enemyPos = v:FindFirstChild("HumanoidRootPart") and v.HumanoidRootPart.CFrame or "no-hrp",
                                }, 3)
                                FarmMob(v, "Auto Farm", function()
                                    return not QuestUI.Visible
                                end)
                            end
                        end
                    end
                    if not foundEnemy then
                        SendDebug("AutoFarm", "quest enemy missing moving to spawn", {
                            enemy = State.Mon,
                            enemySpawn = State.CFrameMon,
                        }, 5)
                        TweenPlayer(State.CFrameMon)
                        UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Main["Auto Farm Mon"] then
            pcall(function()
                local sel = _G.Settings.Main["Selected Mon"]
                if not sel then
                    SendDebug("AutoFarmMon", "no selected monster", nil, 5)
                    return
                end
                local foundEnemy = false
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v.Name == sel then
                        foundEnemy = true
                        FarmMob(v, "Auto Farm Mon")
                    end
                end
                if not foundEnemy then
                    SendDebug("AutoFarmMon", "selected monster not found", { enemy = sel }, 5)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Main["Auto Farm Boss"] then
            pcall(function()
                local sel = _G.Settings.Main["Selected Boss"]
                if not sel then
                    SendDebug("AutoFarmBoss", "no selected boss", nil, 5)
                    return
                end
                if workspace.Enemies:FindFirstChild(sel) then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == sel then
                            SendDebug("AutoFarmBoss", "boss found in enemies", { boss = sel }, 5)
                            FarmMob(v, "Auto Farm Boss")
                        end
                    end
                elseif RepStore:FindFirstChild(sel) then
                    local rf = RepStore:FindFirstChild(sel)
                    if rf and rf:FindFirstChild("HumanoidRootPart") then
                        SendDebug("AutoFarmBoss", "boss in replicated storage moving to spawn", {
                            boss = sel,
                            bossPos = rf.HumanoidRootPart.CFrame,
                        }, 5)
                        TweenPlayer(rf.HumanoidRootPart.CFrame * CFrame.new(5, 10, 2))
                    end
                else
                    SendDebug("AutoFarmBoss", "selected boss not found", { boss = sel }, 8)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Main["Auto Farm All Boss"] then
            pcall(function()
                for _, bossName in pairs(tableBoss) do
                    if workspace.Enemies:FindFirstChild(bossName) then
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if v.Name == bossName then FarmMob(v, "Auto Farm All Boss") end
                        end
                    elseif RepStore:FindFirstChild(bossName) then
                        local rf = RepStore:FindFirstChild(bossName)
                        if rf and rf:FindFirstChild("HumanoidRootPart") then
                            TweenPlayer(rf.HumanoidRootPart.CFrame * CFrame.new(5, 10, 2))
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if not _G.Settings.Main["Auto Farm Sword Mastery"] then continue end
        local method = _G.Settings.Main["Mastery Method"]
        pcall(function()
            local sword = _G.Settings.Main["Selected Mastery Sword"]
            if not sword then return end
            if not LP.Backpack:FindFirstChild(sword) and not LP.Character:FindFirstChild(sword) then
                CommF_:InvokeServer("LoadItem", sword)
            end

            local function engageSword(v)
                if not v or not v.Parent then return end
                if v.Humanoid.Health <= 0 then return end
                repeat
                    RunSvc.Heartbeat:Wait()
                    EquipWeapon(sword)
                    AutoHaki()
                    v.Humanoid.WalkSpeed = 0
                    v.HumanoidRootPart.Size = Vector3.new(1,1,1)
                    TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                until not _G.Settings.Main["Auto Farm Sword Mastery"]
                    or not v.Parent or v.Humanoid.Health <= 0
                State.MonFarm = ""
                State.PosMon  = CFrame.new()
            end

            if method == "Quest" then
                CheckQuest()
                local QUI = LP.PlayerGui.Main.Quest
                if not string.find(QUI.Container.QuestTitle.Title.Text, State.NameMon) then
                    CommF_:InvokeServer("AbandonQuest")
                    TweenPlayer(State.CFrameQuest)
                    if (State.CFrameQuest.Position - GetHRP().Position).Magnitude <= 5 then
                        CommF_:InvokeServer("StartQuest", State.NameQuest, State.LevelQuest)
                    end
                elseif QUI.Visible then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == State.Mon then engageSword(v) end
                    end
                end
            elseif method == "No Quest" then
                CheckQuest()
                TweenPlayer(State.CFrameMon)
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v.Name == State.Mon then engageSword(v) end
                end
            elseif method == "Nearest" then
                local hrp = GetHRP()
                if not hrp then return end
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart")
                        and v.Humanoid.Health > 0
                        and (hrp.Position - v.HumanoidRootPart.Position).Magnitude <= 2000 then
                        engageSword(v)
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if State.UseSkill then
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v.Name == State.MonFarm
                        and v:FindFirstChild("Humanoid")
                        and v:FindFirstChild("HumanoidRootPart")
                        and v.Humanoid.Health <= v.Humanoid.MaxHealth * _G.Settings.Setting["Mastery Health"] / 100
                    then
                        if _G.Settings.Setting["Fruit Mastery Skill Z"] then
                            game:GetService("VirtualInputManager"):SendKeyEvent(true, "Z", false, game)
                            game:GetService("VirtualInputManager"):SendKeyEvent(false, "Z", false, game)
                        end
                        if _G.Settings.Setting["Fruit Mastery Skill X"] then
                            game:GetService("VirtualInputManager"):SendKeyEvent(true, "X", false, game)
                            game:GetService("VirtualInputManager"):SendKeyEvent(false, "X", false, game)
                        end
                        if _G.Settings.Setting["Fruit Mastery Skill C"] then
                            game:GetService("VirtualInputManager"):SendKeyEvent(true, "C", false, game)
                            game:GetService("VirtualInputManager"):SendKeyEvent(false, "C", false, game)
                        end
                        if _G.Settings.Setting["Fruit Mastery Skill V"] then
                            game:GetService("VirtualInputManager"):SendKeyEvent(true, "V", false, game)
                            game:GetService("VirtualInputManager"):SendKeyEvent(false, "V", false, game)
                        end
                        if _G.Settings.Setting["Fruit Mastery Skill F"] then
                            game:GetService("VirtualInputManager"):SendKeyEvent(true, "F", false, game)
                            game:GetService("VirtualInputManager"):SendKeyEvent(false, "F", false, game)
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if State.UseGunSkill then
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v.Name == State.MonFarm
                        and v:FindFirstChild("Humanoid")
                        and v:FindFirstChild("HumanoidRootPart")
                        and v.Humanoid.Health <= v.Humanoid.MaxHealth * _G.Settings.Setting["Mastery Health"] / 100
                    then
                        if _G.Settings.Setting["Gun Mastery Skill Z"] then
                            game:GetService("VirtualInputManager"):SendKeyEvent(true, "Z", false, game)
                            task.wait(0.5)
                            game:GetService("VirtualInputManager"):SendKeyEvent(false, "Z", false, game)
                        end
                        if _G.Settings.Setting["Gun Mastery Skill X"] then
                            game:GetService("VirtualInputManager"):SendKeyEvent(true, "X", false, game)
                            task.wait(0.5)
                            game:GetService("VirtualInputManager"):SendKeyEvent(false, "X", false, game)
                        end
                    end
                end
            end
        end)
    end
end)

local Window = Library:CreateWindow({
    Title    = "Actrium Hub",
    SubTitle = "v" .. Config.Version,
    Size     = UDim2.fromOffset(500, 300),
    TabWidth = 140,
    Theme    = "Default_AH",
})

local Tabs = {
    Farming     = Window:AddTab({ Title = "Farming",       Icon = "lucide-snowflake" }),
    Bosses      = Window:AddTab({ Title = "Bosses",        Icon = "skull"            }),
    Quests      = Window:AddTab({ Title = "Quests",        Icon = "file-question"    }),
    Raids       = Window:AddTab({ Title = "Raids",         Icon = "swords"           }),
    Teleports   = Window:AddTab({ Title = "Teleports",     Icon = "map-pin"          }),
    V4          = Window:AddTab({ Title = "V4 and Trials", Icon = "lucide-trophy"   }),
    ShopEvent   = Window:AddTab({ Title = "Sea Event",     Icon = "waves"            }),
    SeaSettings = Window:AddTab({ Title = "Sea Settings",  Icon = "cog"              }),
    DragonDojo  = Window:AddTab({ Title = "Dragon Dojo",   Icon = "shield"           }),
    ESPTab      = Window:AddTab({ Title = "ESP",           Icon = "eye"              }),
    Status      = Window:AddTab({ Title = "Status",        Icon = "info"             }),
    Player      = Window:AddTab({ Title = "Player",        Icon = "user"             }),
    PvP         = Window:AddTab({ Title = "PvP",           Icon = "crosshair"        }),
    Misc        = Window:AddTab({ Title = "Shop",          Icon = "shopping-bag"     }),
    Social      = Window:AddTab({ Title = "Social",        Icon = "users"            }),
    Display     = Window:AddTab({ Title = "Display",       Icon = "monitor"          }),
    Performance = Window:AddTab({ Title = "Performance",   Icon = "gauge"            }),
    Settings    = Window:AddTab({ Title = "Settings",      Icon = "settings"         }),
    ServerTab   = Window:AddTab({ Title = "Server",         Icon = "server"          }),
}

local UI = {}

-- Live spawn status previously lived in a separate MiniWindow; folded into
-- the Status tab below instead of running a second window.
do
    local qs2 = Tabs.Status:AddSection("Live Spawn Status")
    UI.MiniMoon     = qs2:AddParagraph({ Title = "Moon",       Content = "N/A" })
    UI.MiniKitsune  = qs2:AddParagraph({ Title = "Kitsune",    Content = "N/A" })
    UI.MiniFrozen   = qs2:AddParagraph({ Title = "Frozen",     Content = "N/A" })
    UI.MiniMirage   = qs2:AddParagraph({ Title = "Mirage",     Content = "N/A" })
    UI.MiniDough    = qs2:AddParagraph({ Title = "Dough King", Content = "N/A" })
    UI.MiniIndra    = qs2:AddParagraph({ Title = "Indra",      Content = "N/A" })
    UI.MiniFruit    = qs2:AddParagraph({ Title = "Fruit Spawn", Content = "N/A" })
    UI.MiniHaki     = qs2:AddParagraph({ Title = "Haki Dealer", Content = "N/A" })
    UI.MiniSeaBeast = qs2:AddParagraph({ Title = "Sea Beast",  Content = "N/A" })

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                local moonId = game:GetService("Lighting").Sky.MoonTextureId
                local moonPct = moonId:find("9709149431") and "100%"
                    or moonId:find("9709149052") and "75%"
                    or moonId:find("9709143733") and "50%"
                    or moonId:find("9709150401") and "25%"
                    or moonId:find("9709149680") and "15%"
                    or "0%"
                UI.MiniMoon:SetDesc("Full Moon " .. moonPct)
                local locs = workspace._WorldOrigin.Locations
                UI.MiniKitsune:SetDesc(locs:FindFirstChild("Kitsune Island") and " Spawning" or " Not Spawn")
                UI.MiniFrozen:SetDesc(locs:FindFirstChild("Frozen Dimension") and " Spawning" or " Not Spawn")
                UI.MiniMirage:SetDesc(locs:FindFirstChild("Mirage Island") and " Spawning" or " Not Spawn")
                UI.MiniDough:SetDesc(workspace.Enemies:FindFirstChild("Dough King") and " Spawned" or " Not Spawn")
                UI.MiniIndra:SetDesc(workspace.Enemies:FindFirstChild("rip_indra True Form") and "Spawned" or " Not Spawn")
                local fruitFound = false
                for _, v in pairs(workspace:GetChildren()) do
                    if v:IsA("Tool") and v.Name:find("Fruit") then fruitFound = true break end
                end
                UI.MiniFruit:SetDesc(fruitFound and " Fruit Spawned" or " None")
                local hd = CommF_:InvokeServer("ColorsDealer","1")
                UI.MiniHaki:SetDesc(hd and " Spawning" or " Not Spawn")
                local sb = workspace:FindFirstChild("SeaBeasts")
                local sbCount = sb and #sb:GetChildren() or 0
                UI.MiniSeaBeast:SetDesc(sbCount > 0 and " "..sbCount.." alive" or " None")
            end)
        end
    end)
end

do
    local Farming = Tabs.Farming
    Farming:AddSection("Level Farm")
    UI.ChooseWeapon = Farming:AddDropdown("ChooseWeapon", {
        Title    = "Choose Weapon",
        Values   = {"Melee","Sword","Fruit"},
        Default  = "Melee",
        Callback = function(v) _G.Settings.Main["Select Weapon"] = v end,
    })

    UI.LevelFarmMethod = Farming:AddDropdown("LevelFarmMethod", {
        Title    = "Farm Level Method",
        Values   = {"Quest","No Quest","Nearest"},
        Default  = "Quest",
        Callback = function(v) _G.Settings.Main["Farm Level Method"] = v end,
    })

    UI.AutoFarmLevel = Farming:AddToggle("AutoFarmLevel", {
        Title       = "Auto Farm Level",
        Description = "Automatic level grinding",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Main["Auto Farm"] = s
            StopTween(s)
        end,
    })

    UI.AutoFastFarm = Farming:AddToggle("AutoFastFarm", {
        Title       = "Auto Fast Farm",
        Description = "Fast level farm [Sea 1 Only]",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Main["Auto Fast Farm"] = s
            StopTween(s)
        end,
    })

    Farming:AddSection("Mastery Farm")
    UI.MasteryMethod = Farming:AddDropdown("MasteryMethod", {
        Title    = "Mastery Method",
        Values   = World3 and {"Quest","No Quest","Nearest","Cakeprince","Bones"} or {"Quest","No Quest","Nearest"},
        Default  = "Quest",
        Callback = function(v) _G.Settings.Main["Mastery Method"] = v end,
    })

    UI.AutoFruitMastery = Farming:AddToggle("AutoFruitMastery", {
        Title    = "Auto Fruit Mastery",
        Default  = false,
        Callback = function(s)
            _G.Settings.Main["Auto Farm Fruit Mastery"] = s
            StopTween(s)
        end,
    })

    UI.AutoGunMastery = Farming:AddToggle("AutoGunMastery", {
        Title    = "Auto Gun Mastery",
        Default  = false,
        Callback = function(s)
            _G.Settings.Main["Auto Farm Gun Mastery"] = s
            StopTween(s)
        end,
    })

    local swordList = {}
    pcall(function()
        local inv = CommF_:InvokeServer("getInventory")
        for _, item in pairs(inv) do
            if item.Type == "Sword" then table.insert(swordList, item.Name) end
        end
    end)

    UI.ChooseSword = Farming:AddDropdown("ChooseSword", {
        Title     = "Choose Sword (Mastery)",
        Values    = swordList,
        AllowNull = true,
        Callback  = function(v) _G.Settings.Main["Selected Mastery Sword"] = v end,
    })

    UI.AutoSwordMastery = Farming:AddToggle("AutoSwordMastery", {
        Title    = "Auto Sword Mastery",
        Default  = false,
        Callback = function(s)
            _G.Settings.Main["Auto Farm Sword Mastery"] = s
            StopTween(s)
        end,
    })

    Farming:AddSection("Monster Farm")

    UI.ChooseMon = Farming:AddDropdown("ChooseMon", {
        Title     = "Choose Monster",
        Values    = tableMon,
        AllowNull = true,
        Callback  = function(v) _G.Settings.Main["Selected Mon"] = v end,
    })

    UI.AutoMonFarm = Farming:AddToggle("AutoMonFarm", {
        Title       = "Auto Farm Monster",
        Description = "Kill selected monster when it spawns",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Main["Auto Farm Mon"] = s
            StopTween(s)
        end,
    })

    Farming:AddSection("Elite Hunter  [Sea 3 Only]")

    UI.EliteStatus   = Farming:AddParagraph({ Title = "Elite Hunter Status",   Content = "N/A" })
    UI.EliteProgress = Farming:AddParagraph({ Title = "Elite Hunter Progress",  Content = "N/A" })

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local spawned = workspace.Enemies:FindFirstChild("Diablo")
                    or workspace.Enemies:FindFirstChild("Deandre")
                    or workspace.Enemies:FindFirstChild("Urban")
                    or RepStore:FindFirstChild("Diablo")
                    or RepStore:FindFirstChild("Deandre")
                    or RepStore:FindFirstChild("Urban")
                UI.EliteStatus:SetDesc(spawned and "Spawned!" or "Not Spawn")
                if World3 then
                    local prog = CommF_:InvokeServer("EliteHunter","Progress")
                    UI.EliteProgress:SetDesc(tostring(prog))
                else
                    UI.EliteProgress:SetDesc("Sea 3 Only")
                end
            end)
        end
    end)

    UI.AutoEliteHunter = Farming:AddToggle("AutoEliteHunter", {
        Title       = "Auto Elite Hunter",
        Description = "Sea 3 only",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Farm["Auto Elite Hunter"] = s
            StopTween(s)
        end,
    })

    UI.AutoEliteHop = Farming:AddToggle("AutoEliteHop", {
        Title       = "Auto Elite Hunter Hop",
        Description = "Hop server if elite not spawn",
        Default     = false,
        Callback    = function(s) _G.Settings.Farm["Auto Elite Hunter Hop"] = s end,
    })

    Farming:AddSection("Bone Farm  [Sea 3 Only]")

    UI.BoneFarmMethod = Farming:AddDropdown("BoneFarmMethod", {
        Title    = "Bone Farm Method",
        Values   = {"Quest","No Quest"},
        Default  = "Quest",
        Callback = function(v) _G.Settings.Farm["Selected Bone Farm Method"] = v end,
    })

    UI.BoneCount = Farming:AddParagraph({ Title = "Bones Owned", Content = "N/A" })

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                UI.BoneCount:SetDesc(tostring(GetCountMaterials("Bones")))
            end)
        end
    end)

    UI.AutoFarmBone = Farming:AddToggle("AutoFarmBone", {
        Title       = "Auto Farm Bone",
        Description = "Sea 3 only",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Farm["Auto Farm Bone"] = s
            StopTween(s)
        end,
    })

    UI.AutoRandomSurprise = Farming:AddToggle("AutoRandomSurprise", {
        Title       = "Auto Random Surprise",
        Description = "Sea 3 only",
        Default     = false,
        Callback    = function(s) _G.Settings.Farm["Auto Random Surprise"] = s end,
    })

    Farming:AddSection("Chest Farm")

    UI.AutoChestTween = Farming:AddToggle("AutoChestTween", {
        Title       = "Auto Farm Chest (Tween)",
        Description = "Tween towards chests",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Farm["Auto Farm Chest Tween"] = s
            StopTween(s)
        end,
    })

    UI.AutoChestInstant = Farming:AddToggle("AutoChestInstant", {
        Title       = "Auto Farm Chest (Instant)",
        Description = "Teleport instantly to chests",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Farm["Auto Farm Chest Instant"] = s
            StopTween(s)
        end,
    })

    UI.AutoChestHop = Farming:AddToggle("AutoChestHop", {
        Title       = "Auto Chest Hop",
        Description = "Hop server if no chests",
        Default     = false,
        Callback    = function(s) _G.Settings.Farm["Auto Chest Hop"] = s end,
    })

    UI.AutoChestMirage = Farming:AddToggle("AutoChestMirage", {
        Title       = "Auto Farm Chest (Mirage)",
        Description = "Chest farm Mirage Island only",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Farm["Auto Farm Chest Mirage"] = s
            StopTween(s)
        end,
    })

    UI.AutoStopItems = Farming:AddToggle("AutoStopItems", {
        Title       = "Auto Stop on God's Chalice / FoD",
        Default     = false,
        Callback    = function(s) _G.Settings.Farm["Auto Stop Items"] = s end,
    })

    Farming:AddSection("Materials")

    local matList = World1 and {"Magma Ore","Angel Wings","Leather","Scrap Metal"}
        or World2 and {"Radioactive","Mystic Droplet","Magma Ore","Leather","Ectoplasm","Scrap Metal"}
        or {"Leather","Scrap Metal","Conjured Cocoa","Dragon Scale","Gunpowder","Fish Tail","Mini Tusk"}

    UI.MaterialChoice = Farming:AddDropdown("MaterialChoice", {
        Title     = "Choose Material",
        Values    = matList,
        AllowNull = true,
        Callback  = function(v) _G.Settings.Farm["Selected Material"] = v end,
    })

    UI.AutoFarmMaterial = Farming:AddToggle("AutoFarmMaterial", {
        Title    = "Auto Farm Material",
        Default  = false,
        Callback = function(s)
            _G.Settings.Farm["Auto Farm Material"] = s
            StopTween(s)
        end,
    })

    Farming:AddSection("Pirate Raid  [Sea 3 Only]")

    UI.AutoPirateRaid = Farming:AddToggle("AutoPirateRaid", {
        Title       = "Auto Pirate Raid",
        Description = "Sea 3 only",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Farm["Auto Pirate Raid"] = s
            StopTween(s)
        end,
    })
end

do
    local B = Tabs.Bosses

    B:AddSection("Boss Farm")

    UI.BossStatus = B:AddParagraph({ Title = "Boss Status", Content = "N/A" })
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local sel = _G.Settings.Main["Selected Boss"]
                if sel and (RepStore:FindFirstChild(sel) or workspace.Enemies:FindFirstChild(sel)) then
                    UI.BossStatus:SetDesc("Spawned!")
                else
                    UI.BossStatus:SetDesc("Not spawned")
                end
            end)
        end
    end)

    UI.ChooseBoss = B:AddDropdown("ChooseBoss", {
        Title     = "Choose Boss",
        Values    = tableBoss,
        AllowNull = true,
        Callback  = function(v) _G.Settings.Main["Selected Boss"] = v end,
    })

    UI.AutoFarmBoss = B:AddToggle("AutoFarmBoss", {
        Title       = "Auto Farm Boss",
        Description = "Kill selected boss when it spawns",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Main["Auto Farm Boss"] = s
            StopTween(s)
        end,
    })

    UI.AutoFarmAllBoss = B:AddToggle("AutoFarmAllBoss", {
        Title    = "Auto Farm All Bosses",
        Default  = false,
        Callback = function(s)
            _G.Settings.Main["Auto Farm All Boss"] = s
            StopTween(s)
        end,
    })

    B:AddSection("Tyrant Of The Skies")

    UI.AutoSummonTyrant = B:AddToggle("AutoSummonTyrant", {
        Title       = "Auto Summon Tyrant Of The Skies",
        Description = "Auto farm monsters + summon boss",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Main["Auto Summon Tyrant Of The Skies"] = s
            StopTween(s)
        end,
    })

    UI.AutoKillTyrant = B:AddToggle("AutoKillTyrant", {
        Title    = "Auto Kill Tyrant Of The Skies",
        Default  = false,
        Callback = function(s)
            _G.Settings.Main["Auto Kill Tyrant Of The Skies"] = s
            StopTween(s)
        end,
    })

    B:AddSection("Cake Prince  [Sea 3 Only]")

    UI.CakePrinceStatus = B:AddParagraph({ Title = "Cake Prince Status", Content = "N/A" })
    task.spawn(function()
        while task.wait(5) do
            pcall(function()
                if not World3 then UI.CakePrinceStatus:SetDesc("Sea 3 Only") return end
                local resp = CommF_:InvokeServer("CakePrinceSpawner")
                local len  = string.len(resp)
                if     len == 88 then UI.CakePrinceStatus:SetDesc(resp:sub(39,41).." Remaining")
                elseif len == 87 then UI.CakePrinceStatus:SetDesc(resp:sub(39,40).." Remaining")
                elseif len == 86 then UI.CakePrinceStatus:SetDesc(resp:sub(39,39).." Remaining")
                else                  UI.CakePrinceStatus:SetDesc("Spawned!")
                end
            end)
        end
    end)

    UI.AutoKatakuri = B:AddToggle("AutoKatakuri", {
        Title       = "Auto Katakuri",
        Description = "Auto farm + kill Cake Prince (Sea 3)",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Farm["Auto Farm Katakuri"] = s
            StopTween(s)
        end,
    })

    UI.AutoSpawnCakePrince = B:AddToggle("AutoSpawnCakePrince", {
        Title       = "Auto Spawn Cake Prince",
        Description = "Sea 3 only",
        Default     = false,
        Callback    = function(s) _G.Settings.Farm["Auto Spawn Cake Prince"] = s end,
    })

    UI.AutoKillCakePrince = B:AddToggle("AutoKillCakePrince", {
        Title       = "Auto Kill Cake Prince",
        Description = "Sea 3 only",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Farm["Auto Kill Cake Prince"] = s
            StopTween(s)
        end,
    })

    UI.AutoKillDoughKing = B:AddToggle("AutoKillDoughKing", {
        Title       = "Auto Kill Dough King",
        Description = "Sea 3 only",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Farm["Auto Kill Dough King"] = s
            StopTween(s)
        end,
    })

    B:AddSection("Boss Status Live")
    UI.DoughKingStatus = B:AddParagraph({ Title = "Dough King", Content = "N/A" })
    UI.IndraStatus     = B:AddParagraph({ Title = "Rip Indra",  Content = "N/A" })

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                UI.DoughKingStatus:SetDesc(workspace.Enemies:FindFirstChild("Dough King") and " Spawned" or " Not Spawn")
                UI.IndraStatus:SetDesc(workspace.Enemies:FindFirstChild("rip_indra True Form") and " Spawned" or " Not Spawn")
            end)
        end
    end)
end

do
    local Q = Tabs.Quests

    Q:AddSection("World")
    UI.AutoSecondSea = Q:AddToggle("AutoSecondSea", { Title="Auto Second Sea", Description="Sea 1 only", Default=false,
        Callback=function(s) _G.Settings.Items["Auto Second Sea"]=s end })
    UI.AutoThirdSea  = Q:AddToggle("AutoThirdSea",  { Title="Auto Third Sea",  Description="Sea 2 only", Default=false,
        Callback=function(s) _G.Settings.Items["Auto Third Sea"] =s end })
    UI.AutoFarmFactory = Q:AddToggle("AutoFarmFactory", { Title="Auto Farm Factory", Description="World 2 only", Default=false,
        Callback=function(s) _G.Settings.Items["Auto Farm Factory"]=s end })

    Q:AddSection("Fighting Style")
    local fsToggles = {
        {"AutoSuperHuman",      "Auto Super Human",    "Auto Super Human"},
        {"AutoDeathStep",       "Auto Death Step",     "Auto Death Step"},
        {"AutoSharkmanKarate",  "Auto Sharkman Karate","Auto Fishman Karate"},
        {"AutoElectricClaw",    "Auto Electric Claw",  "Auto Electric Claw"},
        {"AutoDragonTalon",     "Auto Dragon Talon",   "Auto Dragon Talon"},
        {"AutoGodHuman",        "Auto God Human",      "Auto God Human"},
    }
    for _, t in pairs(fsToggles) do
        UI[t[1]] = Q:AddToggle(t[1], { Title=t[2], Default=false,
            Callback=function(s) _G.Settings.Items[t[3]]=s end })
    end

    Q:AddSection("Gun & Sword")
    local gsToggles = {
        {"AutoGetSaber",    "Auto Get Saber",     "Auto Saber",         "Sea 1 only"},
        {"AutoBuddySword",  "Auto Buddy Sword",   "Auto Buddy Sword",   "Sea 3 only"},
        {"AutoSoulGuitar",  "Auto Soul Guitar",   "Auto Soul Guitar",   "Sea 3 only"},
        {"AutoRengoku",     "Auto Rengoku",        "Auto Rengoku",       "Sea 2 only"},
        {"AutoHallowScythe","Auto Hallow Scythe", "Auto Hallow Scythe", "Sea 3 only"},
        {"AutoWardenSword", "Auto Warden Sword",  "Auto Warden Sword",  "Sea 1 only"},
        {"AutoGetYama",     "Auto Get Yama",       "Auto Yama",          "Need 30 Elite Hunter, Sea 3"},
        {"AutoGetTushita",  "Auto Get Tushita",    "Auto Tushita",       ""},
        {"AutoDragonTrident","Auto Dragon Trident","Auto Dragon Trident","Sea 2 only"},
        {"AutoSharkSaw",    "Auto Shark Saw",      "Auto Shark Saw",     "Sea 1 only"},
        {"AutoPole",        "Auto Pole",           "Auto Pole",          "Sea 1 only"},
        {"AutoDarkDagger",  "Auto Dark Dagger",    "Auto Dark Dagger",   "Need Rip Indra spawn, Sea 3"},
        {"AutoCursedDualKatana","Auto Cursed Dual Katana","Auto Cursed Dual Katana","Sea 3 only"},
        {"AutoCanvander",   "Auto Canvander",      "Auto Canvander",     "Sea 3 only"},
        {"AutoGreybeard",   "Auto Greybeard",      "Auto Greybeard",     "Sea 1 only"},
        {"AutoSwanGlasses", "Auto Swan Glasses",   "Auto Swan Glasses",  "Sea 2 only"},
        {"AutoArenaTrainer","Auto Arena Trainer",  "Auto Arena Trainer", "Sea 3 only"},
        {"AutoRainbowHaki", "Auto Rainbow Haki",   "Auto Rainbow Haki",  "Sea 3 only"},
        {"AutoHolyTorch",   "Auto Holy Torch",     "Auto Holy Torch",    "Sea 3 only"},
        {"AutoBartiloQuest","Auto Bartilo Quest",  "Auto Bartilo Quest", "Sea 2 only"},
    }
    for _, t in pairs(gsToggles) do
        UI[t[1]] = Q:AddToggle(t[1], {
            Title       = t[2],
            Description = t[4] ~= "" and t[4] or nil,
            Default     = false,
            Callback    = function(s)
                _G.Settings.Items[t[3]] = s
                StopTween(s)
            end,
        })
    end
end

do
    local R = Tabs.Raids
    R:AddSection("Raid")

    UI.RaidTime   = R:AddParagraph({ Title = "Raid Time", Content = "N/A" })
    UI.RaidIsland = R:AddParagraph({ Title = "Island",    Content = "N/A" })

    task.spawn(function()
        while task.wait(0.3) do
            pcall(function()
                local t = LP.PlayerGui.Main.TopHUDList.RaidTimer
                UI.RaidTime:SetDesc(t.Visible and t.Text or "Wait for dungeon")
                local rm = workspace.Map.RaidMap
                local island = "Start Dungeon"
                for i = 5, 1, -1 do
                    if rm:FindFirstChild("RaidIsland"..i) then island = "Island "..i break end
                end
                UI.RaidIsland:SetDesc(island)
            end)
        end
    end)

    local raidList = {}
    pcall(function()
        local mod = require(RepStore.Raids)
        for _, v in pairs(mod.raids)         do table.insert(raidList, v) end
        for _, v in pairs(mod.advancedRaids) do table.insert(raidList, v) end
    end)

    UI.ChooseChipRaid = R:AddDropdown("ChooseChipRaid", {
        Title     = "Choose Chip",
        Values    = raidList,
        AllowNull = true,
        Callback  = function(v) _G.Settings.Raid["Selected Chip"] = v end,
    })

    UI.AutoRaid = R:AddToggle("AutoRaid", {
        Title       = "Auto Raid",
        Description = "Complete automatically",
        Default     = false,
        Callback    = function(s)
            _G.Settings.Raid["Auto Raid"] = s
            StopTween(s)
            State.MonFarm = ""
            State.PosMon  = CFrame.new()
        end,
    })

    UI.AutoAwakening = R:AddToggle("AutoAwakening", {
        Title    = "Auto Awaken",
        Default  = false,
        Callback = function(s) _G.Settings.Raid["Auto Awaken"] = s end,
    })

    UI.PriceDevilFruit = R:AddSlider("PriceDevilFruit", {
        Title    = "Price (Unstore Devil Fruit)",
        Min      = 100000,
        Max      = 10000000,
        Default  = 1000000,
        Rounding = 0,
        Callback = function(v) _G.Settings.Raid["Price Devil Fruit"] = v end,
    })

    UI.AutoUnstoreDF = R:AddToggle("AutoUnstoreDF", {
        Title    = "Auto Unstore Devil Fruit",
        Default  = false,
        Callback = function(s) _G.Settings.Raid["Unstore Devil Fruit"] = s end,
    })

    R:AddButton({ Title = "Teleport To Lab", Callback = function()
        if World2 then TweenPlayer(CFrame.new(-6438.73,250.64,-4501.50))
        elseif World3 then TweenPlayer(CFrame.new(-5017.40,314.84,-2823.01)) end
    end})

    R:AddSection("Law Raid")
    UI.AutoLawRaid = R:AddToggle("AutoLawRaid", {
        Title    = "Auto Law Raid",
        Default  = false,
        Callback = function(s)
            _G.Settings.Raid["Law Raid"] = s
            StopTween(s)
            State.MonFarm = ""
            State.PosMon  = CFrame.new()
        end,
    })
end

do
    local T = Tabs.Teleports
    T:AddSection("Sea Travel")
    T:AddButton({ Title = "First Sea",  Callback = function() CommF_:InvokeServer("TravelMain")      end })
    T:AddButton({ Title = "Second Sea", Callback = function() CommF_:InvokeServer("TravelDressrosa") end })
    T:AddButton({ Title = "Third Sea",  Callback = function() CommF_:InvokeServer("TravelZou")       end })

    T:AddSection("Island Teleport")
    local islandList = World1 and {
        "WindMill","Marine","Middle Town","Jungle","Pirate Village","Desert","Snow Island",
        "MarineFord","Colosseum","Sky Island 1","Sky Island 2","Sky Island 3","Prison",
        "Magma Village","Under Water Island","Fountain City","Shank Room","Mob Island",
    } or World2 and {
        "The Cafe","Frist Spot","Dark Area","Flamingo Mansion","Flamingo Room","Green Zone",
        "Factory","Colossuim","Zombie Island","Two Snow Mountain","Punk Hazard","Cursed Ship",
        "Ice Castle","Forgotten Island","Ussop Island","Mini Sky Island",
    } or {
        "Mansion","Port Town","Great Tree","Castle On The Sea","MiniSky","Hydra Island",
        "Floating Turtle","Haunted Castle","Ice Cream Island","Peanut Island","Cake Island",
        "Cocoa Island","Candy Island","Tiki Outpost","Dragon Dojo",
    }

    local islandCF = {
        WindMill      = CFrame.new(979.79,16.51,1429.04),
        Marine        = CFrame.new(-2566.42,6.85,2045.25),
        ["Middle Town"]= CFrame.new(-690.33,15.09,1582.23),
        Jungle        = CFrame.new(-1612.79,36.85,149.12),
        ["Pirate Village"]= CFrame.new(-1181.30,4.75,3803.54),
        Desert        = CFrame.new(944.15,20.91,4373.30),
        ["Snow Island"]   = CFrame.new(1347.80,104.66,-1319.73),
        MarineFord    = CFrame.new(-4914.82,50.96,4281.02),
        Colosseum     = CFrame.new(-1427.62,7.28,-2792.77),
        ["Sky Island 1"]  = CFrame.new(-4869.10,733.46,-2667.01),
        Prison        = CFrame.new(4875.33,5.65,734.85),
        ["Magma Village"] = CFrame.new(-5247.71,12.88,8504.96),
        ["Fountain City"] = CFrame.new(5127.12,59.50,4105.44),
        ["Shank Room"]    = CFrame.new(-1442.16,29.87,-28.35),
        ["Mob Island"]    = CFrame.new(-2850.20,7.39,5354.99),
        ["The Cafe"]     = CFrame.new(-380.48,77.22,255.83),
        ["Frist Spot"]   = CFrame.new(-11.31,29.28,2771.52),
        ["Dark Area"]    = CFrame.new(3780.03,22.65,-3498.59),
        ["Flamingo Mansion"] = CFrame.new(-483.73,332.04,595.33),
        ["Flamingo Room"]    = CFrame.new(2284.41,15.15,875.73),
        ["Green Zone"]   = CFrame.new(-2448.53,73.02,-3210.63),
        Factory         = CFrame.new(424.13,211.16,-427.54),
        Colossuim       = CFrame.new(-1503.62,219.80,1369.31),
        ["Zombie Island"]= CFrame.new(-5622.03,492.20,-781.79),
        ["Two Snow Mountain"] = CFrame.new(753.14,408.24,-5274.61),
        ["Punk Hazard"]  = CFrame.new(-6127.65,15.95,-5040.29),
        ["Cursed Ship"]  = CFrame.new(923.40,125.06,32885.88),
        ["Ice Castle"]   = CFrame.new(6148.41,294.39,-6741.12),
        ["Forgotten Island"]= CFrame.new(-3032.76,317.90,-10075.37),
        ["Ussop Island"] = CFrame.new(4816.86,8.46,2863.82),
        ["Mini Sky Island"] = CFrame.new(-288.74,49326.32,-35248.59),
        ["Port Town"]    = CFrame.new(-290.74,6.73,5343.55),
        ["Great Tree"]   = CFrame.new(2681.27,1682.81,-7190.99),
        ["Castle On The Sea"] = CFrame.new(-5083.26,314.61,-3175.67),
        MiniSky         = CFrame.new(-260.66,49325.80,-35253.57),
        ["Hydra Island"]= CFrame.new(5291.25,1005.44,393.76,0.994222522,0,-0.10733854,0,1,0,0.10733854,0,0.994222522),
        ["Floating Turtle"]= CFrame.new(-13274.53,531.82,-7579.22),
        ["Haunted Castle"]= CFrame.new(-9515.37,164.01,5786.06),
        ["Ice Cream Island"]= CFrame.new(-902.57,79.93,-10988.85),
        ["Peanut Island"] = CFrame.new(-2062.75,50.47,-10232.57),
        ["Cake Island"]   = CFrame.new(-1884.77,19.33,-11666.90),
        ["Cocoa Island"]  = CFrame.new(87.94,73.55,-12319.46),
        ["Candy Island"]  = CFrame.new(-1014.42,149.11,-14555.96),
        ["Tiki Outpost"]  = CFrame.new(-16218.68,9.08,445.61),
        ["Dragon Dojo"]   = CFrame.new(5743.31,1206.90,936.01),
    }

    local _selectedIsland = nil
    UI.TeleportIslandDropdown = T:AddDropdown("TeleportIsland", {
        Title     = "Choose Island",
        Values    = islandList,
        AllowNull = true,
        Callback  = function(v) _selectedIsland = v end,
    })

    T:AddButton({ Title = "Teleport to Island", Callback = function()
        if not _selectedIsland then
            Library:Notify({ Title = "Teleport", Content = "No island selected!", Duration = 3 })
            SendDebug("TeleportBtn", "no island selected", nil, 2)
            return
        end
        local cf = islandCF[_selectedIsland]
        SendDebug("TeleportBtn", "selected=" .. tostring(_selectedIsland) .. " hasCF=" .. tostring(cf ~= nil), { cf = cf, hrpPos = GetHRP() and GetHRP().Position }, 2)
        if cf then
            TweenPlayer(cf)
        elseif _selectedIsland == "Sky Island 2" then
            CommF_:InvokeServer("requestEntrance", Vector3.new(-4607.82,872.54,-1667.56))
        elseif _selectedIsland == "Sky Island 3" then
            CommF_:InvokeServer("requestEntrance", Vector3.new(-7894.62,5547.14,-380.29))
        elseif _selectedIsland == "Under Water Island" then
            CommF_:InvokeServer("requestEntrance", Vector3.new(61163.85,11.68,1819.78))
        elseif _selectedIsland == "Mansion" then
            CommF_:InvokeServer("requestEntrance", Vector3.new(-12471.17,374.94,-7551.68))
        end
    end})
end

do
    local V = Tabs.V4
    V:AddSection("Race")

    UI.AutoRaceV2 = V:AddToggle("AutoRaceV2", {
        Title    = "Auto Race V2",
        Default  = false,
        Callback = function(s)
            _G.Settings.Race["Auto Race V2"] = s
            StopTween(s)
        end,
    })

    UI.AutoRaceV3 = V:AddToggle("AutoRaceV3", {
        Title    = "Auto Race V3",
        Default  = false,
        Callback = function(s)
            _G.Settings.Race["Auto Race V3"] = s
            StopTween(s)
        end,
    })

    UI.SelectedPlace = V:AddDropdown("SelectedPlace", {
        Title     = "Selected Place",
        Values    = {"Top Of GreatTree","Timple Of Time","Lever Pull","Acient One"},
        AllowNull = true,
        Callback  = function(v) _G.Settings.Race["Selected Place"] = v end,
    })

    UI.TeleportToPlace = V:AddToggle("TeleportToPlace", {
        Title    = "Teleport To Place",
        Default  = false,
        Callback = function(s) _G.Settings.Race["Teleport To Place"] = s end,
    })

    UI.AutoBuyGear = V:AddToggle("AutoBuyGear", {
        Title    = "Auto Buy Gear",
        Default  = false,
        Callback = function(s) _G.Settings.Race["Auto Buy Gear"] = s end,
    })

    UI.TweenToMirage = V:AddToggle("TweenToMirage", {
        Title       = "Tween To Mirage Island",
        Description = "Tween to highest point",
        Default     = false,
        Callback    = function(s) _G.Settings.Race["Tween To Highest Mirage"] = s end,
    })

    UI.FindBlueGear = V:AddToggle("FindBlueGear", {
        Title    = "Find Blue Gear",
        Default  = false,
        Callback = function(s) _G.Settings.Race["Find Blue Gear"] = s end,
    })

    UI.LookMoonAbility = V:AddToggle("LookMoonAbility", {
        Title    = "Look Moon & Use Ability",
        Default  = false,
        Callback = function(s) _G.Settings.Race["Look Moon Ability"] = s end,
    })

    UI.AutoTrain = V:AddToggle("AutoTrain", {
        Title    = "Auto Train",
        Default  = false,
        Callback = function(s)
            _G.Settings.Race["Auto Train"] = s
            StopTween(s)
        end,
    })

    V:AddButton({ Title = "Teleport To Race Door", Callback = function()
        if not World3 then return end
        LP.Character.HumanoidRootPart.CFrame = CFrame.new(28286.35,14895.30,102.62)
    end})

    V:AddButton({ Title = "Buy Ancient Quest", Callback = function()
        CommF_:InvokeServer("UpgradeRace","Buy")
    end})

    UI.AutoTrial = V:AddToggle("AutoTrial", {
        Title    = "Auto Trial",
        Default  = false,
        Callback = function(s)
            _G.Settings.Race["Auto Trial"] = s
            StopTween(s)
        end,
    })

    UI.AutoKillAfterTrial = V:AddToggle("AutoKillAfterTrial", {
        Title    = "Auto Kill Player After Trial",
        Default  = false,
        Callback = function(s) _G.Settings.Race["Auto Kill Player After Trial"] = s end,
    })
end

do
    local SE = Tabs.ShopEvent
    SE:AddSection("Sea Event")

    UI.ChooseBoat = SE:AddDropdown("ChooseBoat", {
        Title    = "Choose Boat",
        Values   = {"Guardian","Beast Hunter","PirateGrandBrigade","MarineGrandBrigade",
                    "PirateBrigade","MarineBrigade","PirateSloop","MarineSloop"},
        Default  = "Guardian",
        Callback = function(v) _G.Settings.SeaEvent["Selected Boat"] = v end,
    })

    UI.ChooseZone = SE:AddDropdown("ChooseZone", {
        Title    = "Choose Zone",
        Values   = {"Zone 1","Zone 2","Zone 3","Zone 4","Zone 5","Zone 6","Infinite"},
        Default  = "Zone 5",
        Callback = function(v) _G.Settings.SeaEvent["Selected Zone"] = v end,
    })

    UI.BoatTweenSpeed = SE:AddSlider("BoatTweenSpeed", {
        Title    = "Boat Tween Speed",
        Min      = 1, Max = 350, Default = 300, Rounding = 0,
        Callback = function(v) _G.Settings.SeaEvent["Boat Tween Speed"] = v end,
    })

    UI.SailBoat = SE:AddToggle("SailBoat", {
        Title       = "Sail Boat",
        Description = "Auto sail + kill enemies",
        Default     = false,
        Callback    = function(s) _G.Settings.SeaEvent["Sail Boat"] = s end,
    })

    SE:AddSection("Sea Event Enemies")
    local seaEnemyToggles = {
        {"AutoFarmShark",            "Auto Farm Shark",                 "Auto Farm Shark"},
        {"AutoFarmPiranha",          "Auto Farm Piranha",               "Auto Farm Piranha"},
        {"AutoFarmFishCrew",         "Auto Farm Fish Crew Member",      "Auto Farm Fish Crew Member"},
        {"AutoFarmGhostShip",        "Auto Farm Ghost Ship",            "Auto Farm Ghost Ship"},
        {"AutoFarmPirateBrigade",    "Auto Farm Pirate Brigade",        "Auto Farm Pirate Brigade"},
        {"AutoFarmPirateGrandBrig",  "Auto Farm Pirate Grand Brigade",  "Auto Farm Pirate Grand Brigade"},
        {"AutoFarmTerrorshark",      "Auto Farm Terrorshark",           "Auto Farm Terrorshark"},
        {"AutoFarmSeabeasts",        "Auto Farm Seabeasts",             "Auto Farm Seabeasts"},
    }
    for _, t in pairs(seaEnemyToggles) do
        UI[t[1]] = SE:AddToggle(t[1], { Title=t[2], Default=true,
            Callback=function(s) _G.Settings.SeaEvent[t[3]]=s end })
    end

    SE:AddSection("Sea Stack")
    UI.PrehistoricStatus = SE:AddParagraph({ Title="Prehistoric Status", Content="N/A" })
    UI.KitsuneStatus     = SE:AddParagraph({ Title="Kitsune Status",     Content="N/A" })
    UI.FrozenStatus      = SE:AddParagraph({ Title="Frozen Status",      Content="N/A" })
    UI.MirageStatus      = SE:AddParagraph({ Title="Mirage Status",      Content="N/A" })

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                local locs = workspace._WorldOrigin.Locations
                UI.PrehistoricStatus:SetDesc(locs:FindFirstChild("Prehistoric Island") and " Spawning" or " Not Spawn")
                UI.KitsuneStatus:SetDesc(    locs:FindFirstChild("Kitsune Island")     and " Spawning" or " Not Spawn")
                UI.FrozenStatus:SetDesc(     locs:FindFirstChild("Frozen Dimension")   and " Spawning" or " Not Spawn")
                UI.MirageStatus:SetDesc(     locs:FindFirstChild("Mirage Island")      and " Spawning" or " Not Spawn")
            end)
        end
    end)

    SE:AddButton({ Title = "Bribe Leviathan", Callback = function()
        pcall(function() CommF_:InvokeServer("BribeLeviathan") end)
    end})
end

do
    local S = Tabs.Status
    S:AddSection("Status")

    UI.GameTime = S:AddParagraph({ Title = "Game Time", Content = "0" })
    UI.FpsStat  = S:AddParagraph({ Title = "FPS",       Content = "0" })
    UI.PingStat = S:AddParagraph({ Title = "Ping",      Content = "0" })

    task.spawn(function()
        while task.wait() do
            pcall(function()
                local gt  = math.floor(workspace.DistributedGameTime + 0.5)
                local h,m,sec = math.floor(gt/3600)%24, math.floor(gt/60)%60, gt%60
                UI.GameTime:SetDesc(h.." Hours "..m.." Min "..sec.." Sec")
                UI.FpsStat:SetDesc(tostring(math.floor(workspace:GetRealPhysicsFPS())))
                UI.PingStat:SetDesc(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString())
            end)
        end
    end)

    S:AddSection("Server Status")
    UI.MoonStatus        = S:AddParagraph({ Title = "Moon",       Content = "N/A" })
    UI.KitsuneSrvStatus  = S:AddParagraph({ Title = "Kitsune",    Content = "N/A" })
    UI.FrozenSrvStatus   = S:AddParagraph({ Title = "Frozen",     Content = "N/A" })
    UI.MirageSrvStatus   = S:AddParagraph({ Title = "Mirage",     Content = "N/A" })
    UI.HakiDealerStatus  = S:AddParagraph({ Title = "Haki Dealer",Content = "N/A" })

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                local moonId = game:GetService("Lighting").Sky.MoonTextureId
                local moonPct= moonId:find("9709149431") and "100%"
                    or moonId:find("9709149052") and "75%"
                    or moonId:find("9709143733") and "50%"
                    or moonId:find("9709150401") and "25%"
                    or moonId:find("9709149680") and "15%"
                    or "0%"
                UI.MoonStatus:SetDesc("Full Moon "..moonPct)
                local locs = workspace._WorldOrigin.Locations
                UI.KitsuneSrvStatus:SetDesc(locs:FindFirstChild("Kitsune Island")  and "✅ Spawning" or "❌ Not Spawn")
                UI.FrozenSrvStatus:SetDesc( locs:FindFirstChild("Frozen Dimension") and "✅ Spawning" or "❌ Not Spawn")
                UI.MirageSrvStatus:SetDesc( locs:FindFirstChild("Mirage Island")   and "✅ Spawning" or "❌ Not Spawn")
                local hd = CommF_:InvokeServer("ColorsDealer","1")
                UI.HakiDealerStatus:SetDesc(hd and "✅ Master Of Auras Spawning" or "❌ Not Spawn")
            end)
        end
    end)

    S:AddSection("Stats")
    UI.StatsPoints = S:AddParagraph({ Title = "Stat Points", Content = "0" })
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function() UI.StatsPoints:SetDesc(tostring(LP.Data.Points.Value)) end)
        end
    end)

    local statsToggles = {
        {"AutoAddMelee",   "Add Melee Stats",        "Auto Add Melee Stats"},
        {"AutoAddDefense", "Add Defense Stats",       "Auto Add Defense Stats"},
        {"AutoAddSword",   "Add Sword Stats",         "Auto Add Sword Stats"},
        {"AutoAddGun",     "Add Gun Stats",           "Auto Add Gun Stats"},
        {"AutoAddDF",      "Add Devil Fruit Stats",   "Auto Add Devil Fruit Stats"},
    }
    for _, t in pairs(statsToggles) do
        UI[t[1]] = S:AddToggle(t[1], { Title=t[2], Default=false,
            Callback=function(s) _G.Settings.Stats[t[3]]=s end })
    end

    UI.StatsPointSlider = S:AddSlider("StatsPoint", {
        Title    = "Points Per Add",
        Min=1, Max=100, Default=1, Rounding=0,
        Callback = function(v) _G.Settings.Stats["Point Stats"] = v end,
    })
end

do
    local P = Tabs.Player
    P:AddSection("Local Player")

    local lpToggles = {
        {"AutoActiveRaceV3","Active Race V3","Auto Turn On Tribe V3","Active Race V3"},
        {"AutoActiveRaceV4","Active Race V4","Auto Turn On Tribe V4","Active Race V4"},
        {"InfiniteEnergy",  "Infinite Energy","Unlimited energy/stamina","Infinite Energy"},
        {"InfiniteGeppo",   "Infinite Geppo", "No geppo cooldown",   "Infinite Geppo"},
        {"InfiniteSoru",    "Infinite Soru",  "No soru cooldown",    "Infinite Soru"},
        {"DodgeNoCooldown", "Dodge No Cooldown","No dodge cooldown", "Dodge No Cooldown"},
        {"WalkOnWater",     "Walk On Water","Jesus walk on water",   "Walk On Water"},
        {"NoClipPlayer",    "No Clip",      "Travel through walls",  "No Clip"},
    }
    for _, t in pairs(lpToggles) do
        UI[t[1]] = P:AddToggle(t[1], { Title=t[2], Description=t[3], Default=false,
            Callback=function(s) _G.Settings.LocalPlayer[t[4]]=s end })
    end

    P:AddSection("Fruit")
    UI.AutoRandomFruit = P:AddToggle("AutoRandomFruit", { Title="Auto Random Fruit", Default=false,
        Callback=function(s) _G.Settings.Fruit["Auto Buy Random Fruit"]=s end })

    UI.StoreRarity = P:AddDropdown("StoreRarity", {
        Title    = "Store Rarity Fruit",
        Values   = {"Common - Mythical","Rare - Mythical","Legendary - Mythical","Mythical"},
        Default  = "Common - Mythical",
        Callback = function(v) _G.Settings.Fruit["Store Rarity Fruit"]=v end,
    })

    local fruitToggles = {
        {"AutoStoreFruit",    "Auto Store Fruit",    "Auto Store Fruit"},
        {"FruitNotification", "Fruit Notification",  "Fruit Notification"},
        {"TeleportToFruit",   "Teleport To Fruit",   "Teleport To Fruit"},
        {"TweenToFruit",      "Tween To Fruit",      "Tween To Fruit"},
    }
    for _, t in pairs(fruitToggles) do
        UI[t[1]] = P:AddToggle(t[1], { Title=t[2], Default=false,
            Callback=function(s) _G.Settings.Fruit[t[3]]=s end })
    end

    P:AddButton({ Title = "Grab Fruit", Callback = function()
        for _, v in pairs(workspace:GetChildren()) do
            if v:IsA("Tool") then v.Handle.CFrame = GetHRP().CFrame end
        end
    end})
end

do
    local PvP = Tabs.PvP
    PvP:AddSection("Combat")

    UI.PlayersInServer = PvP:AddParagraph({ Title = "Players In Server", Content = "0" })
    task.spawn(function()
        while task.wait(2) do
            pcall(function() UI.PlayersInServer:SetDesc(tostring(#Players:GetPlayers())) end)
        end
    end)

    local function getPlayerList()
        local out = {}
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LP then table.insert(out, v.Name) end
        end
        return out
    end

    UI.ChoosePlayer = PvP:AddDropdown("ChoosePlayer", {
        Title     = "Choose Player",
        Values    = getPlayerList(),
        AllowNull = true,
        Callback  = function(v) _G.SelectedPlayer = v end,
    })

    PvP:AddButton({ Title = "Refresh Player List", Callback = function()
        UI.ChoosePlayer:SetValues(getPlayerList())
    end})

    UI.SpectatePlayer = PvP:AddToggle("SpectatePlayer", {
        Title    = "Spectate Player",
        Default  = false,
        Callback = function(s)
            _G.Settings.Combat = _G.Settings.Combat or {}
            _G.Settings.Combat["Enable PvP"] = s
            if s and _G.SelectedPlayer then
                local target = Players:FindFirstChild(_G.SelectedPlayer)
                if target and target.Character then
                    workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
                end
            else
                workspace.CurrentCamera.CameraSubject = LP.Character and LP.Character.Humanoid
            end
        end,
    })

    UI.TeleportToPlayer = PvP:AddToggle("TeleportToPlayer", {
        Title    = "Teleport To Player",
        Default  = false,
        Callback = function(s)
            _G.TeleportToPlayer = s
            if s then
                _G.TeleportToPlayerGen = (_G.TeleportToPlayerGen or 0) + 1
                local myGen = _G.TeleportToPlayerGen
                task.spawn(function()
                    while _G.TeleportToPlayer and _G.SelectedPlayer and _G.TeleportToPlayerGen == myGen do
                        pcall(function()
                            local t = Players:FindFirstChild(_G.SelectedPlayer)
                            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                                TweenPlayer(t.Character.HumanoidRootPart.CFrame)
                            end
                        end)
                        task.wait(0.1)
                    end
                end)
            else
                _G.TeleportToPlayerGen = (_G.TeleportToPlayerGen or 0) + 1
                StopTween(false)
            end
        end,
    })
end

do
    local M = Tabs.Misc

    M:AddSection("Shop")
    UI.AutoBuyLegendary = M:AddToggle("AutoBuyLegendary", { Title="Auto Buy Legendary Sword", Default=false,
        Callback=function(s) _G.Settings.Shop["Auto Buy Legendary Sword"]=s end })
    UI.AutoBuyHakiColor = M:AddToggle("AutoBuyHakiColor",  { Title="Auto Buy Haki Color",      Default=false,
        Callback=function(s) _G.Settings.Shop["Auto Buy Haki Color"]=s end })

    M:AddSection("Abilities")
    M:AddButton({ Title="Buy Geppo",           Description="$10,000",    Callback=function() CommF_:InvokeServer("BuyHaki","Geppo") end })
    M:AddButton({ Title="Buy Buso Haki",       Description="$25,000",    Callback=function() CommF_:InvokeServer("BuyHaki","Buso")  end })
    M:AddButton({ Title="Buy Soru",            Description="$25,000",    Callback=function() CommF_:InvokeServer("BuyHaki","Soru")  end })
    M:AddButton({ Title="Buy Observation Haki",Description="$750,000",   Callback=function() CommF_:InvokeServer("KenTalk","Buy")   end })

    M:AddSection("Fighting Style")
    -- FIX: these buttons were calling InvokeServer("BuyX") directly with no
    -- validation step, but the game's CommF_ handler expects a check call
    -- first (InvokeServer("BuyX", true) -> returns 1/truthy if eligible),
    -- THEN the real purchase call without the true flag. Skipping the check
    -- call is why these silently did nothing - confirmed by captured args
    -- showing the game itself fires "BuyElectro", true followed by "BuyElectro".
    local function BuyAbility(remoteName)
        pcall(function()
            local ok = CommF_:InvokeServer(remoteName, true)
            if ok == 1 or ok == true then
                CommF_:InvokeServer(remoteName)
            end
        end)
    end
    -- BuyGodhuman's check call returns a string (not 1/true) - it contains
    -- "Bring" when a prerequisite item is missing, matching the Auto God
    -- Human farm logic's handling further down in this file.
    local function BuyGodhumanAbility()
        pcall(function()
            local ok = CommF_:InvokeServer("BuyGodhuman", true)
            if not (type(ok) == "string" and string.find(ok, "Bring")) then
                CommF_:InvokeServer("BuyGodhuman")
            end
        end)
    end
    M:AddButton({ Title="Buy Black Leg",       Description="$150,000",    Callback=function() BuyAbility("BuyBlackLeg")      end })
    M:AddButton({ Title="Buy Electro",         Description="$550,000",    Callback=function() BuyAbility("BuyElectro")        end })
    M:AddButton({ Title="Buy Fishman Karate",  Description="$750,000",    Callback=function() BuyAbility("BuyFishmanKarate")  end })
    M:AddButton({ Title="Buy Dragon Claw",     Description="F'1,500",     Callback=function() CommF_:InvokeServer("BlackbeardReward","DragonClaw","1") CommF_:InvokeServer("BlackbeardReward","DragonClaw","2") end })
    M:AddButton({ Title="Buy Superhuman",      Description="$3,000,000",  Callback=function() BuyAbility("BuySuperhuman")     end })
    M:AddButton({ Title="Buy Death Step",      Description="F'5,000",     Callback=function() BuyAbility("BuyDeathStep")      end })
    M:AddButton({ Title="Buy Sharkman Karate", Description="F'5,000",     Callback=function() BuyAbility("BuySharkmanKarate") end })
    M:AddButton({ Title="Buy Electric Claw",   Description="F'5,000",     Callback=function() BuyAbility("BuyElectricClaw")   end })
    M:AddButton({ Title="Buy Dragon Talon",    Description="F'5,000",     Callback=function() BuyAbility("BuyDragonTalon")    end })
    M:AddButton({ Title="Buy God Human",       Description="F'5,000",     Callback=function() BuyGodhumanAbility()             end })

    M:AddSection("Sword Shop")
    local swords = {{"Cutlass","$1,000"},{"Katana","$10,000"},{"Iron Mace","$20,000"},
                    {"Dual Katana","$100,000"},{"Triple Katana","$250,000"},{"Pipe","$5,000"},
                    {"Dual-Headed Blade","$400,000"},{"Bisento","$1,200,000"},{"Soul Cane","$1,000"}}
    for _, s in pairs(swords) do
        M:AddButton({ Title="Buy "..s[1], Description=s[2],
            Callback=function() CommF_:InvokeServer("BuyItem", s[1]) end })
    end

    M:AddSection("Gun Shop")
    local guns = {{"Slingshot","$5,000"},{"Musket","$8,000"},{"Flintlock","$10,500"},
                  {"Refined Flintlock","$60,000"},{"Cannon","$100,000"}}
    for _, g in pairs(guns) do
        M:AddButton({ Title="Buy "..g[1], Description=g[2],
            Callback=function() CommF_:InvokeServer("BuyItem", g[1]) end })
    end
    M:AddButton({ Title="Buy Kabucha", Description="F'1,500", Callback=function()
        CommF_:InvokeServer("BlackbeardReward","Slingshot","1")
        CommF_:InvokeServer("BlackbeardReward","Slingshot","2")
    end})
end

do
    local SO = Tabs.Social
    SO:AddSection("Team")
    SO:AddButton({ Title="Join Pirates", Callback=function() CommF_:InvokeServer("SetTeam","Pirates") end })
    SO:AddButton({ Title="Join Marines", Callback=function() CommF_:InvokeServer("SetTeam","Marines") end })

    SO:AddSection("Codes")
    local codes = {"ZIOLES","NOOB2ADMIN","KITT_RESET","Sub2CaptainMaui","SUB2GAMERROBOT_RESET1",
                   "kittgaming","Sub2Fer999","Enyu_is_Pro","Magicbus","JCWK","Starcodeheo","Bluxxy",
                   "fudd10_v2","FUDD10","BIGNEWS","THEGREATACE","SUB2GAMERROBOT_EXP1","Sub2OfficialNoobie",
                   "StrawHatMaine","SUB2NOOBMASTER123","Sub2UncleKizaru","Sub2Daigrock","Axiore","TantaiGaming"}
    SO:AddButton({ Title="Redeem All Codes", Callback=function()
        for _, c in pairs(codes) do pcall(function() RepStore.Remotes.Redeem:InvokeServer(c) end) end
    end})
end

do
    local PF = Tabs.Performance
    PF:AddSection("Rendering")
    PF:AddButton({ Title="FPS Boost", Callback=function()
        settings().Rendering.QualityLevel = "Level01"
        for _, v in pairs(game:GetDescendants()) do
            pcall(function()
                if v:IsA("Part") or v:IsA("Union") then v.Material="Plastic" v.Reflectance=0
                elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Lifetime=NumberRange.new(0)
                elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then v.Enabled=false end
            end)
        end
    end})
    PF:AddButton({ Title="Remove Fog",  Callback=function() game:GetService("Lighting").FogEnd = 9e9 end })
    PF:AddButton({ Title="Remove Lava", Callback=function()
        for _, v in pairs(workspace:GetDescendants()) do if v.Name == "Lava" then pcall(function() v:Destroy() end) end end
    end})
end

do
    local S = Tabs.Settings
    S:AddSection("Settings")

    UI.SpinPosition = S:AddToggle("SpinPosition", {
        Title       = "Spin Position",
        Description = "Orbit around mob instead of hovering above",
        Default     = false,
        Callback    = function(s) _G.Settings.Setting["Spin Position"] = s end,
    })

    UI.FarmDistance = S:AddSlider("FarmDistance", {
        Title    = "Farm Distance (height offset)",
        Min=10, Max=50, Default=35, Rounding=0,
        Callback = function(v) _G.Settings.Setting["Farm Distance"] = v end,
    })

    UI.PlayerTweenSpeed = S:AddSlider("PlayerTweenSpeed", {
        Title    = "Player Tween Speed",
        Min=10, Max=350, Default=350, Rounding=0,
        Callback = function(v) _G.Settings.Setting["Player Tween Speed"] = v end,
    })

    UI.BringMob = S:AddToggle("BringMob", {
        Title    = "Bring Mob",
        Default  = true,
        Callback = function(s) _G.Settings.Setting["Bring Mob"] = s end,
    })

    UI.BringMobMode = S:AddDropdown("BringMobMode", {
        Title    = "Bring Mob Range",
        Values   = {"Low","Normal","High"},
        Default  = "Normal",
        Callback = function(v) _G.Settings.Setting["Bring Mob Mode"] = v end,
    })

    UI.FastAttackMode = S:AddDropdown("FastAttackMode", {
        Title    = "Attack Speed",
        Values   = {"Slow","Normal","Fast","Super Fast"},
        Default  = "Normal",
        Callback = function(v) _G.Settings.Setting["Fast Attack Mode"] = v end,
    })

    UI.AttackAura = S:AddToggle("AttackAura", {
        Title       = "Attack Aura",
        Description = "Auto-attack nearest enemies at all times",
        Default     = true,
        Callback    = function(s) _G.Settings.Setting["Attack Aura"] = s end,
    })

    S:AddSection("Mastery Settings")
    UI.MasteryHealth = S:AddSlider("MasteryHealth", {
        Title    = "Mastery Skill Trigger (% HP remaining)",
        Min=1, Max=100, Default=25, Rounding=0,
        Callback = function(v) _G.Settings.Setting["Mastery Health"] = v end,
    })

    S:AddSection("Other")
    local otherToggles = {
        {"AutoSetSpawn",   "Auto Set Spawn Point","Auto Set Spawn Point"},
        {"AutoObservation","Auto Observation",    "Auto Observation"},
        {"AutoHakiSetting","Auto Haki",           "Auto Haki"},
        {"AutoRejoin",     "Auto Rejoin",          "Auto Rejoin"},
    }
    for _, t in pairs(otherToggles) do
        local def = (t[3] == "Auto Haki" or t[3] == "Auto Set Spawn Point" or t[3] == "Auto Rejoin")
        UI[t[1]] = S:AddToggle(t[1], { Title=t[2], Default=def,
            Callback=function(s) _G.Settings.Setting[t[3]]=s end })
    end
end

do
    local DI = Tabs.Display
    DI:AddSection("Screen & Overlay")
    local graphicToggles = {
        {"HideNotification","Hide Notification","Hide Notification"},
        {"HideDamageText",  "Hide Damage Text", "Hide Damage Text"},
        {"BlackScreen",     "Black Screen",     "Black Screen"},
        {"WhiteScreen",     "White Screen",     "White Screen"},
    }
    for _, t in pairs(graphicToggles) do
        UI[t[1]] = DI:AddToggle(t[1], { Title=t[2], Default=false,
            Callback=function(s) _G.Settings.Setting[t[3]]=s end })
    end
end

do
    local SV = Tabs.ServerTab
    SV:AddSection("Server")
    SV:AddButton({ Title="Rejoin", Callback=function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end})
    SV:AddButton({ Title="Server Hop", Callback=function()
        pcall(function()
            local m = loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/raw-scriptpastebin/FE/main/Server_Hop_Settings"))()
            m:Teleport(game.PlaceId)
        end)
    end})

    UI.JobIdPara = SV:AddParagraph({ Title = "Job ID", Content = game.JobId })

    UI.EnterJobId = SV:AddInput("EnterJobId", {
        Title       = "Enter Job ID",
        Placeholder = "Paste Job ID here…",
        Default     = "",
        Callback    = function(v) _G.JobId = v end,
    })

    SV:AddButton({ Title="Join Job ID", Callback=function()
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, _G.JobId)
        end)
    end})
end

do
    local SS = Tabs.SeaSettings
    SS:AddSection("Sea Skills")
    UI.SeaLightning = SS:AddToggle("SeaLightning", {
        Title    = "Lightning",
        Default  = false,
        Callback = function(s) _G.Settings.SettingSea["Lightning"] = s end,
    })
    UI.IncreaseBoatSpeed = SS:AddToggle("IncreaseBoatSpeed", {
        Title    = "Increase Boat Speed",
        Default  = false,
        Callback = function(s) _G.Settings.SettingSea["Increase Boat Speed"] = s end,
    })
    UI.NoClipRock = SS:AddToggle("NoClipRock", {
        Title    = "No Clip Rock",
        Default  = false,
        Callback = function(s) _G.Settings.SettingSea["No Clip Rock"] = s end,
    })

    SS:AddSection("Skill Toggles")
    local seaSkillToggles = {
        {"SeaUseDF",      "Use Devil Fruit Skill",  "Use Devil Fruit Skill"},
        {"SeaUseMelee",   "Use Melee Skill",         "Use Melee Skill"},
        {"SeaUseSword",   "Use Sword Skill",         "Use Sword Skill"},
        {"SeaUseGun",     "Use Gun Skill",           "Use Gun Skill"},
        {"SeaDFZ",        "Devil Fruit Z Skill",     "Devil Fruit Z Skill"},
        {"SeaDFX",        "Devil Fruit X Skill",     "Devil Fruit X Skill"},
        {"SeaDFC",        "Devil Fruit C Skill",     "Devil Fruit C Skill"},
        {"SeaDFV",        "Devil Fruit V Skill",     "Devil Fruit V Skill"},
        {"SeaDFF",        "Devil Fruit F Skill",     "Devil Fruit F Skill"},
        {"SeaMeleeZ",     "Melee Z Skill",           "Melee Z Skill"},
        {"SeaMeleeX",     "Melee X Skill",           "Melee X Skill"},
        {"SeaMeleeC",     "Melee C Skill",           "Melee C Skill"},
        {"SeaMeleeV",     "Melee V Skill",           "Melee V Skill"},
    }
    for _, t in pairs(seaSkillToggles) do
        local def = not (t[1] == "SeaDFV" or t[1] == "SeaDFF")
        UI[t[1]] = SS:AddToggle(t[1], { Title = t[2], Default = def,
            Callback = function(s) _G.Settings.SettingSea[t[3]] = s end })
    end

    SS:AddSection("Sea Stack")
    UI.TweenToFrozen = SS:AddToggle("TweenToFrozen", {
        Title    = "Tween To Frozen Dimension",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Tween To Frozen Dimension"] = s end,
    })
    UI.SummonFrozen = SS:AddToggle("SummonFrozen", {
        Title    = "Summon Frozen Dimension",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Summon Frozen Dimension"] = s end,
    })
    UI.TweenToKitsune = SS:AddToggle("TweenToKitsune", {
        Title    = "Tween To Kitsune Island",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Tween To Kitsune Island"] = s end,
    })
    UI.SummonKitsune = SS:AddToggle("SummonKitsune", {
        Title    = "Summon Kitsune Island",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Summon Kitsune Island"] = s end,
    })
    UI.AutoCollectAzure = SS:AddToggle("AutoCollectAzure", {
        Title    = "Auto Collect Azure Ember",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Auto Collect Azure Ember"] = s end,
    })
    UI.SetAzureEmber = SS:AddSlider("SetAzureEmber", {
        Title = "Set Azure Ember", Min = 1, Max = 50, Default = 20, Rounding = 0,
        Callback = function(v) _G.Settings.SeaStack["Set Azure Ember"] = v end,
    })
    UI.AutoTradeAzure = SS:AddToggle("AutoTradeAzure", {
        Title    = "Auto Trade Azure Ember",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Auto Trade Azure Ember"] = s end,
    })
    UI.TweenToMirageIsland = SS:AddToggle("TweenToMirageIsland", {
        Title    = "Tween To Mirage Island",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Tween To Mirage Island"] = s end,
    })
    UI.TeleportToAdvDealer = SS:AddToggle("TeleportToAdvDealer", {
        Title    = "Teleport To Advanced Fruit Dealer",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Teleport To Advanced Fruit Dealer"] = s end,
    })
    UI.AutoAttackSeabeasts = SS:AddToggle("AutoAttackSeabeasts", {
        Title    = "Auto Attack Seabeasts",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Auto Attack Seabeasts"] = s end,
    })
    UI.SummonPrehistoric = SS:AddToggle("SummonPrehistoric", {
        Title    = "Summon Prehistoric Island",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Summon Prehistoric Island"] = s end,
    })
    UI.TweenToPrehistoric = SS:AddToggle("TweenToPrehistoric", {
        Title    = "Tween To Prehistoric Island",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Tween To Prehistoric Island"] = s end,
    })
    UI.AutoKillLavaGolem = SS:AddToggle("AutoKillLavaGolem", {
        Title    = "Auto Kill Lava Golem",
        Default  = false,
        Callback = function(s) _G.Settings.SeaStack["Auto Kill Lava Golem"] = s end,
    })

    SS:AddSection("Dodge")
    UI.DodgeSeabeasts = SS:AddToggle("DodgeSeabeasts", {
        Title    = "Dodge Seabeasts Attack",
        Default  = true,
        Callback = function(s) _G.Settings.SeaEvent["Dodge Seabeasts Attack"] = s end,
    })
    UI.DodgeTerrorshark = SS:AddToggle("DodgeTerrorshark", {
        Title    = "Dodge Terrorshark Attack",
        Default  = true,
        Callback = function(s) _G.Settings.SeaEvent["Dodge Terrorshark Attack"] = s end,
    })
end

do
    local DD = Tabs.DragonDojo
    DD:AddSection("Dragon Dojo")
    DD:AddParagraph({ Title = "Dragon Dojo - Auto Ember Farm", Content = "Farms Blaze Embers in Dragon Dojo area" })
    UI.AutoFarmBlazeEmber = DD:AddToggle("AutoFarmBlazeEmber", {
        Title    = "Auto Farm Blaze Ember",
        Default  = false,
        Callback = function(s) _G.Settings.DragonDojo["Auto Farm Blaze Ember"] = s end,
    })
    UI.AutoCollectBlaze = DD:AddToggle("AutoCollectBlaze", {
        Title    = "Auto Collect Blaze Ember",
        Default  = false,
        Callback = function(s) _G.Settings.DragonDojo["Auto Collect Blaze Ember"] = s end,
    })
    DD:AddButton({ Title = "Teleport To Dragon Dojo", Callback = function()
        TweenPlayer(CFrame.new(5743.31, 1206.90, 936.01))
    end})
end

do
    local ET = Tabs.ESPTab
    ET:AddSection("ESP Toggles")
    local espToggles = {
        {"EspPlayer",     "ESP Player",     "ESP Player"},
        {"EspChest",      "ESP Chest",      "ESP Chest"},
        {"EspDevilFruit", "ESP Devil Fruit", "ESP DevilFruit"},
        {"EspRealFruit",  "ESP Real Fruit",  "ESP RealFruit"},
        {"EspFlower",     "ESP Flower",      "ESP Flower"},
        {"EspIsland",     "ESP Island",      "ESP Island"},
        {"EspNpc",        "ESP NPC",         "ESP Npc"},
        {"EspSeaBeast",   "ESP Sea Beast",   "ESP Sea Beast"},
        {"EspMonster",    "ESP Monster",     "ESP Monster"},
        {"EspMirage",     "ESP Mirage",      "ESP Mirage"},
        {"EspKitsune",    "ESP Kitsune",     "ESP Kitsune"},
        {"EspFrozen",     "ESP Frozen",      "ESP Frozen"},
        {"EspGear",       "ESP Gear",        "ESP Gear"},
        {"EspAdvDealer",  "ESP Adv. Fruit Dealer", "ESP Advanced Fruit Dealer"},
        {"EspAura",       "ESP Aura Dealer",       "ESP Aura"},
        {"EspPrehistoric","ESP Prehistoric",       "ESP Prehistoric"},
    }
    for _, t in pairs(espToggles) do
        UI[t[1]] = ET:AddToggle(t[1], { Title = t[2], Default = false,
            Callback = function(s) _G.Settings.Esp[t[3]] = s end })
    end
end

do
    local PvP = Tabs.PvP
    PvP:AddSection("Aimbot & Kill")
    UI.AimbotGun = PvP:AddToggle("AimbotGun", {
        Title    = "Aimbot Gun",
        Default  = false,
        Callback = function(s) _G.Settings.Combat["Aimbot Gun"] = s end,
    })
    UI.AimbotSkillNearest = PvP:AddToggle("AimbotSkillNearest", {
        Title    = "Aimbot Skill Nearest",
        Default  = false,
        Callback = function(s) _G.Settings.Combat["Aimbot Skill Nearest"] = s end,
    })
    UI.AimbotSkill = PvP:AddToggle("AimbotSkill", {
        Title    = "Aimbot Skill",
        Default  = false,
        Callback = function(s) _G.Settings.Combat["Aimbot Skill"] = s end,
    })
    UI.AutoKillPlayerQuest = PvP:AddToggle("AutoKillPlayerQuest", {
        Title    = "Auto Kill Player Quest",
        Default  = false,
        Callback = function(s) _G.Settings.Combat["Auto Kill Player Quest"] = s end,
    })
end

do
    local DI = Tabs.Display
    DI:AddSection("UI Tweaks")
    UI.HideChat = DI:AddToggle("HideChat", {
        Title    = "Hide Chat",
        Default  = false,
        Callback = function(s) _G.Settings.Misc["Hide Chat"] = s end,
    })
    UI.HideLeaderboard = DI:AddToggle("HideLeaderboard", {
        Title    = "Hide Leaderboard",
        Default  = false,
        Callback = function(s) _G.Settings.Misc["Hide Leaderboard"] = s end,
    })
    UI.HighlightMode = DI:AddToggle("HighlightMode", {
        Title    = "Highlight Mode",
        Default  = false,
        Callback = function(s) _G.Settings.Misc["Highlight Mode"] = s end,
    })
end

task.spawn(function()
    while task.wait(1) do
        for _, v in pairs(workspace._WorldOrigin.Locations:GetChildren()) do
            pcall(function()
                if _G.Settings.Esp["ESP Island"] then
                    if v.Name ~= "Sea" then
                        if not v:FindFirstChild("EspIsland") then
                            local bill = Instance.new("BillboardGui", v)
                            bill.Name = "EspIsland"
                            bill.ExtentsOffset = Vector3.new(0, 1, 0)
                            bill.Size = UDim2.new(0, 200, 0, 30)
                            bill.Adornee = v
                            bill.AlwaysOnTop = true
                            local name = Instance.new("TextLabel", bill)
                            name.Font = Enum.Font.GothamMedium
                            name.TextSize = 14
                            name.TextWrapped = true
                            name.Size = UDim2.new(1, 0, 1, 0)
                            name.TextYAlignment = Enum.TextYAlignment.Top
                            name.BackgroundTransparency = 1
                            name.TextColor3 = Color3.fromRGB(255, 255, 255)
                        else
                            v.EspIsland.TextLabel.Text = v.Name .. "   \n" .. math.floor((LP.Character.Head.Position - v.Position).Magnitude / 3) .. " Distance"
                        end
                    end
                elseif v:FindFirstChild("EspIsland") then
                    v.EspIsland:Destroy()
                end
            end)
        end
    end
end)

task.spawn(function()
    local espNum = State.EspNum
    while task.wait(1) do
        for _, v in pairs(Players:GetChildren()) do
            pcall(function()
                if v.Character and v.Character:FindFirstChild("Head") then
                    if _G.Settings.Esp["ESP Player"] then
                        if not v.Character.Head:FindFirstChild("EspPlayer" .. espNum) then
                            local bill = Instance.new("BillboardGui", v.Character.Head)
                            bill.Name = "EspPlayer" .. espNum
                            bill.ExtentsOffset = Vector3.new(0, 1, 0)
                            bill.Size = UDim2.new(1, 200, 1, 30)
                            bill.Adornee = v.Character.Head
                            bill.AlwaysOnTop = true
                            local name = Instance.new("TextLabel", bill)
                            name.Font = Enum.Font.GothamSemibold
                            name.FontSize = "Size14"
                            name.TextWrapped = true
                            name.Size = UDim2.new(1, 0, 1, 0)
                            name.TextYAlignment = "Top"
                            name.BackgroundTransparency = 1
                            name.TextStrokeTransparency = 0.5
                            if v.Team == LP.Team then
                                name.TextColor3 = Color3.fromRGB(50, 200, 50)
                            else
                                name.TextColor3 = Color3.fromRGB(200, 50, 50)
                            end
                        else
                            local d = math.floor((LP.Character.Head.Position - v.Character.Head.Position).Magnitude / 3)
                            local hp = math.floor(v.Character.Humanoid.Health * 100 / v.Character.Humanoid.MaxHealth)
                            v.Character.Head["EspPlayer" .. espNum].TextLabel.Text = v.Name .. " | " .. d .. " Dist\nHP: " .. hp .. "%"
                        end
                    elseif v.Character.Head:FindFirstChild("EspPlayer" .. espNum) then
                        v.Character.Head["EspPlayer" .. espNum]:Destroy()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    local espNum = State.EspNum
    while task.wait(1) do
        for _, v in pairs(workspace.ChestModels:GetChildren()) do
            pcall(function()
                if string.find(v.Name, "Chest") and v:FindFirstChild("RootPart") then
                    if _G.Settings.Esp["ESP Chest"] then
                        if not v:FindFirstChild("EspChest" .. espNum) then
                            local bill = Instance.new("BillboardGui", v)
                            bill.Name = "EspChest" .. espNum
                            bill.ExtentsOffset = Vector3.new(0, 1, 0)
                            bill.Size = UDim2.new(1, 200, 1, 30)
                            bill.Adornee = v
                            bill.AlwaysOnTop = true
                            local name = Instance.new("TextLabel", bill)
                            name.Font = Enum.Font.Nunito
                            name.FontSize = "Size14"
                            name.TextWrapped = true
                            name.Size = UDim2.new(1, 0, 1, 0)
                            name.TextYAlignment = "Top"
                            name.BackgroundTransparency = 1
                            name.TextStrokeTransparency = 0.5
                            if v.Name == "SilverChest" then
                                name.TextColor3 = Color3.fromRGB(109, 109, 109)
                                name.Text = "Silver Chest\n" .. math.floor((LP.Character.Head.Position - v.RootPart.Position).Magnitude / 3) .. " Distance"
                            elseif v.Name == "GoldChest" then
                                name.TextColor3 = Color3.fromRGB(173, 158, 21)
                                name.Text = "Gold Chest\n" .. math.floor((LP.Character.Head.Position - v.RootPart.Position).Magnitude / 3) .. " Distance"
                            elseif v.Name == "DiamondChest" then
                                name.TextColor3 = Color3.fromRGB(20, 200, 200)
                                name.Text = "Diamond Chest\n" .. math.floor((LP.Character.Head.Position - v.RootPart.Position).Magnitude / 3) .. " Distance"
                            end
                        else
                            v["EspChest" .. espNum].TextLabel.Text = v.Name .. "   \n" .. math.floor((LP.Character.Head.Position - v.RootPart.Position).Magnitude / 3) .. " Distance"
                        end
                    elseif v:FindFirstChild("EspChest" .. espNum) then
                        v["EspChest" .. espNum]:Destroy()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    local espNum = State.EspNum
    while task.wait(1) do
        for _, folder in pairs({workspace, workspace._WorldOrigin}) do
            for _, v in pairs(folder:GetChildren()) do
                pcall(function()
                    if v:IsA("Tool") and v.Name and string.find(v.Name, "Fruit") and v:FindFirstChild("Handle") then
                        if _G.Settings.Esp["ESP DevilFruit"] then
                            if not v.Handle:FindFirstChild("EspDevilFruit" .. espNum) then
                                local bill = Instance.new("BillboardGui", v.Handle)
                                bill.Name = "EspDevilFruit" .. espNum
                                bill.ExtentsOffset = Vector3.new(0, 1, 0)
                                bill.Size = UDim2.new(1, 200, 1, 30)
                                bill.Adornee = v.Handle
                                bill.AlwaysOnTop = true
                                local name = Instance.new("TextLabel", bill)
                                name.Font = Enum.Font.GothamSemibold
                                name.FontSize = "Size14"
                                name.TextWrapped = true
                                name.Size = UDim2.new(1, 0, 1, 0)
                                name.TextYAlignment = "Top"
                                name.BackgroundTransparency = 1
                                name.TextStrokeTransparency = 0.5
                                name.TextColor3 = Color3.fromRGB(255, 255, 255)
                                local prefix = (folder == workspace._WorldOrigin) and "(SPAWNED)" or ""
                                name.Text = v.Name .. prefix .. "\n" .. math.floor((LP.Character.Head.Position - v.Handle.Position).Magnitude / 3) .. " Distance"
                                local TweenService = game:GetService("TweenService")
                                local rainbowColors = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 127, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255), Color3.fromRGB(75, 0, 130), Color3.fromRGB(148, 0, 211)}
                                local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
                                coroutine.wrap(function()
                                    -- FIX: this previously ran forever even after the fruit despawned
                                    -- and its TextLabel was destroyed, leaking one permanent coroutine
                                    -- per fruit spawn for the rest of the session. Now it checks
                                    -- name.Parent each cycle and exits cleanly once destroyed.
                                    while name and name.Parent do
                                        for _, color in ipairs(rainbowColors) do
                                            if not (name and name.Parent) then return end
                                            local tween = TweenService:Create(name, tweenInfo, {TextColor3 = color})
                                            tween:Play()
                                            tween.Completed:Wait()
                                        end
                                    end
                                end)()
                            else
                                v.Handle["EspDevilFruit" .. espNum].TextLabel.Text = v.Name .. "\n" .. math.floor((LP.Character.Head.Position - v.Handle.Position).Magnitude / 3) .. " Distance"
                            end
                        end
                    elseif v:FindFirstChild("Handle") and v.Handle:FindFirstChild("EspDevilFruit" .. espNum) then
                        v.Handle["EspDevilFruit" .. espNum]:Destroy()
                    end
                end)
            end
        end
    end
end)

task.spawn(function()
    local espNum = State.EspNum
    while task.wait(1) do
        for _, spawner in pairs({workspace:FindFirstChild("AppleSpawner"), workspace:FindFirstChild("PineappleSpawner"), workspace:FindFirstChild("BananaSpawner")}) do
            if spawner then
                for _, v in pairs(spawner:GetChildren()) do
                    pcall(function()
                        if v:IsA("Tool") and v:FindFirstChild("Handle") then
                            if _G.Settings.Esp["ESP RealFruit"] then
                                if not v.Handle:FindFirstChild("EspRealFruit" .. espNum) then
                                    local bill = Instance.new("BillboardGui", v.Handle)
                                    bill.Name = "EspRealFruit" .. espNum
                                    bill.ExtentsOffset = Vector3.new(0, 1, 0)
                                    bill.Size = UDim2.new(1, 200, 1, 30)
                                    bill.Adornee = v.Handle
                                    bill.AlwaysOnTop = true
                                    local name = Instance.new("TextLabel", bill)
                                    name.Font = Enum.Font.GothamSemibold
                                    name.FontSize = "Size14"
                                    name.TextWrapped = true
                                    name.Size = UDim2.new(1, 0, 1, 0)
                                    name.TextYAlignment = "Top"
                                    name.BackgroundTransparency = 1
                                    name.TextStrokeTransparency = 0.5
                                    name.TextColor3 = Color3.fromRGB(255, 170, 0)
                                    name.Text = v.Name .. "\n" .. math.floor((LP.Character.Head.Position - v.Handle.Position).Magnitude / 3) .. " Distance"
                                else
                                    v.Handle["EspRealFruit" .. espNum].TextLabel.Text = v.Name .. " " .. math.floor((LP.Character.Head.Position - v.Handle.Position).Magnitude / 3) .. " Distance"
                                end
                            elseif v.Handle:FindFirstChild("EspRealFruit" .. espNum) then
                                v.Handle["EspRealFruit" .. espNum]:Destroy()
                            end
                        end
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    local espNum = State.EspNum
    while task.wait(1) do
        for _, v in pairs(workspace:GetChildren()) do
            pcall(function()
                if v.Name == "Flower2" or v.Name == "Flower1" then
                    if _G.Settings.Esp["ESP Flower"] then
                        if not v:FindFirstChild("EspFlower" .. espNum) then
                            local bill = Instance.new("BillboardGui", v)
                            bill.Name = "EspFlower" .. espNum
                            bill.ExtentsOffset = Vector3.new(0, 1, 0)
                            bill.Size = UDim2.new(1, 200, 1, 30)
                            bill.Adornee = v
                            bill.AlwaysOnTop = true
                            local name = Instance.new("TextLabel", bill)
                            name.Font = Enum.Font.GothamSemibold
                            name.FontSize = "Size14"
                            name.TextWrapped = true
                            name.Size = UDim2.new(1, 0, 1, 0)
                            name.TextYAlignment = "Top"
                            name.BackgroundTransparency = 1
                            name.TextStrokeTransparency = 0.5
                            if v.Name == "Flower1" then
                                name.Text = "Blue Flower\n" .. math.floor((LP.Character.Head.Position - v.Position).Magnitude / 3) .. " Distance"
                                name.TextColor3 = Color3.fromRGB(40, 40, 255)
                            elseif v.Name == "Flower2" then
                                name.Text = "Red Flower\n" .. math.floor((LP.Character.Head.Position - v.Position).Magnitude / 3) .. " Distance"
                                name.TextColor3 = Color3.fromRGB(255, 100, 100)
                            end
                        else
                            v["EspFlower" .. espNum].TextLabel.Text = v.Name .. "   \n" .. math.floor((LP.Character.Head.Position - v.Position).Magnitude / 3) .. " Distance"
                        end
                    elseif v:FindFirstChild("EspFlower" .. espNum) then
                        v["EspFlower" .. espNum]:Destroy()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if _G.Settings.Esp["ESP Monster"] then
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("HumanoidRootPart") then
                        if not v:FindFirstChild("EspMonster") then
                            local bg = Instance.new("BillboardGui")
                            local tl = Instance.new("TextLabel")
                            bg.Parent = v
                            bg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                            bg.Active = true
                            bg.Name = "EspMonster"
                            bg.AlwaysOnTop = true
                            bg.LightInfluence = 1
                            bg.Size = UDim2.new(0, 200, 0, 50)
                            bg.StudsOffset = Vector3.new(0, 2.5, 0)
                            tl.Parent = bg
                            tl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            tl.BackgroundTransparency = 1
                            tl.Size = UDim2.new(0, 200, 0, 50)
                            tl.Font = Enum.Font.GothamBold
                            tl.TextColor3 = Color3.fromRGB(120, 130, 230)
                            tl.Text.Size = 35
                        end
                        local d = math.floor((LP.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude)
                        v.EspMonster.TextLabel.Text = v.Name .. " - " .. d .. " Distance"
                    end
                end
            else
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("EspMonster") then v.EspMonster:Destroy() end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if _G.Settings.Esp["ESP Sea Beast"] then
                for _, v in pairs(workspace.SeaBeasts:GetChildren()) do
                    if v:FindFirstChild("HumanoidRootPart") then
                        if not v:FindFirstChild("EspSeabeasts") then
                            local bg = Instance.new("BillboardGui")
                            local tl = Instance.new("TextLabel")
                            bg.Parent = v
                            bg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                            bg.Active = true
                            bg.Name = "EspSeabeasts"
                            bg.AlwaysOnTop = true
                            bg.LightInfluence = 1
                            bg.Size = UDim2.new(0, 200, 0, 50)
                            bg.StudsOffset = Vector3.new(0, 2.5, 0)
                            tl.Parent = bg
                            tl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            tl.BackgroundTransparency = 1
                            tl.Size = UDim2.new(0, 200, 0, 50)
                            tl.Font = Enum.Font.Gotham
                            tl.TextColor3 = Color3.fromRGB(60, 240, 120)
                            tl.Text.Size = 35
                        end
                        local d = math.floor((LP.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude)
                        v.EspSeabeasts.TextLabel.Text = v.Name .. " - " .. d .. " Distance"
                    end
                end
            else
                for _, v in pairs(workspace.SeaBeasts:GetChildren()) do
                    if v:FindFirstChild("EspSeabeasts") then v.EspSeabeasts:Destroy() end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if _G.Settings.Esp["ESP Npc"] then
                for _, v in pairs(workspace.NPCs:GetChildren()) do
                    if v:FindFirstChild("HumanoidRootPart") then
                        if not v:FindFirstChild("EspNpc") then
                            local bg = Instance.new("BillboardGui")
                            local tl = Instance.new("TextLabel")
                            bg.Parent = v
                            bg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                            bg.Active = true
                            bg.Name = "EspNpc"
                            bg.AlwaysOnTop = true
                            bg.LightInfluence = 1
                            bg.Size = UDim2.new(0, 200, 0, 50)
                            bg.StudsOffset = Vector3.new(0, 2.5, 0)
                            tl.Parent = bg
                            tl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            tl.BackgroundTransparency = 1
                            tl.Size = UDim2.new(0, 200, 0, 50)
                            tl.Font = Enum.Font.Cartoon
                            tl.TextColor3 = Color3.fromRGB(200, 60, 120)
                            tl.Text.Size = 45
                        end
                        local d = math.floor((LP.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude)
                        v.EspNpc.TextLabel.Text = v.Name .. " - " .. d .. " Distance"
                    end
                end
            else
                for _, v in pairs(workspace.NPCs:GetChildren()) do
                    if v:FindFirstChild("EspNpc") then v.EspNpc:Destroy() end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        local locs = workspace._WorldOrigin.Locations
        local function espLocation(name, espKey, tagName, color)
            for _, v in pairs(locs:GetChildren()) do
                pcall(function()
                    if v.Name == name then
                        if _G.Settings.Esp[espKey] then
                            if not v:FindFirstChild(tagName) then
                                local bill = Instance.new("BillboardGui", v)
                                bill.Name = tagName
                                bill.ExtentsOffset = Vector3.new(0, 1, 0)
                                bill.Size = UDim2.new(1, 200, 1, 30)
                                bill.Adornee = v
                                bill.AlwaysOnTop = true
                                local nameLbl = Instance.new("TextLabel", bill)
                                nameLbl.Font = "Code"
                                nameLbl.FontSize = "Size14"
                                nameLbl.TextWrapped = true
                                nameLbl.Size = UDim2.new(1, 0, 1, 0)
                                nameLbl.TextYAlignment = "Top"
                                nameLbl.BackgroundTransparency = 1
                                nameLbl.TextStrokeTransparency = 0.5
                                nameLbl.TextColor3 = color
                            else
                                v[tagName].TextLabel.Text = v.Name .. "   \n" .. math.floor((LP.Character.Head.Position - v.Position).Magnitude / 3) .. " M"
                            end
                        elseif v:FindFirstChild(tagName) then
                            v[tagName]:Destroy()
                        end
                    end
                end)
            end
        end
        espLocation("Mirage Island", "ESP Mirage", "EspMirageIsland", Color3.fromRGB(50, 180, 50))
        espLocation("Kitsune Island", "ESP Kitsune", "EspKitsuneIsland", Color3.fromRGB(40, 40, 180))
        espLocation("Frozen Dimension", "ESP Frozen", "EspFrozen", Color3.fromRGB(50, 180, 255))
        espLocation("Prehistoric Island", "ESP Prehistoric", "EspPrehistoric", Color3.fromRGB(200, 50, 40))
    end
end)

task.spawn(function()
    while task.wait(1) do
        for _, v in pairs(workspace.NPCs:GetChildren()) do
            pcall(function()
                if v.Name == "Advanced Fruit Dealer" then
                    if _G.Settings.Esp["ESP Advanced Fruit Dealer"] then
                        if not v:FindFirstChild("EspAdvanceFruitDealer") then
                            local bill = Instance.new("BillboardGui", v)
                            bill.Name = "EspAdvanceFruitDealer"
                            bill.ExtentsOffset = Vector3.new(0, 1, 0)
                            bill.Size = UDim2.new(1, 200, 1, 30)
                            bill.Adornee = v
                            bill.AlwaysOnTop = true
                            local name = Instance.new("TextLabel", bill)
                            name.Font = "Code"
                            name.FontSize = "Size14"
                            name.TextWrapped = true
                            name.Size = UDim2.new(1, 0, 1, 0)
                            name.TextYAlignment = "Top"
                            name.BackgroundTransparency = 1
                            name.TextStrokeTransparency = 0.5
                            name.TextColor3 = Color3.fromRGB(250, 50, 50)
                        else
                            v.EspAdvanceFruitDealer.TextLabel.Text = v.Name .. "   \n" .. math.floor((LP.Character.Head.Position - v.Position).Magnitude / 3) .. " M"
                        end
                    elseif v:FindFirstChild("EspAdvanceFruitDealer") then
                        v.EspAdvanceFruitDealer:Destroy()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        for _, v in pairs(workspace.NPCs:GetChildren()) do
            pcall(function()
                if v.Name == "Master of Enhancement" then
                    if _G.Settings.Esp["ESP Aura"] then
                        if not v:FindFirstChild("EspAura") then
                            local bill = Instance.new("BillboardGui", v)
                            bill.Name = "EspAura"
                            bill.ExtentsOffset = Vector3.new(0, 1, 0)
                            bill.Size = UDim2.new(1, 200, 1, 30)
                            bill.Adornee = v
                            bill.AlwaysOnTop = true
                            local name = Instance.new("TextLabel", bill)
                            name.Font = "Code"
                            name.FontSize = "Size14"
                            name.TextWrapped = true
                            name.Size = UDim2.new(1, 0, 1, 0)
                            name.TextYAlignment = "Top"
                            name.BackgroundTransparency = 1
                            name.TextStrokeTransparency = 0.5
                            name.TextColor3 = Color3.fromRGB(200, 55, 255)
                        else
                            v.EspAura.TextLabel.Text = v.Name .. "   \n" .. math.floor((LP.Character.Head.Position - v.Position).Magnitude / 3) .. " M"
                        end
                    elseif v:FindFirstChild("EspAura") then
                        v.EspAura:Destroy()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        local mystic = workspace.Map:FindFirstChild("MysticIsland")
        if mystic then
            for _, v in pairs(mystic:GetChildren()) do
                pcall(function()
                    if v.Name == "MeshPart" then
                        if _G.Settings.Esp["ESP Gear"] then
                            if not v:FindFirstChild("EspGear") then
                                local bill = Instance.new("BillboardGui", v)
                                bill.Name = "EspGear"
                                bill.ExtentsOffset = Vector3.new(0, 1, 0)
                                bill.Size = UDim2.new(1, 200, 1, 30)
                                bill.Adornee = v
                                bill.AlwaysOnTop = true
                                local name = Instance.new("TextLabel", bill)
                                name.Font = "Code"
                                name.FontSize = "Size14"
                                name.TextWrapped = true
                                name.Size = UDim2.new(1, 0, 1, 0)
                                name.TextYAlignment = "Top"
                                name.BackgroundTransparency = 1
                                name.TextStrokeTransparency = 0.5
                                name.TextColor3 = Color3.fromRGB(80, 245, 245)
                            else
                                v.EspGear.TextLabel.Text = "Gear   \n" .. math.floor((LP.Character.Head.Position - v.Position).Magnitude / 3) .. " M"
                            end
                        elseif v:FindFirstChild("EspGear") then
                            v.EspGear:Destroy()
                        end
                    end
                end)
            end
        end
    end
end)

task.spawn(function()
    local function checkEyes()
        local island = workspace.Map:FindFirstChild("TikiOutpost")
        if not island then return false end
        local model = island:FindFirstChild("IslandModel")
        if not model then return false end
        for _, name in pairs({"Eye1","Eye2","Eye3","Eye4"}) do
            local e = model:FindFirstChild(name)
            if not e or e.Transparency ~= 0 then return false end
        end
        return true
    end

    while task.wait(0.2) do
        if _G.Settings.Main["Auto Summon Tyrant Of The Skies"] and World3 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Tyrant of the Skies") then return end
                if not checkEyes() then
                    local valid = {"Serpent Hunter","Skull Slayer","Isle Champion","Sun-kissed Warrior"}
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if table.find(valid, v.Name) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            FarmMob(v, "Auto Summon Tyrant Of The Skies", checkEyes)
                        end
                    end
                else
                    local island = workspace.Map.TikiOutpost.IslandModel
                    for _, m in pairs(island:GetChildren()) do
                        if m:FindFirstChild("EagleBossArena") then
                            for _, tree in pairs(m.EagleBossArena:GetChildren()) do
                                if tree.Name == "Tree" then TweenPlayer(tree.WorldPivot) end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Main["Auto Kill Tyrant Of The Skies"] then
            pcall(function()
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v.Name == "Tyrant of the Skies" then
                        FarmMob(v, "Auto Kill Tyrant Of The Skies")
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Elite Hunter"] and World3 then
            pcall(function()
                local elites = {"Diablo","Deandre","Urban"}
                local found  = false
                for _, n in pairs(elites) do
                    if workspace.Enemies:FindFirstChild(n) or RepStore:FindFirstChild(n) then found=true break end
                end
                if not found then return end

                local QUI  = LP.PlayerGui.Main.Quest
                if not QUI.Visible then
                    local npcCF = CFrame.new(-5418.89,313.74,-2826.22)
                    TweenPlayer(npcCF)
                    if (npcCF.Position - GetHRP().Position).Magnitude <= 3 then
                        CommF_:InvokeServer("EliteHunter")
                    end
                else
                    local qt = QUI.Container.QuestTitle.Title.Text
                    if string.find(qt,"Diablo") or string.find(qt,"Deandre") or string.find(qt,"Urban") then
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if table.find(elites, v.Name) then
                                FarmMob(v, "Auto Elite Hunter")
                            end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Elite Hunter Hop"] and World3 and _G.Settings.Farm["Auto Elite Hunter"] then
            pcall(function()
                local none = not workspace.Enemies:FindFirstChild("Diablo")
                    and not workspace.Enemies:FindFirstChild("Deandre")
                    and not workspace.Enemies:FindFirstChild("Urban")
                if none then
                    local m = loadstring(game:HttpGet(
                        "https://raw.githubusercontent.com/raw-scriptpastebin/FE/main/Server_Hop_Settings"))()
                    m:Teleport(game.PlaceId)
                end
            end)
        end
    end
end)

task.spawn(function()
    local boneNames = {"Reborn Skeleton","Living Zombie","Demonic Soul","Posessed Mummy"}
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Farm Bone"] and World3
            and _G.Settings.Farm["Selected Bone Farm Method"] == "No Quest" then
            pcall(function()
                local any = false
                for _, n in pairs(boneNames) do if workspace.Enemies:FindFirstChild(n) then any=true break end end
                if any then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if table.find(boneNames, v.Name) then FarmMob(v,"Auto Farm Bone") end
                    end
                else
                    TweenPlayer(CFrame.new(-9506.23,172.13,6117.07))
                end
            end)
        end
    end
end)

task.spawn(function()
    local boneNames = {"Reborn Skeleton","Living Zombie","Demonic Soul","Posessed Mummy"}
    local boneQuestCF = CFrame.new(-9516.99,172.01,6078.46)
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Farm Bone"] and World3
            and _G.Settings.Farm["Selected Bone Farm Method"] == "Quest" then
            pcall(function()
                local QUI = LP.PlayerGui.Main.Quest
                local qt  = QUI.Container.QuestTitle.Title.Text
                if not string.find(qt,"Demonic Soul") then CommF_:InvokeServer("AbandonQuest") end
                if not QUI.Visible then
                    TweenPlayer(boneQuestCF)
                    if (boneQuestCF.Position - GetHRP().Position).Magnitude <= 3 then
                        CommF_:InvokeServer("StartQuest","HauntedQuest2",1)
                    end
                else
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if table.find(boneNames, v.Name)
                            and string.find(QUI.Container.QuestTitle.Title.Text,"Demonic Soul") then
                            FarmMob(v,"Auto Farm Bone", function() return not QUI.Visible end)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Random Surprise"] and World3 then
            pcall(function() CommF_:InvokeServer("Bones","Buy",1,1) end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Farm Chest Tween"] then
            pcall(function()
                for _, v in pairs(workspace.ChestModels:GetChildren()) do
                    if v.Name:find("Chest") and v:FindFirstChild("RootPart") then
                        repeat
                            task.wait()
                            TweenPlayer(v.RootPart.CFrame)
                        until not _G.Settings.Farm["Auto Farm Chest Tween"] or (not v.Parent)
                        TweenPlayer(GetHRP().CFrame)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Farm Chest Instant"] then
            pcall(function()
                for _, v in pairs(workspace.ChestModels:GetChildren()) do
                    if v.Name:find("Chest") and v:FindFirstChild("RootPart") then
                        repeat
                            task.wait()
                            if v.Name == "DiamondChest" then
                                InstantTp(v.RootPart.CFrame)
                            elseif v.Name == "GoldChest" then
                                InstantTp(v.RootPart.CFrame)
                            elseif v.Name == "SilverChest" then
                                InstantTp(v.RootPart.CFrame)
                            end
                        until not _G.Settings.Farm["Auto Farm Chest Instant"] or (not v.Parent)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.Farm["Auto Stop Items"] then
            pcall(function()
                local bp, ch = LP.Backpack, LP.Character
                if (bp and (bp:FindFirstChild("God's Chalice") or bp:FindFirstChild("Fist of Darkness")))
                    or (ch and (ch:FindFirstChild("God's Chalice") or ch:FindFirstChild("Fist of Darkness"))) then
                    _G.Settings.Farm["Auto Farm Chest Tween"]   = false
                    _G.Settings.Farm["Auto Farm Chest Instant"] = false
                    UI.AutoChestTween:SetValue(false)
                    UI.AutoChestInstant:SetValue(false)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Rengoku"] and World2 then
            pcall(function()
                if LP.Backpack:FindFirstChild("Hidden Key") or LP.Character:FindFirstChild("Hidden Key") then
                    EquipWeapon("Hidden Key")
                    TweenPlayer(CFrame.new(6571.1201171875, 299.23028564453, -6967.841796875))
                elseif workspace.Enemies:FindFirstChild("Snow Lurker") or workspace.Enemies:FindFirstChild("Arctic Warrior") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if (v.Name == "Snow Lurker" or v.Name == "Arctic Warrior") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                AutoHaki()
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                State.PosMon = v.HumanoidRootPart.CFrame
                                State.MonFarm = v.Name
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until LP.Backpack:FindFirstChild("Hidden Key") or not _G.Settings.Items["Auto Rengoku"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    TweenPlayer(CFrame.new(5439.716796875, 84.420944213867, -6715.1635742188))
                end
            end)
            if not _G.Settings.Items["Auto Rengoku"] then
                State.MonFarm = ""
                State.PosMon  = CFrame.new()
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Spawn Cake Prince"] and World3 then
            task.wait(2)
            pcall(function() CommF_:InvokeServer("CakePrinceSpawner", true) end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Farm Katakuri"] and World3 then
            pcall(function()
                if RepStore:FindFirstChild("Cake Prince") or workspace.Enemies:FindFirstChild("Cake Prince") then
                    if workspace.Enemies:FindFirstChild("Cake Prince") then
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if v.Name == "Cake Prince" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                repeat
                                    RunSvc.Heartbeat:Wait()
                                    AutoHaki()
                                    EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                    v.Humanoid.WalkSpeed = 0
                                    v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                    TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                    RemoveAnimation(v)
                                until not _G.Settings.Farm["Auto Farm Katakuri"] or (not v.Parent) or v.Humanoid.Health <= 0
                            end
                        end
                    elseif workspace.Map.CakeLoaf.BigMirror.Other.Transparency == 0 and (CFrame.new(-1990.672607421875, 4532.99951171875, -14973.6748046875).Position - GetHRP().Position).Magnitude >= 2000 then
                        TweenPlayer(CFrame.new(-2151.82153, 149.315704, -12404.9053))
                    end
                elseif workspace.Enemies:FindFirstChild("Cookie Crafter") or workspace.Enemies:FindFirstChild("Cake Guard") or workspace.Enemies:FindFirstChild("Baking Staff") or workspace.Enemies:FindFirstChild("Head Baker") then
                    local cakeMobs = {"Cookie Crafter","Cake Guard","Baking Staff","Head Baker"}
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if table.find(cakeMobs, v.Name) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                State.PosMon = v.HumanoidRootPart.CFrame
                                State.MonFarm = v.Name
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Farm["Auto Farm Katakuri"] or (not v.Parent) or v.Humanoid.Health <= 0 or workspace.Map.CakeLoaf.BigMirror.Other.Transparency == 0 or RepStore:FindFirstChild("Cake Prince [Lv. 2300] [Raid Boss]") or workspace.Enemies:FindFirstChild("Cake Prince [Lv. 2300] [Raid Boss]")
                        end
                    end
                else
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                    TweenPlayer(CFrame.new(-2091.911865234375, 70.00884246826172, -12142.8359375))
                end
            end)
            if not _G.Settings.Farm["Auto Farm Katakuri"] then
                State.MonFarm = ""
                State.PosMon  = CFrame.new()
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Kill Cake Prince"] and World3 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Cake Prince") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Cake Prince" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                RemoveAnimation(v)
                                if v.Humanoid:FindFirstChild("Animator") then v.Humanoid.Animator:Destroy() end
                            until not _G.Settings.Farm["Auto Kill Cake Prince"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Kill Dough King"] and World3 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Dough King") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Dough King" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                RemoveAnimation(v)
                                if v.Humanoid:FindFirstChild("Animator") then v.Humanoid.Animator:Destroy() end
                            until not _G.Settings.Farm["Auto Kill Dough King"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Farm Material"] then
            pcall(function()
                getConfigMaterial(_G.Settings.Farm["Selected Material"])
                for _, mon in pairs(MaterialMon) do
                    if workspace.Enemies:FindFirstChild(mon) then
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if v.Name == mon and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                repeat
                                    RunSvc.Heartbeat:Wait()
                                    AutoHaki()
                                    EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                    State.PosMon = v.HumanoidRootPart.CFrame
                                    State.MonFarm = v.Name
                                    TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                until not _G.Settings.Farm["Auto Farm Material"] or (not v.Parent) or v.Humanoid.Health <= 0
                            end
                        end
                    else
                        UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                        local Distance = (MaterialPos.Position - GetHRP().Position).Magnitude
                        if Distance > 18000 and _G.Settings.Farm["Selected Material"] == "Ectoplasm" then
                            CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125))
                        end
                        TweenPlayer(MaterialPos)
                    end
                end
            end)
            if not _G.Settings.Farm["Auto Farm Material"] then
                State.MonFarm = ""
                State.PosMon  = CFrame.new()
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        local pt = _G.Settings.Stats["Point Stats"]
        if LP.Data.Points.Value >= pt then
            local statsMap = {
                ["Auto Add Melee Stats"]       = "Melee",
                ["Auto Add Defense Stats"]     = "Defense",
                ["Auto Add Sword Stats"]       = "Sword",
                ["Auto Add Gun Stats"]         = "Gun",
                ["Auto Add Devil Fruit Stats"] = "Demon Fruit",
            }
            for key, statName in pairs(statsMap) do
                if _G.Settings.Stats[key] then
                    pcall(function() CommF_:InvokeServer("AddPoint", statName, pt) end)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            LP.PlayerGui.Notifications.Enabled = not _G.Settings.Setting["Hide Notification"]
        end)
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            RepStore.Assets.GUI.DamageCounter.Enabled = not _G.Settings.Setting["Hide Damage Text"]
        end)
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            LP.PlayerGui.Main.Blackscreen.Size = _G.Settings.Setting["Black Screen"]
                and UDim2.new(500,0,500,500) or UDim2.new(1,0,500,500)
        end)
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            RunSvc:Set3dRenderingEnabled(not _G.Settings.Setting["White Screen"])
        end)
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            local plane = workspace.Map:FindFirstChild("WaterBase-Plane")
            if plane then
                plane.Size = _G.Settings.LocalPlayer["Walk On Water"]
                    and Vector3.new(1000,112,1000) or Vector3.new(1000,80,1000)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.Settings.LocalPlayer["Active Race V4"] then
            pcall(function()
                local re = LP.Character:WaitForChild("RaceEnergy",1)
                if re and tonumber(re.Value) == 1
                    and LP.Character.RaceTransformed.Value == false then
                    game:GetService("VirtualInputManager"):SendKeyEvent(true,"Y",false,game)
                    task.wait(0.1)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false,"Y",false,game)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if _G.Settings.Fruit["Fruit Notification"] then
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Tool") and v.Name:find("Fruit") then
                    Library:Notify({ Title = "Fruit Found!", Content = v.Name, Duration = 4 })
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Tool") and v.Name:find("Fruit") and v:FindFirstChild("Handle") then
                    if _G.Settings.Fruit["Teleport To Fruit"] then
                        GetHRP().CFrame = v.Handle.CFrame
                    elseif _G.Settings.Fruit["Tween To Fruit"] then
                        TweenPlayer(v.Handle.CFrame)
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Fruit["Auto Buy Random Fruit"] then
            pcall(function() CommF_:InvokeServer("Cousin","Buy") end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            LP.PlayerGui.Chat.Frame.Visible = not _G.Settings.Misc["Hide Chat"]
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if LP.PlayerGui:FindFirstChild("Main") and LP.PlayerGui.Main:FindFirstChild("Leaderboard") then
                LP.PlayerGui.Main.Leaderboard.Visible = not _G.Settings.Misc["Hide Leaderboard"]
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.Misc["Highlight Mode"] then
            pcall(function()
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("HumanoidRootPart") and not v.HumanoidRootPart:FindFirstChild("Highlight") then
                        local h = Instance.new("Highlight", v.HumanoidRootPart)
                        h.Name = "Highlight"
                        h.FillColor = Color3.fromRGB(255, 0, 0)
                        h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    end
                end
            end)
        else
            pcall(function()
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("HumanoidRootPart") and v.HumanoidRootPart:FindFirstChild("Highlight") then
                        v.HumanoidRootPart.Highlight:Destroy()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.SettingSea["Lightning"] then
            pcall(function() CommF_:InvokeServer("Lightning") end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.Settings.SettingSea["Increase Boat Speed"] then
            pcall(function()
                local boat = workspace.Boats[_G.Settings.SeaEvent["Selected Boat"]]
                if boat and boat:FindFirstChild("VehicleSeat") then
                    local bv = boat.VehicleSeat:FindFirstChild("BoatBV")
                    if not bv then
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "BoatBV"
                        bv.Parent = boat.VehicleSeat
                        bv.MaxForce = Vector3.new(0, 0, 0)
                        bv.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.Settings.SettingSea["No Clip Rock"] then
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v.Name == "Rock" and v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.DragonDojo["Auto Farm Blaze Ember"] and World3 then
            pcall(function()
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v.Name == "Dragon Crew Warrior" or v.Name == "Dragon Crew Archer" then
                        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                State.PosMon = v.HumanoidRootPart.CFrame
                                State.MonFarm = v.Name
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.DragonDojo["Auto Farm Blaze Ember"] or (not v.Parent) or v.Humanoid.Health <= 0
                            State.MonFarm = ""
                            State.PosMon  = CFrame.new()
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.Settings.DragonDojo["Auto Collect Blaze Ember"] and World3 then
            pcall(function()
                for _, v in pairs(workspace:GetChildren()) do
                    if v.Name == "Blaze Ember" and v:IsA("Tool") and v:FindFirstChild("Handle") then
                        local d = (v.Handle.Position - GetHRP().Position).Magnitude
                        if d <= 100 then
                            v.Handle.CFrame = GetHRP().CFrame
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if _G.Settings.Combat["Aimbot Skill Nearest"] then
            pcall(function()
                local nearest = nil
                local minDist = math.huge
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v ~= GetChar() and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local d = (v.HumanoidRootPart.Position - GetHRP().Position).Magnitude
                        if d < minDist then minDist = d nearest = v end
                    end
                end
                if nearest then
                    State.AimBotSkillPosition = nearest.HumanoidRootPart.Position
                    State.Skillaimbot = true
                else
                    State.Skillaimbot = false
                end
            end)
        else
            State.Skillaimbot = false
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if _G.Settings.Combat["Aimbot Gun"] then
            pcall(function()
                local nearest = nil
                local minDist = math.huge
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= LP and v.Character and v.Character:FindFirstChild("Head") then
                        local d = (v.Character.Head.Position - GetHRP().Position).Magnitude
                        if d < minDist then minDist = d nearest = v end
                    end
                end
                if nearest and nearest.Character then
                    local gun = GetChar() and GetChar():FindFirstChildOfClass("Tool")
                    if gun and gun:FindFirstChild("RemoteFunctionShoot") then
                        pcall(function()
                            gun.RemoteFunctionShoot:InvokeServer("TAP", nearest.Character.Head.Position)
                        end)
                    end
                    local cam = workspace.CurrentCamera
                    cam.CFrame = CFrame.new(cam.CFrame.Position, nearest.Character.Head.Position)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if _G.Settings.Combat["Aimbot Skill"] then
            pcall(function()
                local t = _G.SelectedPlayer and Players:FindFirstChild(_G.SelectedPlayer)
                local target = t
                if not target then
                    local minDist = math.huge
                    for _, v in pairs(Players:GetPlayers()) do
                        if v ~= LP and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (v.Character.HumanoidRootPart.Position - GetHRP().Position).Magnitude
                            if d < minDist then minDist = d target = v end
                        end
                    end
                end
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    State.AimBotSkillPosition = target.Character.HumanoidRootPart.Position
                    State.Skillaimbot = true
                else
                    State.Skillaimbot = false
                end
            end)
        elseif not _G.Settings.Combat["Aimbot Skill Nearest"] then
            State.Skillaimbot = false
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.Settings.Combat["Auto Kill Player Quest"] then
            pcall(function()
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= LP and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                        EquipWeapon(_G.Settings.Main["Selected Weapon"])
                        AutoHaki()
                        TweenPlayer(v.Character.HumanoidRootPart.CFrame * State.Pos)
                        State.AimBotSkillPosition = v.Character.HumanoidRootPart.Position
                        State.Skillaimbot = true
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.SeaStack["Teleport To Advanced Fruit Dealer"] then
            pcall(function()
                for _, v in pairs(workspace.NPCs:GetChildren()) do
                    if v.Name == "Advanced Fruit Dealer" then
                        TweenPlayer(v.HumanoidRootPart.CFrame)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.Settings.SeaStack["Auto Collect Azure Ember"] then
            pcall(function()
                local target = _G.Settings.SeaStack["Set Azure Ember"]
                local col = GetCountMaterials("Azure Ember")
                if col >= target then return end
                for _, v in pairs(workspace:GetChildren()) do
                    if v.Name == "Azure Ember" and v:IsA("Tool") and v:FindFirstChild("Handle") then
                        local d = (v.Handle.Position - GetHRP().Position).Magnitude
                        if d <= 200 then
                            TweenPlayer(v.Handle.CFrame)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if _G.Settings.Farm["Auto Chest Hop"] then
            pcall(function()
                local found = false
                for _, v in pairs(workspace.ChestModels:GetChildren()) do
                    if v.Name:find("Chest") then found = true break end
                end
                if not found then Hop() end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Farm Chest Mirage"] then
            pcall(function()
                local mirage = workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island")
                if not mirage then return end
                for _, v in pairs(workspace.ChestModels:GetChildren()) do
                    if v.Name:find("Chest") and v:FindFirstChild("RootPart") then
                        if (v.RootPart.Position - mirage.Position).Magnitude <= 2000 then
                            repeat
                                task.wait()
                                TweenPlayer(v.RootPart.CFrame)
                            until not _G.Settings.Farm["Auto Farm Chest Mirage"] or (not v.Parent)
                        end
                    end
                end
            end)
        end
    end
end)

local rarityFruits = {
    Common   = {"Rocket Fruit","Spin Fruit","Blade Fruit","Spring Fruit","Bomb Fruit","Smoke Fruit","Spike Fruit"},
    Uncommon = {"Flame Fruit","Falcon Fruit","Ice Fruit","Sand Fruit","Diamond Fruit","Dark Fruit"},
    Rare     = {"Light Fruit","Rubber Fruit","Barrier Fruit","Ghost Fruit","Magma Fruit"},
    Legendary= {"Quake Fruit","Buddha Fruit","Love Fruit","Spider Fruit","Sound Fruit","Phoenix Fruit",
                 "Portal Fruit","Rumble Fruit","Pain Fruit","Blizzard Fruit"},
    Mythical = {"Gravity Fruit","Mammoth Fruit","T-Rex Fruit","Dough Fruit","Shadow Fruit","Venom Fruit",
                "Control Fruit","Gas Fruit","Spirit Fruit","Leopard Fruit","Yeti Fruit","Kitsune Fruit","Dragon Fruit"},
}

local function buildStoreFruitList()
    local sel = _G.Settings.Fruit["Store Rarity Fruit"]
    local order = {"Common","Uncommon","Rare","Legendary","Mythical"}
    local startIdx = 1
    if sel == "Common - Mythical"   then startIdx = 1
    elseif sel == "Rare - Mythical" then startIdx = 3
    elseif sel == "Legendary - Mythical" then startIdx = 4
    elseif sel == "Mythical"        then startIdx = 5
    end
    local out = {}
    for i = startIdx, #order do
        for _, f in pairs(rarityFruits[order[i]]) do table.insert(out, f) end
    end
    return out
end

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.Fruit["Auto Store Fruit"] then
            pcall(function()
                local list = buildStoreFruitList()
                for _, v in pairs(LP.Backpack:GetChildren()) do
                    if v.Name:find("Fruit") then
                        for _, fruitName in pairs(list) do
                            if v.Name == fruitName then
                                local clean = fruitName:gsub(" Fruit","")
                                CommF_:InvokeServer("StoreFruit", clean.."-"..clean, v)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Shop["Auto Buy Legendary Sword"] then
            pcall(function()
                CommF_:InvokeServer("LegendarySwordDealer","1")
                CommF_:InvokeServer("LegendarySwordDealer","2")
                CommF_:InvokeServer("LegendarySwordDealer","3")
            end)
        end
        if _G.Settings.Shop["Auto Buy Haki Color"] then
            pcall(function() CommF_:InvokeServer("ColorsDealer","2") end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Raid["Auto Awaken"] then
            pcall(function() CommF_:InvokeServer("Awakener","Awaken") end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Raid["Auto Raid"] and (World2 or World3) then
            pcall(function()
                local chip = _G.Settings.Raid["Selected Chip"]
                if chip and not workspace._WorldOrigin.Locations:FindFirstChild("Island 1")
                    and not LP.Backpack:FindFirstChild("Special Microchip")
                    and not LP.Character:FindFirstChild("Special Microchip") then
                    CommF_:InvokeServer("RaidsNpc","Select",chip)
                end
            end)
        end
    end
end)

task.spawn(function()
    local placeCF = {
        ["Top Of GreatTree"] = CFrame.new(2947.55,2281.63,-7213.54),
        ["Timple Of Time"]   = CFrame.new(28286.35,14895.30,102.62),
        ["Lever Pull"]       = CFrame.new(28575.18,14936.62,72.31),
        ["Acient One"]       = CFrame.new(28981.55,14888.42,-120.24),
    }
    while task.wait(0.2) do
        if _G.Settings.Race["Teleport To Place"] then
            local cf = placeCF[_G.Settings.Race["Selected Place"]]
            if cf then TweenPlayer(cf) end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Race["Auto Buy Gear"] then
            pcall(function() CommF_:InvokeServer("UpgradeRace","Buy") end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Race["Find Blue Gear"] then
            pcall(function()
                if workspace.Map:FindFirstChild("MysticIsland") then
                    for _, v in pairs(workspace.Map.MysticIsland:GetDescendants()) do
                        if v:IsA("MeshPart") and v.Material == Enum.Material.Neon then
                            TweenPlayer(v.CFrame)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Race["Look Moon Ability"] then
            pcall(function()
                local moonDir   = game:GetService("Lighting"):GetMoonDirection()
                local lookAtPos = workspace.CurrentCamera.CFrame.p + moonDir * 100
                workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.p, lookAtPos)
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Greybeard"] and World1 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Greybeard") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Greybeard" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Greybeard"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                    TweenPlayer(CFrame.new(-5023.38330078125, 28.65203285217285, 4332.3818359375))
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            local char = GetChar()
            if not char then return end
            local hrp = GetHRP()
            if not hrp then return end
            local humanoid = GetHumanoid()
            if not humanoid then return end

            if _G.Settings.LocalPlayer["Infinite Energy"] then
                humanoid.Health = humanoid.MaxHealth
            end
            if _G.Settings.LocalPlayer["Infinite Geppo"] then
                pcall(function() CommF_:InvokeServer("BuyHaki","Geppo") end)
            end
            if _G.Settings.LocalPlayer["Infinite Soru"] then
                pcall(function() CommF_:InvokeServer("BuyHaki","Soru") end)
            end
            if _G.Settings.LocalPlayer["Dodge No Cooldown"] then
                pcall(function()
                    for _, v in pairs(char:GetDescendants()) do
                        if v.Name == "Dodge" and v:IsA("NumberValue") then
                            v.Value = 0
                        end
                    end
                end)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if _G.Settings.LocalPlayer["Active Race V3"] then
                RepStore.Remotes.CommE:FireServer("ActivateAbility")
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.Race["Auto Race V2"] and World2 then
            pcall(function()
                local raceV2Pos = CFrame.new(-1467.22, 30.00, -2800.00)
                TweenPlayer(raceV2Pos)
                pcall(function() CommF_:InvokeServer("RaceV2","Buy") end)
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.Race["Auto Race V3"] and World3 then
            pcall(function()
                local raceV3Pos = CFrame.new(28286.35, 14895.30, 102.62)
                TweenPlayer(raceV3Pos)
                pcall(function() CommF_:InvokeServer("UpgradeRace","Buy") end)
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if _G.Settings.Farm["Auto Chest Hop"] then
            pcall(function()
                local found = false
                for _, v in pairs(workspace.ChestModels:GetChildren()) do
                    if v.Name:find("Chest") then found = true break end
                end
                if not found then
                    local module = (loadstring(game:HttpGet("https://raw.githubusercontent.com/raw-scriptpastebin/FE/main/Server_Hop_Settings")))()
                    module:Teleport(game.PlaceId)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Farm Chest Mirage"] then
            pcall(function()
                if workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island") then
                    for _, v in pairs(workspace.ChestModels:GetChildren()) do
                        if v.Name:find("Chest") and v:FindFirstChild("RootPart") then
                            repeat task.wait() TweenPlayer(v.RootPart.CFrame)
                            until not _G.Settings.Farm["Auto Farm Chest Mirage"] or not v.Parent
                        end
                    end
                else
                    TweenPlayer(CFrame.new(-16547.74, 61.13, -173.41)) -- Tiki Outpost wait area
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Farm Factory"] and World2 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Factory Staff") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Factory Staff" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                State.PosMon = v.HumanoidRootPart.CFrame
                                State.MonFarm = v.Name
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Farm Factory"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    TweenPlayer(CFrame.new(73.07, 81.86, -27.47))
                end
            end)
            if not _G.Settings.Items["Auto Farm Factory"] then
                State.MonFarm = ""
                State.PosMon  = CFrame.new()
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.Items["Auto Cursed Dual Katana"] and World3 then
            pcall(function()
                pcall(function() CommF_:InvokeServer("Curse","Check") end)
                pcall(function() CommF_:InvokeServer("Curse","Buy") end)
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Canvander"] and World3 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Beautiful Pirate") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Beautiful Pirate" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Canvander"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    TweenPlayer(CFrame.new(5310.31, 21.52, 843.61)) -- Beautiful Pirate Domain area
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Swan Glasses"] and World2 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Don Swan") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Don Swan" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Swan Glasses"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    TweenPlayer(CFrame.new(778.54, 72.00, 1338.06)) -- Don Swan's mansion
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.Items["Auto Arena Trainer"] and World3 then
            pcall(function()
                pcall(function() CommF_:InvokeServer("ArenaTrainer","Check") end)
                pcall(function() CommF_:InvokeServer("ArenaTrainer","Buy") end)
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.Items["Auto Rainbow Haki"] and World3 then
            pcall(function()
                pcall(function() CommF_:InvokeServer("Rainbow","Check") end)
                pcall(function() CommF_:InvokeServer("Rainbow","Buy") end)
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Holy Torch"] and World3 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Cursed Captain") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Cursed Captain" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Holy Torch"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                elseif World3 then
                    TweenPlayer(CFrame.new(923.40, 125.05, 32885.87)) -- Cursed Ship area
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.Items["Auto Bartilo Quest"] and World2 then
            pcall(function()
                pcall(function() CommF_:InvokeServer("Bartilo","Check") end)
                pcall(function() CommF_:InvokeServer("Bartilo","Buy") end)
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Dark Dagger"] and World3 then
            pcall(function()
                local ripName = "rip_indra True Form"
                local ripName2 = "rip_indra"
                if workspace.Enemies:FindFirstChild(ripName) or workspace.Enemies:FindFirstChild(ripName2) then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if (v.Name == ripName or v.Name == ripName2) and v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Dark Dagger"] or v.Humanoid.Health <= 0
                        end
                    end
                else
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                    TweenPlayer(CFrame.new(-5344.822265625, 423.98541259766, -2725.0930175781))
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Pole"] and World1 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Thunder God") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Thunder God" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Pole"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                    TweenPlayer(CFrame.new(-7748.0185546875, 5606.80615234375, -2305.898681640625))
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Shark Saw"] and World1 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("The Saw") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "The Saw" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Shark Saw"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                    TweenPlayer(CFrame.new(-690.33081054688, 15.09425163269, 1582.2380371094))
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Dragon Trident"] and World2 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Tide Keeper") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Tide Keeper" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Dragon Trident"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                    TweenPlayer(CFrame.new(-3914.830322265625, 123.29389190673828, -11516.8642578125))
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Warden Sword"] and World1 then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Chief Warden") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Chief Warden" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Warden Sword"] or (not v.Parent) or v.Humanoid.Health <= 0
                        end
                    end
                else
                    UnEquipWeapon(_G.Settings.Main["Selected Weapon"])
                    TweenPlayer(CFrame.new(5186.14697265625, 24.86684226989746, 832.1885375976562))
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Hallow Scythe"] then
            pcall(function()
                if workspace.Enemies:FindFirstChild("Soul Reaper") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if string.find(v.Name, "Soul Reaper") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                AutoHaki()
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                v.HumanoidRootPart.Transparency = 1
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until v.Humanoid.Health <= 0 or not _G.Settings.Items["Auto Hallow Scythe"]
                        end
                    end
                elseif LP.Backpack:FindFirstChild("Hallow Essence") or LP.Character:FindFirstChild("Hallow Essence") then
                    local hallowCF = CFrame.new(-8932.322265625, 146.83154296875, 6062.55078125)
                    repeat
                        TweenPlayer(hallowCF)
                        task.wait()
                    until (hallowCF.Position - GetHRP().Position).Magnitude <= 8 or not _G.Settings.Items["Auto Hallow Scythe"]
                    EquipWeapon("Hallow Essence")
                elseif RepStore:FindFirstChild("Soul Reaper") then
                    TweenPlayer(RepStore["Soul Reaper"].HumanoidRootPart.CFrame * CFrame.new(2, 20, 2))
                end
            end)
        end
    end
end)

function CheckTorch()
    local a
    local torches = workspace.Map.Turtle.QuestTorches
    if not torches.Torch1.Particles.Main.Enabled then a = "1"
    elseif not torches.Torch2.Particles.Main.Enabled then a = "2"
    elseif not torches.Torch3.Particles.Main.Enabled then a = "3"
    elseif not torches.Torch4.Particles.Main.Enabled then a = "4"
    elseif not torches.Torch5.Particles.Main.Enabled then a = "5"
    end
    if not a then return nil end
    for _, v in next, torches:GetChildren() do
        if v:IsA("MeshPart") and string.find(v.Name, a) and (not v.Particles.Main.Enabled) then return v end
    end
end

function CheckNameBoss(a)
    for _, v in next, RepStore:GetChildren() do
        if v:IsA("Model") and (typeof(a) == "table" and table.find(a, v.Name) or v.Name == a) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then return v end
    end
    for _, v in next, workspace.Enemies:GetChildren() do
        if v:IsA("Model") and (typeof(a) == "table" and table.find(a, v.Name) or v.Name == a) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then return v end
    end
end

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Tushita"] and World3 then
            pcall(function()
                if not workspace.Map.Turtle:FindFirstChild("TushitaGate") then
                    local longma = CheckNameBoss("Longma [Lv. 2000] [Boss]")
                    if longma then
                        repeat
                            task.wait()
                            AutoHaki()
                            EquipWeapon(_G.Settings.Main["Selected Weapon"])
                            longma.Humanoid.WalkSpeed = 0
                            longma.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                            TweenPlayer(longma.HumanoidRootPart.CFrame * State.Pos)
                        until not longma or (not longma.Parent) or longma.Humanoid.Health == 0 or not _G.Settings.Items["Auto Tushita"]
                    end
                elseif CheckNameBoss("rip_indra True Form [Lv. 5000] [Raid Boss]") then
                    if not LP.Character:FindFirstChild("Holy Torch") and not LP.Backpack:FindFirstChild("Holy Torch") then
                        TweenPlayer(workspace.Map.Waterfall.SecretRoom.Room.Door.Door.Hitbox.CFrame)
                    else
                        EquipWeapon("Holy Torch")
                        local torch = CheckTorch()
                        if torch then TweenPlayer(torch.CFrame) end
                    end
                else
                    task.wait(3)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Yama"] and World3 then
            pcall(function()
                if CommF_:InvokeServer("EliteHunter", "Progress") < 30 then
                    if not workspace.Enemies:FindFirstChild("Diablo") and not workspace.Enemies:FindFirstChild("Deandre") and not workspace.Enemies:FindFirstChild("Urban") then
                        Hop()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Yama"] and World3 then
            pcall(function()
                local QUI = LP.PlayerGui.Main.Quest
                local qt = QUI.Container.QuestTitle.Title.Text
                if CommF_:InvokeServer("EliteHunter", "Progress") >= 30 then
                    repeat
                        task.wait(0.1)
                        fireclickdetector(workspace.Map.Waterfall.SealedKatana.Handle.ClickDetector)
                    until LP.Backpack:FindFirstChild("Yama") or not _G.Settings.Items["Auto Yama"]
                elseif string.find(qt, "Diablo") or string.find(qt, "Deandre") or string.find(qt, "Urban") then
                    local eliteTargets = {"Diablo","Deandre","Urban"}
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if table.find(eliteTargets, v.Name) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                            until not _G.Settings.Items["Auto Yama"] or v.Humanoid.Health <= 0 or (not v.Parent)
                        end
                    end
                else
                    CommF_:InvokeServer("EliteHunter")
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Second Sea"] and World1 then
            pcall(function()
                local MyLevel = LP.Data.Level.Value
                if MyLevel >= 700 and World1 then
                    if workspace.Map.Ice.Door.CanCollide == false and workspace.Map.Ice.Door.Transparency == 1 then
                        local CFrame1 = CFrame.new(4849.29883, 5.65138149, 719.611877)
                        repeat
                            TweenPlayer(CFrame1)
                            task.wait()
                        until (CFrame1.Position - GetHRP().Position).Magnitude <= 3 or not _G.Settings.Items["Auto Second Sea"]
                        task.wait(1.1)
                        CommF_:InvokeServer("DressrosaQuestProgress", "Detective")
                        task.wait(0.5)
                        EquipWeapon("Key")
                        repeat
                            TweenPlayer(CFrame.new(1347.7124, 37.3751602, -1325.6488))
                            task.wait()
                        until (Vector3.new(1347.7124, 37.3751602, -1325.6488) - GetHRP().Position).Magnitude <= 3 or not _G.Settings.Items["Auto Second Sea"]
                        task.wait(0.5)
                    elseif workspace.Map.Ice.Door.CanCollide == false and workspace.Map.Ice.Door.Transparency == 1 then
                        if workspace.Enemies:FindFirstChild("Ice Admiral") then
                            for _, v in pairs(workspace.Enemies:GetChildren()) do
                                if v.Name == "Ice Admiral" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                    local OldCFrameSecond = v.HumanoidRootPart.CFrame
                                    repeat
                                        RunSvc.Heartbeat:Wait()
                                        AutoHaki()
                                        EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                        v.Humanoid.WalkSpeed = 0
                                        v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                        v.HumanoidRootPart.CFrame = OldCFrameSecond
                                        TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                    until not _G.Settings.Items["Auto Second Sea"] or (not v.Parent) or v.Humanoid.Health <= 0
                                end
                            end
                        elseif RepStore:FindFirstChild("Ice Admiral") then
                            TweenPlayer(RepStore["Ice Admiral"].HumanoidRootPart.CFrame * CFrame.new(5, 10, 7))
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Third Sea"] then
            pcall(function()
                if LP.Data.Level.Value >= 1500 and World2 then
                    if CommF_:InvokeServer("ZQuestProgress", "General") == 0 then
                        local cfZ1 = CFrame.new(-1926.3221435547, 12.819851875305, 1738.3092041016)
                        TweenPlayer(cfZ1)
                        if (cfZ1.Position - GetHRP().Position).Magnitude <= 10 then
                            task.wait(1.5)
                            CommF_:InvokeServer("ZQuestProgress", "Begin")
                        end
                        task.wait(1.8)
                        if workspace.Enemies:FindFirstChild("rip_indra") then
                            for _, v in pairs(workspace.Enemies:GetChildren()) do
                                if v.Name == "rip_indra" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                    local OldCFrameThird = v.HumanoidRootPart.CFrame
                                    repeat
                                        RunSvc.Heartbeat:Wait()
                                        AutoHaki()
                                        EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                        TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                        v.HumanoidRootPart.CFrame = OldCFrameThird
                                        v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                        v.Humanoid.WalkSpeed = 0
                                        CommF_:InvokeServer("TravelZou")
                                    until not _G.Settings.Items["Auto Third Sea"] or v.Humanoid.Health <= 0 or (not v.Parent)
                                end
                            end
                        elseif not workspace.Enemies:FindFirstChild("rip_indra") and (CFrame.new(-26880.93359375, 22.848554611206, 473.18951416016).Position - GetHRP().Position).Magnitude <= 1000 then
                            TweenPlayer(CFrame.new(-26880.93359375, 22.848554611206, 473.18951416016))
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto God Human"] then
            pcall(function()
                local char = LP.Character
                local bp = LP.Backpack
                local has = function(n) return char and char:FindFirstChild(n) or bp and bp:FindFirstChild(n) end
                if has("Superhuman") or has("Black Leg") or has("Death Step") or has("Fishman Karate") or has("Sharkman Karate") or has("Electro") or has("Electric Claw") or has("Dragon Claw") or has("Dragon Talon") or has("Godhuman") then
                    if CommF_:InvokeServer("BuySuperhuman", true) == 1 then
                        if bp:FindFirstChild("Superhuman") and bp.Superhuman.Level.Value >= 400 or char:FindFirstChild("Superhuman") and char.Superhuman.Level.Value >= 400 then
                            CommF_:InvokeServer("BuyDeathStep")
                        end
                    end
                    if CommF_:InvokeServer("BuyDeathStep", true) == 1 then
                        if bp:FindFirstChild("Death Step") and bp["Death Step"].Level.Value >= 400 or char:FindFirstChild("Death Step") and char["Death Step"].Level.Value >= 400 then
                            CommF_:InvokeServer("BuySharkmanKarate")
                        end
                    end
                    if CommF_:InvokeServer("BuySharkmanKarate", true) == 1 then
                        if bp:FindFirstChild("Sharkman Karate") and bp["Sharkman Karate"].Level.Value >= 400 or char:FindFirstChild("Sharkman Karate") and char["Sharkman Karate"].Level.Value >= 400 then
                            CommF_:InvokeServer("BuyElectricClaw")
                        end
                    end
                    if CommF_:InvokeServer("BuyElectricClaw", true) == 1 then
                        if bp:FindFirstChild("Electric Claw") and bp["Electric Claw"].Level.Value >= 400 or char:FindFirstChild("Electric Claw") and char["Electric Claw"].Level.Value >= 400 then
                            CommF_:InvokeServer("BuyDragonTalon")
                        end
                    end
                    if CommF_:InvokeServer("BuyDragonTalon", true) == 1 then
                        if bp:FindFirstChild("Dragon Talon") and bp["Dragon Talon"].Level.Value >= 400 or char:FindFirstChild("Dragon Talon") and char["Dragon Talon"].Level.Value >= 400 then
                            if string.find(CommF_:InvokeServer("BuyGodhuman", true), "Bring") then
                            else
                                CommF_:InvokeServer("BuyGodhuman")
                            end
                        end
                    end
                else
                    CommF_:InvokeServer("BuySuperhuman")
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Dragon Talon"] then
            pcall(function()
                local char = LP.Character
                local bp = LP.Backpack
                if bp:FindFirstChild("Dragon Claw") or char:FindFirstChild("Dragon Claw") or bp:FindFirstChild("Dragon Talon") or char:FindFirstChild("Dragon Talon") then
                    if bp:FindFirstChild("Dragon Claw") and bp["Dragon Claw"].Level.Value >= 400 then
                        CommF_:InvokeServer("BuyDragonTalon")
                        _G.Settings.Main["Selected Weapon"] = "Dragon Talon"
                    end
                    if char:FindFirstChild("Dragon Claw") and char["Dragon Claw"].Level.Value >= 400 then
                        CommF_:InvokeServer("BuyDragonTalon")
                        _G.Settings.Main["Selected Weapon"] = "Dragon Talon"
                    end
                    if bp:FindFirstChild("Dragon Claw") and bp["Dragon Claw"].Level.Value <= 399 then
                        _G.Settings.Main["Selected Weapon"] = "Dragon Claw"
                    end
                else
                    CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Fishman Karate"] then
            pcall(function()
                CommF_:InvokeServer("BuyFishmanKarate")
                if string.find(CommF_:InvokeServer("BuySharkmanKarate"), "keys") then
                    if LP.Character:FindFirstChild("Water Key") or LP.Backpack:FindFirstChild("Water Key") then
                        TweenPlayer(CFrame.new(-2604.6958, 239.432526, -10315.1982, 0.0425701365, 0, -0.999093413, 0, 1, 0, 0.999093413, 0, 0.0425701365))
                        CommF_:InvokeServer("BuySharkmanKarate")
                    elseif LP.Character:FindFirstChild("Fishman Karate") and LP.Character["Fishman Karate"].Level.Value >= 400 then
                    else
                        local Ms = "Tide Keeper"
                        if workspace.Enemies:FindFirstChild(Ms) then
                            for _, v in pairs(workspace.Enemies:GetChildren()) do
                                if v.Name == Ms and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                    local OldCFrameShark = v.HumanoidRootPart.CFrame
                                    repeat
                                        RunSvc.Heartbeat:Wait()
                                        AutoHaki()
                                        EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                        v.Humanoid.WalkSpeed = 0
                                        v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                        v.HumanoidRootPart.CFrame = OldCFrameShark
                                        TweenPlayer(v.HumanoidRootPart.CFrame * CFrame.new(2, 20, 2))
                                    until not v.Parent or v.Humanoid.Health <= 0 or not _G.Settings.Items["Auto Fishman Karate"] or LP.Character:FindFirstChild("Water Key") or LP.Backpack:FindFirstChild("Water Key")
                                end
                            end
                        else
                            TweenPlayer(CFrame.new(-3570.18652, 123.328949, -11555.9072, 0.465199202, -0.000000013857326, 0.885206044, 0.0000000040332897, 1, 0.0000000135347511, -0.885206044, -0.00000000272606271, 0.465199202))
                            task.wait(3)
                        end
                    end
                else
                    CommF_:InvokeServer("BuySharkmanKarate")
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Electric Claw"] then
            pcall(function()
                local char = LP.Character
                local bp = LP.Backpack
                if bp:FindFirstChild("Electro") or char:FindFirstChild("Electro") or bp:FindFirstChild("Electric Claw") or char:FindFirstChild("Electric Claw") then
                    if bp:FindFirstChild("Electro") and bp.Electro.Level.Value >= 400 then
                        CommF_:InvokeServer("BuyElectricClaw")
                        _G.Settings.Main["Selected Weapon"] = "Electric Claw"
                    end
                    if char:FindFirstChild("Electro") and char.Electro.Level.Value >= 400 then
                        CommF_:InvokeServer("BuyElectricClaw")
                        _G.Settings.Main["Selected Weapon"] = "Electric Claw"
                    end
                    if bp:FindFirstChild("Electro") and bp.Electro.Level.Value <= 399 then
                        _G.Settings.Main["Selected Weapon"] = "Electro"
                    end
                else
                    CommF_:InvokeServer("BuyElectro")
                end
                if _G.Settings.Items["Auto Electric Claw"] then
                    if bp:FindFirstChild("Electro") or char:FindFirstChild("Electro") then
                        if (bp:FindFirstChild("Electro") and bp.Electro.Level.Value >= 400) or (char:FindFirstChild("Electro") and char.Electro.Level.Value >= 400) then
                            if _G.Settings.Main["Auto Farm"] == false then
                                repeat
                                    RunSvc.Heartbeat:Wait()
                                    TweenPlayer(CFrame.new(-10371.4717, 330.764496, -10131.4199))
                                until not _G.Settings.Items["Auto Electric Claw"] or (GetHRP().Position - CFrame.new(-10371.4717, 330.764496, -10131.4199).Position).Magnitude <= 10
                                CommF_:InvokeServer("BuyElectricClaw", "Start")
                                task.wait(2)
                                repeat
                                    task.wait()
                                    TweenPlayer(CFrame.new(-12550.532226563, 336.22631835938, -7510.4233398438))
                                until not _G.Settings.Items["Auto Electric Claw"] or (GetHRP().Position - CFrame.new(-12550.532226563, 336.22631835938, -7510.4233398438).Position).Magnitude <= 10
                                task.wait(1)
                                repeat
                                    task.wait()
                                    TweenPlayer(CFrame.new(-10371.4717, 330.764496, -10131.4199))
                                until not _G.Settings.Items["Auto Electric Claw"] or (GetHRP().Position - CFrame.new(-10371.4717, 330.764496, -10131.4199).Position).Magnitude <= 10
                                task.wait(1)
                                CommF_:InvokeServer("BuyElectricClaw")
                            else
                                _G.Settings.Main["Auto Farm"] = false
                                task.wait(1)
                                repeat
                                    task.wait()
                                    TweenPlayer(CFrame.new(-10371.4717, 330.764496, -10131.4199))
                                until not _G.Settings.Items["Auto Electric Claw"] or (GetHRP().Position - CFrame.new(-10371.4717, 330.764496, -10131.4199).Position).Magnitude <= 10
                                CommF_:InvokeServer("BuyElectricClaw", "Start")
                                task.wait(2)
                                repeat
                                    task.wait()
                                    TweenPlayer(CFrame.new(-12550.532226563, 336.22631835938, -7510.4233398438))
                                until not _G.Settings.Items["Auto Electric Claw"] or (GetHRP().Position - CFrame.new(-12550.532226563, 336.22631835938, -7510.4233398438).Position).Magnitude <= 10
                                task.wait(1)
                                repeat
                                    task.wait()
                                    TweenPlayer(CFrame.new(-10371.4717, 330.764496, -10131.4199))
                                until not _G.Settings.Items["Auto Electric Claw"] or (GetHRP().Position - CFrame.new(-10371.4717, 330.764496, -10131.4199).Position).Magnitude <= 10
                                task.wait(1)
                                CommF_:InvokeServer("BuyElectricClaw")
                                _G.Settings.Main["Selected Weapon"] = "Electric Claw"
                                task.wait(0.1)
                                _G.Settings.Main["Auto Farm"] = true
                            end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Death Step"] then
            pcall(function()
                local char = LP.Character
                local bp = LP.Backpack
                if bp:FindFirstChild("Black Leg") or char:FindFirstChild("Black Leg") or bp:FindFirstChild("Death Step") or char:FindFirstChild("Death Step") then
                    if bp:FindFirstChild("Black Leg") and bp["Black Leg"].Level.Value >= 450 then
                        CommF_:InvokeServer("BuyDeathStep")
                        _G.Settings.Main["Selected Weapon"] = "Death Step"
                    end
                    if char:FindFirstChild("Black Leg") and char["Black Leg"].Level.Value >= 450 then
                        CommF_:InvokeServer("BuyDeathStep")
                        _G.Settings.Main["Selected Weapon"] = "Death Step"
                    end
                    if bp:FindFirstChild("Black Leg") and bp["Black Leg"].Level.Value <= 449 then
                        _G.Settings.Main["Selected Weapon"] = "Black Leg"
                    end
                else
                    CommF_:InvokeServer("BuyBlackLeg")
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Super Human"] then
            pcall(function()
                local char = LP.Character
                local bp = LP.Backpack
                if bp:FindFirstChild("Combat") or char:FindFirstChild("Combat") then
                    if LP.Data.Beli.Value >= 150000 then
                        UnEquipWeapon("Combat")
                        task.wait(0.1)
                        CommF_:InvokeServer("BuyBlackLeg")
                    end
                end
                if char:FindFirstChild("Superhuman") or bp:FindFirstChild("Superhuman") then
                    _G.Settings.Main["Selected Weapon"] = "Superhuman"
                end
                if bp:FindFirstChild("Black Leg") or char:FindFirstChild("Black Leg") or bp:FindFirstChild("Electro") or char:FindFirstChild("Electro") or bp:FindFirstChild("Fishman Karate") or char:FindFirstChild("Fishman Karate") or bp:FindFirstChild("Dragon Claw") or char:FindFirstChild("Dragon Claw") then
                    if bp:FindFirstChild("Black Leg") and bp["Black Leg"].Level.Value <= 299 then _G.Settings.Main["Selected Weapon"] = "Black Leg" end
                    if bp:FindFirstChild("Electro") and bp.Electro.Level.Value <= 299 then _G.Settings.Main["Selected Weapon"] = "Electro" end
                    if bp:FindFirstChild("Fishman Karate") and bp["Fishman Karate"].Level.Value <= 299 then _G.Settings.Main["Selected Weapon"] = "Fishman Karate" end
                    if bp:FindFirstChild("Dragon Claw") and bp["Dragon Claw"].Level.Value <= 299 then _G.Settings.Main["Selected Weapon"] = "Dragon Claw" end
                    if (bp:FindFirstChild("Black Leg") and bp["Black Leg"].Level.Value >= 300 and LP.Data.Beli.Value >= 300000) then
                        UnEquipWeapon("Black Leg"); task.wait(0.1); CommF_:InvokeServer("BuyElectro")
                    end
                    if (char:FindFirstChild("Black Leg") and char["Black Leg"].Level.Value >= 300 and LP.Data.Beli.Value >= 300000) then
                        UnEquipWeapon("Black Leg"); task.wait(0.1); CommF_:InvokeServer("BuyElectro")
                    end
                    if (bp:FindFirstChild("Electro") and bp.Electro.Level.Value >= 300 and LP.Data.Beli.Value >= 750000) then
                        UnEquipWeapon("Electro"); task.wait(0.1); CommF_:InvokeServer("BuyFishmanKarate")
                    end
                    if (char:FindFirstChild("Electro") and char.Electro.Level.Value >= 300 and LP.Data.Beli.Value >= 750000) then
                        UnEquipWeapon("Electro"); task.wait(0.1); CommF_:InvokeServer("BuyFishmanKarate")
                    end
                    if (bp:FindFirstChild("Fishman Karate") and bp["Fishman Karate"].Level.Value >= 300 and LP.Data.Fragments.Value >= 1500) then
                        UnEquipWeapon("Fishman Karate"); task.wait(0.1)
                        CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "1")
                        CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
                    end
                    if (char:FindFirstChild("Fishman Karate") and char["Fishman Karate"].Level.Value >= 300 and LP.Data.Fragments.Value >= 1500) then
                        UnEquipWeapon("Fishman Karate"); task.wait(0.1)
                        CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "1")
                        CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
                    end
                    if (bp:FindFirstChild("Dragon Claw") and bp["Dragon Claw"].Level.Value >= 300 and LP.Data.Beli.Value >= 3000000) then
                        UnEquipWeapon("Dragon Claw"); task.wait(0.1); CommF_:InvokeServer("BuySuperhuman")
                    end
                    if (char:FindFirstChild("Dragon Claw") and char["Dragon Claw"].Level.Value >= 300 and LP.Data.Beli.Value >= 3000000) then
                        UnEquipWeapon("Dragon Claw"); task.wait(0.1); CommF_:InvokeServer("BuySuperhuman")
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Items["Auto Saber"] and World1 and LP.Data.Level.Value >= 200 then
            pcall(function()
                if workspace.Map.Jungle.Final.Part.Transparency == 0 then
                    if workspace.Map.Jungle.QuestPlates.Door.Transparency == 0 then
                        local cfPlate = CFrame.new(-1612.55884, 36.9774132, 148.719543, 0.37091279, 0.0000000030717151, -0.928667724, 0.0000000397099491, 1, 0.0000000191679348, 0.928667724, -0.0000000439869794, 0.37091279)
                        if (cfPlate.Position - GetHRP().Position).Magnitude <= 100 then
                            TweenPlayer(GetHRP().CFrame)
                            task.wait(1)
                            GetHRP().CFrame = workspace.Map.Jungle.QuestPlates.Plate1.Button.CFrame; task.wait(1)
                            GetHRP().CFrame = workspace.Map.Jungle.QuestPlates.Plate2.Button.CFrame; task.wait(1)
                            GetHRP().CFrame = workspace.Map.Jungle.QuestPlates.Plate3.Button.CFrame; task.wait(1)
                            GetHRP().CFrame = workspace.Map.Jungle.QuestPlates.Plate4.Button.CFrame; task.wait(1)
                            GetHRP().CFrame = workspace.Map.Jungle.QuestPlates.Plate5.Button.CFrame; task.wait(1)
                        else
                            TweenPlayer(cfPlate)
                        end
                    elseif workspace.Map.Desert.Burn.Part.Transparency == 0 then
                        if LP.Backpack:FindFirstChild("Torch") or LP.Character:FindFirstChild("Torch") then
                            EquipWeapon("Torch")
                            TweenPlayer(CFrame.new(1114.61475, 5.04679728, 4350.22803, -0.648466587, -0.00000000128799094, 0.761243105, -0.000000000570652914, 1, 0.00000000120584542, -0.761243105, 0.000000000347544882, -0.648466587))
                        else
                            TweenPlayer(CFrame.new(-1610.00757, 11.5049858, 164.001587, 0.984807551, -0.167722285, -0.0449818149, 0.17364943, 0.951244235, 0.254912198, 0.0000342372805, -0.258850515, 0.965917408))
                        end
                    elseif CommF_:InvokeServer("ProQuestProgress", "SickMan") ~= 0 then
                        CommF_:InvokeServer("ProQuestProgress", "GetCup")
                        task.wait(0.5)
                        EquipWeapon("Cup")
                        task.wait(0.5)
                        CommF_:InvokeServer("ProQuestProgress", "FillCup", LP.Character.Cup)
                        task.wait(0)
                        CommF_:InvokeServer("ProQuestProgress", "SickMan")
                    elseif CommF_:InvokeServer("ProQuestProgress", "RichSon") == nil then
                        CommF_:InvokeServer("ProQuestProgress", "RichSon")
                    elseif CommF_:InvokeServer("ProQuestProgress", "RichSon") == 0 then
                        if workspace.Enemies:FindFirstChild("Mob Leader") or RepStore:FindFirstChild("Mob Leader") then
                            TweenPlayer(CFrame.new(-2967.59521, -4.91089821, 5328.70703, 0.342208564, -0.0227849055, 0.939347804, 0.0251603816, 0.999569714, 0.0150796166, -0.939287126, 0.0184739735, 0.342634559))
                            for _, v in pairs(workspace.Enemies:GetChildren()) do
                                if v.Name == "Mob Leader" or v.Name == "Mob Leader [Lv. 120] [Boss]" then
                                    if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                        repeat
                                            RunSvc.Heartbeat:Wait()
                                            AutoHaki()
                                            EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                            v.Humanoid.WalkSpeed = 0
                                            v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                            TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                        until v.Humanoid.Health <= 0 or not _G.Settings.Items["Auto Saber"]
                                    end
                                end
                            end
                            if RepStore:FindFirstChild("Mob Leader") then
                                TweenPlayer(RepStore["Mob Leader"].HumanoidRootPart.CFrame * State.Pos)
                            end
                        end
                    elseif CommF_:InvokeServer("ProQuestProgress", "RichSon") == 1 then
                        CommF_:InvokeServer("ProQuestProgress", "RichSon")
                        task.wait(0.5)
                        EquipWeapon("Relic")
                        task.wait(0.5)
                        TweenPlayer(CFrame.new(-1404.91504, 29.9773273, 3.80598116, 0.876514494, 0.00000000566906877, 0.481375456, 0.0000000253851997, 1, -0.0000000579995607, -0.481375456, 0.0000000630572643, 0.876514494))
                    end
                elseif workspace.Enemies:FindFirstChild("Saber Expert") or RepStore:FindFirstChild("Saber Expert") then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v.Name == "Saber Expert" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            repeat
                                RunSvc.Heartbeat:Wait()
                                EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                v.HumanoidRootPart.Transparency = 1
                                v.Humanoid.JumpPower = 0
                                v.Humanoid.WalkSpeed = 0
                                State.PosMon = v.HumanoidRootPart.CFrame
                                State.MonFarm = v.Name
                            until v.Humanoid.Health <= 0 or not _G.Settings.Items["Auto Saber"]
                            if v.Humanoid.Health <= 0 then
                                CommF_:InvokeServer("ProQuestProgress", "PlaceRelic")
                            end
                        end
                    end
                end
            end)
            if not _G.Settings.Items["Auto Saber"] then
                State.MonFarm = ""
                State.PosMon  = CFrame.new()
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if LP.PlayerGui.Main.TopHUDList.RaidTimer.Visible == true then
                UI.RaidTime:SetDesc(LP.PlayerGui.Main.TopHUDList.RaidTimer.Text)
            else
                UI.RaidTime:SetDesc("Wait For Dungeon")
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            local rm = workspace.Map.RaidMap
            if rm:FindFirstChild("RaidIsland5") then
                UI.RaidIsland:SetDesc("Island 5")
            elseif rm:FindFirstChild("RaidIsland4") then
                UI.RaidIsland:SetDesc("Island 4")
            elseif rm:FindFirstChild("RaidIsland3") then
                UI.RaidIsland:SetDesc("Island 3")
            elseif rm:FindFirstChild("RaidIsland2") then
                UI.RaidIsland:SetDesc("Island 2")
            elseif rm:FindFirstChild("RaidIsland1") then
                UI.RaidIsland:SetDesc("Island 1")
            else
                UI.RaidIsland:SetDesc("Start Dungeon")
            end
        end)
    end
end)

function NextRaidIsland()
    local RaidPos = CFrame.new(0, 35, 0)
    if LP.PlayerGui.Main.TopHUDList.RaidTimer.Visible == true then
        local locs = workspace._WorldOrigin.Locations
        if locs:FindFirstChild("Island 5") then
            TweenPlayer(locs["Island 5"].CFrame * RaidPos)
        elseif locs:FindFirstChild("Island 4") then
            TweenPlayer(locs["Island 4"].CFrame * RaidPos)
        elseif locs:FindFirstChild("Island 3") then
            TweenPlayer(locs["Island 3"].CFrame * RaidPos)
        elseif locs:FindFirstChild("Island 2") then
            TweenPlayer(locs["Island 2"].CFrame * RaidPos)
        elseif locs:FindFirstChild("Island 1") then
            TweenPlayer(locs["Island 1"].CFrame * RaidPos)
        end
    end
end

function CheckMonRaids()
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("HumanoidRootPart") and (v.HumanoidRootPart.Position - GetHRP().Position).Magnitude <= 300 then
            return true
        end
    end
    return false
end

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Raid["Auto Raid"] and (World2 or World3) then
            pcall(function()
                if LP.PlayerGui.Main.TopHUDList.RaidTimer.Visible == true then
                    if CheckMonRaids() then
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                if (v.HumanoidRootPart.Position - GetHRP().Position).Magnitude <= 500 then
                                    repeat
                                        task.wait()
                                        EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                        TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                        AutoHaki()
                                        v.Humanoid.WalkSpeed = 0
                                        v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                    until not _G.Settings.Raid["Auto Raid"] or (not v.Parent) or v.Humanoid.Health <= 0
                                end
                            end
                        end
                    else
                        NextRaidIsland()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if _G.Settings.Raid["Auto Raid"] and (World2 or World3) then
                if LP.PlayerGui.Main.TopHUDList.RaidTimer.Visible == false then
                    if not workspace.Map.RaidMap:FindFirstChild("RaidIsland1") and
                        (LP.Backpack:FindFirstChild("Special Microchip") or LP.Character:FindFirstChild("Special Microchip")) then
                        if World2 then
                            fireclickdetector(workspace.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector)
                        elseif World3 then
                            CommF_:InvokeServer("requestEntrance", Vector3.new(-5083.26025390625, 314.6056823730469, -3175.673095703125))
                            fireclickdetector(workspace.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector)
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Raid["Auto Raid"] and (World2 or World3) then
            pcall(function()
                if not LP.Backpack:FindFirstChild("Special Microchip") and not LP.Character:FindFirstChild("Special Microchip") then
                    if not workspace._WorldOrigin.Locations:FindFirstChild("Island 1") then
                        CommF_:InvokeServer("RaidsNpc", "Select", _G.Settings.Raid["Selected Chip"])
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if _G.Settings.Raid["Unstore Devil Fruit"] then
                local fruit = CommF_:InvokeServer("getInventoryFruits")
                for _, v in pairs(fruit) do
                    if v.Price < _G.Settings.Raid["Price Devil Fruit"] then
                        local hasFruit = false
                        for _, item in pairs(LP.Backpack:GetChildren()) do
                            if string.find(item.Name, "Fruit") then hasFruit = true break end
                        end
                        if not hasFruit then
                            for _, item in pairs(LP.Character:GetChildren()) do
                                if string.find(item.Name, "Fruit") then hasFruit = true break end
                            end
                        end
                        if not hasFruit then
                            CommF_:InvokeServer("LoadFruit", v.Name)
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Raid["Law Raid"] then
            pcall(function()
                if not LP.Character:FindFirstChild("Microchip") and not LP.Backpack:FindFirstChild("Microchip") and
                    not workspace.Enemies:FindFirstChild("Order") and not RepStore:FindFirstChild("Order") then
                    task.wait(0.3)
                    CommF_:InvokeServer("BlackbeardReward", "Microchip", "1")
                    CommF_:InvokeServer("BlackbeardReward", "Microchip", "2")
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Raid["Law Raid"] then
            pcall(function()
                if not workspace.Enemies:FindFirstChild("Order") and not RepStore:FindFirstChild("Order") then
                    if LP.Character:FindFirstChild("Microchip") or LP.Backpack:FindFirstChild("Microchip") then
                        fireclickdetector(workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
                    end
                end
                if RepStore:FindFirstChild("Order") or workspace.Enemies:FindFirstChild("Order") then
                    if workspace.Enemies:FindFirstChild("Order") then
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if v.Name == "Order" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                repeat
                                    RunSvc.Heartbeat:Wait()
                                    AutoHaki()
                                    EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                    TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                    v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                until not v.Parent or v.Humanoid.Health <= 0 or not _G.Settings.Raid["Law Raid"]
                            end
                        end
                    elseif RepStore:FindFirstChild("Order") then
                        TweenPlayer(CFrame.new(-6217.2021484375, 28.047645568848, -5053.1357421875))
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if _G.Settings.Farm["Auto Pirate Raid"] then
            pcall(function()
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                        if v.Name then
                            if getPirateRaidEnemies() then
                                if (GetHRP().Position - v.HumanoidRootPart.Position).Magnitude <= 2000 then
                                    repeat
                                        RunSvc.Heartbeat:Wait()
                                        AutoHaki()
                                        EquipWeapon(_G.Settings.Main["Selected Weapon"])
                                        TweenPlayer(v.HumanoidRootPart.CFrame * State.Pos)
                                        v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                        v.HumanoidRootPart.Transparency = 1
                                        v.Humanoid.JumpPower = 0
                                        v.Humanoid.WalkSpeed = 0
                                        State.PosMon = v.HumanoidRootPart.CFrame
                                        State.MonFarm = v.Name
                                    until not _G.Settings.Farm["Auto Pirate Raid"] or (not v.Parent) or v.Humanoid.Health <= 0 or (not workspace.Enemies:FindFirstChild(v.Name))
                                end
                            else
                                TweenPlayer(CFrame.new(-5515.08301, 343.112762, -3013.25171, 0.0679906458, 0.0000000121971047, -0.997685969, -0.0000000640159001, 1, 0.00000000786281706, 0.997685969, 0.000000063333168, 0.0679906458))
                            end
                        end
                    end
                end
            end)
            if not _G.Settings.Farm["Auto Pirate Raid"] then
                State.MonFarm = ""
                State.PosMon  = CFrame.new()
            end
        end
    end
end)

SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
InterfaceManager:SetFolder("ActriumHub")
SaveManager:SetFolder("ActriumHub")
function boostFps()
    local decalsyeeted = true
    local g = game
    local l = g.Lighting
    pcall(function() settings().Rendering.QualityLevel = "Level01" end)
    for i, v in pairs(g:GetDescendants()) do
        if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
            v.Material = "Plastic"
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") and decalsyeeted then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
            v.Enabled = false
        end
    end
end

local codeList = {"ZIOLES", "NOOB2ADMIN", "KITT_RESET", "Sub2CaptainMaui", "SUB2GAMERROBOT_RESET1", "kittgaming",
                  "Sub2Fer999", "Enyu_is_Pro", "Magicbus", "JCWK", "Starcodeheo", "Bluxxy", "fudd10_v2", "FUDD10",
                  "BIGNEWS", "THEGREATACE", "SUB2GAMERROBOT_EXP1", "Sub2OfficialNoobie", "StrawHatMaine",
                  "SUB2NOOBMASTER123", "Sub2UncleKizaru", "Sub2Daigrock", "Axiore", "TantaiGaming"}

function redeemCode(code)
    RepStore.Remotes.Redeem:InvokeServer(code)
end

function redeemAllCodes()
    for i, v in pairs(codeList) do
        pcall(function() redeemCode(v) end)
        task.wait(0.5)
    end
end

function CheckFruits()
    ResultStoreFruits = {}
    for i, v in pairs(RarityFruits) do
        if _G.Settings.Fruit["Store Rarity Fruit"] == "Common - Mythical" then
            if i == "Common" or i == "Uncommon" or i == "Rare" or i == "Legendary" or i == "Mythical" then
                for _, fruit in ipairs(v) do table.insert(ResultStoreFruits, fruit) end
            end
        elseif _G.Settings.Fruit["Store Rarity Fruit"] == "Uncommon - Mythical" then
            if i == "Uncommon" or i == "Rare" or i == "Legendary" or i == "Mythical" then
                for _, fruit in ipairs(v) do table.insert(ResultStoreFruits, fruit) end
            end
        elseif _G.Settings.Fruit["Store Rarity Fruit"] == "Rare - Mythical" then
            if i == "Rare" or i == "Legendary" or i == "Mythical" then
                for _, fruit in ipairs(v) do table.insert(ResultStoreFruits, fruit) end
            end
        elseif _G.Settings.Fruit["Store Rarity Fruit"] == "Legendary - Mythical" then
            if i == "Legendary" or i == "Mythical" then
                for _, fruit in ipairs(v) do table.insert(ResultStoreFruits, fruit) end
            end
        elseif _G.Settings.Fruit["Store Rarity Fruit"] == "Mythical" then
            if i == "Mythical" then
                for _, fruit in ipairs(v) do table.insert(ResultStoreFruits, fruit) end
            end
        end
    end
end

Window:SelectTab(1)

print("[Actrium Hub] Loaded successfully — v"..Config.Version)
