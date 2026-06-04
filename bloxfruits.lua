
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local WEBHOOK_URL = "https://discord.com/api/webhooks/1511060078403522591/fjKWrx72RknPnUNTDojXioa3j9pXiCCweCtipHSi9Jo0Rr4HWKUEvS3GeketwwUnQzcW" -- e.g. "https://discord.com/api/webhooks/..."

local function safePostJson(url, data)
    if not url or url == "" then
        return
    end
    pcall(function()
        HttpService:PostAsync(url, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
end

local function concatArgs(args)
    for i = 1, #args do args[i] = tostring(args[i]) end
    return table.concat(args, "\t")
end

local function sendWebhookMessage(text)
    pcall(function()
        safePostJson(WEBHOOK_URL, { content = tostring(text) })
    end)
end

local _print, _warn, _error = print, warn, error
print = function(...)
    local args = { ... }
    pcall(_print, table.unpack(args))
    spawn(function()
        sendWebhookMessage("[PRINT] " .. concatArgs(args))
    end)
end
warn = function(...)
    local args = { ... }
    pcall(_warn, table.unpack(args))
    spawn(function()
        sendWebhookMessage("[WARN] " .. concatArgs(args))
    end)
end
error = function(...)
    local args = { ... }
    pcall(_error, table.unpack(args))
    spawn(function()
        sendWebhookMessage("[ERROR] " .. concatArgs(args))
    end)
end

pcall(function()
    LogService.MessageOut:Connect(function(message, messageType)
        spawn(function()
            sendWebhookMessage(string.format("[ROBLOX][%s] %s", tostring(messageType), tostring(message)))
        end)
    end)
end)

local Config = { Version = "1.0.0" }
local Library, SaveManager, InterfaceManager
do
    local ok, results = pcall(function()
        local fn
        if readfile and isfile and isfile("Ui.lua") then
            local content = readfile("Ui.lua")
            fn = loadstring(content)
        else
            local url = "https://raw.githubusercontent.com/xritura01/Ui/main/Ui.lua"
            fn = loadstring(game:HttpGet(url, true))
        end
        return { fn() }
    end)
    if not ok or not results then
        error("Failed to load UI library")
    end
    Library, SaveManager, InterfaceManager = results[1], results[2], results[3]
end

local Window = Library:CreateWindow({
    Title    = "Actrium Hub",
    SubTitle = "v" .. Config.Version,
    Size     = UDim2.fromOffset(600, 480),
    TabWidth = 140,
    Theme    = "Default_AH",
})

local Tabs = {
    Farming   = Window:AddTab({ Title = "Farming",       Icon = "lucide-snowflake" }),
    Quests    = Window:AddTab({ Title = "Quests",        Icon = "file-question" }),
    Raids     = Window:AddTab({ Title = "Raids",         Icon = "skull" }),
    Teleports = Window:AddTab({ Title = "Teleports",     Icon = "rbxassetid://10734910680" }),
    V4        = Window:AddTab({ Title = "V4 and Trials", Icon = "lucide-trophy" }),
    ShopEvent = Window:AddTab({ Title = "Sea Event",     Icon = "waves" }),
    Status    = Window:AddTab({ Title = "Status",        Icon = "info" }),
    Player    = Window:AddTab({ Title = "Player",        Icon = "user" }),
    PvP       = Window:AddTab({ Title = "PvP",           Icon = "swords" }),
    Webhook   = Window:AddTab({ Title = "Webhook",       Icon = "rbxassetid://112812457747322" }),
    Misc      = Window:AddTab({ Title = "Shop",          Icon = "shopping-bag" }),
    Settings  = Window:AddTab({ Title = "Settings",      Icon = "settings" }),
}

local MiniWindow = Library:CreateMiniWindow({
    Title    = "Actrium Hub",
    SubTitle = "Sub Window",
    Size     = UDim2.fromOffset(320, 220),
    Position = UDim2.fromOffset(640, 50),
})

local QuickSection = MiniWindow:AddSection("Information")
QuickSection:AddParagraph({
    Title   = "Welcome",
    Content = "Actrium Hub v" .. Config.Version .. " loaded successfully.",
})
































local FarmMainSection = Tabs.Farming:AddSection("Level Farm")

local ChooseWeaponDropdown = Tabs.Farming:AddDropdown("ChooseWeapon", {
    Title   = "Choose Weapon",
    Values  = { "Melee", "Sword", "Fruit" },
    Default = "Melee",
    Callback = function(option)
        _G.Settings.Main["Select Weapon"] = option
    end,
})

local LevelFarmMethodDropdown = Tabs.Farming:AddDropdown("LevelFarmMethod", {
    Title   = "Farm Level Method",
    Values  = { "Quest", "No Quest", "Nearest" },
    Default = "Quest",
    Callback = function(option)
        _G.Settings.Main["Farm Level Method"] = option
    end,
})

local AutoLevelFarmToggle = Tabs.Farming:AddToggle("AutoFarmLevel", {
    Title    = "Auto Farm Level",
    Description = "Automatic Plowing Level",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Farm"] = state
    end,
})

local AutoFastFarmToggle = Tabs.Farming:AddToggle("AutoFastFarm", {
    Title    = "Auto Fast Farm",
    Description = "Work on Sea 1 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Fast Farm"] = state
    end,
})

local FarmMasterySection = Tabs.Farming:AddSection("Mastery Farm")

local MasteryMethodDropdown = Tabs.Farming:AddDropdown("MasteryMethod", {
    Title   = "Choose Mastery Method",
    Values  = { "Quest", "No Quest", "Nearest" },
    Default = "Quest",
    Callback = function(option)
        _G.Settings.Main["Mastery Method"] = option
    end,
})

local AutoFruitMasteryToggle = Tabs.Farming:AddToggle("AutoFruitMastery", {
    Title    = "Auto Fruit Mastery",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Farm Fruit Mastery"] = state
    end,
})

local AutoGunMasteryToggle = Tabs.Farming:AddToggle("AutoGunMastery", {
    Title    = "Auto Gun Mastery",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Farm Gun Mastery"] = state
    end,
})

local ChooseSwordDropdown = Tabs.Farming:AddDropdown("ChooseSword", {
    Title     = "Choose Sword",
    Values    = { "Cutlass", "Katana", "Dual Katana", "Triple Katana", "Pipe", "Bisento", "Soul Cane" },
    Default   = nil,
    AllowNull = true,
    Callback  = function(option)
        _G.Settings.Main["Selected Mastery Sword"] = option
    end,
})

local AutoSwordMasteryToggle = Tabs.Farming:AddToggle("AutoSwordMastery", {
    Title    = "Auto Sword Mastery",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Farm Sword Mastery"] = state
    end,
})

local FarmTyrantSection = Tabs.Farming:AddSection("Tyrant Of The Skies")

local AutoSummonTyrantToggle = Tabs.Farming:AddToggle("AutoSummonTyrant", {
    Title    = "Auto Summon Tyrant Of The Skies",
    Description = "Auto Farming Monsters and Summoning Bosses",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Summon Tyrant Of The Skies"] = state
    end,
})

local AutoKillTyrantToggle = Tabs.Farming:AddToggle("AutoKillTyrant", {
    Title    = "Auto Kill Tyrant Of The Skies",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Kill Tyrant Of The Skies"] = state
    end,
})

local FarmMonSection = Tabs.Farming:AddSection("Monster Farm")

local ChooseMonDropdown = Tabs.Farming:AddDropdown("ChooseMon", {
    Title     = "Choose Monster",
    Values    = { "Custom" },
    Default   = nil,
    AllowNull = true,
    Callback  = function(option)
        _G.Settings.Main["Selected Mon"] = option
    end,
})

local AutoMonFarmToggle = Tabs.Farming:AddToggle("AutoMonFarm", {
    Title    = "Auto Farm Monster",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Farm Mon"] = state
    end,
})

local FarmBossSection = Tabs.Farming:AddSection("Boss Farm")

local BossStatusParagraph = Tabs.Farming:AddParagraph({
    Title   = "Boss Status",
    Content = "N/A",
})

local ChooseBossDropdown = Tabs.Farming:AddDropdown("ChooseBoss", {
    Title     = "Choose Boss",
    Values    = { "Custom" },
    Default   = nil,
    AllowNull = true,
    Callback  = function(option)
        _G.Settings.Main["Selected Boss"] = option
    end,
})

local AutoFarmBossToggle = Tabs.Farming:AddToggle("AutoFarmBoss", {
    Title    = "Auto Farm Boss",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Farm Boss"] = state
    end,
})

local AutoFarmAllBossToggle = Tabs.Farming:AddToggle("AutoFarmAllBoss", {
    Title    = "Auto Farm All Boss",
    Default  = false,
    Callback = function(state)
        _G.Settings.Main["Auto Farm All Boss"] = state
    end,
})

local FarmEliteSection = Tabs.Farming:AddSection("Elite Hunter")

local EliteHunterStatusParagraph = Tabs.Farming:AddParagraph({
    Title   = "Elite Hunter Status",
    Content = "N/A",
})

local EliteHunterProgressParagraph = Tabs.Farming:AddParagraph({
    Title   = "Elite Hunter Progress",
    Content = "N/A",
})

local AutoEliteHunterToggle = Tabs.Farming:AddToggle("AutoEliteHunter", {
    Title    = "Auto Elite Hunter",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Elite Hunter"] = state
    end,
})

local AutoEliteHunterHopToggle = Tabs.Farming:AddToggle("AutoEliteHunterHop", {
    Title    = "Auto Elite Hunter Hop",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Elite Hunter Hop"] = state
    end,
})

local FarmBoneSection = Tabs.Farming:AddSection("Bone Farm")

local BoneFarmMethodDropdown = Tabs.Farming:AddDropdown("BoneFarmMethod", {
    Title   = "Choose Bone Farm Method",
    Values  = { "Quest", "No Quest" },
    Default = "Quest",
    Callback = function(option)
        _G.Settings.Farm["Selected Bone Farm Method"] = option
    end,
})

local BoneCountParagraph = Tabs.Farming:AddParagraph({
    Title   = "Bones Owned",
    Content = "N/A",
})

local AutoFarmBoneToggle = Tabs.Farming:AddToggle("AutoFarmBone", {
    Title    = "Auto Farm Bone",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Farm Bone"] = state
    end,
})

local AutoRandomSurpriseToggle = Tabs.Farming:AddToggle("AutoRandomSurprise", {
    Title    = "Auto Random Surprise",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Random Surprise"] = state
    end,
})

local FarmChestSection = Tabs.Farming:AddSection("Chest Farm")

local AutoFarmChestTweenToggle = Tabs.Farming:AddToggle("AutoFarmChestTween", {
    Title    = "Auto Farm Chest Tween",
    Description = "Tween to chest",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Farm Chest Tween"] = state
    end,
})

local AutoFarmChestInstantToggle = Tabs.Farming:AddToggle("AutoFarmChestInstant", {
    Title    = "Auto Farm Chest Instant",
    Description = "Instant to chest",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Farm Chest Instant"] = state
    end,
})

local AutoStopItemsToggle = Tabs.Farming:AddToggle("AutoStopItems", {
    Title    = "Auto Stop Items",
    Description = "Stop When Get God's Chalice or FoD",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Stop Items"] = state
    end,
})

local FarmMaterialSection = Tabs.Farming:AddSection("Materials")

local MaterialDropdown = Tabs.Farming:AddDropdown("MaterialChoice", {
    Title     = "Choose Material",
    Values    = { "Custom" },
    Default   = nil,
    AllowNull = true,
    Callback  = function(option)
        _G.Settings.Farm["Selected Material"] = option
    end,
})

local AutoFarmMaterialToggle = Tabs.Farming:AddToggle("AutoFarmMaterial", {
    Title    = "Auto Farm Material",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Farm Material"] = state
    end,
})

local FarmCakePrinceSection = Tabs.Farming:AddSection("Cake Prince")

local CakePrinceStatusParagraph = Tabs.Farming:AddParagraph({
    Title   = "Cake Prince Status",
    Content = "N/A",
})

local AutoKatakuriToggle = Tabs.Farming:AddToggle("AutoKatakuri", {
    Title    = "Auto Katakuri",
    Description = "Auto Farm + Kill Cake Prince [ Sea 3 Only ]",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Farm Katakuri"] = state
    end,
})

local AutoSpawnCakePrinceToggle = Tabs.Farming:AddToggle("AutoSpawnCakePrince", {
    Title    = "Auto Spawn Cake Prince",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Spawn Cake Prince"] = state
    end,
})

local AutoKillCakePrinceToggle = Tabs.Farming:AddToggle("AutoKillCakePrince", {
    Title    = "Auto Kill Cake Prince",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Kill Cake Prince"] = state
    end,
})

local AutoKillDoughKingToggle = Tabs.Farming:AddToggle("AutoKillDoughKing", {
    Title    = "Auto Kill Dough King",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Kill Dough King"] = state
    end,
})

local FarmPirateRaidSection = Tabs.Farming:AddSection("Pirate Raid")

local AutoPirateRaidToggle = Tabs.Farming:AddToggle("AutoPirateRaid", {
    Title    = "Auto Pirate Raid",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Farm["Auto Pirate Raid"] = state
    end,
})

-- ============================================================
-- QUESTS TAB
-- (ItemsTab → World / Fighting Style / Gun & Sword)
-- ============================================================
local WorldSection = Tabs.Quests:AddSection("World")

local AutoSecondSeaToggle = Tabs.Quests:AddToggle("AutoSecondSea", {
    Title    = "Auto Second Sea",
    Description = "Function Sea 1 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Second Sea"] = state
    end,
})

