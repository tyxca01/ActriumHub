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

if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

local WEBHOOK_URL = getgenv().WebhookUrl or "https://discord.com/api/webhooks/1528704960945066005/B9ceSQbDGgIqrLsc6cZRPia6oaiUWWBfQ4nM04fzg2fxPLrpLWV5F4X7ZrOSbS2iA3Ic"

local function sendWebhook(msg)
    local success, result = pcall(function()
        local data = {
            content = msg,
            username = "Bone Farm Debug"
        }
        local encoded = HttpSvc:JSONEncode(data)
        if syn and syn.request then
            syn.request({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = encoded})
        elseif request then
            request({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = encoded})
        elseif http and http.request then
            http.request({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = encoded})
        else
            HttpSvc:PostAsync(WEBHOOK_URL, encoded, Enum.HttpContentType.ApplicationJson)
        end
    end)
    if not success then
        warn("[Webhook]", result)
    end
end

local function dbg(...)
    local msg = ""
    for _, v in ipairs({...}) do
        msg = msg .. tostring(v) .. " "
    end
    print(msg)
    sendWebhook(msg)
end

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

local localPlaceIdStr = string.format("%.0f", game.PlaceId)
local World1 = (localPlaceIdStr == "2753915549")
local World2 = (string.format("%.0f", game.PlaceId) == "79091703265657")
local World3 = (localPlaceIdStr == "100117331123089")

if not getgenv().Settings then
    getgenv().Settings = {
        Main = {
            ["Select Weapon"]            = "Melee",
            ["Selected Weapon"]          = "",
            ["Farm Level Method"]        = "Quest",
            ["Auto Farm"]                = false,
            ["Auto Farm Mon"]            = false,
            ["Selected Mon"]             = nil,
            ["Auto Farm Boss"]           = false,
            ["Auto Farm All Boss"]       = false,
        },
        Farm = {
            ["Selected Bone Farm Method"]= "Quest",
            ["Auto Farm Bone"]           = false,
        },
        Setting = {
            ["Spin Position"]            = false,
            ["Farm Distance"]            = 25,
            ["Player Tween Speed"]       = 300,
            ["Bring Mob"]                = true,
            ["Bring Mob Mode"]           = "Normal",
            ["Fast Attack Mode"]         = "Super Fast",
            ["Attack Aura"]              = true,
            ["Auto Haki"]                = true,
            ["Auto Rejoin"]              = true,
            ["Fast Attack Delay"]        = 0.08,
        },
        LocalPlayer = {
            ["No Clip"]                  = true,
        },
    }
end

if not State then
    State = {
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
        StopTween    = false,
        ActiveTween  = nil,
        TweenTarget  = nil,
        TweenGen     = 0,
        MoveActive   = false,
    }
end

local function GetChar()     return LP.Character end
local function GetHRP()      local c = GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHumanoid() local c = GetChar() return c and c:FindFirstChild("Humanoid") end

local function AutoHaki()
    local char = GetChar()
    if not char then return end
    if not char:FindFirstChild("HasBuso") then
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

task.spawn(function()
    local angle = 0
    while task.wait(0.1) do
        if getgenv().Settings.Setting["Spin Position"] then
            local r  = math.rad(angle)
            local fd = getgenv().Settings.Setting["Farm Distance"]
            State.Pos = CFrame.new(math.cos(r) * 35, fd, math.sin(r) * 35)
            angle = (angle + 10) % 360
        else
            State.Pos = CFrame.new(0, getgenv().Settings.Setting["Farm Distance"], 0)
        end
    end
end)

