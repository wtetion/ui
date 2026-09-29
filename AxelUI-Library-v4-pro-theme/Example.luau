-- AxelUI library example for the Axel Hub tab layout.
-- This is a UI-only preview: controls demonstrate the library and do not run
-- Roblox game automation. The feature names/pages mirror the legacy Luau UI.

local LIBRARY_URL = "https://raw.githubusercontent.com/wtetion/ui/refs/heads/main/AxelUI-Library-v4-pro-theme/AxelUI_Library.luau"
local MIN_LIBRARY_VERSION = 6.92

local function hasMethods(owner, names)
    if type(owner) ~= "table" then return false end
    for _, name in ipairs(names) do
        if type(owner[name]) ~= "function" then return false end
    end
    return true
end

local function isCompatible(library)
    return type(library) == "table"
        and (tonumber(library.Version) or 0) >= MIN_LIBRARY_VERSION
        and type(library.CreateWindow) == "function"
        and type(library.AddTab) == "function"
        and hasMethods(library.TabMethods, { "AddHero", "AddPill", "AddSubTab", "AddSection" })
        and hasMethods(library.SectionMethods, { "AddStatus", "AddToggle", "AddSlider", "AddDropdown", "AddButton" })
end

local function getEnvironment()
    local environment = _G
    pcall(function()
        if type(getgenv) == "function" then environment = getgenv() end
    end)
    return environment
end

local function compileLibrary(source)
    local compiler = loadstring or load
    if type(compiler) ~= "function" then return nil, "loadstring/load is unavailable" end
    local ok, chunk = pcall(compiler, source)
    if not ok or type(chunk) ~= "function" then return nil, tostring(chunk) end
    local ran, library = pcall(chunk)
    if not ran or not isCompatible(library) then return nil, tostring(library or "incompatible library") end
    return library
end

local function loadAxelUI()
    local environment = getEnvironment()
    if isCompatible(environment.AxelUI) then return environment.AxelUI end

    local compiler = loadstring or load
    if type(compiler) == "function" then
        local ok, source = pcall(function() return game:HttpGet(LIBRARY_URL) end)
        if ok and type(source) == "string" and #source > 0 then
            local library = compileLibrary(source)
            if library then environment.AxelUI = library; return library end
        end
    end

    if type(readfile) == "function" then
        local ok, source = pcall(readfile, "AxelUI_Library.luau")
        if ok and type(source) == "string" and #source > 0 then
            local library = compileLibrary(source)
            if library then environment.AxelUI = library; return library end
        end
    end
    warn("[AxelUI Example] Use the bundled AxelUI_Library.luau v6.92 or update the configured raw GitHub file.")
    return nil
end

local AxelUI = loadAxelUI()
if not AxelUI then return end

local Window = AxelUI.CreateWindow({
    Name = "Axel Hub",
    Subtitle = "Play Further",
    Footer = "AxelUI v6.92\nLibrary example",
    GuiName = "AxelUIExample",
    ToggleKeybind = "RightControl",
    Size = UDim2.fromOffset(926, 616),
    StartMinimized = false,
    Logo = "star",
    Theme = {
        Accent = Color3.fromRGB(255, 193, 7),
        Accent2 = Color3.fromRGB(255, 224, 115),
        Accent3 = Color3.fromRGB(184, 126, 0),
        Background = Color3.fromRGB(10, 10, 12),
        Surface = Color3.fromRGB(17, 17, 19),
        Surface2 = Color3.fromRGB(24, 24, 27),
        Element = Color3.fromRGB(30, 29, 28),
        Border = Color3.fromRGB(58, 59, 67),
    },
    Glass = { Enabled = true, Transparency = 0.24, AnimatedBorder = true },
})

local function safeElement(owner, methodName, data)
    local method = owner and owner[methodName]
    if type(method) ~= "function" then
        warn("[AxelUI Example] Missing method: " .. tostring(methodName))
        return nil
    end
    local ok, result = pcall(method, owner, data)
    if not ok then
        warn("[AxelUI Example] " .. tostring(methodName) .. " failed: " .. tostring(result))
        return nil
    end
    return result
end

local function safeGroup(owner, createMethod, data)
    local actual = safeElement(owner, createMethod, data)
    return setmetatable({}, {
        __index = function(_, key)
            local value = actual and actual[key]
            if type(value) == "function" and (string.sub(key, 1, 3) == "Add" or string.sub(key, 1, 6) == "Create") then
                return function(_, payload) return safeElement(actual, key, payload) end
            end
            return value
        end,
    })
end