local AutoThirdSeaToggle = Tabs.Quests:AddToggle("AutoThirdSea", {
    Title    = "Auto Third Sea",
    Description = "Function Sea 2 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Third Sea"] = state
    end,
})

local FightingStyleSection = Tabs.Quests:AddSection("Fighting Style")

local AutoSuperHumanToggle = Tabs.Quests:AddToggle("AutoSuperHuman", {
    Title    = "Auto Super Human",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Super Human"] = state
    end,
})

local AutoDeathStepToggle = Tabs.Quests:AddToggle("AutoDeathStep", {
    Title    = "Auto Death Step",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Death Step"] = state
    end,
})

local AutoSharkmanKarateToggle = Tabs.Quests:AddToggle("AutoSharkmanKarate", {
    Title    = "Auto Sharkman Karate",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Fishman Karate"] = state
    end,
})

local AutoElectricClawToggle = Tabs.Quests:AddToggle("AutoElectricClaw", {
    Title    = "Auto Electric Claw",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Electric Claw"] = state
    end,
})

local AutoDragonTalonToggle = Tabs.Quests:AddToggle("AutoDragonTalon", {
    Title    = "Auto Dragon Talon",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Dragon Talon"] = state
    end,
})

local AutoGodHumanToggle = Tabs.Quests:AddToggle("AutoGodHuman", {
    Title    = "Auto God Human",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto God Human"] = state
    end,
})

local GunSwordSection = Tabs.Quests:AddSection("Gun & Sword")

local AutoGetSaberToggle = Tabs.Quests:AddToggle("AutoGetSaber", {
    Title    = "Auto Get Saber",
    Description = "Function Sea 1 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Saber"] = state
    end,
})

local AutoBuddySwordToggle = Tabs.Quests:AddToggle("AutoBuddySword", {
    Title    = "Auto Buddy Sword",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Buddy Sword"] = state
    end,
})

local AutoSoulGuitarToggle = Tabs.Quests:AddToggle("AutoSoulGuitar", {
    Title    = "Auto Soul Guitar",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Soul Guitar"] = state
    end,
})

local AutoRengokuToggle = Tabs.Quests:AddToggle("AutoRengoku", {
    Title    = "Auto Rengoku",
    Description = "Function Sea 2 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Rengoku"] = state
    end,
})

local AutoHallowScytheToggle = Tabs.Quests:AddToggle("AutoHallowScythe", {
    Title    = "Auto Hallow Scythe",
    Description = "Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Hallow Scythe"] = state
    end,
})

