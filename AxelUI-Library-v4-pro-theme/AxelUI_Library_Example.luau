-- AxelUI dashboard showcase
-- Replace YOUR_AXEL_UI_LIBRARY_URL with the URL where you host AxelUI_Library.luau.
local AxelUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/wtetion/ui/refs/heads/main/AxelUI-Library-v4-pro-theme/AxelUI_Library.luau))()

local Window = AxelUI.CreateWindow({
    Name = "Axel Hub",
    Subtitle = "Play Further",
    Footer = "AxelUI 5.7  •  Ready when you are",
    GuiName = "AxelHubUI",
    ToggleKeybind = "RightControl",
    -- Set this when your executor stores AxelLogo.png in a subfolder.
    -- AssetFolder = "AxelUI",
    Theme = {
        Accent = Color3.fromRGB(255, 193, 7),
        Accent2 = Color3.fromRGB(255, 221, 120),
        Background = Color3.fromRGB(10, 10, 12),
        Surface = Color3.fromRGB(17, 17, 19),
        Surface2 = Color3.fromRGB(24, 24, 27),
        Element = Color3.fromRGB(30, 29, 28),
        -- Reference cards use a quiet graphite border; gold is reserved for
        -- the active state, focus glow and primary actions.
        Border = Color3.fromRGB(58, 59, 67),
    },
    -- This is the supplied Roblox asset. If the asset is unavailable in the
    -- current game, the library keeps its deterministic logo fallback visible.
    Logo = "rbxassetid://86949082023913",
    Background = nil,
    BackgroundTransparency = 0.94,
    LoadingText = "Axel Hub",
    LoadingSubtitle = "AxelUI 5.7  •  Preparing your workspace",
})

Window:Notify({
    Title = "Welcome to Axel Hub",
    Content = "Search features from the top bar or choose a section from the sidebar.",
    Type = "success",
})

-- Home follows the reference composition: hero, pill tabs, then two columns of cards.
local Home = Window:AddTab({ Name = "Home", Description = "Live status and quick actions", Icon = "home" })
local function safeElement(owner, methodName, data)
    local method = owner and owner[methodName]
    if type(method) ~= "function" then
        warn("[AxelUI] Missing method: " .. tostring(methodName) .. " (library is older than the example)")
        return nil
    end
    local ok, result = pcall(method, owner, data)
    if not ok then
        warn("[AxelUI] " .. tostring(methodName) .. " failed: " .. tostring(result))
        return nil
    end
    return result
end

local function safeSection(tab, data)
    local actual = safeElement(tab, "AddSection", data)
    return setmetatable({}, {
        __index = function(_, key)
            local value = actual and actual[key]
            if type(value) == "function" and string.sub(key, 1, 3) == "Add" then
                return function(_, payload) return safeElement(actual, key, payload) end
            end
            return value
        end,
    })
end

safeElement(Home, "AddHero", {
    Image = "rbxassetid://86949082023913", -- replace with a scenic rbxassetid/local image if desired
    WelcomeLabel = "Welcome to",
    WelcomeTitle = "Axel Hub",
    WelcomeContent = "Powerful tools. A smoother way to play.",
    BannerTitle = "Customize your experience",
    Title = "Customize your experience",
    Content = "Simple. Powerful. Yours. Build your own control center with clean, readable controls.",
    Button = "Get Started",
    Height = 104,
    Callback = function() Window:Notify("Axel Hub", "Your dashboard is ready.", "info") end,
})

safeElement(Home, "AddPill", { Name = "Overview", Active = true })
safeElement(Home, "AddPill", { Name = "Player", Callback = function() Window:Notify("Overview", "Player tools are below.", "info") end })
safeElement(Home, "AddPill", { Name = "World", Callback = function() Window:Notify("Overview", "World settings are below.", "info") end })
safeElement(Home, "AddPill", { Name = "Visuals", Callback = function() Window:Notify("Overview", "Visual controls are below.", "info") end })
safeElement(Home, "AddPill", { Name = "Utilities", Callback = function() Window:Notify("Overview", "Utility controls are below.", "info") end })
safeElement(Home, "AddPill", { Name = "Configs", Callback = function() Window:Notify("Overview", "Configuration is below.", "info") end })

local PlayerTools = safeSection(Home, { Name = "Player Tools", Description = "Fine tune your movement and abilities.", Side = "Left" })
PlayerTools:AddToggle({ Name = "Enable Movement Mods", Description = "Unlock advanced movement options.", Icon = "running", Default = true })
PlayerTools:AddSlider({ Name = "Walk Speed", Icon = "speed", Min = 1, Max = 50, Default = 16, Flag = "walk_speed" })
PlayerTools:AddSlider({ Name = "Jump Power", Icon = "arrows", Min = 1, Max = 100, Default = 50, Flag = "jump_power" })
PlayerTools:AddToggle({ Name = "Infinite Jump", Description = "Keep going higher.", Icon = "move", Default = false })
PlayerTools:AddToggle({ Name = "No Fall Damage", Description = "Land without limits.", Icon = "shield", Default = true })

local WorldSettings = safeSection(Home, { Name = "World Settings", Description = "Adjust how you see and interact with the world.", Side = "Right" })
WorldSettings:AddToggle({ Name = "Full Bright", Description = "Light up dark areas.", Icon = "star", Default = true })
WorldSettings:AddToggle({ Name = "Remove Fog", Description = "See further, play clearer.", Icon = "eyeoff", Default = false })
WorldSettings:AddDropdown({ Name = "Time of Day", Description = "Choose a world lighting preset.", Icon = "clock", Options = { "Day", "Sunset", "Night" }, Default = "Day" })
WorldSettings:AddSlider({ Name = "Field of View", Icon = "eye", Min = 40, Max = 120, Default = 70, Suffix = "°" })
WorldSettings:AddToggle({ Name = "Show Hitboxes", Description = "Visualize important objects.", Icon = "grid", Default = false })