local Home = Window:AddTab({ Name = "Home", Description = "Overview & live status", Icon = "home" })
local Eggs = Window:AddTab({ Name = "Eggs", Description = "Steal, hatch & plant", Icon = "eggs" })
local Base = Window:AddTab({ Name = "Base", Description = "Homestead & training", Icon = "wrench" })
local Combat = Window:AddTab({ Name = "Combat", Description = "Bat, slaps & defense", Icon = "combat" })
local PlayerTab = Window:AddTab({ Name = "Player", Description = "Movement & teleports", Icon = "player" })
local Settings = Window:AddTab({ Name = "Settings", Description = "Configs & unloader", Icon = "settings" })
local Server = Window:AddTab({ Name = "Server", Description = "Server hop", Icon = "server" })
local Webhook = Window:AddTab({ Name = "Webhook", Description = "Discord notifications", Icon = "webhook" })

safeElement(Home, "AddHero", {
    Image = "rbxassetid://86949082023913",
    ScaleType = Enum.ScaleType.Fit,
    WelcomeLabel = "Welcome to",
    WelcomeTitle = "Axel Hub",
    WelcomeContent = "Powerful tools. A smoother way to play.",
    BannerTitle = "Join Axel Hub on Discord",
    Title = "Join Axel Hub on Discord",
    Content = "Copy the invite to join the Axel Hub community.",
    Button = "Copy Discord",
    Height = 104,
    Callback = function()
        local invite = "https://discord.gg/axelhub"
        local copier = setclipboard or toclipboard
        if type(copier) == "function" then
            local ok = pcall(copier, invite)
            if ok then
                Window:Notify("Discord", "Invite copied to clipboard.", "success")
                return
            end
        end
        Window:Notify("Discord invite", invite, "info")
    end,
})
Home:AddPill({ Name = "Overview", TargetTab = Home, Active = true })
Home:AddPill({ Name = "Eggs", TargetTab = Eggs })
Home:AddPill({ Name = "Base", TargetTab = Base })
Home:AddPill({ Name = "Combat", TargetTab = Combat })
Home:AddPill({ Name = "Player", TargetTab = PlayerTab })
Home:AddPill({ Name = "Settings", TargetTab = Settings })
Home:AddPill({ Name = "Server", TargetTab = Server })
Home:AddPill({ Name = "Webhook", TargetTab = Webhook })

local Session = safeGroup(Home, "AddSection", {
    Name = "Session Status", Description = "Current player and experience.", Side = "Left", Pill = "Overview",
})
local localPlayer = game:GetService("Players").LocalPlayer
Session:AddStatus({ Name = "Player", Icon = "user", Text = localPlayer and (localPlayer.DisplayName or localPlayer.Name) or "Waiting", Color = Window.Theme.Success })
Session:AddStatus({ Name = "Experience", Icon = "gamepad", Text = game.Name, Color = Window.Theme.Accent2 })
Session:AddStatus({ Name = "Place ID", Icon = "map", Text = tostring(game.PlaceId), Color = Window.Theme.SubText })
Session:AddStatus({ Name = "Server", Icon = "server", Text = string.sub(tostring(game.JobId or ""), 1, 8), Color = Window.Theme.SubText })

local Runtime = safeGroup(Home, "AddSection", {
    Name = "Hub Status", Description = "Status cards used by the live hub dashboard.", Side = "Right", Pill = "Overview",
})
Runtime:AddStatus({ Name = "AxelUI", Icon = "check", Text = "Online · v6.92", Color = Window.Theme.Success })
Runtime:AddStatus({ Name = "Feature pages", Icon = "grid", Text = "7 linked", Color = Window.Theme.Accent2 })
Runtime:AddParagraph({ Title = "Navigation", Content = "A Home pill and its matching sidebar tab open the same function page." })

local Steal = safeGroup(Eggs, "AddSubTab", "Auto Steal")
Steal:AddToggle({ Name = "Auto Steal", Description = "Enable the egg collection routine.", Icon = "eggs", Default = false })
Steal:AddDropdown({ Name = "Rarity filter", Icon = "star", Options = { "Any", "Rare", "Epic", "Legendary" }, Default = "Any" })
Steal:AddSlider({ Name = "Scan delay", Icon = "timer", Min = 0.1, Max = 5, Default = 1, Suffix = "s" })
local Hatch = safeGroup(Eggs, "AddSubTab", "Auto Hatch & Plant")
Hatch:AddToggle({ Name = "Auto Hatch", Icon = "eggs", Default = false })
Hatch:AddToggle({ Name = "Auto Place Egg", Icon = "home", Default = false })
local EggESP = safeGroup(Eggs, "AddSubTab", "Egg Tracker ESP")
EggESP:AddToggle({ Name = "Egg ESP", Icon = "eye", Default = false })