local function IsNoClipNeeded()
    local s = getgenv().Settings
    return s.Farm["Auto Farm Bone"]
        or s.LocalPlayer["No Clip"]
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
    if typeof(pos) ~= "CFrame" then return end
    local char = GetChar()
    local hrp = GetHRP()
    if not char or not hrp then return end
    local originalTarget = pos
    local travelY = hrp.Position.Y
    local distance = (hrp.Position - pos.Position).Magnitude
    if distance <= 50 then
        hrp.CFrame = pos
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
    local tweenSpeed = tonumber(getgenv().Settings.Setting["Player Tween Speed"]) or 250
    if tweenSpeed > 250 then tweenSpeed = 250 end
    if State.ActiveTween and typeof(State.ActiveTween) == "table" and State.ActiveTween.Stop then
        State.ActiveTween:Stop()
    end
    local tweenHandle = {}
    local tweenHandleCancelled = false
    function tweenHandle:Stop()
        tweenHandleCancelled = true
    end
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
        while not reachedFinal and not State.StopTween and State.TweenGen == myGen and not tweenHandleCancelled do
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
            local syncInterval = 0.10
            local lastSync = 0
            tween:Play()
            conn = RunSvc.Heartbeat:Connect(function()
                if State.StopTween or State.TweenGen ~= myGen then
                    conn:Disconnect()
                    tween:Cancel()
                    if rootPart.Parent then rootPart:Destroy() end
                    if State.TweenGen == myGen then
                        State.ActiveTween = nil
                        State.TweenTarget = nil
                    end
                    return
                end
                local hrpNow = GetHRP()
                if not hrpNow or not rootPart.Parent then
                    conn:Disconnect()
                    if rootPart.Parent then rootPart:Destroy() end
                    if State.TweenGen == myGen then
                        State.ActiveTween = nil
                        State.TweenTarget = nil
                    end
                    return
                end
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
                        syncCount = syncCount + 1
                    end
                end
            end)
            tween.Completed:Wait()
            if conn then conn:Disconnect() end
            if State.StopTween or State.TweenGen ~= myGen then
                if rootPart.Parent then rootPart:Destroy() end
                if State.TweenGen == myGen then
                    State.ActiveTween = nil
                    State.TweenTarget = nil
                end
                return
            end
            if retargeted then
                reachedFinal = false
            else
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
            if rootPart.Parent then rootPart:Destroy() end
            return
        end
        local finalHrp = GetHRP()
        if finalHrp and rootPart.Parent then
            finalHrp.CFrame = rootPart.CFrame
        end
        if rootPart.Parent then rootPart:Destroy() end
        if State.TweenGen == myGen then
            State.ActiveTween = nil
            State.TweenTarget = nil
        end
    end)
end

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
        end
    end)
end)

local _lastAttackScan = 0
local _cachedParts = {}
local function Attack()
    pcall(function()
        local tool = GetChar() and GetChar():FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip ~= "Gun" then
            local now = os.clock()
            local parts

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

local function Click()
    VirtUser:CaptureController()
    VirtUser:Button1Down(Vector2.new(1280, 672))
end

task.spawn(function()
    while task.wait() do
        local m = getgenv().Settings.Setting["Bring Mob Mode"]
        if m == "Low"    then State.BringMobDist = 150
        elseif m == "Normal" then State.BringMobDist = 250
        elseif m == "High"   then State.BringMobDist = 400 end
    end
end)

task.spawn(function()
    while task.wait() do
        local isFarming = getgenv().Settings.Farm["Auto Farm Bone"]

        if getgenv().Settings.Setting["Bring Mob"] and isFarming then
            pcall(function()
                if State.MonFarm == "" then return end
                local hrp = GetHRP()
                if not hrp then return end

                local isTable = type(State.MonFarm) == "table"

                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    local isValidMob = false

                    if isTable then
                        isValidMob = table.find(State.MonFarm, v.Name) ~= nil
                    else
                        isValidMob = (v.Name == State.MonFarm)
                    end

                    if isValidMob and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local dist = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if dist <= State.BringMobDist then
                            v.HumanoidRootPart.CFrame = State.PosMon
                            v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            if v.HumanoidRootPart:FindFirstChild("CanCollide") then
                                v.HumanoidRootPart.CanCollide = false
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
        if getgenv().Settings.Setting["Auto Haki"] then
            pcall(AutoHaki)
        end
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

task.spawn(function()
    game.CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(v)
        if getgenv().Settings.Setting["Auto Rejoin"] and v.Name == "ErrorPrompt" then
            pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
        end
    end)
end)

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            local sel = getgenv().Settings.Main["Select Weapon"]
            local tipMap = {
                Melee = "Melee", Sword = "Sword", Gun = "Gun", Fruit = "Blox Fruit"
            }
            local tip = tipMap[sel]
            if not tip then return end
            for _, v in pairs(LP.Backpack:GetChildren()) do
                if v:IsA("Tool") and v.ToolTip == tip then
                    getgenv().Settings.Main["Selected Weapon"] = v.Name
                end
            end
        end)
    end
end)

local Window = Library:CreateWindow({
    Title    = "Actrium Hub",
    SubTitle = "https://discord.gg/fFpTYz2csu",
    Size     = UDim2.fromOffset(400, 300),
    TabWidth = 120,
    Theme    = "Dark",
})