local AutoWardenSwordToggle = Tabs.Quests:AddToggle("AutoWardenSword", {
    Title    = "Auto Warden Sword",
    Description = "Function Sea 1 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Warden Sword"] = state
    end,
})

local AutoGetYamaToggle = Tabs.Quests:AddToggle("AutoGetYama", {
    Title    = "Auto Get Yama",
    Description = "Need 30 Elite Hunter, Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Yama"] = state
    end,
})

local AutoGetYamaHopToggle = Tabs.Quests:AddToggle("AutoGetYamaHop", {
    Title    = "Auto Get Yama Hop",
    Description = "Hop If Elite Hunter Not Spawn",
    Default  = false,
    Callback = function(state) end,
})

local AutoGetTushitaToggle = Tabs.Quests:AddToggle("AutoGetTushita", {
    Title    = "Auto Get Tushita",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Tushita"] = state
    end,
})

local AutoDragonTridentToggle = Tabs.Quests:AddToggle("AutoDragonTrident", {
    Title    = "Auto Dragon Trident",
    Description = "Function Sea 2 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Dragon Trident"] = state
    end,
})

local AutoGreybeardToggle = Tabs.Quests:AddToggle("AutoGreybeard", {
    Title    = "Auto Greybeard",
    Description = "Function Sea 1 Only",
    Default  = false,
    Callback = function(state) end,
})

local AutoSharkSawToggle = Tabs.Quests:AddToggle("AutoSharkSaw", {
    Title    = "Auto Shark Saw",
    Description = "Function Sea 1 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Shawk Saw"] = state
    end,
})

local AutoPoleToggle = Tabs.Quests:AddToggle("AutoPole", {
    Title    = "Auto Pole",
    Description = "Function Sea 1 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Pole"] = state
    end,
})

local AutoDarkDaggerToggle = Tabs.Quests:AddToggle("AutoDarkDagger", {
    Title    = "Auto Dark Dagger",
    Description = "Need Spawn Rip Indra, Function Sea 3 Only",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Dark Dagger"] = state
    end,
})































local RaidSection = Tabs.Raids:AddSection("Raid")

local RaidTimeParagraph = Tabs.Raids:AddParagraph({
    Title   = "Raid Time",
    Content = "N/A",
})

local IslandRaidParagraph = Tabs.Raids:AddParagraph({
    Title   = "Island",
    Content = "N/A",
})

local ChooseChipRaidDropdown = Tabs.Raids:AddDropdown("ChooseChipRaid", {
    Title     = "Choose Chip",
    Values    = { "Custom" },
    Default   = nil,
    AllowNull = true,
    Callback  = function(option)
        _G.Settings.Raid["Selected Chip"] = option
    end,
})

local AutoRaidToggle = Tabs.Raids:AddToggle("AutoRaid", {
    Title    = "Auto Raid",
    Description = "Complete automatically",
    Default  = false,
    Callback = function(state)
        _G.Settings.Raid["Auto Raid"] = state
    end,
})

local AutoAwakeningToggle = Tabs.Raids:AddToggle("AutoAwakening", {
    Title    = "Auto Awaken",
    Default  = false,
    Callback = function(state)
        _G.Settings.Raid["Auto Awaken"] = state
    end,
})

local PriceDevilFruitSlider = Tabs.Raids:AddSlider("PriceDevilFruit", {
    Title    = "Price (Unstore Devil Fruit)",
    Min      = 100000,
    Max      = 10000000,
    Default  = 1000000,
    Rounding = 0,
    Callback = function(value)
        _G.Settings.Raid["Price Devil Fruit"] = value
    end,
})

local AutoUnstoreDevilFruitToggle = Tabs.Raids:AddToggle("AutoUnstoreDevilFruit", {
    Title    = "Auto Unstore Devil Fruit",
    Default  = false,
    Callback = function(state)
        _G.Settings.Raid["Unstore Devil Fruit"] = state
    end,
})

Tabs.Raids:AddButton({
    Title    = "Teleport To Lab",
    Callback = function()
        if World2 then
            TweenPlayer(CFrame.new(-6438.73535, 250.645355, -4501.50684))
        elseif World3 then
            TweenPlayer(CFrame.new(-5017.40869, 314.844055, -2823.0127))
        end
    end,
})

local LawRaidSection = Tabs.Raids:AddSection("Law Raid")

local AutoLawRaidToggle = Tabs.Raids:AddToggle("AutoLawRaid", {
    Title    = "Auto Law Raid",
    Default  = false,
    Callback = function(state)
        _G.Settings.Raid["Law Raid"] = state
    end,
})



















local TeleportSeaSection = Tabs.Teleports:AddSection("Teleport")

Tabs.Teleports:AddButton({
    Title    = "Teleport To First Sea",
    Callback = function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelMain")
    end,
})

Tabs.Teleports:AddButton({
    Title    = "Teleport To Second Sea",
    Callback = function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelDressrosa")
    end,
})

Tabs.Teleports:AddButton({
    Title    = "Teleport To Third Sea",
    Callback = function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelZou")
    end,
})

local TeleportIslandSection = Tabs.Teleports:AddSection("Island")

local SelectedTeleportIslandDropdown = Tabs.Teleports:AddDropdown("TeleportIsland", {
    Title     = "Choose Island",
    Values    = { "Custom" },
    Default   = nil,
    AllowNull = true,
    Callback  = function(option) end,
})

local AutoTeleportToIslandToggle = Tabs.Teleports:AddToggle("AutoTeleportIsland", {
    Title    = "Teleport To Island",
    Default  = false,
    Callback = function(state)
        _G.Settings.Items["Auto Press Haki Button"] = state
    end,
})

local TeleportNpcSection = Tabs.Teleports:AddSection("Npc")

local SelectedNpcDropdown = Tabs.Teleports:AddDropdown("TeleportNpc", {
    Title     = "Choose Npc",
    Values    = { "Custom" },
    Default   = nil,
    AllowNull = true,
    Callback  = function(option) end,
})

local TeleportToNpcToggle = Tabs.Teleports:AddToggle("TeleportToNpc", {
    Title    = "Teleport To Npc",
    Default  = false,
    Callback = function(state) end,
})
































local RaceSection = Tabs.V4:AddSection("Race")

local SelectedPlaceDropdown = Tabs.V4:AddDropdown("SelectedPlace", {
    Title     = "Selected Place",
    Values    = { "Custom" },
    Default   = nil,
    AllowNull = true,
    Callback  = function(option)
        _G.Settings.Race["Selected Place"] = option
    end,
})

local TeleportToPlaceToggle = Tabs.V4:AddToggle("TeleportToPlace", {
    Title    = "Teleport To Place",
    Default  = false,
    Callback = function(state)
        _G.Settings.Race["Teleport To Place"] = state
    end,
})

local AutoBuyGearToggle = Tabs.V4:AddToggle("AutoBuyGear", {
    Title    = "Auto Buy Gear",
    Default  = false,
    Callback = function(state)
        _G.Settings.Race["Auto Buy Gear"] = state
    end,
})

local TweenToMirageIslandToggle = Tabs.V4:AddToggle("TweenToMirageIsland", {
    Title    = "Tween To Mirage Island",
    Description = "Tween to highest point",
    Default  = false,
    Callback = function(state)
        _G.Settings.Race["Tween To Highest Mirage"] = state
    end,
})

local FindBlueGearToggle = Tabs.V4:AddToggle("FindBlueGear", {
    Title    = "Find Blue Gear",
    Default  = false,
    Callback = function(state)
        _G.Settings.Race["Find Blue Gear"] = state
    end,
})

local LookMoonAbilityToggle = Tabs.V4:AddToggle("LookMoonAbility", {
    Title    = "Look Moon & use Ability",
    Default  = false,
    Callback = function(state)
        _G.Settings.Race["Look Moon Ability"] = state
    end,
})

local AutoTrainToggle = Tabs.V4:AddToggle("AutoTrain", {
    Title    = "Auto Train",
    Default  = false,
    Callback = function(state)
        _G.Settings.Race["Auto Train"] = state
    end,
})

