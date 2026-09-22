-- AxelUI Library showcase
-- Replace this URL with your hosted/local loader when distributing it.
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
    },
    Logo = "AxelLogo.png",
    Background = "AxelLogo.png",
    BackgroundTransparency = 0.94,
    LoadingText = "Axel Hub",
    LoadingSubtitle = "Preparing your workspace",
})

Window:Notify({
    Title = "Welcome to Axel Hub",
    Content = "Your workspace is ready. Use the search box to find any feature faster.",
    Type = "success",
})

local Home = Window:AddTab({ Name = "Home", Description = "Live status and quick actions", Icon = "home" })
Home:AddHero({
    Image = "AxelLogo.png",
    Title = "Customize your experience",
    Content = "Simple. Powerful. Yours. Build your own control center with clean, readable controls.",
    Button = "Get Started",
    Height = 116,
    Callback = function() Window:Notify("Axel Hub", "Your dashboard is ready.", "info") end,
})

local PlayerTools = Home:AddSection({ Name = "Player Tools", Description = "Fine tune your movement and abilities.", Side = "Left" })
PlayerTools:AddToggle({ Name = "Enable Movement Mods", Description = "Unlock advanced movement options.", Icon = "running", Default = true })
PlayerTools:AddSlider({ Name = "Walk Speed", Description = "Adjust the character movement speed.", Icon = "speed", Min = 1, Max = 50, Default = 16, Flag = "walk_speed" })
PlayerTools:AddSlider({ Name = "Jump Power", Description = "Adjust the character jump strength.", Icon = "arrows", Min = 1, Max = 100, Default = 50, Flag = "jump_power" })
PlayerTools:AddToggle({ Name = "Infinite Jump", Description = "Keep going higher when enabled.", Icon = "move", Default = false })
PlayerTools:AddToggle({ Name = "No Fall Damage", Description = "Land without limits.", Icon = "shield", Default = true })

local WorldSettings = Home:AddSection({ Name = "World Settings", Description = "Adjust how you see and interact with the world.", Side = "Right" })
WorldSettings:AddToggle({ Name = "Full Bright", Description = "Light up dark areas.", Icon = "star", Default = true })
WorldSettings:AddToggle({ Name = "Remove Fog", Description = "See further and play clearer.", Icon = "eyeoff", Default = false })
WorldSettings:AddDropdown({ Name = "Time of Day", Description = "Choose a world lighting preset.", Icon = "clock", Options = { "Day", "Sunset", "Night" }, Default = "Day" })
WorldSettings:AddSlider({ Name = "Field of View", Description = "Tune the camera view angle.", Icon = "eye", Min = 40, Max = 120, Default = 70, Suffix = "°" })
WorldSettings:AddToggle({ Name = "Show Hitboxes", Description = "Visualize important objects.", Icon = "grid", Default = false })

local Config = Home:AddSection({ Name = "Configuration", Description = "Save and load your favorite setups.", Side = "Left" })
Config:AddDropdown({ Name = "Preset", Icon = "folder", Options = { "Default", "Farm", "Combat" }, Default = "Default" })
Config:AddButton({ Name = "Save configuration", Description = "Persist all flagged settings.", Icon = "save", Callback = function()
    local ok, err = Window:SaveConfig("axelhub-demo")
    Window:Notify("Configuration", ok and "Configuration saved." or tostring(err), ok and "success" or "error")
end })
Config:AddButton({ Name = "Load configuration", Description = "Restore your last saved setup.", Icon = "download", Callback = function()
    local ok, err = Window:LoadConfig("axelhub-demo")
    Window:Notify("Configuration", ok and "Configuration loaded." or tostring(err), ok and "success" or "error")
end })

local Quick = Home:AddSection({ Name = "Quick Actions", Description = "Common features, one click away.", Side = "Right" })
Quick:AddButton({ Name = "Rejoin current server", Icon = "refresh", Callback = function() Window:Notify("Quick Action", "Rejoin requested.", "info") end })
Quick:AddButton({ Name = "Copy Discord link", Description = "Copy the Axel Hub community invite.", Icon = "discord", Callback = function()
    local copy = setclipboard or toclipboard
    if copy then copy("https://discord.gg/axelhub") end
end })
Quick:AddButton({ Name = "Unload UI", Description = "Remove the interface and stop all listeners.", Icon = "power", Callback = function() Window:Unload() end })

local Automation = Window:AddTab({ Name = "Player", Description = "Automation and travel", Icon = "player", Badge = "LIVE" })
local Travel = Automation:AddSection({ Name = "Travel", Description = "Choose how the character moves between targets.", Side = "Left" })
Travel:AddToggle({ Name = "Auto travel", Icon = "teleport", Default = false, Flag = "auto_travel" })
Travel:AddDropdown({ Name = "Travel method", Description = "Teleport, safe walk or guarded movement.", Icon = "move", Options = { "Teleport", "Safe Walk", "Anti Guard", "Fly Glide" }, Default = "Teleport", Flag = "travel_method" })
Travel:AddSlider({ Name = "Check delay", Description = "How often the worker checks for a target.", Icon = "timer", Min = 0.1, Max = 10, Default = 1, Suffix = "s" })
Travel:AddKeybind({ Name = "Toggle automation", Icon = "bolt", Default = "RightShift" })

local Status = Automation:AddSection({ Name = "Runner status", Description = "Live state of the current workspace.", Side = "Right" })
Status:AddStatus({ Name = "Library state", Text = "Online", Color = Window.Theme.Success, Icon = "check" })
Status:AddStatus({ Name = "Current profile", Text = "Default", Color = Window.Theme.Accent2, Icon = "user" })
Status:AddParagraph({ Title = "Readable by design", Content = "Every control accepts a description, icon and flag. Cards resize from their real content so nothing overlaps or disappears." })

local Settings = Window:AddTab({ Name = "Settings", Description = "Appearance and cleanup", Icon = "settings" })
local Interface = Settings:AddSection({ Name = "Interface", Description = "Tune the UI or remove it safely." })
Interface:AddColorPicker({ Name = "Accent color", Description = "Choose the highlight color used by the interface.", Icon = "palette", Flag = "accent_color" })
Interface:AddMultiDropdown({ Name = "Visible modules", Description = "Pick which modules should be active.", Icon = "layers", Options = { "Player", "World", "Visuals", "Utilities" }, Default = { "Player", "World" }, Flag = "visible_modules" })
Interface:AddButton({ Name = "Set online status", Icon = "check", Callback = function() Window:SetStatus("Online", Window.Theme.Success) end })
Interface:AddButton({ Name = "Clear background", Icon = "x", Callback = function() Window:ClearBackground() end })

return Window