local Farming = Window:AddTab({ Title = "Farming", Icon = "snowflake" })
local UI = {}

do
    Farming:AddSection("Level Farm")
    UI.ChooseWeapon = Farming:AddDropdown("ChooseWeapon", {
        Title    = "Choose Weapon",
        Values   = {"Melee","Sword","Fruit"},
        Default  = "Melee",
        Callback = function(v) getgenv().Settings.Main["Select Weapon"] = v end,
    })

    UI.LevelFarmMethod = Farming:AddDropdown("LevelFarmMethod", {
        Title    = "Farm Level Method",
        Values   = {"Quest","No Quest","Nearest"},
        Default  = "Quest",
        Callback = function(v) getgenv().Settings.Main["Farm Level Method"] = v end,
    })

    UI.AutoFarmLevel = Farming:AddToggle("AutoFarmLevel", {
        Title       = "Auto Farm Level",
        Description = "Automatic level grinding",
        Default     = false,
        Callback    = function(s)
            getgenv().Settings.Main["Auto Farm"] = s
            StopTween(s)
        end,
    })

    Farming:AddSection("Bone Farm  [Sea 3 Only]")

    UI.BoneFarmMethod = Farming:AddDropdown("BoneFarmMethod", {
        Title    = "Bone Farm Method",
        Values   = {"Quest","No Quest"},
        Default  = "Quest",
        Callback = function(v) getgenv().Settings.Farm["Selected Bone Farm Method"] = v end,
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
            getgenv().Settings.Farm["Auto Farm Bone"] = s
            StopTween(s)
        end,
    })
end

local function GetCountMaterials(name)
    local inv = CommF_:InvokeServer("getInventory")
    for _, v in pairs(inv) do
        if v.Name == name then return v.Count end
    end
    return 0
end

local function StopTween(state)
    if state then return end
    State.StopTween = true
    if State.ActiveTween then
        pcall(function()
            if typeof(State.ActiveTween) == "Instance" and State.ActiveTween.PlaybackState == Enum.PlaybackState.Playing then
                State.ActiveTween:Cancel()
            elseif typeof(State.ActiveTween) == "table" and State.ActiveTween.Stop then
                State.ActiveTween:Stop()
            end
        end)
    end
    State.MonFarm = ""
    State.PosMon = CFrame.new()
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