Tabs.V4:AddButton({
    Title    = "Teleport To Race Door",
    Callback = function()
        if World3 then
            TweenPlayer(CFrame.new(-4888.05127, 695.891113, -2520.98584))
        end
    end,
})

Tabs.V4:AddButton({
    Title    = "Buy Ancient Quest",
    Callback = function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("NPCTalk", "Ability_Trainer", "Buy", 5)
    end,
})

local AutoTrialToggle = Tabs.V4:AddToggle("AutoTrial", {
    Title    = "Auto Trial",
    Default  = false,
    Callback = function(state)
        _G.Settings.Race["Auto Trial"] = state
    end,
})

local AutoKillPlayerAfterTrialToggle = Tabs.V4:AddToggle("AutoKillAfterTrial", {
    Title    = "Auto Kill Player After Trial",
    Default  = false,
    Callback = function(state)
        _G.Settings.Race["Auto Kill Player After Trial"] = state
    end,
})

























local SeaEventSection = Tabs.ShopEvent:AddSection("Sea Event")

local ChooseBoatDropdown = Tabs.ShopEvent:AddDropdown("ChooseBoat", {
    Title   = "Choose Boat",
    Values  = { "Guardian", "Beast Hunter", "PirateGrandBrigade", "MarineGrandBrigade", "PirateBrigade", "MarineBrigade", "PirateSloop", "MarineSloop" },
    Default = "Guardian",
    Callback = function(option)
        _G.Settings.SeaEvent["Selected Boat"] = option
    end,
})

local ChooseZoneDropdown = Tabs.ShopEvent:AddDropdown("ChooseZone", {
    Title   = "Choose Zone",
    Values  = { "Zone 1", "Zone 2", "Zone 3", "Zone 4", "Zone 5", "Zone 6", "Infinite" },
    Default = "Zone 5",
    Callback = function(option)
        _G.Settings.SeaEvent["Selected Zone"] = option
    end,
})

local BoatTweenSpeedSlider = Tabs.ShopEvent:AddSlider("BoatTweenSpeed", {
    Title    = "Boat Tween Speed",
    Min      = 1,
    Max      = 350,
    Default  = 300,
    Rounding = 0,
    Callback = function(value)
        _G.Settings.SeaEvent["Boat Tween Speed"] = value
    end,
})

local AutoSailBoatToggle = Tabs.ShopEvent:AddToggle("AutoSailBoat", {
    Title    = "Sail Boat",
    Description = "Auto Sail Boat & Kill Enemies",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaEvent["Sail Boat"] = state
    end,
})

local SeaEnemiesSection = Tabs.ShopEvent:AddSection("Enemies")

local AutoFarmSharkToggle = Tabs.ShopEvent:AddToggle("AutoFarmShark", {
    Title    = "Auto Farm Shark",
    Default  = true,
    Callback = function(state)
        _G.Settings.SeaEvent["Auto Farm Shark"] = state
    end,
})

local AutoFarmPiranhaToggle = Tabs.ShopEvent:AddToggle("AutoFarmPiranha", {
    Title    = "Auto Farm Piranha",
    Default  = true,
    Callback = function(state)
        _G.Settings.SeaEvent["Auto Farm Piranha"] = state
    end,
})

local AutoFarmFishCrewToggle = Tabs.ShopEvent:AddToggle("AutoFarmFishCrew", {
    Title    = "Auto Farm Fish Crew Member",
    Default  = true,
    Callback = function(state)
        _G.Settings.SeaEvent["Auto Farm Fish Crew Member"] = state
    end,
})

local SeaBoatSection = Tabs.ShopEvent:AddSection("Boat")

local AutoFarmGhostShipToggle = Tabs.ShopEvent:AddToggle("AutoFarmGhostShip", {
    Title    = "Auto Farm Ghost Ship",
    Default  = true,
    Callback = function(state)
        _G.Settings.SeaEvent["Auto Farm Ghost Ship"] = state
    end,
})

local AutoFarmPirateBrigadeToggle = Tabs.ShopEvent:AddToggle("AutoFarmPirateBrigade", {
    Title    = "Auto Farm Pirate Brigade",
    Default  = true,
    Callback = function(state)
        _G.Settings.SeaEvent["Auto Farm Pirate Brigade"] = state
    end,
})

local AutoFarmPirateGrandBrigadeToggle = Tabs.ShopEvent:AddToggle("AutoFarmPirateGrandBrigade", {
    Title    = "Auto Farm Pirate Grand Brigade",
    Default  = true,
    Callback = function(state)
        _G.Settings.SeaEvent["Auto Farm Pirate Grand Brigade"] = state
    end,
})

local SeaBossSection = Tabs.ShopEvent:AddSection("Sea Bosses")

local AutoFarmTerrorsharkToggle = Tabs.ShopEvent:AddToggle("AutoFarmTerrorshark", {
    Title    = "Auto Farm Terrorshark",
    Default  = true,
    Callback = function(state)
        _G.Settings.SeaEvent["Auto Farm Terrorshark"] = state
    end,
})

local AutoFarmSeabeastsToggle = Tabs.ShopEvent:AddToggle("AutoFarmSeabeasts", {
    Title    = "Auto Farm Seabeasts",
    Default  = true,
    Callback = function(state)
        _G.Settings.SeaEvent["Auto Farm Seabeasts"] = state
    end,
})

local SeaStackSection = Tabs.ShopEvent:AddSection("Sea Stack")

local PrehistoricStatusParagraph = Tabs.ShopEvent:AddParagraph({
    Title   = "Prehistoric Status",
    Content = "N/A",
})

local AutoSummonPrehistoricToggle = Tabs.ShopEvent:AddToggle("AutoSummonPrehistoric", {
    Title    = "Summon Prehistoric Island",
    Description = "Need Volcanic Magnet",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Summon Prehistoric Island"] = state
    end,
})

local TweenToPrehistoricToggle = Tabs.ShopEvent:AddToggle("TweenToPrehistoric", {
    Title    = "Tween To Prehistoric Island",
    Description = "Need Spawn",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Tween To Prehistoric Island"] = state
    end,
})

local AutoKillLavaGolemToggle = Tabs.ShopEvent:AddToggle("AutoKillLavaGolem", {
    Title    = "Auto Kill Lava Golem",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Auto Kill Lava Golem"] = state
    end,
})

local FrozenStatusParagraph2 = Tabs.ShopEvent:AddParagraph({
    Title   = "Frozen Status",
    Content = "N/A",
})

local AutoSummonFrozenToggle = Tabs.ShopEvent:AddToggle("AutoSummonFrozen", {
    Title    = "Summon Frozen Dimension",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Summon Frozen Dimension"] = state
    end,
})

local TweenToFrozenToggle = Tabs.ShopEvent:AddToggle("TweenToFrozen", {
    Title    = "Tween To Frozen Dimension",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Tween To Frozen Dimension"] = state
    end,
})

local LeviathanStatusParagraph = Tabs.ShopEvent:AddParagraph({
    Title   = "Leviathan Status",
    Content = "0",
})

Tabs.ShopEvent:AddButton({
    Title    = "Bribe Leviathan",
    Callback = function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BribeLeviathan")
    end,
})

local KitsuneStatusParagraph2 = Tabs.ShopEvent:AddParagraph({
    Title   = "Kitsune Status",
    Content = "N/A",
})

local AutoSummonKitsuneToggle = Tabs.ShopEvent:AddToggle("AutoSummonKitsune", {
    Title    = "Summon Kitsune Island",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Summon Kitsune Island"] = state
    end,
})

local TweenToKitsuneToggle = Tabs.ShopEvent:AddToggle("TweenToKitsune", {
    Title    = "Tween To Kitsune Island",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Tween To Kitsune Island"] = state
    end,
})

local AutoCollectAzureToggle = Tabs.ShopEvent:AddToggle("AutoCollectAzure", {
    Title    = "Auto Collect Azure Ember",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Auto Collect Azure Ember"] = state
    end,
})

local SetAzureEmberSlider = Tabs.ShopEvent:AddSlider("SetAzureEmber", {
    Title    = "Set Azure Ember",
    Min      = 1,
    Max      = 100,
    Default  = 20,
    Rounding = 0,
    Callback = function(value)
        _G.Settings.SeaStack["Set Azure Ember"] = value
    end,
})