local Config = safeSection(Home, { Name = "Configuration", Description = "Save and load your favorite setups.", Side = "Left" })
Config:AddDropdown({ Name = "Preset", Icon = "folder", Options = { "Default", "Farm", "Combat" }, Default = "Default" })
safeElement(Config, "AddActionBar", { Actions = {
    { Name = "Save", Primary = true, Callback = function()
        local ok, err = Window:SaveConfig("axelhub-demo")
        Window:Notify("Configuration", ok and "Configuration saved." or tostring(err), ok and "success" or "error")
    end },
    { Name = "Load", Callback = function()
        local ok, err = Window:LoadConfig("axelhub-demo")
        Window:Notify("Configuration", ok and "Configuration loaded." or tostring(err), ok and "success" or "error")
    end },
    { Name = "...", Callback = function() Window:Notify("Configuration", "More configuration actions are available through the library API.", "info") end },
} })

local Quick = safeSection(Home, { Name = "Quick Actions", Description = "Common features, one click away.", Side = "Right" })
safeElement(Quick, "AddActionBar", { Actions = {
    { Name = "Rejoin", Callback = function() Window:Notify("Quick Action", "Rejoin requested.", "info") end },
    { Name = "Reset Character", Callback = function() Window:Notify("Quick Action", "Character reset requested.", "info") end },
    { Name = "Server Hop", Callback = function() Window:Notify("Quick Action", "Server hop requested.", "info") end },
} })

-- Sidebar pages keep the library useful beyond the visual showcase.
local Player = Window:AddTab({ Name = "Player", Description = "Movement and automation", Icon = "player", Badge = "LIVE" })
local Travel = safeSection(Player, { Name = "Player Tools", Description = "Movement and travel controls.", Side = "Left" })
Travel:AddToggle({ Name = "Auto travel", Description = "Run the selected travel method.", Icon = "teleport", Default = false, Flag = "auto_travel" })
Travel:AddDropdown({ Name = "Travel method", Description = "Teleport, safe walk or guarded movement.", Icon = "move", Options = { "Teleport", "Safe Walk", "Anti Guard", "Fly Glide" }, Default = "Teleport", Flag = "travel_method" })
Travel:AddSlider({ Name = "Check delay", Description = "How often the worker checks for a target.", Icon = "timer", Min = 0.1, Max = 10, Default = 1, Suffix = "s" })
Travel:AddKeybind({ Name = "Toggle automation", Icon = "bolt", Default = "RightShift" })
local PlayerStatus = safeSection(Player, { Name = "Runner status", Description = "Live state of the current workspace.", Side = "Right" })
PlayerStatus:AddStatus({ Name = "Library state", Text = "Online", Color = Window.Theme.Success, Icon = "check" })
PlayerStatus:AddStatus({ Name = "Current profile", Text = "Default", Color = Window.Theme.Accent2, Icon = "user" })
PlayerStatus:AddParagraph({ Title = "Readable by design", Content = "Every control accepts a description, icon and flag. Cards resize from their real content so nothing overlaps or disappears." })

local World = Window:AddTab({ Name = "World", Description = "Lighting and environment", Icon = "world" })
local WorldCard = safeSection(World, { Name = "Environment", Description = "Tune the current world.", Side = "Left" })
WorldCard:AddToggle({ Name = "Full Bright", Icon = "sun", Default = true })
WorldCard:AddToggle({ Name = "Remove Fog", Icon = "eyeoff", Default = false })
WorldCard:AddDropdown({ Name = "Time of Day", Icon = "clock", Options = { "Day", "Sunset", "Night" }, Default = "Day" })

local Visuals = Window:AddTab({ Name = "Visuals", Description = "Clean visual controls", Icon = "eye" })
local VisualCard = safeSection(Visuals, { Name = "Visuals", Description = "Optional visual helpers.", Side = "Left" })
VisualCard:AddToggle({ Name = "Show Hitboxes", Description = "Visualize important objects.", Icon = "grid", Default = false })
VisualCard:AddToggle({ Name = "Monochrome screen", Description = "Toggle the black and white display effect.", Icon = "contrast", Default = false })

local Utilities = Window:AddTab({ Name = "Utilities", Description = "Useful one-click tools", Icon = "utilities" })
local UtilityCard = safeSection(Utilities, { Name = "Quick Actions", Description = "Common features, one click away.", Side = "Left" })
UtilityCard:AddButton({ Name = "Copy Discord link", Description = "Copy the Axel Hub community invite.", Icon = "discord", Callback = function()
    local copy = setclipboard or toclipboard
    if copy then copy("https://discord.gg/axelhub") end
end })
UtilityCard:AddButton({ Name = "Unload UI", Description = "Remove the interface and stop all listeners.", Icon = "power", Callback = function() Window:Unload() end })

local Configs = Window:AddTab({ Name = "Configs", Description = "Save and load setups", Icon = "configs" })
local ConfigCard = safeSection(Configs, { Name = "Configuration", Description = "Keep your favorite setups ready.", Side = "Left" })
ConfigCard:AddButton({ Name = "Save current configuration", Icon = "save", Callback = function() Window:SaveConfig("axelhub-demo") end })
ConfigCard:AddButton({ Name = "Load saved configuration", Icon = "download", Callback = function() Window:LoadConfig("axelhub-demo") end })

Window:AddTab({ Name = "Marketplace", Description = "More tools coming soon", Icon = "shop" })

return Window