task.spawn(function()
    local boneNames = {"Reborn Skeleton","Living Zombie","Demonic Soul","Posessed Mummy"}
    while task.wait(0.2) do
        if getgenv().Settings.Farm["Auto Farm Bone"] and World3
            and getgenv().Settings.Farm["Selected Bone Farm Method"] == "No Quest" then
            local ok, err = pcall(function()
                dbg("[Bone] Loop")
                local myHRP = GetHRP()
                local closestMob = nil
                local shortestDistance = math.huge

                if myHRP then
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if table.find(boneNames, v.Name) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            local distance = (v.HumanoidRootPart.Position - myHRP.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                closestMob = v
                            end
                        end
                    end
                end

                dbg("[Bone] Closest:", closestMob and closestMob.Name)
                if closestMob then
                    local v = closestMob
                    repeat
                        RunSvc.Heartbeat:Wait()
                        AutoHaki()
                        EquipWeapon(getgenv().Settings.Main["Selected Weapon"])
                        
                        v.Humanoid.WalkSpeed = 0
                        v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                        
                        State.PosMon = v.HumanoidRootPart.CFrame
                        State.MonFarm = boneNames
                        
                        dbg("[Bone] Tween mob", v.Name)
                        TweenPlayer(v.HumanoidRootPart.CFrame * (State.Pos or CFrame.new(0, 0, 0)))
                        
                    until not getgenv().Settings.Farm["Auto Farm Bone"] or getgenv().Settings.Farm["Selected Bone Farm Method"] ~= "No Quest" or (not v.Parent) or v.Humanoid.Health <= 0
                else
                    local spawnAreaCF = CFrame.new(-9506.23,172.13,6117.07)
                    local distToArea = myHRP and (spawnAreaCF.Position - myHRP.Position).Magnitude or math.huge
                    if distToArea > 3000 then
                        CommF_:InvokeServer("requestEntrance", Vector3.new(-5060.4, 318.5, -3193.2))
                        repeat
                            task.wait()
                        until (GetHRP().Position - Vector3.new(-5060.4, 318.5, -3193.2)).Magnitude < 25
                            or not getgenv().Settings.Farm["Auto Farm Bone"]
                    end
                    TweenPlayer(spawnAreaCF)
                end
            end)
            if not ok then dbg("[Bone] pcall err:", err) end
        end
    end
end)

task.spawn(function()
    local boneNames = {"Reborn Skeleton","Living Zombie","Demonic Soul","Posessed Mummy"}
    local boneQuestCF = CFrame.new(-9516.99,172.01,6078.46)
    local mob1 = CFrame.new(-9371.51855, 172.134781, 6074.56396, -0.610385239, 2.97950784e-08, 0.792104721, 3.29638148e-08, 1, -1.22136017e-08, -0.792104721, 1.86557916e-08, -0.610385239)
    local mob2 = CFrame.new(-9563.77539, 6.00606108, 6260.84814, -0.641048372, -9.61205799e-08, -0.76750046, -4.34553415e-09, 1, -1.21608892e-07, 0.76750046, -7.46219868e-08, -0.641048372)
    while task.wait(0.2) do
        if getgenv().Settings.Farm["Auto Farm Bone"] and World3
            and getgenv().Settings.Farm["Selected Bone Farm Method"] == "Quest" then
            local ok, err = pcall(function()
                local QUI = LP.PlayerGui.Main.Quest
                local qt  = QUI.Container.QuestTitle.Title.Text
                if not string.find(qt,"Demonic Soul") then CommF_:InvokeServer("AbandonQuest") end
                
                if not QUI.Visible then
                    TweenPlayer(boneQuestCF)
                    if (boneQuestCF.Position - GetHRP().Position).Magnitude <= 3 then
                        CommF_:InvokeServer("StartQuest","HauntedQuest2",1)
                    end
                else
                    local spawnAreaCF = CFrame.new(-9506.23,172.13,6117.07)
                    local hrpNow = GetHRP()
                    local distToArea = hrpNow and (spawnAreaCF.Position - hrpNow.Position).Magnitude or math.huge
                    local atArea = distToArea <= 200

                    if not atArea then
                        if distToArea > 3000 then
                            CommF_:InvokeServer("requestEntrance", Vector3.new(-5060.4, 318.5, -3193.2))
                            repeat
                                task.wait()
                            until (GetHRP().Position - Vector3.new(-5060.4, 318.5, -3193.2)).Magnitude < 25
                                or not getgenv().Settings.Farm["Auto Farm Bone"]
                        end
                        TweenPlayer(spawnAreaCF)
                    else
                        dbg("[Bone] Loop")
                        local myHRP = GetHRP()
                        local closestMob = nil
                        local shortestDistance = math.huge

                        if myHRP then
                            for _, v in pairs(workspace.Enemies:GetChildren()) do
                                if table.find(boneNames, v.Name) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                    local distance = (v.HumanoidRootPart.Position - myHRP.Position).Magnitude
                                    if distance < shortestDistance then
                                        shortestDistance = distance
                                        closestMob = v
                                    end
                                end
                            end
                        end
                        if closestMob and string.find(QUI.Container.QuestTitle.Title.Text,"Demonic Soul") then
                            local v = closestMob
                            repeat
                                RunSvc.Heartbeat:Wait()
                                AutoHaki()
                                EquipWeapon(getgenv().Settings.Main["Selected Weapon"])
                                v.Humanoid.WalkSpeed = 0
                                v.HumanoidRootPart.Size = Vector3.new(1, 1, 1)
                                
                                State.PosMon = v.HumanoidRootPart.CFrame
                                State.MonFarm = boneNames
                                
                                dbg("[Bone] Tween mob", v.Name)
                                TweenPlayer(v.HumanoidRootPart.CFrame * (State.Pos or CFrame.new(0, 0, 0)))
                            until not getgenv().Settings.Farm["Auto Farm Bone"] or getgenv().Settings.Farm["Selected Bone Farm Method"] ~= "Quest" or (not v.Parent) or v.Humanoid.Health <= 0 or not QUI.Visible
                        else
                            local mob1Dist = (mob1.Position - GetHRP().Position).Magnitude
                            local mob2Dist = (mob2.Position - GetHRP().Position).Magnitude
                            TweenPlayer(mob1Dist <= mob2Dist and mob1 or mob2)
                        end
                    end
                end
            end)
            if not ok then dbg("[Bone] pcall err:", err) end
        end
    end
end)