local AutoTradeAzureToggle = Tabs.ShopEvent:AddToggle("AutoTradeAzure", {
    Title    = "Auto Trade Azure Ember",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Auto Trade Azure Ember"] = state
    end,
})

local MirageStatusParagraph2 = Tabs.ShopEvent:AddParagraph({
    Title   = "Mirage Status",
    Content = "N/A",
})

local TweenToMirageToggle = Tabs.ShopEvent:AddToggle("TweenToMirage", {
    Title    = "Tween To Mirage Island",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Tween To Mirage Island"] = state
    end,
})

local SeaBeastStackSection = Tabs.ShopEvent:AddSection("Sea Beasts")

local AutoAttackSeaBeastsToggle = Tabs.ShopEvent:AddToggle("AutoAttackSeaBeasts", {
    Title    = "Auto Attack Seabeasts",
    Default  = false,
    Callback = function(state)
        _G.Settings.SeaStack["Auto Attack Seabeasts"] = state
    end,
})

local SeaSettingSection = Tabs.ShopEvent:AddSection("Setting Sea")

local LightningToggle = Tabs.ShopEvent:AddToggle("Lightning", {
    Title    = "Lightning",
    Default  = false,
    Callback = function(state)
        _G.Settings.SettingSea["Lightning"] = state
    end,
})

local IncreaseBoatSpeedToggle = Tabs.ShopEvent:AddToggle("IncreaseBoatSpeed", {
    Title    = "Increase Speed Boat",
    Default  = false,
    Callback = function(state)
        _G.Settings.SettingSea["Increase Boat Speed"] = state
    end,
})

local NoClipRockToggle = Tabs.ShopEvent:AddToggle("NoClipRock", {
    Title    = "No Clip Rock",
    Default  = false,
    Callback = function(state)
        _G.Settings.SettingSea["No Clip Rock"] = state
    end,
})

local SeaToolsSection = Tabs.ShopEvent:AddSection("Tools")

local UseDevilFruitSkillToggle = Tabs.ShopEvent:AddToggle("UseDevilFruitSkill", {
    Title    = "Use Devil Fruit Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Use Devil Fruit Skill"] = state
    end,
})

local UseMeleeSkillToggle = Tabs.ShopEvent:AddToggle("UseMeleeSkill", {
    Title    = "Use Melee Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Use Melee Skill"] = state
    end,
})

local UseSwordSkillToggle = Tabs.ShopEvent:AddToggle("UseSwordSkill", {
    Title    = "Use Sword Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Use Sword Skill"] = state
    end,
})

local UseGunSkillToggle = Tabs.ShopEvent:AddToggle("UseGunSkill", {
    Title    = "Use Gun Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Use Gun Skill"] = state
    end,
})

local SeaDevilFruitSkillSection = Tabs.ShopEvent:AddSection("Devil Fruit Skill")

local DFZSkillToggle = Tabs.ShopEvent:AddToggle("DFZSkill", {
    Title    = "Devil Fruit Z Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Devil Fruit Z Skill"] = state
    end,
})

local DFXSkillToggle = Tabs.ShopEvent:AddToggle("DFXSkill", {
    Title    = "Devil Fruit X Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Devil Fruit X Skill"] = state
    end,
})

local DFCSkillToggle = Tabs.ShopEvent:AddToggle("DFCSkill", {
    Title    = "Devil Fruit C Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Devil Fruit C Skill"] = state
    end,
})

local DFVSkillToggle = Tabs.ShopEvent:AddToggle("DFVSkill", {
    Title    = "Devil Fruit V Skill",
    Default  = false,
    Callback = function(state)
        _G.Settings.SettingSea["Devil Fruit V Skill"] = state
    end,
})

local DFFSkillToggle = Tabs.ShopEvent:AddToggle("DFFSkill", {
    Title    = "Devil Fruit F Skill",
    Default  = false,
    Callback = function(state)
        _G.Settings.SettingSea["Devil Fruit F Skill"] = state
    end,
})

local MeleeSkillSection = Tabs.ShopEvent:AddSection("Melee Skill")

local MeleeZSkillToggle = Tabs.ShopEvent:AddToggle("MeleeZSkill", {
    Title    = "Melee Z Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Melee Z Skill"] = state
    end,
})

local MeleeXSkillToggle = Tabs.ShopEvent:AddToggle("MeleeXSkill", {
    Title    = "Melee X Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Melee X Skill"] = state
    end,
})

local MeleeCSkillToggle = Tabs.ShopEvent:AddToggle("MeleeCSkill", {
    Title    = "Melee C Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Melee C Skill"] = state
    end,
})

local MeleeVSkillToggle = Tabs.ShopEvent:AddToggle("MeleeVSkill", {
    Title    = "Melee V Skill",
    Default  = true,
    Callback = function(state)
        _G.Settings.SettingSea["Melee V Skill"] = state
    end,
})

-- Dragon Dojo inside Sea Event
local DragonDojoSection = Tabs.ShopEvent:AddSection("Dragon Dojo")

local AutoFarmBlazeEmberToggle = Tabs.ShopEvent:AddToggle("AutoFarmBlazeEmber", {
    Title    = "Auto Farm Blaze Ember",
    Default  = false,
    Callback = function(state)
        _G.Settings.DragonDojo["Auto Farm Blaze Ember"] = state
    end,
})

Tabs.ShopEvent:AddButton({
    Title    = "Craft Volcanic Magnet",
    Callback = function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("CraftItem", "Volcanic Magnet")
    end,
})


























local StatusSection = Tabs.Status:AddSection("Status")

local GameTimeParagraph = Tabs.Status:AddParagraph({
    Title   = "Game Time",
    Content = "0",
})

spawn(function()
    while task.wait() do
        pcall(function()
            local GameTime = math.floor(workspace.DistributedGameTime + 0.5)
            local Hour = math.floor(GameTime / 60 ^ 2) % 24
            local Minute = math.floor(GameTime / 60 ^ 1) % 60
            local Second = math.floor(GameTime / 60 ^ 0) % 60
            GameTimeParagraph:SetDesc(Hour .. " Hours " .. Minute .. " Minute " .. Second .. " Second")
        end)
    end
end)

local FpsParagraph = Tabs.Status:AddParagraph({
    Title   = "FPS",
    Content = "0",
})

spawn(function()
    while task.wait() do
        pcall(function()
            FpsParagraph:SetDesc(workspace:GetRealPhysicsFPS())
        end)
    end
end)

local PingParagraph = Tabs.Status:AddParagraph({
    Title   = "Ping",
    Content = "0",
})

spawn(function()
    while task.wait() do
        pcall(function()
            PingParagraph:SetDesc(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString())
        end)
    end
end)

local ServerStatusSection = Tabs.Status:AddSection("Server Status")

local MoonServerParagraph = Tabs.Status:AddParagraph({ Title = "Moon Server",       Content = "N/A" })
local KitsuneStatusParagraph = Tabs.Status:AddParagraph({ Title = "Kitsune Status", Content = "N/A" })
local FrozenStatusParagraph = Tabs.Status:AddParagraph({ Title = "Frozen Status",   Content = "N/A" })
local MirageStatusParagraph = Tabs.Status:AddParagraph({ Title = "Mirage Status",   Content = "N/A" })
local HakiDealerParagraph = Tabs.Status:AddParagraph({ Title = "Haki Dealer Status", Content = "N/A" })
local PrehistoricStatusParagraph2 = Tabs.Status:AddParagraph({ Title = "Prehistoric Status", Content = "N/A" })

local StatsSection = Tabs.Status:AddSection("Stats")

local StatsPointParagraph = Tabs.Status:AddParagraph({
    Title   = "Stats",
    Content = "0",
})

local AutoAddMeleeStats = Tabs.Status:AddToggle("AutoAddMelee", {
    Title    = "Add Melee Stats",
    Default  = false,
    Callback = function(state)
        _G.Settings.Stats["Auto Add Melee Stats"] = state
    end,
})

