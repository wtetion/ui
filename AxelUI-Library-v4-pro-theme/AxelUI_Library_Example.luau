-- AxelUI dashboard showcase
-- Replace YOUR_AXEL_UI_LIBRARY_URL with the URL where you host AxelUI_Library.luau.
local AxelUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/wtetion/ui/refs/heads/main/AxelUI-Library-v4-pro-theme/AxelUI_Library.luau"))()

local Window = AxelUI.CreateWindow({
    Name = "Axel Hub",
    Subtitle = "Play Further",
    Footer = "v1.0.0  •  Ready when you are",
    GuiName = "AxelHubUI",
    ToggleKeybind = "RightControl",
    Theme = {
        Accent = Color3.fromRGB(255, 193, 7),
        Accent2 = Color3.fromRGB(255, 221, 120),
        Background = Color3.fromRGB(10, 10, 12),
        Surface = Color3.fromRGB(17, 17, 19),
        Surface2 = Color3.fromRGB(24, 24, 27),
        Element = Color3.fromRGB(30, 29, 28),
        Border = Color3.fromRGB(91, 72, 31),
    },
    Logo = "AxelLogo.png",
    Background = "AxelLogo.png",
    BackgroundTransparency = 0.94,
    LoadingText = "Axel Hub",
    LoadingSubtitle = "Preparing your workspace",
})

Window:Notify({
    Title = "Welcome to Axel Hub",
    Content = "Search features from the top bar or choose a section from the sidebar.",
    Type = "success",
})

-- Home follows the reference composition: hero, pill tabs, then two columns of cards.
local Home = Window:AddTab({ Name = "Home", Description = "Live status and quick actions", Icon = "home" })
Home:AddHero({
    Image = "AxelLogo.png", -- replace with your own scenic rbxassetid/local image if desired
    Title = "Customize your experience",
    Content = "Simple. Powerful. Yours. Build your own control center with clean, readable controls.",
    Button = "Get Started",
    Height = 116,
    Callback = function() Window:Notify("Axel Hub", "Your dashboard is ready.", "info") end,
})

Home:AddPill({ Name = "Overview", Active = true })
Home:AddPill({ Name = "Player", Callback = function() Window:Notify("Overview", "Player tools are below.", "info") end })
Home:AddPill({ Name = "World", Callback = function() Window:Notify("Overview", "World settings are below.", "info") end })
Home:AddPill({ Name = "Visuals", Callback = function() Window:Notify("Overview", "Visual controls are below.", "info") end })
Home:AddPill({ Name = "Utilities", Callback = function() Window:Notify("Overview", "Utility controls are below.", "info") end })
Home:AddPill({ Name = "Configs", Callback = function() Window:Notify("Overview", "Configuration is below.", "info") end })

local PlayerTools = Home:AddSection({ Name = "Player Tools", Description = "Fine tune your movement and abilities.", Side = "Left" })
PlayerTools:AddToggle({ Name = "Enable Movement Mods", Description = "Unlock advanced movement options.", Icon = "running", Default = true })
PlayerTools:AddSlider({ Name = "Walk Speed", Description = "Adjust the character movement speed.", Icon = "speed", Min = 1, Max = 50, Default = 16, Flag = "walk_speed" })
PlayerTools:AddSlider({ Name = "Jump Power", Description = "Adjust the character jump strength.", Icon = "arrows", Min = 1, Max = 100, Default = 50, Flag = "jump_power" })
PlayerTools:AddToggle({ Name = "Infinite Jump", Description = "Keep going higher.", Icon = "move", Default = false })
PlayerTools:AddToggle({ Name = "No Fall Damage", Description = "Land without limits.", Icon = "shield", Default = true })

local WorldSettings = Home:AddSection({ Name = "World Settings", Description = "Adjust how you see and interact with the world.", Side = "Right" })
WorldSettings:AddToggle({ Name = "Full Bright", Description = "Light up dark areas.", Icon = "star", Default = true })
WorldSettings:AddToggle({ Name = "Remove Fog", Description = "See further, play clearer.", Icon = "eyeoff", Default = false })
WorldSettings:AddDropdown({ Name = "Time of Day", Description = "Choose a world lighting preset.", Icon = "clock", Options = { "Day", "Sunset", "Night" }, Default = "Day" })
WorldSettings:AddSlider({ Name = "Field of View", Description = "Tune the camera view angle.", Icon = "eye", Min = 40, Max = 120, Default = 70, Suffix = "°" })
WorldSettings:AddToggle({ Name = "Show Hitboxes", Description = "Visualize important objects.", Icon = "grid", Default = false })