local Upgrades = safeGroup(Base, "AddSubTab", "Homestead & Treadmill")
Upgrades:AddToggle({ Name = "Auto Treadmill", Icon = "activity", Default = false })
Upgrades:AddDropdown({ Name = "Upgrade target", Icon = "chart", Options = { "Homestead", "Treadmill" }, Default = "Homestead" })
local Pets = safeGroup(Base, "AddSubTab", "Pets & Satchel")
Pets:AddButton({ Name = "Equip best pets", Icon = "favorite" })
Pets:AddButton({ Name = "Open satchel", Icon = "backpack" })
local Sales = safeGroup(Base, "AddSubTab", "Auto Sell")
Sales:AddToggle({ Name = "Auto Sell Pets", Icon = "cart", Default = false })
Sales:AddToggle({ Name = "Auto Sell Eggs", Icon = "eggs", Default = false })
local BaseEvents = safeGroup(Base, "AddSubTab", "Events & Bosses")
BaseEvents:AddToggle({ Name = "Auto Rift", Icon = "star", Default = false })
local Rewards = safeGroup(Base, "AddSubTab", "Claim Rewards")
Rewards:AddButton({ Name = "Claim ready rewards", Icon = "gift" })

local Aura = safeGroup(Combat, "AddSubTab", "Bat & Slap Aura")
Aura:AddToggle({ Name = "Bat Aura", Icon = "combat", Default = false })
Aura:AddSlider({ Name = "Aura range", Icon = "target", Min = 5, Max = 30, Default = 12, Suffix = " studs" })
local Defense = safeGroup(Combat, "AddSubTab", "Defense & Guards")
Defense:AddToggle({ Name = "Anti-Trap", Icon = "shield", Default = false })
Defense:AddToggle({ Name = "Knockback protection", Icon = "shield", Default = false })

local Movement = safeGroup(PlayerTab, "AddSubTab", "Movement")
Movement:AddToggle({ Name = "WalkSpeed", Icon = "speed", Default = false })
Movement:AddSlider({ Name = "Walk speed", Icon = "running", Min = 16, Max = 100, Default = 24 })
Movement:AddToggle({ Name = "JumpPower", Icon = "move", Default = false })
Movement:AddSlider({ Name = "Jump power", Icon = "arrows", Min = 50, Max = 150, Default = 60 })
Movement:AddToggle({ Name = "Fly", Icon = "move", Default = false })
local Travel = safeGroup(PlayerTab, "AddSubTab", "Area Travel")
Travel:AddDropdown({ Name = "Destination", Icon = "map", Options = { "Forest", "Lake", "Desert", "Jungle" }, Default = "Forest" })
local PlotTravel = safeGroup(PlayerTab, "AddSubTab", "Plot Travel")
PlotTravel:AddDropdown({ Name = "Plot", Icon = "home", Options = { "Plot 1", "Plot 2", "Plot 3" }, Default = "Plot 1" })
local PlayerTravel = safeGroup(PlayerTab, "AddSubTab", "Player Travel")
PlayerTravel:AddDropdown({ Name = "Player", Icon = "users", Options = { "Select player" }, Default = "Select player" })
local Performance = safeGroup(PlayerTab, "AddSubTab", "Visuals & Performance")
Performance:AddToggle({ Name = "Anti-AFK", Icon = "clock", Default = false })

local Config = safeGroup(Settings, "AddSubTab", "Configuration")
Config:AddInput({ Name = "Config Name", Icon = "file", Placeholder = "stealanegg", Default = "stealanegg" })
Config:AddButton({ Name = "Save Config", Icon = "save", Primary = true, Callback = function() Window:SaveConfig("stealanegg") end })
Config:AddButton({ Name = "Load Config", Icon = "download", Callback = function() Window:LoadConfig("stealanegg") end })
Config:AddKeybind({ Name = "Toggle UI Keybind", Icon = "bolt", Default = "RightControl" })

local ServerHop = safeGroup(Server, "AddSubTab", "Server Hop")
ServerHop:AddToggle({ Name = "Enable Auto Server Hop", Icon = "server", Default = false })
ServerHop:AddToggle({ Name = "Hop on No Matching Egg", Icon = "search", Default = false })
ServerHop:AddSlider({ Name = "Max Hops", Icon = "refresh", Min = 1, Max = 100, Default = 20 })

local WebhookMain = safeGroup(Webhook, "AddSubTab", "Webhook")
WebhookMain:AddInput({ Name = "Webhook URL", Icon = "webhook", Placeholder = "https://discord.com/api/webhooks/..." })
WebhookMain:AddToggle({ Name = "Enable Webhook", Icon = "webhook", Default = false })
local WebhookEvents = safeGroup(Webhook, "AddSubTab", "Notifications")
WebhookEvents:AddToggle({ Name = "Notify on animal", Icon = "bell", Default = true })
WebhookEvents:AddToggle({ Name = "Notify on rarity", Icon = "star", Default = true })
WebhookEvents:AddToggle({ Name = "Notify on egg", Icon = "eggs", Default = true })

Window:SetStatus("Online", Window.Theme.Success)
return Window