local AutoAddDefenseStats = Tabs.Status:AddToggle("AutoAddDefense", {
    Title    = "Add Defense Stats",
    Default  = false,
    Callback = function(state)
        _G.Settings.Stats["Auto Add Defense Stats"] = state
    end,
})

local AutoAddSwordStats = Tabs.Status:AddToggle("AutoAddSword", {
    Title    = "Add Sword Stats",
    Default  = false,
    Callback = function(state)
        _G.Settings.Stats["Auto Add Sword Stats"] = state
    end,
})

local AutoAddGunStats = Tabs.Status:AddToggle("AutoAddGun", {
    Title    = "Add Gun Stats",
    Default  = false,
    Callback = function(state)
        _G.Settings.Stats["Auto Add Gun Stats"] = state
    end,
})

local AutoAddDevilFruitStats = Tabs.Status:AddToggle("AutoAddDF", {
    Title    = "Add Devil Fruit Stats",
    Default  = false,
    Callback = function(state)
        _G.Settings.Stats["Auto Add Devil Fruit Stats"] = state
    end,
})

local StatsPointSlider = Tabs.Status:AddSlider("StatsPoint", {
    Title    = "Point",
    Min      = 1,
    Max      = 100,
    Default  = 1,
    Rounding = 0,
    Callback = function(value)
        _G.Settings.Stats["Point Stats"] = value
    end,
})


















local LocalPlayerSection = Tabs.Player:AddSection("Local Player")

local AutoActiveRaceV3Toggle = Tabs.Player:AddToggle("AutoActiveRaceV3", {
    Title    = "Active Race V3",
    Description = "Auto Turn On Tribe V3",
    Default  = false,
    Callback = function(state)
        _G.Settings.LocalPlayer["Active Race V3"] = state
    end,
})

local AutoActiveRaceV4Toggle = Tabs.Player:AddToggle("AutoActiveRaceV4", {
    Title    = "Active Race V4",
    Description = "Auto Turn On Tribe V4",
    Default  = true,
    Callback = function(state)
        _G.Settings.LocalPlayer["Active Race V4"] = state
    end,
})

local WalkOnWaterToggle = Tabs.Player:AddToggle("WalkOnWater", {
    Title    = "Walk On Water",
    Description = "Moving on Water Surface (Jesus)",
    Default  = true,
    Callback = function(state)
        _G.Settings.LocalPlayer["Walk On Water"] = state
    end,
})

local NoClipPlayerToggle = Tabs.Player:AddToggle("NoClipPlayer", {
    Title    = "No Clip",
    Description = "Travel Through Walls",
    Default  = false,
    Callback = function(state)
        _G.Settings.LocalPlayer["No Clip"] = state
    end,
})

local FruitSection = Tabs.Player:AddSection("Fruit")

local AutoRandomFruitToggle = Tabs.Player:AddToggle("AutoRandomFruit", {
    Title    = "Auto Random Fruit",
    Default  = false,
    Callback = function(state)
        _G.Settings.Fruit["Auto Buy Random Fruit"] = state
    end,
})

local StoreRarityDropdown = Tabs.Player:AddDropdown("StoreRarity", {
    Title   = "Store Rarity Fruit",
    Values  = { "Common - Mythical", "Rare - Mythical", "Legendary - Mythical", "Mythical" },
    Default = "Common - Mythical",
    Callback = function(option)
        _G.Settings.Fruit["Store Rarity Fruit"] = option
    end,
})

local AutoStoreFruitToggle = Tabs.Player:AddToggle("AutoStoreFruit", {
    Title    = "Auto Store Fruit",
    Default  = false,
    Callback = function(state)
        _G.Settings.Fruit["Auto Store Fruit"] = state
    end,
})

local FruitNotificationToggle = Tabs.Player:AddToggle("FruitNotification", {
    Title    = "Fruit Notification",
    Default  = false,
    Callback = function(state)
        _G.Settings.Fruit["Fruit Notification"] = state
    end,
})

local TeleportToFruitToggle = Tabs.Player:AddToggle("TeleportToFruit", {
    Title    = "Teleport To Fruit",
    Default  = false,
    Callback = function(state)
        _G.Settings.Fruit["Teleport To Fruit"] = state
    end,
})

local TweenToFruitToggle = Tabs.Player:AddToggle("TweenToFruit", {
    Title    = "Tween To Fruit",
    Default  = false,
    Callback = function(state)
        _G.Settings.Fruit["Tween To Fruit"] = state
    end,
})

Tabs.Player:AddButton({
    Title    = "Grab Fruit",
    Callback = function()
        for i, v in pairs(game.Workspace:GetChildren()) do
            if v:IsA("Tool") then
                v.Handle.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end,
})

local EspSection = Tabs.Player:AddSection("ESP")

local EspPlayerToggle = Tabs.Player:AddToggle("EspPlayer", {
    Title    = "ESP Player",
    Description = "Highlight Player",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Player"] = state
    end,
})

local EspChestToggle = Tabs.Player:AddToggle("EspChest", {
    Title    = "ESP Chest",
    Description = "Highlight Chest",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Chest"] = state
    end,
})

local EspDevilFruitToggle = Tabs.Player:AddToggle("EspDevilFruit", {
    Title    = "ESP Devil Fruit",
    Description = "Highlight DevilFruit",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP DevilFruit"] = state
    end,
})

local EspRealFruitToggle = Tabs.Player:AddToggle("EspRealFruit", {
    Title    = "ESP Real Fruit",
    Description = "Highlight RealFruit",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP RealFruit"] = state
    end,
})

local EspFlowerToggle = Tabs.Player:AddToggle("EspFlower", {
    Title    = "ESP Flower",
    Description = "Highlight Flower",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Flower"] = state
    end,
})

local EspIslandToggle = Tabs.Player:AddToggle("EspIsland", {
    Title    = "ESP Island",
    Description = "Highlight Island",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Island"] = state
    end,
})

local EspNpcToggle = Tabs.Player:AddToggle("EspNpc", {
    Title    = "ESP Npc",
    Description = "Highlight Npc",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Npc"] = state
    end,
})

local EspSeaBeastToggle = Tabs.Player:AddToggle("EspSeaBeast", {
    Title    = "ESP Sea Beast",
    Description = "Highlight SeaBeast",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Sea Beast"] = state
    end,
})

local EspMonsterToggle = Tabs.Player:AddToggle("EspMonster", {
    Title    = "ESP Monster",
    Description = "Highlight Monster",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Monster"] = state
    end,
})

local EspMirageToggle = Tabs.Player:AddToggle("EspMirage", {
    Title    = "ESP Mirage Island",
    Description = "Highlight Mirage Island",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Mirage"] = state
    end,
})

local EspKitsuneToggle = Tabs.Player:AddToggle("EspKitsune", {
    Title    = "ESP Kitsune Island",
    Description = "Highlight Kitsune Island",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Kitsune"] = state
    end,
})

local EspFrozenToggle = Tabs.Player:AddToggle("EspFrozen", {
    Title    = "ESP Frozen Dimension",
    Description = "Highlight Frozen Dimension",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Frozen"] = state
    end,
})

local EspPrehistoricToggle = Tabs.Player:AddToggle("EspPrehistoric", {
    Title    = "ESP Prehistoric Island",
    Description = "Highlight Prehistoric Island",
    Default  = false,
    Callback = function(state) end,
})

local EspGearToggle = Tabs.Player:AddToggle("EspGear", {
    Title    = "ESP Gear",
    Description = "Highlight Gear",
    Default  = false,
    Callback = function(state)
        _G.Settings.Esp["ESP Gear"] = state
    end,
})
















local CombatSection = Tabs.PvP:AddSection("Combat")

local PlayersInServerParagraph = Tabs.PvP:AddParagraph({
    Title   = "Players In Server",
    Content = "0",
})

local ChoosePlayerDropdown = Tabs.PvP:AddDropdown("ChoosePlayer", {
    Title     = "Choose Player",
    Values    = { "None" },
    Default   = nil,
    AllowNull = true,
    Callback  = function(option) end,
})

Tabs.PvP:AddButton({
    Title    = "Refresh Player",
    Callback = function()
        local players = {}
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= game.Players.LocalPlayer then
                table.insert(players, v.Name)
            end
        end
        ChoosePlayerDropdown:SetValues(players)
    end,
})