local Config = Home:AddSection({ Name = "Configuration", Description = "Save and load your favorite setups.", Side = "Left" })
Config:AddDropdown({ Name = "Preset", Icon = "folder", Options = { "Default", "Farm", "Combat" }, Default = "Default" })
Config:AddButton({ Name = "Save", Description = "Persist all flagged settings.", Icon = "save", Callback = function()
    local ok, err = Window:SaveConfig("axelhub-demo")
    Window:Notify("Configuration", ok and "Configuration saved." or tostring(err), ok and "success" or "error")
end })
Config:AddButton({ Name = "Load", Description = "Restore your last saved setup.", Icon = "download", Callback = function()
    local ok, err = Window:LoadConfig("axelhub-demo")
    Window:Notify("Configuration", ok and "Configuration loaded." or tostring(err), ok and "success" or "error")
end })

local Quick = Home:AddSection({ Name = "Quick Actions", Description = "Common features, one click away.", Side = "Right" })
Quick:AddButton({ Name = "Rejoin", Icon = "refresh", Callback = function() Window:Notify("Quick Action", "Rejoin requested.", "info") end })
Quick:AddButton({ Name = "Reset Character", Icon = "user", Callback = function() Window:Notify("Quick Action", "Character reset requested.", "info") end })
Quick:AddButton({ Name = "Server Hop", Icon = "server", Callback = function() Window:Notify("Quick Action", "Server hop requested.", "info") end })

-- Sidebar pages keep the library useful beyond the visual showcase.
local Player = Window:AddTab({ Name = "Player", Description = "Movement and automation", Icon = "player", Badge = "LIVE" })
local Travel = Player:AddSection({ Name = "Player Tools", Description = "Movement and travel controls.", Side = "Left" })
Travel:AddToggle({ Name = "Auto travel", Description = "Run the selected travel method.", Icon = "teleport", Default = false, Flag = "auto_travel" })
Travel:AddDropdown({ Name = "Travel method", Description = "Teleport, safe walk or guarded movement.", Icon = "move", Options = { "Teleport", "Safe Walk", "Anti Guard", "Fly Glide" }, Default = "Teleport", Flag = "travel_method" })
Travel:AddSlider({ Name = "Check delay", Description = "How often the worker checks for a target.", Icon = "timer", Min = 0.1, Max = 10, Default = 1, Suffix = "s" })
Travel:AddKeybind({ Name = "Toggle automation", Icon = "bolt", Default = "RightShift" })
local PlayerStatus = Player:AddSection({ Name = "Runner status", Description = "Live state of the current workspace.", Side = "Right" })
PlayerStatus:AddStatus({ Name = "Library state", Text = "Online", Color = Window.Theme.Success, Icon = "check" })
PlayerStatus:AddStatus({ Name = "Current profile", Text = "Default", Color = Window.Theme.Accent2, Icon = "user" })
PlayerStatus:AddParagraph({ Title = "Readable by design", Content = "Every control accepts a description, icon and flag. Cards resize from their real content so nothing overlaps or disappears." })

local World = Window:AddTab({ Name = "World", Description = "Lighting and environment", Icon = "world" })
local WorldCard = World:AddSection({ Name = "Environment", Description = "Tune the current world.", Side = "Left" })
WorldCard:AddToggle({ Name = "Full Bright", Icon = "sun", Default = true })
WorldCard:AddToggle({ Name = "Remove Fog", Icon = "eyeoff", Default = false })
WorldCard:AddDropdown({ Name = "Time of Day", Icon = "clock", Options = { "Day", "Sunset", "Night" }, Default = "Day" })

local Visuals = Window:AddTab({ Name = "Visuals", Description = "Clean visual controls", Icon = "eye" })
local VisualCard = Visuals:AddSection({ Name = "Visuals", Description = "Optional visual helpers.", Side = "Left" })
VisualCard:AddToggle({ Name = "Show Hitboxes", Description = "Visualize important objects.", Icon = "grid", Default = false })
VisualCard:AddToggle({ Name = "Monochrome screen", Description = "Toggle the black and white display effect.", Icon = "contrast", Default = false })

local Utilities = Window:AddTab({ Name = "Utilities", Description = "Useful one-click tools", Icon = "utilities" })
local UtilityCard = Utilities:AddSection({ Name = "Quick Actions", Description = "Common features, one click away.", Side = "Left" })
UtilityCard:AddButton({ Name = "Copy Discord link", Description = "Copy the Axel Hub community invite.", Icon = "discord", Callback = function()
    local copy = setclipboard or toclipboard
    if copy then copy("https://discord.gg/axelhub") end
end })
UtilityCard:AddButton({ Name = "Unload UI", Description = "Remove the interface and stop all listeners.", Icon = "power", Callback = function() Window:Unload() end })

local Configs = Window:AddTab({ Name = "Configs", Description = "Save and load setups", Icon = "configs" })
local ConfigCard = Configs:AddSection({ Name = "Configuration", Description = "Keep your favorite setups ready.", Side = "Left" })
ConfigCard:AddButton({ Name = "Save current configuration", Icon = "save", Callback = function() Window:SaveConfig("axelhub-demo") end })
ConfigCard:AddButton({ Name = "Load saved configuration", Icon = "download", Callback = function() Window:LoadConfig("axelhub-demo") end })

Window:AddTab({ Name = "Marketplace", Description = "More tools coming soon", Icon = "shop" })

return Window