local SpectatePlayerToggle = Tabs.PvP:AddToggle("SpectatePlayer", {
    Title    = "Spectate Player",
    Default  = false,
    Callback = function(state)
        _G.Settings.Combat["Enable PvP"] = state
    end,
})

local TeleportToPlayerToggle = Tabs.PvP:AddToggle("TeleportToPlayer", {
    Title    = "Teleport To Player",
    Default  = false,
    Callback = function(state) end,
})






















local ShopSection = Tabs.Misc:AddSection("Shop")

local AutoBuyLegendarySwordToggle = Tabs.Misc:AddToggle("AutoBuyLegendary", {
    Title    = "Auto Buy Legendary Sword",
    Default  = false,
    Callback = function(state)
        _G.Settings.Shop["Auto Buy Legendary Sword"] = state
    end,
})

local AutoBuyHakiColorToggle = Tabs.Misc:AddToggle("AutoBuyHakiColor", {
    Title    = "Auto Buy Haki Color",
    Default  = false,
    Callback = function(state)
        _G.Settings.Shop["Auto Buy Haki Color"] = state
    end,
})

local AbilitiesSection = Tabs.Misc:AddSection("Abilities")

Tabs.Misc:AddButton({ Title = "Buy Geppo",            Description = "$10,000",    Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyHaki", "Geppo") end })
Tabs.Misc:AddButton({ Title = "Buy Buso Haki",         Description = "$25,000",    Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyHaki", "Buso") end })
Tabs.Misc:AddButton({ Title = "Buy Soru",              Description = "$25,000",    Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyHaki", "Soru") end })
Tabs.Misc:AddButton({ Title = "Buy Observation Haki",  Description = "$750,000",   Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("KenTalk", "Buy") end })

local FightingStyleShopSection = Tabs.Misc:AddSection("Fighting Style")

Tabs.Misc:AddButton({ Title = "Buy Black Leg",     Description = "$150,000",   Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyBlackLeg") end })
Tabs.Misc:AddButton({ Title = "Buy Electro",       Description = "$400,000",   Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyElectro") end })
Tabs.Misc:AddButton({ Title = "Buy Fishman Karate",Description = "$750,000",   Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("FishmanKarate") end })
Tabs.Misc:AddButton({ Title = "Buy Dragon Claw",   Description = "$1,500,000", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("DragonClaw") end })
Tabs.Misc:AddButton({ Title = "Buy Superhuman",    Description = "$3,000,000", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Superhuman") end })
Tabs.Misc:AddButton({ Title = "Buy Death Step",    Description = "$5,000,000", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("DeathStep") end })
Tabs.Misc:AddButton({ Title = "Buy Sharkman Karate",Description="$2,500,000", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SharkmanKarate") end })
Tabs.Misc:AddButton({ Title = "Buy Electric Claw", Description = "$5,000,000", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("ElectricClaw") end })
Tabs.Misc:AddButton({ Title = "Buy Dragon Talon",  Description = "$7,500,000", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("DragonTalon") end })
Tabs.Misc:AddButton({ Title = "Buy God Human",     Description = "$10,000,000",Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("GodHuman") end })
Tabs.Misc:AddButton({ Title = "Buy Sanguine Art",  Description = "F' Cost",    Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SanguineArt") end })

local SwordShopSection = Tabs.Misc:AddSection("Sword Shop")

Tabs.Misc:AddButton({ Title = "Buy Cutlass",        Description = "$1,000",    Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuySword", "Cutlass") end })
Tabs.Misc:AddButton({ Title = "Buy Katana",         Description = "$10,000",   Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuySword", "Katana") end })
Tabs.Misc:AddButton({ Title = "Buy Iron Mace",      Description = "$20,000",   Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuySword", "IronMace") end })
Tabs.Misc:AddButton({ Title = "Buy Dual Katana",    Description = "$100,000",  Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuySword", "DualKatana") end })
Tabs.Misc:AddButton({ Title = "Buy Triple Katana",  Description = "$250,000",  Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuySword", "TripleKatana") end })
Tabs.Misc:AddButton({ Title = "Buy Pipe",           Description = "$5,000",    Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuySword", "Pipe") end })
Tabs.Misc:AddButton({ Title = "Buy Dual Headed Blade",Description="$400,000",  Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuySword", "DualHeadedBlade") end })
Tabs.Misc:AddButton({ Title = "Buy Bisento",        Description = "$1,200,000",Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuySword", "Bisento") end })
Tabs.Misc:AddButton({ Title = "Buy Soul Cane",      Description = "$1,000",    Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuySword", "SoulCane") end })

local GunShopSection = Tabs.Misc:AddSection("Gun Shop")

Tabs.Misc:AddButton({ Title = "Buy Slingshot",       Description = "$5,000",    Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyGun", "Slingshot") end })
Tabs.Misc:AddButton({ Title = "Buy Musket",          Description = "$8,000",    Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyGun", "Musket") end })
Tabs.Misc:AddButton({ Title = "Buy Flintlock",       Description = "$10,500",   Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyGun", "Flintlock") end })
Tabs.Misc:AddButton({ Title = "Buy Refined Flintlock",Description="$60,000",   Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyGun", "RefinedFlintlock") end })
Tabs.Misc:AddButton({ Title = "Buy Cannon",          Description = "$100,000",  Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyGun", "Cannon") end })
Tabs.Misc:AddButton({ Title = "Buy Kabucha",         Description = "F' 1,500",  Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyGun", "Kabucha") end })

local StatsShopSection = Tabs.Misc:AddSection("Stats & Race")

Tabs.Misc:AddButton({ Title = "Reset Stats",  Description = "F' 2,500", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("ResetStat") end })
Tabs.Misc:AddButton({ Title = "Random Race",  Description = "F' 3,000", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("RandomRace") end })

local AccessoriesSection = Tabs.Misc:AddSection("Accessories")

Tabs.Misc:AddButton({ Title = "Buy Black Cape",     Description = "$50,000",   Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyAcc", "BlackCape") end })
Tabs.Misc:AddButton({ Title = "Buy Swordsman Hat",  Description = "$150,000",  Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyAcc", "SwordsmanHat") end })
Tabs.Misc:AddButton({ Title = "Buy Tomoe Ring",     Description = "$500,000",  Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("BuyAcc", "TomoeRing") end })

local MiscMiscSection = Tabs.Misc:AddSection("Misc")

Tabs.Misc:AddButton({ Title = "Join Pirates Team", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Pirates") end })
Tabs.Misc:AddButton({ Title = "Join Marines Team", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Marines") end })

local CodesSection = Tabs.Misc:AddSection("Codes")

local codeList = { "ZIOLES", "NOOB2ADMIN", "KITT_RESET", "Sub2CaptainMaui", "SUB2GAMERROBOT_RESET1", "kittgaming",
    "Sub2Fer999", "Enyu_is_Pro", "Magicbus", "JCWK", "Starcodeheo", "Bluxxy", "fudd10_v2", "FUDD10",
    "BIGNEWS", "THEGREATACE", "SUB2GAMERROBOT_EXP1", "Sub2OfficialNoobie", "StrawHatMaine",
    "SUB2NOOBMASTER123", "Sub2UncleKizaru", "Sub2Daigrock", "Axiore", "TantaiGaming" }

Tabs.Misc:AddButton({
    Title    = "Redeem All Codes",
    Callback = function()
        for _, code in pairs(codeList) do
            game:GetService("ReplicatedStorage").Remotes.Redeem:InvokeServer(code)
        end
    end,
})

local GraphicSection = Tabs.Misc:AddSection("Graphic")

Tabs.Misc:AddButton({
    Title    = "Fps Boost",
    Callback = function()
        settings().Rendering.QualityLevel = "Level01"
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Part") or v:IsA("Union") then
                v.Material = "Plastic"; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
                v.Enabled = false
            end
        end
    end,
})

Tabs.Misc:AddButton({
    Title    = "Remove Fog",
    Callback = function()
        game:GetService("Lighting").FogEnd = 9000000000
    end,
})

Tabs.Misc:AddButton({
    Title    = "Remove Lava",
    Callback = function()
        for _, v in pairs(game.Workspace:GetDescendants()) do
            if v.Name == "Lava" then v:Destroy() end
        end
    end,
})

Tabs.Misc:AddButton({
    Title    = "Rain Fruit",
    Callback = function()
        for _, i in pairs(game:GetObjects("rbxassetid://14759368201")[1]:GetChildren()) do
            i.Parent = game.Workspace.Map
            i:MoveTo(game.Players.LocalPlayer.Character.PrimaryPart.Position + Vector3.new(math.random(-50,50), 100, math.random(-50,50)))
        end
    end,
})



























local SettingsSection = Tabs.Settings:AddSection("Settings")

local SpinPositionToggle = Tabs.Settings:AddToggle("SpinPosition", {
    Title    = "Spin Position",
    Description = "Spin Position When Farm",
    Default  = false,
    Callback = function(state)
        _G.Settings.Setting["Spin Position"] = state
    end,
})

local FarmDistanceSlider = Tabs.Settings:AddSlider("FarmDistance", {
    Title    = "Farm Distance",
    Min      = 10,
    Max      = 50,
    Default  = 35,
    Rounding = 0,
    Callback = function(value)
        _G.Settings.Setting["Farm Distance"] = value
    end,
})

local PlayerTweenSpeedSlider = Tabs.Settings:AddSlider("PlayerTweenSpeed", {
    Title    = "Player Tween Speed",
    Min      = 10,
    Max      = 350,
    Default  = 350,
    Rounding = 0,
    Callback = function(value)
        _G.Settings.Setting["Player Tween Speed"] = value
    end,
})

local BringMobToggle = Tabs.Settings:AddToggle("BringMob", {
    Title    = "Bring Mob",
    Default  = true,
    Callback = function(state)
        _G.Settings.Setting["Bring Mob"] = state
    end,
})

local BringMobDropdown = Tabs.Settings:AddDropdown("BringMobMode", {
    Title   = "Bring Mob Mode",
    Values  = { "Low", "Normal", "High" },
    Default = "Normal",
    Callback = function(option)
        _G.Settings.Setting["Bring Mob Mode"] = option
    end,
})

local FastAttackMethodDropdown = Tabs.Settings:AddDropdown("FastAttackMethod", {
    Title   = "Fast Attack Method",
    Values  = { "Slow", "Normal", "Fast", "Super Fast" },
    Default = "Normal",
    Callback = function(option)
        _G.Settings.Setting["Fast Attack Mode"] = option
    end,
})

local AttackAuraToggle = Tabs.Settings:AddToggle("AttackAura", {
    Title    = "Attack Aura",
    Description = "Attack Nearest Enemies",
    Default  = true,
    Callback = function(state)
        _G.Settings.Setting["Attack Aura"] = state
    end,
})

local GraphicSettingSection = Tabs.Settings:AddSection("Graphic")

local HideNotificationToggle = Tabs.Settings:AddToggle("HideNotification", {
    Title    = "Hide Notification",
    Default  = false,
    Callback = function(state)
        _G.Settings.Setting["Hide Notification"] = state
    end,
})

local HideDamageTextToggle = Tabs.Settings:AddToggle("HideDamageText", {
    Title    = "Hide Damage Text",
    Default  = true,
    Callback = function(state)
        _G.Settings.Setting["Hide Damage Text"] = state
    end,
})

local BlackScreenToggle = Tabs.Settings:AddToggle("BlackScreen", {
    Title    = "Black Screen",
    Default  = false,
    Callback = function(state)
        _G.Settings.Setting["Black Screen"] = state
    end,
})

local WhiteScreenToggle = Tabs.Settings:AddToggle("WhiteScreen", {
    Title    = "White Screen",
    Default  = false,
    Callback = function(state)
        _G.Settings.Setting["White Screen"] = state
    end,
})

local MasterySettingsSection = Tabs.Settings:AddSection("Mastery Settings")

local MasteryHealthSlider = Tabs.Settings:AddSlider("MasteryHealth", {
    Title    = "Mastery Health %",
    Min      = 1,
    Max      = 100,
    Default  = 25,
    Rounding = 0,
    Callback = function(value)
        _G.Settings.Setting["Mastery Health"] = value
    end,
})

local DevilFruitSkillSection = Tabs.Settings:AddSection("Devil Fruit Skill")

local MasteryFruitSkillZToggle = Tabs.Settings:AddToggle("MasteryFruitZ", { Title = "Skill Z", Default = true,  Callback = function(s) _G.Settings.Setting["Fruit Mastery Skill Z"] = s end })
local MasteryFruitSkillXToggle = Tabs.Settings:AddToggle("MasteryFruitX", { Title = "Skill X", Default = true,  Callback = function(s) _G.Settings.Setting["Fruit Mastery Skill X"] = s end })
local MasteryFruitSkillCToggle = Tabs.Settings:AddToggle("MasteryFruitC", { Title = "Skill C", Default = true,  Callback = function(s) _G.Settings.Setting["Fruit Mastery Skill C"] = s end })
local MasteryFruitSkillVToggle = Tabs.Settings:AddToggle("MasteryFruitV", { Title = "Skill V", Default = false, Callback = function(s) _G.Settings.Setting["Fruit Mastery Skill V"] = s end })
local MasteryFruitSkillFToggle = Tabs.Settings:AddToggle("MasteryFruitF", { Title = "Skill F", Default = false, Callback = function(s) _G.Settings.Setting["Fruit Mastery Skill F"] = s end })

local GunSkillSection = Tabs.Settings:AddSection("Gun Skill")

local MasteryGunSkillZToggle = Tabs.Settings:AddToggle("MasteryGunZ", { Title = "Skill Z", Default = true, Callback = function(s) _G.Settings.Setting["Gun Mastery Skill Z"] = s end })
local MasteryGunSkillXToggle = Tabs.Settings:AddToggle("MasteryGunX", { Title = "Skill X", Default = true, Callback = function(s) _G.Settings.Setting["Gun Mastery Skill X"] = s end })

local OtherSettingsSection = Tabs.Settings:AddSection("Others")

local AutoSetSpawnToggle = Tabs.Settings:AddToggle("AutoSetSpawn", {
    Title    = "Auto Set Spawn Point",
    Default  = true,
    Callback = function(state)
        _G.Settings.Setting["Auto Set Spawn Point"] = state
    end,
})

local AutoObservationToggle = Tabs.Settings:AddToggle("AutoObservation", {
    Title    = "Auto Observation",
    Default  = false,
    Callback = function(state)
        _G.Settings.Setting["Auto Observation"] = state
    end,
})

local AutoHakiToggle = Tabs.Settings:AddToggle("AutoHaki", {
    Title    = "Auto Haki",
    Default  = true,
    Callback = function(state)
        _G.Settings.Setting["Auto Haki"] = state
    end,
})

local AutoRejoinToggle = Tabs.Settings:AddToggle("AutoRejoin", {
    Title    = "Auto Rejoin",
    Default  = true,
    Callback = function(state)
        _G.Settings.Setting["Auto Rejoin"] = state
    end,
})

local ServerSection = Tabs.Settings:AddSection("Server")

Tabs.Settings:AddButton({
    Title    = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end,
})

Tabs.Settings:AddButton({
    Title    = "Server Hop",
    Callback = function()
        local module = loadstring(game:HttpGet("https://raw.githubusercontent.com/raw-scriptpastebin/FE/main/Server_Hop_Settings"))()
        module:Teleport(game.PlaceId)
    end,
})

local JobIdParagraph = Tabs.Settings:AddParagraph({
    Title   = "Job ID",
    Content = game.JobId,
})

local EnterJobIdInput = Tabs.Settings:AddInput("EnterJobId", {
    Title       = "Enter Job ID",
    Placeholder = "Paste Job ID here...",
    Default     = "",
    Callback    = function(value)
        _G.JobId = value
    end,
})

Tabs.Settings:AddButton({
    Title    = "Join Job ID",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, _G.JobId)
    end,
})


return {
    Window           = Window,
    Tabs             = Tabs,
    SaveManager      = SaveManager,
    InterfaceManager = InterfaceManager,
}
